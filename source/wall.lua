import "CoreLibs/graphics"
import "CoreLibs/easing"
import "CoreLibs/timer"
import "CoreLibs/math"
import 'shared_funcs'
import 'platform_base'

local graphics <const> = playdate.graphics
local geometry <const> = playdate.geometry

class('Wall').extends(PlatformBase)

function Wall:init(width,height,body,ninesliceImg)	
	Wall.super.init(self,width,height,body,ninesliceImg)
end