local Frame  = require 'lib.gui.frame'
local Lists  = require 'lib.gui.lists'

local GuiTest = {}
GuiTest.__index = GuiTest

function GuiTest.new(settings)
    local self = setmetatable({}, GuiTest)

    self.screenW = settings:get("width")
    self.screenH = settings:get("height")
    self.invW, self.invH = self.screenW - 30, self.screenH / 1.7

    self.inventory = Frame.new(15, self.screenH/2 - self.invH/2, self.invW, self.invH, {
        shipStat = Frame.new(self.invW - self.invW/3 - 15, 15, self.invW/3, self.invH - 30, {}),
        craftsLists = Lists.new(
            15, 15,
            300,
            300,  
            {}, true,
            {
                padding = {left=10, right=10, top=10, bottom=15},
                stretch = true,
                itemHeight = 40,
                spacing = 5,
                hoverToScroll = false,
                showScrollbar = true   
            }
        )
    })

    local list = self.inventory.childrens.craftsLists
    for i = 1, 20 do
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
        glow     = {0.40, 0.80, 1.00, 0.3},
    }

    self.inventory.render = function(self)
        love.graphics.setColor(theme.shadow)
        love.graphics.rectangle("fill", self.x + 4, self.y + 4, self.w, self.h, 12)
        love.graphics.setColor(theme.bgDark)
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 12)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(theme.accent)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 12)
    end

    self.inventory.childrens.shipStat.render = function(self)
        love.graphics.setColor(theme.shadow)
        love.graphics.rectangle("fill", self.x + 3, self.y + 3, self.w, self.h, 8)
        love.graphics.setColor(theme.bgMedium)
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 8)
        love.graphics.setLineWidth(1.5)
        love.graphics.setColor(theme.accent)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 8)
    end

    self.inventory.childrens.craftsLists.render = function(self)
        love.graphics.setColor(theme.shadow)
        love.graphics.rectangle("fill", self.x + 3, self.y + 3, self.w, self.h, 8)
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

function GuiTest:draw() self.inventory:draw() end
function GuiTest:wheelmoved(x, y)
    if self.inventory and self.inventory.childrens and self.inventory.childrens.craftsLists then
        self.inventory.childrens.craftsLists:onWheelMoved(x, y)
    end
end

function GuiTest:mousepressed(mx, my, button)
    if self.inventory and self.inventory.childrens and self.inventory.childrens.craftsLists then
        self.inventory.childrens.craftsLists:mousepressed(mx, my, button)
    end
end

function GuiTest:mousereleased(mx, my, button)
    if self.inventory and self.inventory.childrens and self.inventory.childrens.craftsLists then
        self.inventory.childrens.craftsLists:mousereleased(mx, my, button)
    end
end


return GuiTest