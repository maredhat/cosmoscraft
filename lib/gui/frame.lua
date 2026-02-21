local _condition_events = {
    onHover = function(frame, mx, my)
        return mx >= frame.x and mx <= frame.x + frame.w and my >= frame.y and my <= frame.y + frame.h
    end,
    onClick = function(frame, mx, my)
        return mx >= frame.x and mx <= frame.x + frame.w and my >= frame.y and my <= frame.y + frame.h and love.mouse.isDown(1)
    end,
    onAdded = function() return true end
}

local Frame = {}
Frame.__index = Frame


--[[
Frame.new(x, y, w, h, childrens, isVisible)
    x, y, w, h – абсолютные координаты и размер
    childrens   – таблица дочерних элементов (ключ-значение)
    isVisible   – видимость фрейма (по умолчанию true)
    События: onHover, onClick, onHold, onEnter, onAdded – устанавливаются через :_event()
]]



function Frame.new(x, y, w, h, childrens, isVisiable)
    local self = setmetatable({}, Frame)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.isVisiable = (isVisiable == nil) and true or isVisiable
    self.childrens = childrens or {}
    self.event = { onHover = nil, onClick = nil, onHold = nil, onEnter = nil, onAdded = nil }
    self.other = {}
    return self
end

function Frame:render(callback)
    if callback then callback(self) return self end
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    return self
end

function Frame:_event(key, cb) self.event[key] = cb; return self end
function Frame:addChildren(key, child) self.childrens[key] = child; return self end
function Frame:SelectChidren(key) return self.childrens[key] end

function Frame:update(dt)
    if self.isVisiable then
        local mx, my = love.mouse.getPosition()
        for key, cb in pairs(self.event) do
            if cb and _condition_events[key](self, mx, my) then
                cb({mx, my})
            end
        end
        for _, child in pairs(self.childrens) do
            if child.update then child:update(dt) end
        end
    end
    return self
end

function Frame:draw()
    if self.isVisiable then
        self:render()
        for _, child in pairs(self.childrens) do
            if child.draw then child:draw() end
        end
    end
    return self
end

return Frame