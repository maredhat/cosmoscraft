math.aabb = function(px, py, x, y, w, h) return px > x and px < x + w and py > y and py < y + h end

math.clamp = function(min, val, max) return math.max(min, math.min(max, value)) end

math.lerp = function(a,b,t) return a * (1-t) + b * t end

math.dot = function(x, y) return math.sqrt(x*x + y*y) end







