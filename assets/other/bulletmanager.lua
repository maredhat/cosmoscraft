local Bullet = require('assets.other.bullet')

local BulletManager = {}
BulletManager.__index = BulletManager

function BulletManager.new()
    local self = setmetatable({}, BulletManager)
    self.bullets = {}
    self.pool = {}
    return self
end

function BulletManager:shoot(x, y, angle, speed, damage, size, color, lifeTime, owner)
    local bullet
    
    if #self.pool > 0 then
        bullet = table.remove(self.pool)
        bullet.x = x
        bullet.y = y
        bullet.angle = angle
        bullet.speed = speed
        bullet.damage = damage
        bullet.size = size
        bullet.color = color or {1, 1, 1, 1}
        bullet.lifeTime = lifeTime or 2
        bullet.timer = 0
        bullet.active = true
        bullet.owner = owner or "neutral"
        bullet.vx = math.cos(angle) * speed
        bullet.vy = math.sin(angle) * speed
    else
        bullet = Bullet.new(x, y, angle, speed, damage, size, color, lifeTime, owner)
    end
    
    table.insert(self.bullets, bullet)
    return bullet
end

function BulletManager:update(dt)
    local i = 1
    while i <= #self.bullets do
        local bullet = self.bullets[i]
        bullet:update(dt)
        
        if not bullet.active then
            table.remove(self.bullets, i)
            table.insert(self.pool, bullet)
        else
            i = i + 1
        end
    end
end

function BulletManager:draw()
    for _, bullet in ipairs(self.bullets) do
        bullet:draw()
    end
end

function BulletManager:clear()
    for _, bullet in ipairs(self.bullets) do
        table.insert(self.pool, bullet)
    end
    self.bullets = {}
end

function BulletManager:getCount()
    return #self.bullets
end

return BulletManager