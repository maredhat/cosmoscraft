local Checkbox = {}
Checkbox.__index = Checkbox

--[[
Checkbox.new(x, y, w, h, options)
    x, y, w, h – абсолютные координаты и размер чекбокса

    options = {
        checked      = false,
        bgColor      = {0.9,0.9,0.9,1},
        checkColor   = {0.2,0.6,1,1},
        borderColor  = {0.3,0.3,0.3,1},
        borderRadius = 3,
        onChange     = function(checked) end
    }
]]

function Checkbox.new(x, y, w, h, options)
    local self = setmetatable({}, Checkbox)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.visible = true

    options = options or {}
    self.checked = options.checked or false
    self.bgColor = options.bgColor or {0.9, 0.9, 0.9, 1}
    self.checkColor = options.checkColor or {0.2, 0.6, 1, 1}
    self.borderColor = options.borderColor or {0.3, 0.3, 0.3, 1}
    self.borderRadius = options.borderRadius or 3
    self.onChange = options.onChange

    return self
end

function Checkbox:isChecked() return self.checked end

function Checkbox:setChecked(state)
    if self.checked ~= state then
        self.checked = state
        if self.onChange then self.onChange(self.checked) end
    end
end

function Checkbox:toggle() self:setChecked(not self.checked) end

function Checkbox:mousepressed(mx, my, button)
    if not self.visible or button ~= 1 then return end
    if mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h then
        self:toggle()
    end
end

function Checkbox:draw()
    if not self.visible then return end

    love.graphics.setColor(self.bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, self.borderRadius)
    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, self.borderRadius)

    if self.checked then
        love.graphics.setColor(self.checkColor)
        love.graphics.setLineWidth(2)
        love.graphics.line(
            self.x + self.w * 0.2, self.y + self.h * 0.5,
            self.x + self.w * 0.45, self.y + self.h * 0.7,
            self.x + self.w * 0.8, self.y + self.h * 0.3
        )
    end
end

return Checkbox