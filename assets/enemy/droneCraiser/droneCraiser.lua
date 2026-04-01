-- assets/enemy/capital_ship/capital_ship.lua
-- Огромный вражеский крейсер с тактикой удержания дистанции
-- Выпускает дронов-камикадзе, стреляет огромными медленными снарядами

local CapitalShip = {}
CapitalShip.__index = CapitalShip

local random = math.random
local sin = math.sin
local cos = math.cos
local atan2 = math.atan2
local sqrt = math.sqrt
local pi = math.pi
local insert = table.insert
local remove = table.remove

function CapitalShip.new(x, y, bulletManager, player, scene)
    local self = setmetatable({}, CapitalShip)
    self.x = x or 0
    self.y = y or 0
    self.scene = scene
    self.bulletManager = bulletManager
    self.player = player

    -- Огромный размер (увеличим)
    self.width = 340
    self.height = 220
    self.radius = 180

    -- Здоровье (теперь без регенерации)
    self.health = 2500
    self.maxHealth = 2500

    -- Состояние
    self.active = true
    self.angle = 0
    self.targetAngle = 0
    self.rotationSpeed = 0.8

    -- Позиционная тактика
    self.desiredDistance = 550
    self.approachSpeed = 35
    self.retreatSpeed = 55
    self.strafeSpeed = 45
    self.strafeDirection = 0
    self.strafeTimer = 0

    self.vx = 0
    self.vy = 0
    self.maxSpeed = 85

    -- Атака
    self.shootCooldown = 0
    self.shootCooldownMax = 2.2
    self.bigBulletSpeed = 140
    self.bigBulletDamage = 45
    self.bigBulletSize = 20
    self.bigBulletColor = {1, 0.2, 0.2, 1}

    -- Спавн камикадзе
    self.kamikazeSpawnCooldown = 0
    self.kamikazeSpawnCooldownMax = 7    -- чаще, чем обычные дроны
    self.kamikazeCount = 3               -- за раз вылетает 3 камикадзе
    self.kamikazes = {}                  -- активные камикадзе (для контроля)

    -- Визуальные эффекты
    self.engineGlow = 0
    self.hitFlash = 0
    self.deathEffect = nil

    -- Коллизия
    self.collisionDamage = 65

    return self
end

-- ------------------------------------------------------------------------
-- Спавн дронов-камикадзе
-- ------------------------------------------------------------------------
function CapitalShip:spawnKamikaze(count)
    local Kamikaze = require 'assets.enemy.kamikaze_drone.kamikaze_drone'
    for i = 1, count do
        local angle = random() * 2 * pi
        local dist = self.radius + 50
        local dx = cos(angle) * dist
        local dy = sin(angle) * dist
        local spawnX = self.x + dx
        local spawnY = self.y + dy

        local kamikaze = Kamikaze.new(spawnX, spawnY, self.bulletManager, self.player, self.scene)
        kamikaze.owner = self   -- ссылка на корабль (если нужно)
        insert(self.kamikazes, kamikaze)
        if self.scene and self.scene.enemies then
            insert(self.scene.enemies, kamikaze)
        end
    end
end

-- ------------------------------------------------------------------------
-- Стрельба огромными медленными пулями
-- ------------------------------------------------------------------------
function CapitalShip:shoot()
    if not self.bulletManager then return end
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local dist = sqrt(dx*dx + dy*dy)
    if dist < 0.01 then return end
    local dirX = dx / dist
    local dirY = dy / dist

    local noseX = self.x + cos(self.angle) * (self.width * 0.6)
    local noseY = self.y + sin(self.angle) * (self.width * 0.6)

    self.bulletManager:shoot({
        x = noseX, y = noseY,
        vx = dirX * self.bigBulletSpeed,
        vy = dirY * self.bigBulletSpeed,
        angle = atan2(dy, dx),
        speed = self.bigBulletSpeed,
        damage = self.bigBulletDamage,
        penetration = 2,
        size = self.bigBulletSize,
        color = self.bigBulletColor,
        lifeTime = 5.0,
        owner = "enemy"
    })
end

-- ------------------------------------------------------------------------
-- Получение урона (обычный, без регенерации)
-- ------------------------------------------------------------------------
function CapitalShip:takeDamage(amount, bullet)
    if not self.active then return false end
    self.health = self.health - amount
    self.hitFlash = 0.2
    if self.health <= 0 then
        self:die()
        return true
    end
    return false
end

-- ------------------------------------------------------------------------
-- Смерть корабля
-- ------------------------------------------------------------------------
function CapitalShip:die()
    self.active = false
    self.deathEffect = 1.8
    -- Взрыв
    for i = 1, 120 do
        if self.scene and self.scene.particles then
            insert(self.scene.particles, {
                x = self.x + (random() - 0.5) * self.width,
                y = self.y + (random() - 0.5) * self.height,
                vx = (random() - 0.5) * 350,
                vy = (random() - 0.5) * 350,
                life = 1.2,
                color = {1, 0.5, 0.1, 1}
            })
        end
    end
    -- Уничтожаем всех камикадзе
    for _, k in ipairs(self.kamikazes) do
        k.active = false
        k.deathEffect = 0.6
    end
    self.kamikazes = {}
