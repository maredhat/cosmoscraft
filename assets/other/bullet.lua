local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(options)
    local self = setmetatable({}, Bullet)
    self.x = options.x or 0
    self.y = options.y or 0
    self.angle = options.angle or 0
    self.speed = options.speed or 500
    self.damage = options.damage or 10
    self.size = options.size or 4
    self.color = options.color or {1, 1, 1, 1}
    self.lifeTime = options.lifeTime or 2
    self.penetration = options.penetration or 0.5
    self.owner = options.owner or "none"
    self.timer = 0
    self.active = true
    if options.vx and options.vy then
        self.vx = options.vx
        self.vy = options.vy
    else
        self.vx = math.cos(self.angle) * self.speed
        self.vy = math.sin(self.angle) * self.speed
    end
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