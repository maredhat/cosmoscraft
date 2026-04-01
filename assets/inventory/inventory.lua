local Inventory = {}
Inventory.__index = Inventory

function Inventory.new()
    local self = setmetatable({}, Inventory)
    self.ItemList = {}
    return self
end


-- @param dt: number 
function Inventory:update(dt) end

function Inventory:draw() end


function Inventory:get( item ) -- Получение кол-во предмета
    local it = self.ItemList[type(item) == 'table' and item.name or item] 
    if it == nil then self.ItemList[type(item) == 'table' and item.name or item] = 0 end
    return it
end

function Inventory:set( item, new_value ) -- Добавить предмет
     self.ItemList[type(item) == 'table' and item.name or item] = new_value      
end

return Inventory 