end

-- ------------------------------------------------------------------------
-- Обновление
-- ------------------------------------------------------------------------
function CapitalShip:update(dt)
    if not self.active then
        if self.deathEffect then self.deathEffect = self.deathEffect - dt end
        return
    end

    if self.hitFlash then
        self.hitFlash = self.hitFlash - dt
        if self.hitFlash <= 0 then self.hitFlash = nil end
    end

    -- Позиционная логика
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local distToPlayer = sqrt(dx*dx + dy*dy)
    local dirToPlayerX = 0
    local dirToPlayerY = 0
    if distToPlayer > 0 then
        dirToPlayerX = dx / distToPlayer
        dirToPlayerY = dy / distToPlayer
    end

    local moveX, moveY = 0, 0
    if distToPlayer > self.desiredDistance + 100 then
        moveX = dirToPlayerX
        moveY = dirToPlayerY
    elseif distToPlayer < self.desiredDistance - 100 then
        moveX = -dirToPlayerX
        moveY = -dirToPlayerY
    end

    -- Уклонение
    self.strafeTimer = self.strafeTimer - dt
    if self.strafeTimer <= 0 then
        self.strafeDirection = random(-1, 1)
        self.strafeTimer = 1.5 + random() * 2
    end
    local perpX = -dirToPlayerY
    local perpY = dirToPlayerX
    moveX = moveX + perpX * self.strafeDirection * self.strafeSpeed / self.maxSpeed
    moveY = moveY + perpY * self.strafeDirection * self.strafeSpeed / self.maxSpeed

    local moveLen = sqrt(moveX*moveX + moveY*moveY)
    if moveLen > 0 then
        moveX = moveX / moveLen
        moveY = moveY / moveLen
    end

    local desiredSpeed = self.approachSpeed
    if distToPlayer < self.desiredDistance then
        desiredSpeed = self.retreatSpeed
    end
    local targetVx = moveX * desiredSpeed
    local targetVy = moveY * desiredSpeed

    local accel = 90 * dt
    self.vx = self.vx + (targetVx - self.vx) * accel
    self.vy = self.vy + (targetVy - self.vy) * accel

    local spd = sqrt(self.vx*self.vx + self.vy*self.vy)
    if spd > self.maxSpeed then
        self.vx = self.vx / spd * self.maxSpeed
        self.vy = self.vy / spd * self.maxSpeed
    end

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Поворот к игроку
    local targetAngle = atan2(dy, dx)
    local diff = targetAngle - self.angle
    while diff > pi do diff = diff - 2*pi end
    while diff < -pi do diff = diff + 2*pi end
    local maxTurn = self.rotationSpeed * dt
    if diff > maxTurn then
        self.angle = self.angle + maxTurn
    elseif diff < -maxTurn then
        self.angle = self.angle - maxTurn
    else
        self.angle = targetAngle
    end

    -- Границы
    if self.scene and self.scene.worldBounds then
        local wb = self.scene.worldBounds
        local margin = 80
        if self.x - self.radius < wb.left then self.x = wb.left + self.radius end
        if self.x + self.radius > wb.right then self.x = wb.right - self.radius end
        if self.y - self.radius < wb.top then self.y = wb.top + self.radius end
        if self.y + self.radius > wb.bottom then self.y = wb.bottom - self.radius end
    end

    -- Стрельба
    if self.shootCooldown <= 0 then
        self.shootCooldown = self.shootCooldownMax
        self:shoot()
    else
        self.shootCooldown = self.shootCooldown - dt
    end

    -- Спавн камикадзе
    if self.kamikazeSpawnCooldown <= 0 then
        self.kamikazeSpawnCooldown = self.kamikazeSpawnCooldownMax
        self:spawnKamikaze(self.kamikazeCount)
    else
        self.kamikazeSpawnCooldown = self.kamikazeSpawnCooldown - dt
    end

    -- Удаляем мёртвых камикадзе из списка
    for i = #self.kamikazes, 1, -1 do
        if not self.kamikazes[i].active then
            remove(self.kamikazes, i)
        end
    end

    -- Коллизия с игроком
    self:checkCollisionWithPlayer()

    -- Анимация двигателей
    self.engineGlow = 0.4 + sin(love.timer.getTime() * 8) * 0.3
end

-- ------------------------------------------------------------------------
-- Коллизия с игроком
-- ------------------------------------------------------------------------

function CapitalShip:getRadius()
    return self.radius
end

-- ------------------------------------------------------------------------
-- Отрисовка (улучшенный крейсер)
-- ------------------------------------------------------------------------
function CapitalShip:draw()
    if self.deathEffect then
        love.graphics.setColor(1, 0.5, 0.1, self.deathEffect)
        love.graphics.circle("fill", self.x, self.y, self.radius * (1 + self.deathEffect))
        return
    end
    if not self.active then return end




end

return CapitalShip