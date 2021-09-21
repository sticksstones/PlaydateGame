import "CoreLibs/math"
import "CoreLibs/graphics"
import "CoreLibs/nineslice"
import "CoreLibs/easing"
import "CoreLibs/timer"
import "CoreLibs/sprites"
import 'ball'
import 'platform'
import 'editorMenu'
import 'shared_funcs'

local graphics <const> = playdate.graphics
local geometry <const> = playdate.geometry

local game_setup = false
local inEditor = false
local editorToggleButtonReleased = false

function playdate.update()
  if not game_setup then
    setup()
    enterGameMode()
  end
    
  local dt <const> = 1.0 / playdate.display.getRefreshRate()
  
  checkToggleEditorMode() 

  if not inEditor then
    update(dt)  
  else
    updateInEditor(dt)
  end
  
  updateCamera(dt)  
  draw()

  playdate.graphics.sprite.update()    

  postSpriteDraw()  

  if inEditor then 
    drawInEditor()
  end

end

function playdate.keyPressed(key)
end

function playdate.keyReleased(key)
end


local SCREEN_WIDTH <const> = 400.0
local SCREEN_HEIGHT <const> = 240.0

local WORLD_WIDTH <const> = SCREEN_WIDTH
local WORLD_HEIGHT <const> = SCREEN_WIDTH

local WORLD_PIXEL_SCALE <const> = 1.0

local wallninesliceImg = nil
local ninesliceImg = nil

local world = nil
local levelObjs = table.create(2,0)
local selectedPlatformIndex = 0
local box = nil
local ball = nil

-- Camera vars

local CAMERA_TRACK_BOUND_X <const> = 0.25
local CAMERA_TRACK_BOUND_Y <const> = 0.15

local CAMERA_BOUND_X <const> = 0.2
local CAMERA_BOUND_Y <const> = 0.2

local desiredCameraOffset = nil
local currentCameraOffset = nil

local cameraRecenterTimestamp = 0.0
local CAMERA_RECENTER_TIME <const> = 1.0
local cameraNeedsRecenter = false
local cameraTarget = nil


-- Editor vars
local editorMenuRef = nil
local editorToggleButtonReleaseRequired = false
local cursor = nil
local cursorMoveVel = 1.0
local CURSOR_MAX_VEL <const> = 8.0
local cursorTarget = nil
local editorSelectedTarget = nil
local editorAButtonTimestamp = 0.0

local editorMode = "base"
local prevEditorMode = "base"
local manipulateType = ""

-- BG vars
local bgTilemap = nil
local bgImage = nil

