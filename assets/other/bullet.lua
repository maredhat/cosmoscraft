local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(x, y, angle, speed, damage, size, color, lifeTime, owner)
    local self = setmetatable({}, Bullet)
    self.x = x or 0
    self.y = y or 0
    self.angle = angle or 0
    self.speed = speed or 500
    self.damage = damage or 10
    self.size = size or 4
    self.color = color or {1, 1, 1, 1}
    self.lifeTime = lifeTime or 2
    self.timer = 0
    self.active = true
    self.owner = owner or "neutral"
    
    self.vx = math.cos(self.angle) * self.speed
    self.vy = math.sin(self.angle) * self.speed
    
    return self
end

function Bullet:update(dt)
    if not self.active then return end
    
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    self.timer = self.timer + dt
    if self.timer >= self.lifeTime then
        self.active = false
    end
end

function Bullet:draw()
    if not self.active then return end
    
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.size)
    love.graphics.setColor(1, 1, 1, 1)
end

return Bullet