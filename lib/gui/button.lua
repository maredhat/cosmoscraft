-- lib/gui/button.lua
local Button = {}
Button.__index = Button

--[[
Button.new(x, y, w, h, text, options)
    x, y, w, h – абсолютные координаты и размер
    text       – текст на кнопке
    options = {
        bgColor      = {0.2,0.2,0.2,1},
        hoverColor   = {0.3,0.3,0.3,1},
        pressColor   = {0.1,0.1,0.2,1},  -- цвет при нажатии
        textColor    = {1,1,1,1},
        borderColor  = {0.5,0.5,0.5,1},
        borderRadius = 4,
        font         = love.graphics.getFont(),
        onClick      = function() end,   -- вызывается при отпускании (если мышь внутри)
        onPress      = function() end,   -- вызывается сразу при нажатии
        onHold       = function() end,   -- вызывается каждый кадр, пока кнопка зажата и мышь внутри
        onRelease    = function() end,   -- вызывается при отпускании в любом случае
    }
]]
function Button.new(x, y, w, h, text, options)
    local self = setmetatable({}, Button)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.text = text
    self.visible = true

    options = options or {}
    self.bgColor = options.bgColor or {0.2, 0.2, 0.2, 1}
    self.hoverColor = options.hoverColor or {0.3, 0.3, 0.3, 1}
    self.pressColor = options.pressColor or {0.1, 0.1, 0.2, 1}
    self.textColor = options.textColor or {1, 1, 1, 1}
    self.borderColor = options.borderColor or {0.5, 0.5, 0.5, 1}
    self.borderRadius = options.borderRadius or 4
    self.font = options.font or love.graphics.getFont()
    self.onClick = options.onClick
    self.onPress = options.onPress
    self.onHold = options.onHold
    self.onRelease = options.onRelease

    self.hovered = false
    self.pressed = false 
    return self
end

function Button:mousepressed(mx, my, button)
    if not self.visible or button ~= 1 then return end
    if mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h then
        self.pressed = true
        if self.onPress then
            self.onPress()
        end
    end
end

function Button:mousereleased(mx, my, button)
    if not self.visible or button ~= 1 then return end
    if self.pressed then
        local inside = mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h
        if inside and self.onClick then
            self.onClick()
        end
        if self.onRelease then
            self.onRelease(inside)  
        end
        self.pressed = false
    end
end

function Button:update(dt)
    if not self.visible then return end
    local mx, my = love.mouse.getPosition()
    self.hovered = mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h

    if self.pressed and self.hovered and self.onHold then
        self.onHold(dt)  
    end
end

function Button:draw()
    if not self.visible then return end

    if self.pressed then
        love.graphics.setColor(self.pressColor)
    elseif self.hovered then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.bgColor)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, self.borderRadius)

    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, self.borderRadius)

    love.graphics.setColor(self.textColor)
    love.graphics.setFont(self.font)
    local tw = self.font:getWidth(self.text)
    local th = self.font:getHeight()
    love.graphics.print(self.text, self.x + self.w/2 - tw/2, self.y + self.h/2 - th/2)
end

return Button