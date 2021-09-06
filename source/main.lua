import "CoreLibs/math"
import "CoreLibs/graphics"
import "CoreLibs/nineslice"
import "CoreLibs/easing"
import "CoreLibs/timer"
import "CoreLibs/sprites"
import 'ball'

local graphics <const> = playdate.graphics
local geometry <const> = playdate.geometry

local game_setup = false
local inEditor = false
local editorToggleButtonReleased = false


function playdate.update()
  if not game_setup then
    setup()
  end
  
  -- test 
  
  local dt <const> = 1.0 / playdate.display.getRefreshRate()
  
  if not inEditor then
    update(dt)  
  else
    updateInEditor(dt)
  end
  
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

local world = nil
local platforms = table.create(2, 0)
local selectedPlatformIndex = 0
local box = nil
local selected_box = 1

local ball = nil

local boltAnimPhase = 0.0
local boltAnimTimer = nil

local CAMERA_TRACK_BOUND_X <const> = 0.4
local CAMERA_TRACK_BOUND_Y <const> = 0.4

local CAMERA_BOUND_X <const> = 0.2
local CAMERA_BOUND_Y <const> = 0.2

local desiredCameraOffset = nil
local currentCameraOffset = nil


local function deg2Rad(degrees)
  return (degrees * 3.14 / 180.0)
end

local function rad2Deg(radians)
  return (radians * 180.0 / 3.14)
end

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
end

local function createBall(x, y, width, height, mass)
  box = playbox.body.new(width, height, mass)
  box:setCenter(x, y)
  box:setFriction(0.1)
  world:addBody(box)
  
  ball = Ball()
  ball:addSprite()
end

function getPolyCenter(poly)
  local x1 = poly:getPointAt(1).x
  local x2 = poly:getPointAt(2).x 
  local y1 = poly:getPointAt(1).y 
  local y2 = poly:getPointAt(2).y
  local x21 = poly:getPointAt(3).x
  local x22 = poly:getPointAt(4).x 
  local y21 = poly:getPointAt(3).y 
  local y22 = poly:getPointAt(4).y
    
  center = geometry.point.new((x1+x21)/2.0, (y1+y21)/2.0)
  return center
end

function drawPlatform(drawPoly, isSelected)
  local x1 = drawPoly:getPointAt(1).x
  local x2 = drawPoly:getPointAt(2).x 
  local y1 = drawPoly:getPointAt(1).y 
  local y2 = drawPoly:getPointAt(2).y
  local x21 = drawPoly:getPointAt(3).x
  local x22 = drawPoly:getPointAt(4).x 
  local y21 = drawPoly:getPointAt(3).y 
  local y22 = drawPoly:getPointAt(4).y
 
  width = geometry.lineSegment.new(x1,y1,x2,y2):length()
  height = geometry.lineSegment.new(x2,y2,x21,y21):length()
  center = geometry.point.new((x1+x21)/2.0, (y1+y21)/2.0)
   
  ninesliceImg = graphics.nineSlice.new("assets/pngs/general/Platform9SliceSquare", 4, 4, 8, 8)
  
  contextImg = playdate.graphics.image.new(width, height, graphics.kColorClear)
  graphics.lockFocus(contextImg)
  graphics.setColor(graphics.kColorBlack)
  ninesliceImg:drawInRect(0, 0, width, height)
  graphics.unlockFocus()

  graphics.setColor(graphics.kColorBlack)
  contextImg:drawRotated(center.x, center.y, math.atan2((y2-y1),(x2-x1)) * 180.0/ 3.14, 1.0, 1.0 )
  
  if isSelected then
    playdate.graphics.drawCircleAtPoint(center, playdate.math.lerp(0.0, math.min(height/2.0 - 2, 8), boltAnimTimer.value))
  end
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
  -- Setup game refresh rate
  playdate.display.setRefreshRate(30)

  -- Setup camera
  currentCameraOffset = geometry.point.new(0,0)
  desiredCameraOffset = geometry.point.new(0,0)
  
  -- Setup background color
  playdate.graphics.setBackgroundColor(playdate.graphics.kColorClear)
  
  -- Create world
  world = playbox.world.new(0.0, 200.0, 30)
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

function updateInEditor(dt)  
  if editorToggleButtonReleased and playdate.buttonIsPressed(playdate.kButtonA) and playdate.buttonIsPressed(playdate.kButtonB) then 
    print("leave editor")
    inEditor = false
    editorToggleButtonReleased = false;
    return
  end   
 
  if not playdate.buttonIsPressed(playdate.kButtonA) or not playdate.buttonIsPressed(playdate.kButtonB) then 
    editorToggleButtonReleased = true
  end
  
end

