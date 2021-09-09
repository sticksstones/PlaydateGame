import "CoreLibs/graphics"

class('Ball').extends(playdate.graphics.sprite)

function Ball:init(physObj)	
	Ball.super.init(self)
	ballImage = playdate.graphics.image.new("assets/pngs/general/Ball")
    self:setImage(ballImage)
	self:setZIndex(1000)
	self:setCenter(0.5, 0.5)
	x,y = physObj:getCenter()
	self:moveTo(x,y)
	self:add()
	
	self.physObj = physObj
	self.originalPosX = x 
	self.originalPosY = y
	self.originalRotation = physObj:getRotation()
end