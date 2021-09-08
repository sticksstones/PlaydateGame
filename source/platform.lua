import "CoreLibs/graphics"
import "CoreLibs/easing"
import "CoreLibs/timer"
import "CoreLibs/math"
import 'shared_funcs'

class('Platform').extends(playdate.graphics.sprite)


function Platform:init(width,height,body,ninesliceImg)	
	self.selected = false
	self.boltAnimTimer = nil
	
	Platform.super.init(self)
	self.platformBody = body

	drawPoly = playdate.geometry.polygon.new(body:getPolygon())
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
	    	
  	contextImg = playdate.graphics.image.new(width+1, height+1, playdate.graphics.kColorClear)
  	playdate.graphics.lockFocus(contextImg)
  	playdate.graphics.setColor(playdate.graphics.kColorBlack)
  	ninesliceImg:drawInRect(0, 0, self.width, self.height)
  	playdate.graphics.unlockFocus()
	
  	self:setImage(contextImg) 
  	self:add()
end

function Platform:updatePhysics(dt) 
	self.platformBody:setTorque(self.platformBody:getTorque() * math.pow(0.2, dt))
	
	x,y = self.platformBody:getCenter()
	self:moveTo(x,y)
	
	rotation = rad2Deg(self.platformBody:getRotation())
	if self:getRotation() ~= rotation then 
  		self:setRotation(rotation)
	end
	
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
end 

function Platform:setSelected(flag)
	self.boltAnimTimer = playdate.timer.new(500, 0.0, 1.0, playdate.easingFunctions.outElastic)
	self.selected = flag
end