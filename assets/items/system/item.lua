local Item = {}
Item.__index = Item

function Item.new(x, y, itemConfig)
    local self = setmetatable({}, Item)
    self.x = x or 0
    self.y = y or 0
    self.config = itemConfig
    self.sprite = love.graphics.newImage(itemConfig.sprite)
    self.width  = self.sprite:getWidth()
    self.height = self.sprite:getHeight()
    self.radius = math.max(self.width, self.height) / 2
    self.active = true


    self.angle = 0
    self.rotationSpeed = math.rad(90) * (0.5 + math.random() * 0.5)  -- от 45 до 90 град/сек
    self.floatOffset = 0
    self.floatSpeed = 1 + math.random() * 2   -- 1..3
    self.glowIntensity = 0
    self.glowSpeed = 1 + math.random() * 2

    self.sprite:setFilter('nearest', 'nearest')
    return self
end

function Item:update(dt)
    if not self.active then return end
    self.angle          = self.angle + self.rotationSpeed * dt
    self.floatOffset    = math.sin(love.timer.getTime() * self.floatSpeed) * 5
    self.glowIntensity  = 0.5 + 0.5 * math.sin(love.timer.getTime() * self.glowSpeed)
end

function Item:draw()
    if not self.active then return end

    if self.config.animation == nil then
        love.graphics.setColor(self.config.color_sphere.r, self.config.color_sphere.g, self.config.color_sphere.b, (self.config.color_sphere.a or 0.3) * self.glowIntensity)
        love.graphics.circle("fill", self.x, self.y + self.floatOffset, self.radius * 1)
    else
        self.config.animation()
    end

    if self.config.information ~= nil then
        self.config.information() 
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.sprite, self.x, self.y + self.floatOffset, self.angle, 1, 1, self.width/2, self.height/2)
end

function Item:getPosition()
    return self.x, self.y
end

function Item:getRadius()
    return self.radius
end

function Item:pickup(player, isResource, inventory)
    isResource = isResource or false
    if isResource == false then
        local state_logic_pickup = self.config.logic(player)
        if state_logic_pickup == true then self.active = false end
    else
        self.active = false 
    end
end

return Item