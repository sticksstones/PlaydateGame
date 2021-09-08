import "CoreLibs/graphics"

class('Ball').extends(playdate.graphics.sprite)

function Ball:init()	
	Ball.super.init(self)
	ballImage = playdate.graphics.image.new("assets/pngs/general/Ball")
    self:setImage(ballImage)
	self:setZIndex(1000)
	self:setCenter(0.5, 0.5)
	self:moveTo(102, 210)
	self:add()
end