local function createPlatform(x, y, width, height, rotation)
  rotation = rotation or 0.0
  local platform = playbox.body.new(width, height, 10000)
  platform:setCenter(x, y)
  platform:setFriction(0.7)
  platform:setLockPosition(1)
  platform:setGravityMult(0.0)
  platform:setTorque(0.0)
  platform:setI(100000.0)
  platform:setRotation(deg2Rad(rotation))
  world:addBody(platform)
    
  platformObj = Platform(width,height,platform,ninesliceImg)
  platformObj:moveTo(x,y)
  platformObj:setRotation(rotation)
  levelObjs[#levelObjs + 1] = platformObj
  return platformObj
end

local function createWall(x, y, width, height, rotation)
  rotation = rotation or 0.0
  local platform = playbox.body.new(width, height, 0)
  platform:setCenter(x, y)
  platform:setFriction(0.7)
  platform:setLockPosition(1)
  platform:setGravityMult(0.0)
  platform:setTorque(0.0)
  platform:setI(100000.0)
  platform:setRotation(deg2Rad(rotation))
  world:addBody(platform)
  
  platformObj = Wall(width,height,platform,ninesliceImg)
  platformObj:moveTo(x,y)
  platformObj:setRotation(rotation)
  levelObjs[#levelObjs + 1] = platformObj
  return platformObj
end

function editorCreatePlatform()
  local x,y = cursor:getPosition()
  local platform = createPlatform(x, y, 20, 20, 0.0)
  editorSelectedTarget = platform
  cursor:moveTo(editorSelectedTarget:getPosition())
  snapCameraToTarget()

  changeEditorMode("manipulate")
end 

function editorCloseMenu() 
  changeEditorMode("base")
end 

local function createBall(x, y, width, height, mass)
  box = playbox.body.new(width, height, mass)
  box:setCenter(x, y)
  box:setFriction(0.1)
  world:addBody(box)
  ball = Ball(box)
end

function loadLevelFromData(levelData)
  platformData = levelData["platforms"]
  for i, platform in ipairs(platformData) do 
    createPlatform(platform["x"], platform["y"], platform["width"], platform["height"], platform["rotation"])  
  end

  -- Create box
  playerData = levelData["player"]  
  createBall(playerData["x"], playerData["y"], playerData["width"], playerData["height"], playerData["mass"])
end

function writeLevelData() 
  levelData["player"] = {x=0.6*SCREEN_WIDTH, y=0.0, width=16, height=16, mass=1.0}
  levelData["platforms"] = {}
  for i, platform in ipairs(levelObjs) do
    platformBody = platform.platformBody
    x,y = platformBody:getCenter()
    width,height = platformBody:getSize()
    levelData["platforms"][i] = {x=x, y=y, width=width, height=height, rotation=rad2Deg(platformBody:getRotation())}  
  end 
  
  playdate.datastore.write(levelData)    
end

function initializeLevelData() 
  local levelData = {}
  levelData["player"] = {x=0.6*SCREEN_WIDTH, y=0.0, width=16, height=16, mass=1.0}
  levelData["platforms"] = {}
  levelData["platforms"][1] = {x=0.5*SCREEN_WIDTH,y=0.5*SCREEN_HEIGHT,width=200.0,height=16.0,rotation=0.0}
  levelData["platforms"][2] = {x=0.9*SCREEN_WIDTH,y=0.8*SCREEN_HEIGHT,width=200.0,height=16.0,rotation=90.0}
  levelData["platforms"][3] = {x=0.4*SCREEN_WIDTH,y=0.7*SCREEN_HEIGHT,width=100.0,height=16.0,rotation=0.0}
  
  playdate.datastore.write(levelData)  
end

function setup()
 -- Setup graphics
  playdate.display.setRefreshRate(30)
  playdate.graphics.setBackgroundColor(playdate.graphics.kColorClear)
  ninesliceImg = graphics.nineSlice.new("assets/pngs/general/Platform9SliceSquare", 4, 4, 8, 8)
  wallninesliceImg = graphics.nineSlice.new("assets/pngs/general/Wall9SliceSquare", 4, 4, 8, 8)
  -- Setup camera
  currentCameraOffset = geometry.point.new(0,0)
  desiredCameraOffset = geometry.point.new(0,0)
    
  -- Create physics world
  world = playbox.world.new(0.0, 200.0, 4)
  world:setPixelScale(WORLD_PIXEL_SCALE)
  world:setAngularVelocityDampening(0.4)
  
  -- Initialize level
  levelData = playdate.datastore.read()
  if levelData == nil then 
    initializeLevelData()
  end
    
  levelData = playdate.datastore.read()
  loadLevelFromData(levelData)
  
  -- Setup BG
  imageTable = playdate.graphics.imagetable.new("assets/pngs/tilemaps/tilemap")
  bgTilemap = playdate.graphics.tilemap.new()
  bgTilemap:setImageTable(imageTable)
  data = {} 
  tilesWidth = (SCREEN_WIDTH/16*8)
  tilesHeight = (SCREEN_HEIGHT/16*4)
  for i=1,tilesWidth*tilesHeight do
    data[i] = 1
  end
  
  bgTilemap:setTiles(data, tilesWidth)
  
  bgImage = playdate.graphics.image.new(tilesWidth*16, tilesHeight*16, playdate.graphics.kColorClear)
  playdate.graphics.lockFocus(bgImage)
  playdate.graphics.setColor(playdate.graphics.kColorBlack)
  bgTilemap:draw(0,0)
  playdate.graphics.unlockFocus()
  bgImage = bgImage:fadedImage(0.6,playdate.graphics.image.kDitherTypeScreen)
  
  game_setup = true  
end

function leaveGameMode() 
  if levelObjs[selectedPlatformIndex] then 
    levelObjs[selectedPlatformIndex]:setSelected(false)
  end
  selectedPlatformIndex = -1
  selectedBolt = nil  
end

function enterEditor() 
  
  editorToggleButtonReleaseRequired = true  
  
  if not editorMenuRef then 
    editorMenuRef = EditorMenu(self)
  end 
  
  if not cursor then 
    cursorImg = graphics.image.new("assets/pngs/general/Cursor")
    cursor = graphics.sprite.new(cursorImg)
    cursor:setCollideRect(0,0,cursor:getSize())
    cursor:setZIndex(1000)
    cursor:moveTo(currentCameraOffset.x + SCREEN_WIDTH/2.0, currentCameraOffset.y + SCREEN_HEIGHT/2)
    cursor:add()
    cameraTarget = cursor
  end
  
  for i,platform in ipairs(levelObjs) do     
    platform.platformBody:setRotation(deg2Rad(platform.originalRotation))
  end 
  
  ball.physObj:setCenter(ball.originalPosX, ball.originalPosY)
  ball.physObj:setRotation(ball.originalRotation)
  ball.physObj:setForce(0.0,0.0)
  ball.physObj:setVelocity(0.0,0.0)
  ball.physObj:setAngularVelocity(0.0)
  
  prevEditorMode = "base"
  changeEditorMode("base")

end

function leaveEditor() 
  writeLevelData()

  if cursorTarget then   
    cursorTarget:setHighlighted(false)
    cursorTarget:setEditorSelected(false)
    cursorTarget = nil
  end

  if cursor then 
    cursor:remove()
    cursor = nil
  end    
  
  if editorMenuRef then 
    editorMenuRef:kill() 
    editorMenuRef = nil
  end 

end 

function enterGameMode() 
  cameraTarget = ball;
end 

function checkToggleEditorMode() 
  if editorToggleButtonReleased and playdate.buttonIsPressed(playdate.kButtonA) and playdate.buttonIsPressed(playdate.kButtonB) then 
    inEditor = not inEditor
    editorToggleButtonReleased = false;
    
    if inEditor then
      leaveGameMode() 
      enterEditor()
    else
      leaveEditor()
      enterGameMode()
    end 
    return true
  end   
 
  if not playdate.buttonIsPressed(playdate.kButtonA) or not playdate.buttonIsPressed(playdate.kButtonB) then 
    editorToggleButtonReleased = true
  end
  
  return false
end

function checkCursorTargeting() 
  overlappingSprites = cursor:overlappingSprites()
  
  newCursorTarget = nil
  
  if #overlappingSprites > 0 then 
    newCursorTarget = overlappingSprites[1]          
  end 
  
  if cursorTarget ~= newCursorTarget then 
    if cursorTarget then 
      cursorTarget:setHighlighted(false)
    end
    
    cursorTarget = newCursorTarget
    
    if cursorTarget then 
      cursorTarget:setHighlighted(true)
    end
  end 
end

function deleteCursorTarget() 
  for i=1,#levelObjs do 
    if levelObjs[i] == cursorTarget then 
      world:removeBody(levelObjs[i].platformBody)
      levelObjs[i]:remove()
      table.remove(levelObjs,i)
      return
    end 
  end 
end 

function changeEditorMode(newMode) 
  prevEditorMode = editorMode
  editorMode = newMode
  
  if prevEditorMode == "menu" then 
    editorMenuRef:close()
  end 
  
  if editorMode == "menu" then 
    editorMenuRef:open()
  end
  
  if prevEditorMode == "manipulate" then 
    editorLeaveManipulateMode()
  end 
end 

function editorLeaveManipulateMode() 
  editorSelectedTarget:setEditorSelected(false)  
end 

function updateInEditor(dt)    
  playdate.timer.updateTimers()

  -- Update platforms
  for i, platform in ipairs(levelObjs) do
    platform:updatePhysics(0.0)
  end
  
  updateBall()
  
  -- Input handling
  if editorToggleButtonReleaseRequired
     and not (playdate.buttonIsPressed(playdate.kButtonA) 
          or playdate.buttonJustPressed(playdate.kButtonA)) 
     and not (playdate.buttonIsPressed(playdate.kButtonB)
          or playdate.buttonJustPressed(playdate.kButtonB))
     then 
    editorToggleButtonReleaseRequired = false
    return
  end

  if editorToggleButtonReleaseRequired then 
    return 
  end 
  
  -- Buttons
  if playdate.buttonJustPressed(playdate.kButtonA) then
    editorAButtonTimestamp = playdate.getElapsedTime()
  end
  
  -- MENU
  if editorMode == "menu" then 
    -- B
    if playdate.buttonJustReleased(playdate.kButtonB) then
      changeEditorMode("base")
    end  
    
  -- BASE 
  elseif editorMode == "base" then 
    -- A
    if playdate.buttonJustPressed(playdate.kButtonA) then    
      if cursorTarget then 
        editorSelectedTarget = cursorTarget
        cursor:moveTo(cursorTarget:getPosition())
        snapCameraToTarget()
      end 
    elseif playdate.buttonJustReleased(playdate.kButtonA) then     
      if cursorTarget and editorSelectedTarget and playdate.getElapsedTime() < editorAButtonTimestamp + 0.5 then 
        changeEditorMode("manipulate")
        editorSelectedTarget:setEditorSelected(true)  
      elseif prevEditorMode == "manipulate" then 
          changeEditorMode("manipulate")
      end 
    elseif playdate.buttonIsPressed(playdate.kButtonA) then 
      if editorSelectedTarget and playdate.getElapsedTime() > editorAButtonTimestamp + 0.5 then 
        changeEditorMode("move")
      end   
    end

    -- B
    if playdate.buttonJustReleased(playdate.kButtonB) then 
      if cursorTarget then 
        deleteCursorTarget()
      else 
        changeEditorMode("menu")      
      end
    end 
  -- MOVE 
  elseif editorMode == "move" then 
    -- A
    if playdate.buttonJustReleased(playdate.kButtonA) then
      if prevEditorMode == "manipulate" then 
        changeEditorMode("manipulate")
        editorSelectedTarget:setEditorSelected(true)
      else 
        changeEditorMode("base")
        editorSelectedTarget = nil
      end
    end

  -- MANIPULATE
  elseif editorMode == "manipulate" then 
    -- A
    -- if playdate.buttonJustReleased(playdate.kButtonA) then
    --   changeEditorMode("base")
    if playdate.buttonIsPressed(playdate.kButtonA) then 
      -- if editorSelectedTarget and playdate.getElapsedTime() > editorAButtonTimestamp + 0.5 then 
      changeEditorMode("move")
      -- end   
    end 
    
    -- B 
    if playdate.buttonJustReleased(playdate.kButtonB) then
      changeEditorMode("base")      
    end 

  -- ALL OTHERS
  else 
    -- A
    if playdate.buttonJustReleased(playdate.kButtonA) then
      changeEditorMode("base")
      editorSelectedTarget = nil
    end
  
    -- B
    if playdate.buttonJustReleased(playdate.kButtonB) then 
      if editorSelectedTarget then 
        changeEditorMode("base")
      end 
    end    
  end 
      
  
  

  -- Dpad controls tools while in manipulate mode
  if editorMode == "manipulate" then 
    if playdate.buttonIsPressed(playdate.kButtonUp) then 
      manipulateType = "scaleVertical"
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then 
      manipulateType = "scaleHorizontal"
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then 
      manipulateType = "rotation"
    end 
    
    local crankVal = playdate.getCrankChange()
    if manipulateType == "rotation" then 
      currentRotation = editorSelectedTarget.platformBody:getRotation()
      newRotation = currentRotation + deg2Rad(crankVal)
      editorSelectedTarget.platformBody:setRotation(newRotation)
      editorSelectedTarget.originalRotation = rad2Deg(newRotation)
    elseif manipulateType == "scaleHorizontal" then 
      x,y = editorSelectedTarget.platformBody:getSize()
      editorSelectedTarget.platformBody:setSize(math.max(x + crankVal, 16.0), y)
    elseif manipulateType == "scaleVertical" then 
      x,y = editorSelectedTarget.platformBody:getSize()
      editorSelectedTarget.platformBody:setSize(x, math.max(y + crankVal, 16.0))
    end 
  end
  
  -- Update cursor velocity
  if not playdate.buttonIsPressed(playdate.kButtonLeft) and 
   not playdate.buttonIsPressed(playdate.kButtonRight) and 
   not playdate.buttonIsPressed(playdate.kButtonUp) and 
   not playdate.buttonIsPressed(playdate.kButtonDown)
   then 
    manipulateType = "" 
    cursorMoveVel = 1.0
  else 
    cursorMoveVel += dt * 5.0
    cursorMoveVel = math.min(CURSOR_MAX_VEL, cursorMoveVel)
  end
    
  -- Update cursor position
  if editorMode == "menu" then 
    -- don't do anything with cursor while in menu
  elseif editorMode == "manipulate" then 
    -- don't do anything with cursor while in manipulate mode
  else
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
      cursor:moveBy(-cursorMoveVel, 0)
    end
    
    if playdate.buttonIsPressed(playdate.kButtonRight) then
      cursor:moveBy(cursorMoveVel, 0)
    end  
  
    if playdate.buttonIsPressed(playdate.kButtonDown) then
      cursor:moveBy(0, cursorMoveVel)
    end  
    
    if playdate.buttonIsPressed(playdate.kButtonUp) then
      cursor:moveBy(0, -cursorMoveVel)
    end  
  end
  
  -- Update position of object in move mode
  if editorMode == "move" then 
    posX, posY = editorSelectedTarget.platformBody:getCenter()
    editorSelectedTarget.platformBody:setCenter(cursor:getPosition())
  end 
  
  -- Update cursor target
  if editorMode == "base" then 
    checkCursorTargeting()
  end  
  
  if editorMenuRef then 
    editorMenuRef:update()
  end
end

function updateCrankPlatformControl() 
  local crankVal = playdate.getCrankChange()
  local crankValAbs = math.abs(crankVal)
  local crankValPerc = crankValAbs / 50.0
  local crankValClamped = math.min(crankValPerc, 1.0)
    
  local maxDegrees = 90.0
  
  local delta = playdate.math.lerp(0.0, maxDegrees, crankValClamped)
  if crankVal < 0.0 then
    delta *= -1.0
  end

  local selectedBolt = levelObjs[selectedPlatformIndex].platformBody
  selectedBolt:setTorque(selectedBolt:getTorque() + crankVal*10000.0)  
end

function jumpPlatform(direction)
  if levelObjs[selectedPlatformIndex] then 
    levelObjs[selectedPlatformIndex]:setSelected(false)
  end 
  
  selectedPlatformIndex -= direction  
  
  if selectedPlatformIndex < 1 then
    selectedPlatformIndex = #levelObjs
  elseif selectedPlatformIndex > #levelObjs then
    selectedPlatformIndex = 1
  end
  
  if levelObjs[selectedPlatformIndex] then 
    levelObjs[selectedPlatformIndex]:setSelected(true)
  end

end

function snapCameraToTarget() 
  -- currentCameraOffset.x = desiredCameraOffset.x 
  -- currentCameraOffset.y = desiredCameraOffset.y
  cameraNeedsRecenter = true
  cameraRecenterTimestamp = playdate.getElapsedTime()
end 

function updateCamera(dt)     
  if cameraTarget then     
    local camUpdated = false

    local rightBoundX = desiredCameraOffset.x + ((1.0 - CAMERA_TRACK_BOUND_X) * SCREEN_WIDTH)
    local leftBoundX = desiredCameraOffset.x + (CAMERA_TRACK_BOUND_X * SCREEN_WIDTH)
    
    if cameraTarget.x > rightBoundX then
      local newOffset = desiredCameraOffset.x + cameraTarget.x - rightBoundX
      if math.abs(newOffset - desiredCameraOffset.x) > 1.0 then 
        desiredCameraOffset.x = newOffset
        camUpdated = true
      end
    elseif cameraTarget.x < leftBoundX then 
      local newOffset = desiredCameraOffset.x + cameraTarget.x - leftBoundX
      if math.abs(newOffset - desiredCameraOffset.x) > 1.0 then 
        desiredCameraOffset.x =  newOffset
        camUpdated = true
      end
    end
    
    local upBoundY = desiredCameraOffset.y + (CAMERA_TRACK_BOUND_Y * SCREEN_HEIGHT)    
    local downBoundY = desiredCameraOffset.y + ((1.0 - CAMERA_TRACK_BOUND_Y) * SCREEN_HEIGHT)
    
    if cameraTarget.y < upBoundY then
      local newOffset = desiredCameraOffset.y + cameraTarget.y - upBoundY
      if math.abs(newOffset - desiredCameraOffset.y) > 1.0 then 
        desiredCameraOffset.y = newOffset
        camUpdated = true
      end
    elseif cameraTarget.y > downBoundY then 
      local newOffset = desiredCameraOffset.y + cameraTarget.y - downBoundY
      if math.abs(newOffset - desiredCameraOffset.y) > 1.0 then 
        desiredCameraOffset.y =  newOffset
        camUpdated = true
      end
    end
    
    if camUpdated then 
      cameraRecenterTimestamp = playdate.getElapsedTime() + CAMERA_RECENTER_TIME
      cameraNeedsRecenter = true
    end
        
    if cameraNeedsRecenter and playdate.getElapsedTime() > cameraRecenterTimestamp then
      desiredCameraOffset.x = cameraTarget.x - SCREEN_WIDTH/2.0
      desiredCameraOffset.y = cameraTarget.y - SCREEN_HEIGHT/2.0
      cameraNeedsRecenter = false
    end
    
    local moveVec = geometry.vector2D.new(desiredCameraOffset.x - currentCameraOffset.x, desiredCameraOffset.y - currentCameraOffset.y) 
    local lerpFactor = playdate.math.lerp(7.5, 10.0, moveVec:magnitude()/100.0) 
    
    currentCameraOffset.x = currentCameraOffset.x + ((desiredCameraOffset.x - currentCameraOffset.x) / lerpFactor)--* math.pow(99.0, dt))
    currentCameraOffset.y = currentCameraOffset.y + ((desiredCameraOffset.y - currentCameraOffset.y) / lerpFactor)--* math.pow(99.0, dt))
    
  end