function update(dt)
  if editorToggleButtonReleased and playdate.buttonIsPressed(playdate.kButtonA) and playdate.buttonIsPressed(playdate.kButtonB) then 
    editorToggleButtonReleased = false
    inEditor = true
    print("Go to editor")
    return
  end 
  
  if not playdate.buttonIsPressed(playdate.kButtonA) or not playdate.buttonIsPressed(playdate.kButtonB) then 
    editorToggleButtonReleased = true
  end
  
  playdate.timer.updateTimers()
  local crankVal = playdate.getCrankChange()
  local crankValAbs = math.abs(crankVal)
  local crankValPerc = crankValAbs / 50.0
  local crankValClamped = math.min(crankValPerc, 1.0)
  
  if boltAnimPhase < 1.0 then
    boltAnimPhase += 4.0*dt
  elseif boltAnimPhase > 1.0 then
    boltAnimPhase = 1.0
  end
  
  local maxDegrees = 90.0
  
  local delta = playdate.math.lerp(0.0, maxDegrees, crankValClamped)
  if crankVal < 0.0 then
    delta *= -1.0
  end
  
  if selectedPlatformIndex > 0 then
    local selectedBolt = platforms[selectedPlatformIndex]
    selectedBolt:setTorque(selectedBolt:getTorque() + crankVal*10000.0)
  end

  for i, platform in ipairs(platforms) do
    platform:setTorque(platform:getTorque() * math.pow(0.2, dt))
  end

  world:update(dt)
  
  
  if playdate.buttonJustPressed(playdate.kButtonB) then

  end
    
  if playdate.buttonJustPressed(playdate.kButtonA) then
  end
  
  if playdate.buttonJustPressed(playdate.kButtonLeft) then
    --box:addForce(-300, 0)
    --bolt:setRotation(bolt:getRotation() + 0.1)
    
    selectedPlatformIndex -= 1
    if selectedPlatformIndex < 1 then
      selectedPlatformIndex = #platforms
    end
   
   boltAnimPhase = 0.0
   boltAnimTimer = playdate.timer.new(500, 0.0, 1.0, playdate.easingFunctions.outElastic)

  end
  
  if playdate.buttonJustPressed(playdate.kButtonRight) then
    selectedPlatformIndex += 1
    if selectedPlatformIndex > #platforms then
      selectedPlatformIndex = 1
    end
    
    boltAnimPhase = 0.0
    boltAnimTimer = playdate.timer.new(500, 0.0, 1.0, playdate.easingFunctions.outElastic) 
  end  
  
  -- Update camera
  
  local rightBoundX = currentCameraOffset.x + ((1.0 - CAMERA_TRACK_BOUND_X) * SCREEN_WIDTH)
  local leftBoundX = currentCameraOffset.x + (CAMERA_TRACK_BOUND_X * SCREEN_WIDTH)
  
  if ball.x > rightBoundX and box:getVelocity() > 0 then
    desiredCameraOffset.x = ball.x - rightBoundX
  elseif ball.x < leftBoundX and box:getVelocity() < 0 then 
    desiredCameraOffset.x =  ball.x - leftBoundX
  end
  
  if math.abs(desiredCameraOffset.x - currentCameraOffset.x) > 2.0 then 
    currentCameraOffset.x = currentCameraOffset.x + (desiredCameraOffset.x - currentCameraOffset.x) * math.pow(1.0 - 0.5, dt)
  -- else 
  --   currentCameraOffset.x = desiredCameraOffset.x
  end
  
  currentCameraOffset.y = currentCameraOffset.y + (desiredCameraOffset.y - currentCameraOffset.y) * math.pow(1.0 - 0.5, dt)

end

function draw()
  graphics.setDrawOffset(-currentCameraOffset.x, currentCameraOffset.y)
  graphics.clear(graphics.kColorWhite)
  graphics.setColor(graphics.kColorBlack)
  
  local box_polygon = geometry.polygon.new(box:getPolygon())
  box_polygon:close()
  ball:setRotation(ball:getRotation() + box:getVelocity())
  ball:moveTo(getPolyCenter(box_polygon))
  
  -- graphics.setDitherPattern(0.25)
  -- graphics.fillPolygon(box_polygon)
  -- graphics.setColor(graphics.kColorBlack)
  -- graphics.setLineWidth(3)
  -- graphics.drawPolygon(box_polygon)
  -- print(box:getVelocity())
  -- ball:setBounds(box_polygon:getBoundsRect())  
  

  graphics.setLineWidth(1)
  graphics.setDitherPattern(0.5)
  
  -- Draw platforms
  for i, platform in ipairs(platforms) do
    local platform_polygon = geometry.polygon.new(platform:getPolygon())
    platform_polygon:close()
    graphics.setDitherPattern(0.5)
    
    drawPlatform(platform_polygon, i == selectedPlatformIndex)
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