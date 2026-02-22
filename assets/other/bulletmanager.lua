local Bullet = require('assets.other.bullet')

local BulletManager = {}
BulletManager.__index = BulletManager

function BulletManager.new()
    local self = setmetatable({}, BulletManager)
    self.bullets = {}
    self.pool = {}
    return self
end


function BulletManager:shoot(options)
    local bullet
    if #self.pool > 0 then
        bullet = table.remove(self.pool)
        bullet.x = options.x
        bullet.y = options.y
        bullet.angle = options.angle
        bullet.speed = options.speed
        bullet.damage = options.damage
        bullet.penetration = options.penetration or 0
        bullet.size = options.size
        bullet.color = options.color or {1, 1, 1, 1}
        bullet.lifeTime = options.lifeTime or 2
        bullet.owner = options.owner or nil
        bullet.timer = 0
        bullet.active = true
        if options.vx and options.vy then
            bullet.vx = options.vx
            bullet.vy = options.vy
        else
            bullet.vx = math.cos(bullet.angle) * bullet.speed
            bullet.vy = math.sin(bullet.angle) * bullet.speed
        end
    else
        bullet = Bullet.new(options)
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
    local bullets = self.bullets          
    for i = 1, #bullets do
        bullets[i]:draw()
    end
end

function BulletManager:clear()
    if #self.bullets == 0 then return end

    local bullets = self.bullets

    local pool = self.pool
    local offset = #pool               
    for i = 1, #bullets do
        pool[offset + i] = bullets[i]  
    end
    

    self.bullets = {}                      
end


function BulletManager:getCount()
    return #self.bullets
end

return BulletManager