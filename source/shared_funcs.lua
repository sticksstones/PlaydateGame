
function deg2Rad(degrees)
	retVal = (degrees * 3.14 / 180.0)
  return retVal
end
	
function rad2Deg(radians)
	retVal = (radians * 180.0 / 3.14)
  return retVal
end

function getPolyCenter(poly)
  local x1 = poly:getPointAt(1).x
  local x2 = poly:getPointAt(2).x 
  local y1 = poly:getPointAt(1).y 
  local y2 = poly:getPointAt(2).y
  local x21 = poly:getPointAt(3).x
  local x22 = poly:getPointAt(4).x 
  local y21 = poly:getPointAt(3).y 
  local y22 = poly:getPointAt(4).y
	
  center = playdate.geometry.point.new((x1+x21)/2.0, (y1+y21)/2.0)
  return center
end