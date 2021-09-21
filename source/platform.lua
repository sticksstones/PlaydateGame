import "CoreLibs/graphics"
import "CoreLibs/easing"
import "CoreLibs/timer"
import "CoreLibs/math"
import 'shared_funcs'
import 'platform_base'

local graphics <const> = playdate.graphics
local geometry <const> = playdate.geometry

class('Platform').extends(PlatformBase)

function Platform:init(width,height,body,ninesliceImg)	
	Platform.super.init(self,width,height,body,ninesliceImg)

	self.isSelectable = true
	self.boltAnimTimer = nil
	self.selected = false
end

function Platform:updatePhysics(dt) 
	Platform.super.updatePhysics(self, dt)

	self.body:setTorque(self.body:getTorque() * math.pow(0.2, dt))
end

function Platform:draw() 
	Platform.super.draw(self)
	
	if self.selected then 
		graphics.setColor(graphics.kColorBlack)
		graphics.drawCircleAtPoint(self.center, playdate.math.lerp(0.0, math.max(math.min(self.height/2.0 - 2, 8),4), self.boltAnimTimer.value))	
	end 			
end 

function Platform:setSelected(flag)
	self.boltAnimTimer = playdate.timer.new(500, 0.0, 1.0, playdate.easingFunctions.outElastic)
	self.selected = flag
end