end

function updateBall() 
  local box_polygon = geometry.polygon.new(box:getPolygon())
  box_polygon:close()
  ball:setRotation(ball:getRotation() + box:getVelocity())
  ball:moveTo(getPolyCenter(box_polygon))
end 

function update(dt)
  
  playdate.timer.updateTimers()

  -- Update crank on selected platform
  if selectedPlatformIndex > 0 then
    updateCrankPlatformControl()
  end

  -- Update physics world
  world:update(dt)
  
  -- Update platforms
  for i, platform in ipairs(levelObjs) do
    platform:updatePhysics(dt)
  end

  -- Update ball rotation
  updateBall()
  
  -- Input handling
  if playdate.buttonJustPressed(playdate.kButtonB) then

  end
    
  if playdate.buttonJustPressed(playdate.kButtonA) then
  end
  
  if playdate.buttonJustPressed(playdate.kButtonLeft) then
    --box:addForce(-300, 0)   
   jumpPlatform(-1)
  end
  
  if playdate.buttonJustPressed(playdate.kButtonRight) then
    jumpPlatform(1)
  end  
end

function draw()
  graphics.setDrawOffset(-currentCameraOffset.x, -currentCameraOffset.y)
  graphics.clear(graphics.kColorWhite)
  graphics.setColor(graphics.kColorWhite)
  -- graphics.setLineWidth(1)
  -- graphics.setDitherPattern(0.0)
  
  bgImage:draw(0,0)
  
  -- -- Draw swing joint
  -- graphics.setStrokeLocation(graphics.kStrokeCentered)
  -- local _, _, px1, py1, x2, y2, _, _ = swing_joint:getPoints()
  -- graphics.setDitherPattern(0.5)
  -- graphics.drawLine(x2, y2, px1, py1)
  -- 
  -- Draw FPS on device
  if not playdate.isSimulator then
    playdate.drawFPS(380, 15)
  end  
