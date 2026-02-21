

local Frame  = require 'lib.gui.frame'
-- local Button = require 'lib.gui.button'
------------------------------------------------
local GuiTest = {}
GuiTest.__index = GuiTest


function GuiTest.new(settings)
    local self = setmetatable({}, GuiTest)

    
    self.screenW = settings:get("width") 
    self.screenH = settings:get("height")
    self.invW, self.invH = self.screenW - 30, self.screenH / 1.7 -- Size Inventory

    self.inventory = Frame.new(15, self.screenH / 2 - (self.invH / 2), self.invW, self.invH, 
    {
       shipStat = Frame.new(self.invW - (self.invW / 3) - 30, 15, self.invW / 3, self.invH - 30, 
        {

        }),
        
    })


    self.inventory.render = function(self)
        love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 15)
        
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0.3, 0.5, 1, 0.6)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 15)
        
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.5, 0.7, 1, 0.3)
        love.graphics.rectangle("line", self.x + 2, self.y + 2, self.w - 4, self.h - 4, 12)
        
        love.graphics.setColor(0.4, 0.6, 1, 0.8)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.print("≡ inventory", self.x + 20, self.y + 15)
    end

    self.inventory.childrens.shipStat.render = function(self)
        love.graphics.setColor(0.15, 0.15, 0.2, 0.7)
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 10)
        
        love.graphics.setColor(0.3, 0.5, 1, 0.2)
        love.graphics.rectangle("fill", self.x, self.y, self.w, 3)
        
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.4, 0.6, 1, 0.5)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 10)
        
        love.graphics.setColor(0.8, 0.8, 1, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print("System ship", self.x + 15, self.y + 8)
        
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.print("Body:", self.x + 20, self.y + 35)
        love.graphics.print("Armor:", self.x + 20, self.y + 55)
        love.graphics.print("Engine:", self.x + 20, self.y + 75)
        
        love.graphics.setColor(0.5, 1, 0.5, 1)
        love.graphics.print("100%", self.x + 100, self.y + 35)
        love.graphics.setColor(0.5, 0.5, 1, 1)
        love.graphics.print("80%", self.x + 100, self.y + 55)
        love.graphics.setColor(1, 1, 0.5, 1)
        love.graphics.print("120%", self.x + 100, self.y + 75)
        
        love.graphics.setColor(1, 1, 1, 1)
    end

    return self
end
------------------------------------------------
---Supportive
------------------------------------------------

function GuiTest:addingItemInventory(item, counter)

end

------------------------------------------------
function GuiTest:update(dt) self.inventory:update() end
function GuiTest:draw() self.inventory:draw() end



return GuiTest