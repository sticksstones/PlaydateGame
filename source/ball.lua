import "CoreLibs/graphics"

class('Ball').extends(playdate.graphics.sprite)

function Ball:init()
	
	Ball.super.init(self)
	-- playdate.graphics.setColor(playdate.graphics.kColorClear)
	ballImage = playdate.graphics.image.new("assets/pngs/general/Ball")
    self:setImage(ballImage)
	-- self:setZIndex(1000)
	self:setCenter(0.5, 0.5)	-- set center point to center bottom middle
	self:moveTo(102, 210)
	-- self:add()
end


-- function Ball:reset()
-- 	self.position = Point.new(102, 108)
-- 	self.velocity = vector2D.new(0,0)
-- end

-- function Ball:update()
-- 
-- end

-- function Ball:draw() 
-- 	
-- end