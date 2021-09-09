import "CoreLibs/graphics"
import "CoreLibs/easing"
import "CoreLibs/timer"
import "CoreLibs/math"
import 'shared_funcs'

class('Platform').extends(playdate.graphics.sprite)

function Platform:updateImage() 
  drawPoly = playdate.geometry.polygon.new(self.platformBody:getPolygon())
  x1 = drawPoly:getPointAt(1).x
  x2 = drawPoly:getPointAt(2).x 
  y1 = drawPoly:getPointAt(1).y 
  y2 = drawPoly:getPointAt(2).y
  x21 = drawPoly:getPointAt(3).x
  x22 = drawPoly:getPointAt(4).x 
  y21 = drawPoly:getPointAt(3).y 
  y22 = drawPoly:getPointAt(4).y
 

  self.width = playdate.geometry.lineSegment.new(x1,y1,x2,y2):length()
  self.height = playdate.geometry.lineSegment.new(x2,y2,x21,y21):length()
  self.center = playdate.geometry.point.new((x1+x21)/2.0, (y1+y21)/2.0)

  self.rectWidth, self.rectHeight = self.platformBody:getSize()
  contextImg = playdate.graphics.image.new(self.rectWidth+1, self.rectHeight+1, playdate.graphics.kColorClear)
  playdate.graphics.lockFocus(contextImg)
  playdate.graphics.setColor(playdate.graphics.kColorBlack)
  self.ninesliceImgRef:drawInRect(0, 0, self.width, self.height)
  playdate.graphics.unlockFocus()

  self:setImage(contextImg)   
	
end 

function Platform:init(width,height,body,ninesliceImg)	
	self.selected = false
	self.highlighted = false
	self.editorSelected = false
	self.boltAnimTimer = nil
	self.ninesliceImgRef = ninesliceImg
	
	Platform.super.init(self)
	self.platformBody = body
	self.originalRotation = rad2Deg(body:getRotation())
	self:updateImage()
  	self:add()
end

function Platform:updatePhysics(dt) 
	currentRectWidth, currentRectHeight = self.platformBody:getCenter()
	
	if self.rectWidth ~= currentRectWidth or self.currentRectHeight ~= currentRectHeight then 
		self:updateImage()
	end 

	self.platformBody:setTorque(self.platformBody:getTorque() * math.pow(0.2, dt))
	
	x,y = self.platformBody:getCenter()
	self:moveTo(x,y)
	
	rotation = rad2Deg(self.platformBody:getRotation())
	if self:getRotation() ~= rotation then 
  		self:setRotation(rotation)
	end
	
	boundsRect = self:getBoundsRect()
	self:setCollideRect(0,0,boundsRect.width, boundsRect.height)	
	
end

function Platform:draw() 
	drawPoly = playdate.geometry.polygon.new(self.platformBody:getPolygon())
  	x1 = drawPoly:getPointAt(1).x
  	x2 = drawPoly:getPointAt(2).x 
  	y1 = drawPoly:getPointAt(1).y 
  	y2 = drawPoly:getPointAt(2).y
  	x21 = drawPoly:getPointAt(3).x
  	x22 = drawPoly:getPointAt(4).x 
  	y21 = drawPoly:getPointAt(3).y 
  	y22 = drawPoly:getPointAt(4).y
 	
  	self.width = playdate.geometry.lineSegment.new(x1,y1,x2,y2):length()
  	self.height = playdate.geometry.lineSegment.new(x2,y2,x21,y21):length()
  	self.center = playdate.geometry.point.new((x1+x21)/2.0, (y1+y21)/2.0)	
	
	if self.selected then 
		playdate.graphics.drawCircleAtPoint(self.center, playdate.math.lerp(0.0, math.min(self.height/2.0 - 2, 8), self.boltAnimTimer.value))	
	end 	
	
	if self.editorSelected then 
		if math.fmod(playdate.getElapsedTime(), 0.5) > 0.25 then 
			self:setVisible(false)	
		else 
			self:setVisible(true)	
		end
	elseif self.highlighted then 
		if math.fmod(playdate.getElapsedTime(), 1.0) > 0.5 then 
			self:setVisible(false)	
		else 
			self:setVisible(true)	
		end
	else 
		self:setVisible(true)
	end 
end 


function Platform:setEditorSelected(flag)
	self.editorSelected = flag
end

function Platform:setHighlighted(flag)
	self.highlighted = flag
end

function Platform:setSelected(flag)
	self.boltAnimTimer = playdate.timer.new(500, 0.0, 1.0, playdate.easingFunctions.outElastic)
	self.selected = flag
end