end

function postSpriteDraw() 
  -- Draw platforms
  for i, platform in ipairs(levelObjs) do
    platform:draw()
  end    
end

function drawInEditor() 
  editorMenuRef:draw()
  
  -- draw controls footer
  local x,y = graphics.getDrawOffset()
  local footerHeight = 20
  x = -x 
  y = -y + SCREEN_HEIGHT - footerHeight
  graphics.setColor(graphics.kColorBlack)
  graphics.fillRect(x, y,SCREEN_WIDTH, footerHeight)
  graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
  graphics.drawText(editorMode, x+5, y + 2)
  graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
  
  -- draw button controls
  graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
  local buttonText = ""
  if editorMode == "base" then 
    buttonText = "(b) menu"
    if cursorTarget then 
      buttonText = "(b) delete (a) select"
    end 
  elseif editorMode == "manipulate" then 
    if manipulateType == "scaleVertical" then 
      buttonText = "(crank) thickness"
    elseif manipulateType == "scaleHorizontal" then 
      buttonText = "(crank) length"      
    elseif manipulateType == "rotation" then 
      buttonText = "(crank) rotate"
    else 
      buttonText = "(b) done (a) move"
    end 
  elseif editorMode == "menu" then 
    buttonText = "(b) close (a) select"
  end 
  graphics.drawTextInRect(buttonText, x + SCREEN_WIDTH/2.0, y + 2, SCREEN_WIDTH/2.0 - 5, 20, 0, "", kTextAlignment.right)
  graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)


  -- draw manipulate controls
  if editorMode == "manipulate" then 
    local crossSize = 25
    local crossThickness = 8
    local xInset = 30
    local yInset = 40
    local circleBackSize = 1.4 * crossSize
    graphics.setColor(graphics.kColorBlack)
    graphics.setDitherPattern(0.1, graphics.image.kDitherTypeBayer8x8)
    graphics.fillCircleAtPoint(x + xInset + crossSize/2.0, y - yInset + 0.0*crossThickness/2.0, circleBackSize)
    -- graphics.drawCircleAtPoint(x + xInset + crossSize/2.0, y - yInset + 0.0*crossThickness/2.0, circleBackSize)
    graphics.setColor(graphics.kColorWhite)    
  
    -- horiz bar
    graphics.fillRect(x + xInset, y - yInset - crossThickness/2.0, crossSize, crossThickness)    
    -- vert bar
    graphics.fillRect(x + xInset + crossSize/2.0 - crossThickness/2.0, y - yInset - crossSize/2.0, crossThickness, crossSize)
    
    graphics.setColor(graphics.kColorBlack)    
    graphics.setDitherPattern(0.5, graphics.image.kDitherTypeDiagonalLine)
  
    if manipulateType == "scaleVertical" then 
      graphics.fillRect(x + xInset + crossSize/2.0 - crossThickness/2.0, y - yInset - crossSize/2.0, crossThickness, crossSize/2.0 - crossThickness/2.0)            
    elseif manipulateType == "scaleHorizontal" then 
      graphics.fillRect(x + xInset + crossSize/2.0 + crossThickness/2.0, y - yInset - crossThickness/2.0, crossSize/2.0 - crossThickness/2.0, crossThickness)    
    elseif manipulateType == "rotation" then 
      graphics.fillRect(x + xInset + crossSize/2.0 - crossThickness/2.0, y - yInset + crossThickness/2.0, crossThickness, crossSize/2.0 - crossThickness/2.0)    
    end 
    
    graphics.setColor(graphics.kColorWhite)    
    graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
    graphics.drawTextInRect("X", x + xInset + crossSize + 5, y - yInset - crossSize/2.0 + 5, 100, 20, 0, "", kTextAlignment.left)
    graphics.drawTextInRect("Y", x + xInset + crossSize/2.0 - 50 + 1, y - yInset - crossSize - 5, 100, 20, 0, "", kTextAlignment.center)
    graphics.drawTextInRect("ROT", x + xInset + crossSize/2.0 - 50 + 1, y - yInset + crossSize - 10, 100, 20, 0, "", kTextAlignment.center)
    graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
  end 
end