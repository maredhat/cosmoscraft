-- label.lua
local Label = {}
Label.__index = Label

function Label.new(x, y, text, options)
    local self = setmetatable({}, Label)
    self.x = x
    self.y = y
    self.text = text or ""
    self.visible = true

    options = options or {}
    self.color = options.color or {1,1,1,1}
    self.font = options.font or love.graphics.getFont()
    self.align = options.align or "left"

    return self
end

function Label:setText(newText)
    self.text = newText
end

function Label:draw()
    if not self.visible then return end
    love.graphics.setColor(self.color)
    love.graphics.setFont(self.font)

    local x = self.x
    if self.align == "center" then
        x = x - self.font:getWidth(self.text) / 2
    elseif self.align == "right" then
        x = x - self.font:getWidth(self.text)
    end

    love.graphics.print(self.text, x, self.y)
end

return Label