local Frame = require 'lib.gui.frame'
local Lists = require 'lib.gui.lists'

local Dropdown = {}
Dropdown.__index = Dropdown


--[[
Dropdown.new(x, y, width, height, options)
    x, y, width, height – абсолютные координаты и размер основной кнопки
    options = {
        items           = {},              -- массив элементов (строки или таблицы {text, value})
        selectedIndex   = 1,                -- индекс выбранного элемента
        itemHeight      = 30,               -- высота каждого пункта списка
        maxListHeight   = 200,              -- максимальная высота выпадающего списка
        bgColor         = {0.2,0.2,0.2,1},  -- цвет кнопки
        textColor       = {1,1,1,1},        -- цвет текста
        hoverColor      = {0.3,0.3,0.3,1},  -- цвет подсветки при наведении
        borderColor     = {0.5,0.5,0.5,1},  -- цвет рамки
        onSelect        = function(item)    -- колбэк при выборе элемента
    }
]]
function Dropdown.new(x, y, width, height, options)
    local self = setmetatable({}, Dropdown)
    self.x = x
    self.y = y
    self.w = width
    self.h = height
    self.visible = true
    self.expanded = false

    options = options or {}
    self.items = options.items or {}
    self.selectedIndex = options.selectedIndex or 1
    self.bgColor = options.bgColor or {0.2, 0.2, 0.2, 1}
    self.textColor = options.textColor or {1, 1, 1, 1}
    self.hoverColor = options.hoverColor or {0.3, 0.3, 0.3, 1}
    self.borderColor = options.borderColor or {0.5, 0.5, 0.5, 1}
    self.itemHeight = options.itemHeight or 30
    self.maxListHeight = options.maxListHeight or 200
    self.onSelect = options.onSelect

    -- Создаём Lists для выпадающей части
    self.list = Lists.new(
        self.x, self.y + self.h,
        self.w,
        math.min(#self.items * self.itemHeight, self.maxListHeight),
        {}, true,
        {
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            stretch = true,
            itemHeight = self.itemHeight,
            spacing = 0,
            hoverToScroll = true,
            showScrollbar = #self.items * self.itemHeight > self.maxListHeight,
            scrollbarWidth = 6,
            scrollbarGap = 2
        }
    )

    for i, item in ipairs(self.items) do
        local text = type(item) == "table" and item.text or tostring(item)
        local value = type(item) == "table" and item.value or item
        self.list:addChildren("item"..i, {
            order = i,
            text = text,
            value = value,
            draw = function(self)
                love.graphics.setColor(0.3, 0.3, 0.3, 1)
                love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
                love.graphics.setColor(1,1,1,1)
                love.graphics.print(self.text, self.x + 10, self.y + self.h/2 - 6)
            end
        })
    end

    return self
end

function Dropdown:getSelected()
    return self.items[self.selectedIndex]
end

function Dropdown:setSelected(index)
    if index >= 1 and index <= #self.items then
        self.selectedIndex = index
        if self.onSelect then
            self.onSelect(self.items[index])
        end
    end
end

function Dropdown:toggle()
    self.expanded = not self.expanded
    self.list.isVisible = self.expanded
end

function Dropdown:close()
    self.expanded = false
    self.list.isVisible = false
end

function Dropdown:mousepressed(mx, my, button)
    if not self.visible or button ~= 1 then return end

    if mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h then
        self:toggle()
        return
    end

    if self.expanded then
        self.list:mousepressed(mx, my, button)

        local listY = self.y + self.h
        if mx >= self.x and mx <= self.x + self.w and my >= listY and my <= listY + self.list.h then
            local localY = my - listY + self.list.scrollY
            local index = math.floor(localY / self.itemHeight) + 1
            if index >= 1 and index <= #self.items then
                self:setSelected(index)
                self:close()
            end
        else
            self:close()
        end
    end
end

function Dropdown:mousereleased(mx, my, button)
    if self.expanded then
        self.list:mousereleased(mx, my, button)
    end
end

function Dropdown:update(dt)
    if self.expanded then
        self.list:update(dt)
    end
end

function Dropdown:draw()
    if not self.visible then return end

    love.graphics.setColor(self.bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 4)
    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 4)

    if self.items[self.selectedIndex] then
        local text = type(self.items[self.selectedIndex]) == "table" and self.items[self.selectedIndex].text or tostring(self.items[self.selectedIndex])
        love.graphics.setColor(self.textColor)
        love.graphics.print(text, self.x + 10, self.y + self.h/2 - 6)
    end

    love.graphics.setColor(self.textColor)
    if self.expanded then
        love.graphics.polygon("fill", self.x + self.w - 15, self.y + 10, self.x + self.w - 5, self.y + 10, self.x + self.w - 10, self.y + 5)
    else
        love.graphics.polygon("fill", self.x + self.w - 15, self.y + 5, self.x + self.w - 5, self.y + 5, self.x + self.w - 10, self.y + 10)
    end

    if self.expanded then
        self.list:draw()
    end
end

return Dropdown