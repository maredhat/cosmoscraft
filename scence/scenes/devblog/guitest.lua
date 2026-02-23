local Frame     = require 'lib.gui.frame'
local Lists     = require 'lib.gui.lists'
local Slider    = require 'lib.gui.slider'
local Checkbox  = require 'lib.gui.checkbox'
local Dropdown  = require 'lib.gui.dropdown'
local TextBox   = require 'lib.gui.textbox'

local GuiTest = {}
GuiTest.__index = GuiTest

function GuiTest.new(settings)
    local self = setmetatable({}, GuiTest)

    self.screenW = settings:get("width")
    self.screenH = settings:get("height")
    self.invW, self.invH = self.screenW - 30, self.screenH / 1.7

    local invX = 15
    local invY = self.screenH/2 - self.invH/2

    self.inventory = Frame.new(invX, invY, self.invW, self.invH, {
        shipStat = Frame.new(
            invX + self.invW - self.invW/3 - 15,
            invY + 15,
            self.invW/3,
            self.invH - 30,
            {}
        ),
        craftsLists = Lists.new(
            invX + 15,
            invY + 15,
            self.invW - self.invW/3 - 45,
            self.invH - 300,
            {}, true,
            {
                padding = { left = 10, right = 10, top = 10, bottom = 15 },
                stretch = true,
                itemHeight = 40,
                spacing = 5,
                hoverToScroll = true,
                showScrollbar = true,
                scrollbarWidth = 8,
                scrollbarGap = 2,
                scrollbarColor = {0.3, 0.3, 0.3, 0.6},
                scrollbarThumbColor = {0.6, 0.6, 0.6, 0.9},
                scrollSpeed = 5,
                scrollStep = 40
            }
        ),
        slider = Slider.new(
            invX + 50, invY + 300, 300, 20,
            {
                vertical = false,
                min = 0,
                max = 100,
                value = 0,
                thumbSize = 15,
                bgColor = {0.2, 0.2, 0.2, 0.8},
                thumbColor = {0.8, 0.5, 0.2, 1},
                onChanged = function(val)
                    print("HSlider:", val)
                end
            }
        ),
        checkbox = Checkbox.new(
            invX + 50, invY + 350, 20, 20,
            {
                checked = false,
                bgColor = {0.2, 0.2, 0.2, 0.8},
                checkColor = {0.3, 0.8, 1, 1},
                borderColor = {0.6, 0.6, 0.6, 1},
                borderRadius = 4,
                onChange = function(checked)
                    print("Checkbox is now", checked)
                end
            }
        ),
        dropdown = Dropdown.new(
            invX + 50, invY + 400, 200, 30,
            {
                items = { "Option A", "Option B", "Option C", "Option D", "Option E", "Option F", "Option G" },
                selectedIndex = 1,
                itemHeight = 30,
                maxListHeight = 150,
                onSelect = function(item)
                    print("Selected:", item)
                end
            }
        ),
        textInput = TextBox.new(
            invX + 50, invY + 450, 300, 30,
            {
                placeholder = "Insert text...",
                maxLength = 50,
                fontSize = 16,
                bgColor = {0.15, 0.15, 0.2, 0.9},
                textColor = {1, 1, 1, 1},
                placeholderColor = {0.5, 0.5, 0.5, 1},
                focusBorderColor = {0.3, 0.7, 1, 1},
                onChange = function(text)
                    
                end,
                onEnter = function(text)
                    
                end
            }
        )
    })

    local list = self.inventory.childrens.craftsLists
    for i = 1, 30 do
        list:addChildren("item"..i, {
            order = i,
            draw = function(self)
                love.graphics.setColor(0.2, 0.5, 0.8)
                love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 5)
                love.graphics.setColor(1,1,1)
                love.graphics.print("Element No "..i, self.x+10, self.y+12)
            end
        })
    end

    self:reDraw()
    return self
end

function GuiTest:reDraw()
    local theme = {
        bgDark   = {0.07, 0.07, 0.12, 1},
        bgMedium = {0.12, 0.12, 0.18, 1},
        bgLight  = {0.18, 0.18, 0.25, 1},
        accent   = {0.30, 0.70, 1.00, 1},
        shadow   = {0.00, 0.00, 0.00, 0.5},
    }

    self.inventory.render = function(self)
        love.graphics.setColor(theme.shadow)
        love.graphics.rectangle("fill", self.x+4, self.y+4, self.w, self.h, 12)
        love.graphics.setColor(theme.bgDark)
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 12)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(theme.accent)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 12)
    end

    self.inventory.childrens.shipStat.render = function(self)
        love.graphics.setColor(theme.shadow)
        love.graphics.rectangle("fill", self.x+3, self.y+3, self.w, self.h, 8)
        love.graphics.setColor(theme.bgMedium)
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 8)
        love.graphics.setLineWidth(1.5)
        love.graphics.setColor(theme.accent)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 8)
    end

    self.inventory.childrens.craftsLists.render = function(self)
        love.graphics.setColor(theme.shadow)
        love.graphics.rectangle("fill", self.x+3, self.y+3, self.w, self.h, 8)
        love.graphics.setColor(theme.bgLight)
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 8)
        love.graphics.setLineWidth(1.5)
        love.graphics.setColor(theme.accent)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 8)
    end
end

function GuiTest:update(dt)
    self.inventory:update(dt)
end

function GuiTest:draw()
    self.inventory:draw()
end

-- Все вызовы унифицированы: используем wheelmoved, а не onWheelMoved
function GuiTest:wheelmoved(x, y)
    self.inventory:wheelmoved(x, y)
end

function GuiTest:mousepressed(mx, my, button)
    self.inventory:mousepressed(mx, my, button)
end

function GuiTest:mousereleased(mx, my, button)
    self.inventory:mousereleased(mx, my, button)
end

function GuiTest:textinput(t)
    self.inventory:textinput(t)
end

function GuiTest:keypressed(key, scancode, isrepeat)
    self.inventory:keypressed(key, scancode, isrepeat)
end

function GuiTest:keyreleased(key, scancode)
    self.inventory:keyreleased(key, scancode)
end

return GuiTest