local Item = require 'assets.items.system.item'

local ItemManager = {}
ItemManager.__index = ItemManager

function ItemManager.new()
    local self = setmetatable({}, ItemManager)
    self.items = {}        
    self.pool = {}         
    return self
end

function ItemManager:addItem(x, y, itemName)
    local itemConfig = require("assets.items." .. itemName)
    local item = Item.new(x, y, itemConfig)
    table.insert(self.items, item)
    return item
end

function ItemManager:update(dt, player)
    local i = 1
    while i <= #self.items do
        local item = self.items[i]
        item:update(dt)

        if player and player.active and item.active then
            local dx = item.x - player.x
            local dy = item.y - player.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < 30 + item.radius then
                item:pickup(player)
            end
        end

        if not item.active then
            table.remove(self.items, i)
        else
            i = i + 1
        end
    end
end

function ItemManager:draw()
    for _, item in ipairs(self.items) do
        item:draw()
    end
end

function ItemManager:clear()
    self.items = {}
end

function ItemManager:getCount()
    return #self.items
end

return ItemManager