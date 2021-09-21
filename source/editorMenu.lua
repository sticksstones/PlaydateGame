import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/easing"
import "CoreLibs/timer"
import "CoreLibs/ui"
import 'shared_funcs'
import 'CoreLibs/ui/gridview.lua'

local graphics <const> = playdate.graphics
local geometry <const> = playdate.geometry


class('EditorMenu').extends()

local SCREEN_WIDTH <const> = 400.0
local SCREEN_HEIGHT <const> = 240.0
local MENU_WIDTH <const> = 120

local opened = false
local slideTimer = nil
local listview = nil
local menuOptions = 
{
	{name="Platform"}, 
	{name="Wall"}, 
	{name="Ball"}
}
local mainScriptRef = nil


function EditorMenu:init(mainScript)
	self.mainScriptRef = mainScript	

	self.listview = playdate.ui.gridview.new(0, 40)
	self.listview:setNumberOfRows(#menuOptions)
	self.listview:setCellPadding(0, 0, 13, 2)
	self.listview:setContentInset(12, 12, 10, 6)		

	function self.listview:drawCell(section, row, column, selected, x, y, width, height)
		if selected then
				graphics.setColor(graphics.kColorWhite)
				graphics.setDitherPattern(0.1, graphics.image.kDitherTypeBayer8x8)
				graphics.fillRoundRect(x, y, width, height, 4)
				-- graphics.setImageDrawMode(graphics.kDrawModeFillWhite)
		else
				graphics.setColor(graphics.kColorWhite)
				-- graphics.setDitherPattern(0.5, graphics.image.kDitherTypeDiagonalLine)
				graphics.fillRoundRect(x, y, width, height, 4)
				-- graphics.setImageDrawMode(graphics.kDrawModeWhiteTransparent)
				-- graphics.setImageDrawMode(graphics.kDrawModeCopy)
		end
		graphics.drawTextInRect(menuOptions[row].name, x, y+(height/2 - 4), width, height, nil, "...", kTextAlignment.center)
	end
end

function EditorMenu:selectOption(item) 
	name = item.name
	
	if name == "Platform" then 
		editorCreatePlatform()
	elseif name == "Wall" then 
		editorCreateWall()
	end 
	
end 

function EditorMenu:update()
	if self.opened then 
		-- Cursor movement
		if playdate.buttonJustPressed(playdate.kButtonUp) then 
			self.listview:selectPreviousRow(true)
		elseif playdate.buttonJustPressed(playdate.kButtonDown) then 
			self.listview:selectNextRow(true)
		end 
		
		-- Buttons
		if playdate.buttonJustPressed(playdate.kButtonA) then 
			self:selectOption(menuOptions[self.listview:getSelectedRow()])
			
		end 
	end 
end

function EditorMenu:open() 
	self.opened = true
	self.slideTimer = playdate.timer.new(500, 0.0, 1.0, playdate.easingFunctions.outExpo)
end 

function EditorMenu:close()
	self.opened = false
end

function EditorMenu:draw() 
	if self.opened then 
		graphics.setColor(graphics.kColorBlack)
		local drawOffsetX, drawOffsetY = graphics.getDrawOffset()
		graphics.fillRect(SCREEN_WIDTH - (self.slideTimer.value * MENU_WIDTH) - drawOffsetX, -drawOffsetY, MENU_WIDTH, SCREEN_HEIGHT)
		
		self.listview:drawInRect(SCREEN_WIDTH - (self.slideTimer.value * MENU_WIDTH) - drawOffsetX, -drawOffsetY, MENU_WIDTH, SCREEN_HEIGHT)

	end
	
end

function EditorMenu:kill() 
	
end