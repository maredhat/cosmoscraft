local Slider = {}
Slider.__index = Slider

local function clamp(low, val, high) return math.max(low, math.min(high, val)) end

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
    self.step = options.step or 0
    self.thumbSize = options.thumbSize or (self.vertical and 20 or 30)
    self.bgColor = options.bgColor or {0.3, 0.3, 0.3, 0.6}
    self.fillColor = options.fillColor
    self.thumbColor = options.thumbColor or {0.6, 0.6, 0.6, 0.9}
    self.borderColor = options.borderColor
    self.showValue = options.showValue or false
    self.valueFormat = options.valueFormat or function(v) return tostring(v) end
    self.valueColor = options.valueColor or {1,1,1,1}
    self.valueOffset = options.valueOffset or 5
    self.font = options.font or love.graphics.getFont()
    self.tickCount = options.tickCount or 0
    self.tickColor = options.tickColor or {1,1,1,0.3}
    self.tickSize = options.tickSize or 5
    self.onChanged = options.onChanged

    self.dragging = false
    self.dragOffset = 0

    if not self.fillColor and self.thumbColor then
        self.fillColor = {self.thumbColor[1], self.thumbColor[2], self.thumbColor[3], self.thumbColor[4] * 0.5}
    end

    return self
end

function Slider:getValue() return self.value end

function Slider:setValue(val, trigger)
    val = clamp(self.min, val, self.max)
    if self.step > 0 then
        val = math.floor((val - self.min) / self.step + 0.5) * self.step + self.min
    end
    if self.value ~= val then
        self.value = val
        if trigger ~= false and self.onChanged then self.onChanged(self.value) end
    end
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

function Slider:_valueFromPos(px, py)
    if self.vertical then
        local rangeY = self.h - self.thumbSize
        local t = (py - self.y - self.thumbSize/2) / rangeY
        t = clamp(0, t, 1)
        return self.min + t * (self.max - self.min)
    else
        local rangeX = self.w - self.thumbSize
        local t = (px - self.x - self.thumbSize/2) / rangeX
        t = clamp(0, t, 1)
        return self.min + t * (self.max - self.min)
    end
end

function Slider:mousepressed(mx, my, button)
    if not self.visible or button ~= 1 then return end

    local inSlider
    if self.vertical then
        inSlider = mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h
    else
        inSlider = my >= self.y and my <= self.y + self.h and mx >= self.x and mx <= self.x + self.w
    end
    if not inSlider then return end

    local thumbPos = self:_thumbPos()
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

    local newVal = self:_valueFromPos(mx, my)
    self:setValue(newVal)
end

function Slider:mousereleased(mx, my, button)
    if button == 1 then self.dragging = false end
end

function Slider:update(dt)
    if self.dragging then
        local mx, my = love.mouse.getPosition()
        if self.vertical then
            local rangeY = self.h - self.thumbSize
            local t = (my - self.y - self.dragOffset) / rangeY
            t = clamp(0, t, 1)
            local newVal = self.min + t * (self.max - self.min)
            self:setValue(newVal, false)
        else
            local rangeX = self.w - self.thumbSize
            local t = (mx - self.x - self.dragOffset) / rangeX
            t = clamp(0, t, 1)
            local newVal = self.min + t * (self.max - self.min)
            self:setValue(newVal, false)
        end
    end
end

function Slider:draw()
    if not self.visible then return end

    local thumbPos = self:_thumbPos()
    local fillSize

    if self.vertical then
        fillSize = thumbPos + self.thumbSize/2 - self.y
    else
        fillSize = thumbPos + self.thumbSize/2 - self.x
    end

    love.graphics.setColor(self.bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, self.h/2)

    if self.fillColor then
        love.graphics.setColor(self.fillColor)
        if self.vertical then
            love.graphics.rectangle("fill", self.x, self.y, self.w, fillSize, self.h/2)
        else
            love.graphics.rectangle("fill", self.x, self.y, fillSize, self.h, self.h/2)
        end
    end

    if self.borderColor then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h, self.h/2)
    end

    if self.tickCount > 1 then
        love.graphics.setColor(self.tickColor)
        love.graphics.setLineWidth(1)
        for i = 0, self.tickCount - 1 do
            local t = i / (self.tickCount - 1)
            if self.vertical then
                local y = self.y + t * self.h
                love.graphics.line(self.x - self.tickSize, y, self.x, y)
                love.graphics.line(self.x + self.w, y, self.x + self.w + self.tickSize, y)
            else
                local x = self.x + t * self.w
                love.graphics.line(x, self.y - self.tickSize, x, self.y)
                love.graphics.line(x, self.y + self.h, x, self.y + self.h + self.tickSize)
            end
        end
    end

    love.graphics.setColor(self.thumbColor)
    if self.vertical then
        love.graphics.rectangle("fill", self.x, thumbPos, self.w, self.thumbSize, self.thumbSize/2)
        love.graphics.setColor(1,1,1,0.3)
        love.graphics.rectangle("fill", self.x, thumbPos, self.w, 2, 1)
    else
        love.graphics.rectangle("fill", thumbPos, self.y, self.thumbSize, self.h, self.thumbSize/2)
        love.graphics.setColor(1,1,1,0.3)
        love.graphics.rectangle("fill", thumbPos, self.y, self.thumbSize, 2, 1)
    end

    if self.showValue then
        love.graphics.setColor(self.valueColor)
        love.graphics.setFont(self.font)
        local valueStr = self.valueFormat(self.value)
        local tw = self.font:getWidth(valueStr)
        local th = self.font:getHeight()
        if self.vertical then
            local tx = self.x + self.w + self.valueOffset
            local ty = thumbPos + self.thumbSize/2 - th/2
            love.graphics.print(valueStr, tx, ty)
        else
            local tx = thumbPos + self.thumbSize/2 - tw/2
            local ty = self.y - th - self.valueOffset
            love.graphics.print(valueStr, tx, ty)
        end
    end
end

return Slider