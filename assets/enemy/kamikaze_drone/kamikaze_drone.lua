-- assets/enemy/kamikaze_drone/kamikaze_drone.lua
-- Дрон-камикадзе: летит к игроку и взрывается при касании

local KamikazeDrone = {}
KamikazeDrone.__index = KamikazeDrone

function KamikazeDrone.new(x, y, bulletManager, player, scene)
    local self = setmetatable({}, KamikazeDrone)
    self.x = x or 0
    self.y = y or 0
    self.scene = scene
    self.bulletManager = bulletManager
    self.player = player
    self.active = true

    -- Размер
    self.radius = 20
    self.width = 40
    self.height = 40

    -- Параметры движения
    self.speed = 180
    self.acceleration = 300
    self.vx = 0
    self.vy = 0
    self.angle = 0

    -- Взрыв
    self.explosionRadius = 60
    self.explosionDamage = 35

    -- Визуал
    self.hitFlash = 0
    self.deathEffect = nil

    return self
end

function KamikazeDrone:update(dt)
    if not self.active then
        if self.deathEffect then
            self.deathEffect = self.deathEffect - dt
        end
        return
    end

    -- Наводимся на игрока
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > 0.01 then
        local targetAngle = math.atan2(dy, dx)
        local diff = targetAngle - self.angle
        while diff > math.pi do diff = diff - 2*math.pi end
        while diff < -math.pi do diff = diff + 2*math.pi end
        local maxTurn = 5 * dt
        if diff > maxTurn then
            self.angle = self.angle + maxTurn
        elseif diff < -maxTurn then
            self.angle = self.angle - maxTurn
        else
            self.angle = targetAngle
        end

        -- Ускорение
        local ax = math.cos(self.angle) * self.acceleration * dt
        local ay = math.sin(self.angle) * self.acceleration * dt
        self.vx = self.vx + ax
        self.vy = self.vy + ay

        local spd = math.sqrt(self.vx*self.vx + self.vy*self.vy)
        if spd > self.speed then
            self.vx = self.vx / spd * self.speed
            self.vy = self.vy / spd * self.speed
        end
    end

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Проверка столкновения с игроком
    if self.player and self.player.active then
        local pdx = self.player.x - self.x
        local pdy = self.player.y - self.y
        local pdist = math.sqrt(pdx*pdx + pdy*pdy)
        if pdist < self.radius + self.player:getRadius() then
            self:explode()
        end
    end

    -- Проверка столкновения с пулями игрока
    if self.bulletManager then
        for _, bullet in ipairs(self.bulletManager.bullets) do
            if bullet.owner == "player" then
                local bdx = bullet.x - self.x
                local bdy = bullet.y - self.y
                if bdx*bdx + bdy*bdy < (self.radius + bullet.size)^2 then
                    self:explode()
                    bullet.active = false
                    break
                end
            end
        end
    end

    -- Удаляем, если улетел за границы
    if self.scene and self.scene.worldBounds then
        local wb = self.scene.worldBounds
        if self.x + self.radius < wb.left or self.x - self.radius > wb.right or
           self.y + self.radius < wb.top or self.y - self.radius > wb.bottom then
            self.active = false
        end
    end
end

function KamikazeDrone:explode()
    if not self.active then return end
    self.active = false
    self.deathEffect = 0.6

    -- Наносим урон игроку
    if self.player and self.player.active then
        local dx = self.player.x - self.x
        local dy = self.player.y - self.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < self.explosionRadius then
            local damage = self.explosionDamage
            if dist > 0 then
                damage = damage * (1 - dist / self.explosionRadius)
            end
            self.player:applyCollisionDamage(damage)
        end
    end

    -- Создаём взрывные частицы
    for i = 1, 20 do
        if self.scene and self.scene.particles then
            table.insert(self.scene.particles, {
                x = self.x + (math.random() - 0.5) * self.radius,
                y = self.y + (math.random() - 0.5) * self.radius,
                vx = (math.random() - 0.5) * 200,
                vy = (math.random() - 0.5) * 200,
                life = 0.5,
                color = {1, 0.5, 0.1, 1}
            })
        end
    end
end

function KamikazeDrone:draw()
    if self.deathEffect then
        love.graphics.setColor(1, 0.3, 0.1, self.deathEffect)
        love.graphics.circle("fill", self.x, self.y, self.radius * (1 + self.deathEffect))
        return
    end
    if not self.active then return end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    -- Корпус (красный, агрессивный)
    love.graphics.setColor(0.8, 0.2, 0.1, 1)
    love.graphics.ellipse("fill", 0, 0, self.width/2, self.height/2)

    -- Острые шипы
    love.graphics.setColor(1, 0.4, 0.1, 1)
    love.graphics.polygon("fill",
        0, -self.height/2 - 10,
        -8, -self.height/2,
        8, -self.height/2)
    love.graphics.polygon("fill",
        0, self.height/2 + 10,
        -8, self.height/2,
        8, self.height/2)

    -- Глаза (злобные)
    love.graphics.setColor(1, 1, 0.5, 1)
    love.graphics.circle("fill", -12, -5, 4)
    love.graphics.circle("fill", 12, -5, 4)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", -12, -5, 2)
    love.graphics.circle("fill", 12, -5, 2)

    -- Двигатель (свечение)
    love.graphics.setColor(1, 0.5, 0.2, 0.7 + math.sin(love.timer.getTime() * 15) * 0.3)
    love.graphics.rectangle("fill", -10, self.height/2 - 5, 20, 10)

    love.graphics.pop()
end

function KamikazeDrone:getRadius()
    return self.radius
end

function KamikazeDrone:takeDamage(amount, bullet)
    if not self.active then return false end
    -- Камикадзе взрывается при любом попадании
    self:explode()
    return true
end

function KamikazeDrone:applyCollisionDamage(impact)
    -- Не используется, но для совместимости
end

return KamikazeDrone