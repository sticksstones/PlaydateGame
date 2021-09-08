import "CoreLibs/math"
import "CoreLibs/graphics"
import "CoreLibs/nineslice"
import "CoreLibs/easing"
import "CoreLibs/timer"
import "CoreLibs/sprites"
import 'ball'
import 'platform'
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
  
  if inEditor then 
    drawInEditor()
  end

  playdate.graphics.sprite.update()    
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

local ninesliceImg = nil

local world = nil
local platforms = table.create(2, 0)
local platformSprites = table.create(2,0)
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
local cursor = nil
local cursorMoveVel = 1.0
local CURSOR_MAX_VEL <const> = 8.0

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
  platforms[#platforms + 1] = platform
  
  platformObj = Platform(width,height,platform,ninesliceImg)
  platformObj:moveTo(x,y)
  platformObj:setRotation(rotation)
  platformSprites[#platformSprites + 1] = platformObj
end

local function createBall(x, y, width, height, mass)
  box = playbox.body.new(width, height, mass)
  box:setCenter(x, y)
  box:setFriction(0.1)
  world:addBody(box)
  ball = Ball()
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
  
  game_setup = true  
end

function leaveGameMode() 
  
end

function enterEditor() 
  if not cursor then 
    cursorImg = graphics.image.new("assets/pngs/general/Cursor")
    cursor = graphics.sprite.new(cursorImg)
    cursor:moveTo(currentCameraOffset.x + SCREEN_WIDTH/2.0, currentCameraOffset.y + SCREEN_HEIGHT/2)
    cursor:add()
    cameraTarget = cursor
  end
end

function leaveEditor() 
  if cursor then 
    cursor:remove()
    cursor = nil
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

function updateInEditor(dt)    
  -- Input handling
  if playdate.buttonJustPressed(playdate.kButtonB) then

  end
    
  if playdate.buttonJustPressed(playdate.kButtonA) then
  end

  if not playdate.buttonIsPressed(playdate.kButtonLeft) and 
     not playdate.buttonIsPressed(playdate.kButtonRight) and 
     not playdate.buttonIsPressed(playdate.kButtonUp) and 
     not playdate.buttonIsPressed(playdate.kButtonDown)
     then 
      cursorMoveVel = 1.0
    else 
      cursorMoveVel += dt * 5.0
      cursorMoveVel = math.min(CURSOR_MAX_VEL, cursorMoveVel)
  end
  
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

  local selectedBolt = platforms[selectedPlatformIndex]
  selectedBolt:setTorque(selectedBolt:getTorque() + crankVal*10000.0)  
end

function jumpPlatform(direction)
  if platformSprites[selectedPlatformIndex] then 
    platformSprites[selectedPlatformIndex]:setSelected(false)
  end 
  
  selectedPlatformIndex -= direction  
  
  if selectedPlatformIndex < 1 then
    selectedPlatformIndex = #platformSprites
  elseif selectedPlatformIndex > #platformSprites then
    selectedPlatformIndex = 1
  end
  
  if platformSprites[selectedPlatformIndex] then 
    platformSprites[selectedPlatformIndex]:setSelected(true)
  end

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

function update(dt)
  
  playdate.timer.updateTimers()

  -- Update crank on selected platform
  if selectedPlatformIndex > 0 then
    updateCrankPlatformControl()
  end

  -- Update physics world
  world:update(dt)
  
  -- Update platforms
  for i, platform in ipairs(platformSprites) do
    platform:updatePhysics(dt)
  end

  -- Update ball rotation
  local box_polygon = geometry.polygon.new(box:getPolygon())
  box_polygon:close()
  ball:setRotation(ball:getRotation() + box:getVelocity())
  ball:moveTo(getPolyCenter(box_polygon))
  
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
  graphics.setColor(graphics.kColorBlack)
  graphics.setLineWidth(1)
  graphics.setDitherPattern(0.0)
  
  -- Draw platforms
  for i, platform in ipairs(platformSprites) do
    platform:draw()
  end    
  
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

function drawInEditor() 
  
end