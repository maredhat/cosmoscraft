-- slider.lua
local Slider = {}
Slider.__index = Slider

local function clamp(low, val, high) return math.max(low, math.min(high, val)) end


--[[
Slider.new(x, y, w, h, options)
    x, y, w, h – абсолютные координаты и размер слайдера
    options = {
        vertical    = false,            -- вертикальный/горизонтальный
        min         = 0,                 -- минимальное значение
        max         = 100,               -- максимальное значение
        value       = min,                -- начальное значение
        thumbSize   = (vertical и 20 или 30), -- размер ползунка
        bgColor     = {0.3,0.3,0.3,0.6}, -- цвет трека
        thumbColor  = {0.6,0.6,0.6,0.9}, -- цвет ползунка
        onChanged   = function(val)       -- колбэк при изменении значения
    }
]]
function Slider.new(x, y, w, h, options)
    local self = setmetatable({}, Slider)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.visible = true

    options = options or {}
    self.vertical = options.vertical or false
    self.min = options.min or 0
    self.max = options.max or 100
    self.value = clamp(self.min, options.value or self.min, self.max)
    self.thumbSize = options.thumbSize or (self.vertical and 20 or 30)
    self.bgColor = options.bgColor or {0.3, 0.3, 0.3, 0.6}
    self.thumbColor = options.thumbColor or {0.6, 0.6, 0.6, 0.9}
    self.onChanged = options.onChanged

    self.dragging = false
    self.dragOffset = 0

    return self
end

function Slider:getValue() return self.value end

function Slider:setValue(val)
    self.value = clamp(self.min, val, self.max)
    if self.onChanged then self.onChanged(self.value) end
end

function Slider:_thumbPos()
    if self.vertical then
        local rangeY = self.h - self.thumbSize
        local t = (self.value - self.min) / (self.max - self.min)
        return self.y + t * rangeY
    else
        local rangeX = self.w - self.thumbSize
        local t = (self.value - self.min) / (self.max - self.min)
        return self.x + t * rangeX
    end
end

function Slider:_updateValueFromMouse(mx, my)
    if self.vertical then
        local rangeY = self.h - self.thumbSize
        local t = (my - self.y - self.dragOffset) / rangeY
        t = clamp(0, t, 1)
        self.value = self.min + t * (self.max - self.min)
    else
        local rangeX = self.w - self.thumbSize
        local t = (mx - self.x - self.dragOffset) / rangeX
        t = clamp(0, t, 1)
        self.value = self.min + t * (self.max - self.min)
    end
    if self.onChanged then self.onChanged(self.value) end
end

function Slider:mousepressed(mx, my, button)
    if not self.visible or button ~= 1 then return end

    -- Проверка, в области слайдера
    local inSlider
    if self.vertical then
        inSlider = mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h
    else
        inSlider = my >= self.y and my <= self.y + self.h and mx >= self.x and mx <= self.x + self.w
    end
    if not inSlider then return end

    local thumbPos = self:_thumbPos()
    -- Попадание в ползунок?
    if self.vertical then
        if my >= thumbPos and my <= thumbPos + self.thumbSize then
            self.dragging = true
            self.dragOffset = my - thumbPos
            return
        end
    else
        if mx >= thumbPos and mx <= thumbPos + self.thumbSize then
            self.dragging = true
            self.dragOffset = mx - thumbPos
            return
        end
    end

    -- Клик по треку – мгновенное перемещение
    if self.vertical then
        local rangeY = self.h - self.thumbSize
        local t = (my - self.y - self.thumbSize/2) / rangeY
        t = clamp(0, t, 1)
        self.value = self.min + t * (self.max - self.min)
    else
        local rangeX = self.w - self.thumbSize
        local t = (mx - self.x - self.thumbSize/2) / rangeX
        t = clamp(0, t, 1)
        self.value = self.min + t * (self.max - self.min)
    end
    if self.onChanged then self.onChanged(self.value) end
end

function Slider:mousereleased(mx, my, button)
    if button == 1 then self.dragging = false end
end

function Slider:update(dt)
    if self.dragging then
        local mx, my = love.mouse.getPosition()
        self:_updateValueFromMouse(mx, my)
    end
end

function Slider:draw()
    if not self.visible then return end

    love.graphics.setColor(self.bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 4)

    love.graphics.setColor(self.thumbColor)
    if self.vertical then
        local thumbY = self:_thumbPos()
        love.graphics.rectangle("fill", self.x, thumbY, self.w, self.thumbSize, 4)
    else
        local thumbX = self:_thumbPos()
        love.graphics.rectangle("fill", thumbX, self.y, self.thumbSize, self.h, 4)
    end
end

return Slider