local _condition_events = 
{
    onHover = function(frame, mx, my)
        return math.aabb(mx, my, frame.x, frame.y, frame.x + frame.w, frame.y + frame.h)
    end,

    onClick = function(frame, mx, my)
        return math.aabb(mx, my, frame.x, frame.y, 
                        frame.x + frame.w, 
                        frame.y + frame.h) and love.mouse.isDown(1)
    end,
    onAdded = function(frame, mx, my) return true end
}


local Frame = {}
Frame.__index = Frame

function Frame.new(x, y, width, height, childrens, isVisiable)
    local self = setmetatable({}, Frame)

    self.x           = x
    self.y           = y
    self.h           = height
    self.w           = width
    self.isVisiable  = isVisiable or true
    self.childrens   = childrens or {}
    
    self.event       = 
    {
        onHover  = nil,
        onClick  = nil,
        onHold   = nil,
        onEnter  = nil,
        onAdded  = nil,
    }

    self.other      = {}
    return self
end

function Frame.render(self, callback)
    if callback then callback(self) return self end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    return self
end

function Frame._event(self, key, callback)
    self.event[key] = callback
    return self
end

function Frame:addChildren(key, children)
    self.childrens[key] = children
    return self
end

function Frame:SelectChidren(key)
    return self.childrens[key]
end

function Frame:update(dt)
    if self.isVisiable then
        local mouse_x, mouse_y = love.mouse.getPosition()
        for key, item in pairs(self.event) do
            if item ~= nil and _condition_events[key](self, mouse_x, mouse_y) then
                item({mouse_x, mouse_y})
            end
        end

        if next(self.childrens) ~= nil then
            for key, item in pairs(self.childrens) do
                if type(item) == "table" and item.update then
                    item:update(dt)
                end
            end
        end
    end
    return self
end

function Frame:draw()
    if self.isVisiable then
        self:render()
        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        
        if next(self.childrens) ~= nil then
            for key, item in pairs(self.childrens) do
                if type(item) == "table" and item.draw then
                    item:draw()
                end
            end
        end
        
        love.graphics.pop()
    end
    return self
end

return Frame