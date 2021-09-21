import "CoreLibs/graphics"
import "CoreLibs/easing"
import "CoreLibs/timer"
import "CoreLibs/math"
import 'shared_funcs'

local graphics <const> = playdate.graphics
local geometry <const> = playdate.geometry

class('PlatformBase').extends(playdate.graphics.sprite)

function PlatformBase:updateImage() 
   local drawPoly = geometry.polygon.new(self.body:getPolygon())
   local x1 = drawPoly:getPointAt(1).x
   local x2 = drawPoly:getPointAt(2).x 
   local y1 = drawPoly:getPointAt(1).y 
   local y2 = drawPoly:getPointAt(2).y
   local x21 = drawPoly:getPointAt(3).x
   local x22 = drawPoly:getPointAt(4).x 
   local y21 = drawPoly:getPointAt(3).y 
   local y22 = drawPoly:getPointAt(4).y
  
 
   self.width = geometry.lineSegment.new(x1,y1,x2,y2):length()
   self.height = geometry.lineSegment.new(x2,y2,x21,y21):length()
   self.center = geometry.point.new((x1+x21)/2.0, (y1+y21)/2.0)
 
   self.rectWidth, self.rectHeight = self.body:getSize()
   local contextImg = graphics.image.new(self.rectWidth+1, self.rectHeight+1, graphics.kColorClear)
   graphics.lockFocus(contextImg)
   graphics.setColor(graphics.kColorBlack)
   self.ninesliceImgRef:drawInRect(0, 0, self.width, self.height)
   graphics.unlockFocus()
 
   self:setImage(contextImg)   	
end 

function PlatformBase:init(width,height,body,ninesliceImg)	
	PlatformBase.super.init(self)
	
	self.highlighted = false
	self.editorSelected = false
	self.ninesliceImgRef = ninesliceImg
	self.isSelectable = false
	self.selected = false
	
	self.body = body
	self.originalRotation = rad2Deg(self.body:getRotation())
	self:setZIndex(0)
	self:updateImage()
	self:add()
end

function PlatformBase:updatePhysics(dt) 	
	local x,y = self.body:getCenter()
	self:moveTo(x,y)

	local boundsRect = self:getBoundsRect()
	self:setCollideRect(0,0,boundsRect.width, boundsRect.height)	
end

function PlatformBase:draw() 
	local currentRectWidth, currentRectHeight = self.body:getSize()
		
	local drawPoly = geometry.polygon.new(self.body:getPolygon())
	  local x1 = drawPoly:getPointAt(1).x
	  local x2 = drawPoly:getPointAt(2).x 
	  local y1 = drawPoly:getPointAt(1).y 
	  local y2 = drawPoly:getPointAt(2).y
	  local x21 = drawPoly:getPointAt(3).x
	  local x22 = drawPoly:getPointAt(4).x 
	  local y21 = drawPoly:getPointAt(3).y 
	  local y22 = drawPoly:getPointAt(4).y
	 
	  self.width = geometry.lineSegment.new(x1,y1,x2,y2):length()
	  self.height = geometry.lineSegment.new(x2,y2,x21,y21):length()
	  self.center = geometry.point.new((x1+x21)/2.0, (y1+y21)/2.0)	
	
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
	
	if math.abs(self.rectWidth - currentRectWidth) > 0.01 or math.abs(self.rectHeight - currentRectHeight) > 0.01 then 
		self:updateImage()
	end 	
	
	local rotation = math.fmod(rad2Deg(self.body:getRotation()), 360.0)
	if self:getRotation() ~= rotation then 
		  self:setRotation(rotation)
	end			
end 

function PlatformBase:setEditorSelected(flag)
	self.editorSelected = flag
end

function PlatformBase:setHighlighted(flag)
	self.highlighted = flag
end

function PlatformBase:setSelected(flag)
	self.selected = self.isSelectable and flag
end