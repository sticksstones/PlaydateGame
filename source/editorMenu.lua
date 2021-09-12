import "CoreLibs/graphics"
import "CoreLibs/object"

local graphics <const> = playdate.graphics
local geometry <const> = playdate.geometry

class('EditorMenu').extends()

function EditorMenu:init()	
	
end

function EditorMenu:update()

end

function EditorMenu:draw() 
	print("Drawing editor menu")
	graphics.setColor(graphics.kColorBlack)
	graphics.drawRect(200, 0, 200, 240)
end

function EditorMenu:kill() 
	
end