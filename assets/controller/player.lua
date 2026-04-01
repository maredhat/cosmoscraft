-- assets/controller/player.lua (оптимизированная версия без изменения API)

require 'lib.util.math'

local Shaders = require 'lib.shaders'
local Ships   = require 'assets.controller.ships'
local SpriteLoader = require 'lib.util.animation.spriteloader'

local PlayerShip = {}
PlayerShip.__index = PlayerShip

function PlayerShip.new(x, y, s_x, s_y, tier, bulletManager)
    local self = setmetatable({}, PlayerShip)

    self.x = x or 0
    self.y = y or 0
    self.size_x = s_x or 16
    self.size_y = s_y or 16
    self.tier = tier or 1
    self.angle = 0
    self.__bulletCoolDown = 0
    self.active = true
    self.bulletManager = bulletManager
    self.currentSprite = nil
    self.isEngineOn = false
    self.engineTimer = 0
    self._spriteWidth = 0
    self._spriteHeight = 0

    self.stamina = Ships[self.tier].staminaCounter
    self.staminaMax = Ships[self.tier].staminaCounter
    self.items = {}

    self.highSpeedTimer = 0
    self.overheated = false
    self.overheatCooldown = 0
    self.overheatDuration = 5         
    self.overheatLockDuration = 3      
    self.overheatThreshold = 0.85      

    self.health = Ships[self.tier].hitPoints
    self.maxHealth = Ships[self.tier].hitPoints
    self.armor = Ships[self.tier].armor
    self.maxArmor = Ships[self.tier].armor
    self.invincibleTimer = 0
    self.invincibleDuration = 1.0
    self.hitFlash = 0

    self.displayHealth = self.health
    self.displayArmor = self.armor
    self.displayStamina = self.stamina
    self.speedMult = 1
    self.damageNumbers = {}
    self.deathEffect = nil

    self.inventory = {
        companents = {},
        resource = {},
        temporary_bufs = {}
    }

    self.vx = 0
    self.vy = 0

    local shipData = Ships[self.tier]
    self.acceleration = shipData.acceleration or 400
    self.friction = shipData.friction or 2.0
    self.maxSpeed = shipData.maxSpeed or 300

    self.sprintAcceleration = shipData.sprintAcceleration or 800
    self.sprintMaxSpeed = shipData.sprintMaxSpeed or 500

    self.animation = {
        path = {
            idle = shipData.directSprite .. 'ship.png',
            engine_turn = shipData.directSprite .. 'ship_turn_on.png',
            sprint = shipData.directSprite .. 'ship_sprint.png',
        },
        sprite = {}
    }

    self.angularVelocity = shipData.angularVelocity or 0.3
    self.angularFriction = shipData.angularFriction or 0.3

    self.trail = {}
    self.trailTimer = 0
    self.trailInterval = 0.02
    self.trailOffset = self.size_y + 16
    self.trailLife = 1.5
    self.trailFadeSpeed = 1 / self.trailLife

    return self
end

-- ------------------------------------------------------------
-- Вспомогательные методы (без изменений)
-- ------------------------------------------------------------
function PlayerShip:setHealth(health) self.health = math.clamp(self.health + health, 0, self.maxHealth) end
function PlayerShip:setArmor(armor) self.armor = math.clamp(self.armor + armor, 0, self.maxArmor) end
function PlayerShip:getHealth() return self.health end
function PlayerShip:getArmor() return self.armor end
function PlayerShip:getMaxHealth() return self.maxHealth end
function PlayerShip:getMaxArmor() return self.maxArmor end
function PlayerShip:getTierShip() return self.tier end
function PlayerShip:getDataShip() return Ships[self.tier] end
function PlayerShip:addItemInvenroty(type, item) self.inventory[type][item.name] = (self.inventory[type][item.name] or 0) + 1 end
function PlayerShip:deleteItemInvenroty(type, item) self.inventory[type][item.name] = math.max(0, (self.inventory[type][item.name] or 0) - 1) end
function PlayerShip:getPosition() return self.x, self.y end
function PlayerShip:getRadius() return 20 end
function PlayerShip:setStamina(stamina) self.stamina = math.clamp(self.stamina + stamina, 0, self.staminaMax) end
function PlayerShip:getStamina() return self.stamina end
function PlayerShip:getStaminaMax() return self.staminaMax end

function PlayerShip:takeDamage(damage)
    if not self.active or self.invincibleTimer > 0 then return false end
    self.health = self.health - damage
    return true
end

function PlayerShip:bulletTakeDamage(bullet)
    if not self.active or self.invincibleTimer > 0 then return false end
    local actualDamage = bullet.damage
    if self.armor > 0 then
        self.armor = math.max(0, self.armor - bullet.damage * bullet.penetration)
        actualDamage = math.max(1, actualDamage - self.armor * 0.5)
    end
    self.health = self.health - actualDamage
    table.insert(self.damageNumbers, {x = self.x, y = self.y, amount = math.floor(actualDamage), timer = 0.5, alpha = 1})
    if self.health <= 0 then self.active = false end
    return true
end

function PlayerShip:applyCollisionDamage(impact)
    if not self.active or self.invincibleTimer > 0 then return end
    local damage = math.max(1, math.floor(impact))
    self.health = self.health - damage
    table.insert(self.damageNumbers, {x = self.x, y = self.y, amount = damage, timer = 0.5, alpha = 1})
    if self.health <= 0 then self.active = false end
    self.hitFlash = 0.2
    self.invincibleTimer = self.invincibleDuration
end

function PlayerShip:checkCollision(bullet)
    if not self.active then return false end
    local dx = bullet.x - self.x
    local dy = bullet.y - self.y
    return dx*dx + dy*dy < (25 + bullet.size)^2
end

function PlayerShip:shoot()
    local bulletData = Ships[self.tier].bulletConfig
    local dirAngle = self.angle - math.pi/2
    local dirX = math.cos(dirAngle)
    local dirY = math.sin(dirAngle)
    local bulletX = self.x + dirX * 25
    local bulletY = self.y + dirY * 25
    self.bulletManager:shoot({
        x = bulletX,
        y = bulletY,
        vx = dirX * bulletData.speed + self.vx,
        vy = dirY * bulletData.speed + self.vy,
        angle = dirAngle,
        speed = bulletData.speed,
        damage = bulletData.damage,
        penetration = bulletData.penetration,
        size = bulletData.size,
        color = bulletData.color,
        lifeTime = bulletData.lifetime,
        owner = "player"
    })
end

-- ------------------------------------------------------------
-- Основные функции (оптимизированные)
-- ------------------------------------------------------------
function PlayerShip:load()
    local shipPath = Ships[self.tier].directSprite
    self.animation = SpriteLoader(shipPath)
    self.currentSprite = self.animation['idle'].sprite
    Shaders.load('trailGlow', [[
        extern float intensity = 1.0;
        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
            vec4 c = Texel(tex, tc) * color;
            float bright = max(max(c.r, c.g), c.b);
            return c + c * bright * intensity;
        }
    ]])
end

function PlayerShip:update(dt)
    if not self.active then
        if self.deathEffect then self.deathEffect = self.deathEffect - dt end
        return
    end




    -- Ограничение dt для предотвращения скачков
    local maxDt = 0.05
    if dt > maxDt then dt = maxDt end

    -- Обновление таймеров
    if self.invincibleTimer > 0 then self.invincibleTimer = self.invincibleTimer - dt end
    if self.hitFlash > 0 then self.hitFlash = self.hitFlash - dt end

    -- Плавное обновление отображаемых значений
    local lerp = math.min(1, dt * 10)
    self.displayHealth = self.displayHealth + (self.health - self.displayHealth) * lerp
    self.displayArmor  = self.displayArmor  + (self.armor  - self.displayArmor)  * lerp
    self.displayStamina = self.displayStamina + (self.stamina - self.displayStamina) * lerp

    -- Обновление чисел урона
    for i = #self.damageNumbers, 1, -1 do
        local dmg = self.damageNumbers[i]
        dmg.timer = dmg.timer - dt
        dmg.alpha = dmg.timer * 2
        dmg.y = dmg.y - 20 * dt
        if dmg.timer <= 0 then table.remove(self.damageNumbers, i) end
    end

    local ship = Ships[self.tier]

    -- Чтение ввода
    local up = love.keyboard.isDown('w')
    local down = love.keyboard.isDown('s')
    local left = love.keyboard.isDown('a')
    local right = love.keyboard.isDown('d')
    local sprint = love.keyboard.isDown('lshift')
    self.isEngineOn = up or down

    -- Определяем параметры движения
    local currentAccel = self.acceleration
    local currentMaxSpeed = self.maxSpeed
    local isSprinting = false

    if sprint and self.isEngineOn and self.stamina > 0 and self.stamina >= (ship.minStaminaForSprint or 0) then
        currentAccel = self.sprintAcceleration
        currentMaxSpeed = self.sprintMaxSpeed
        isSprinting = true
        self.stamina = math.max(0, self.stamina - (ship.staminaExpenditure or 0) * dt)
        self.currentSprite = self.animation.sprint.sprite
    else
        if self.stamina < self.staminaMax then
            self.stamina = math.min(self.stamina + (ship.staminaTimeRegen or 1.5) * dt, self.staminaMax)
        end
        self.currentSprite = (self.isEngineOn and self.animation.engine_turn.sprite) or self.animation.idle.sprite
    end

    -- Направления
    local forwardX = math.cos(self.angle - math.pi/2)
    local forwardY = math.sin(self.angle - math.pi/2)
    local rightX   = math.cos(self.angle)
    local rightY   = math.sin(self.angle)

    -- Поворот (зависит от скорости)
    local speed = math.sqrt(self.vx*self.vx + self.vy*self.vy)
    local turnFactor = 0
    if speed > 5 then
        turnFactor = math.min(1, (speed - 5) / (currentMaxSpeed - 5))
    end
    local angularAccel = 0
    if left then angularAccel = angularAccel - ship.speedRotation * turnFactor end
    if right then angularAccel = angularAccel + ship.speedRotation * turnFactor end
    self.angularVelocity = self.angularVelocity + angularAccel * dt
    self.angularVelocity = self.angularVelocity * (1 - self.angularFriction * dt)
    self.angle = self.angle + self.angularVelocity * dt

    -- Боковой импульс при повороте (уменьшена сила, сглажено)
    if angularAccel ~= 0 then
        local impulseStrength = 15 * dt
        if left then
            self.vx = self.vx + rightX * impulseStrength
            self.vy = self.vy + rightY * impulseStrength
        elseif right then
            self.vx = self.vx - rightX * impulseStrength
            self.vy = self.vy - rightY * impulseStrength
        end
    end

    -- Ускорение вперёд/назад
    if self.isEngineOn then
        local accelDir = (up and 1 or (down and -1 or 0))
        if accelDir ~= 0 then
            self.vx = self.vx + forwardX * accelDir * currentAccel * dt
            self.vy = self.vy + forwardY * accelDir * currentAccel * dt
        end
    end

    -- Разделение скорости на продольную и поперечную (дрифт)
    local forwardSpeed = self.vx * forwardX + self.vy * forwardY
    local rightSpeed   = self.vx * rightX   + self.vy * rightY

    forwardSpeed = forwardSpeed * (1 - ship.friction * dt)
    rightSpeed   = rightSpeed   * (1 - ship.friction * dt * 1.5)

    self.vx = forwardSpeed * forwardX + rightSpeed * rightX
    self.vy = forwardSpeed * forwardY + rightSpeed * rightY

    -- Ограничение максимальной скорости
    speed = math.sqrt(self.vx*self.vx + self.vy*self.vy)
    if speed > currentMaxSpeed then
        self.vx = self.vx / speed * currentMaxSpeed
        self.vy = self.vy / speed * currentMaxSpeed
    end

    -- Перемещение
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Трейл
    if speed > 20 then
        self.trailTimer = self.trailTimer - dt
        if self.trailTimer <= 0 then
            self.trailTimer = self.trailTimer + self.trailInterval
            local backX = self.x - forwardX * self.trailOffset
            local backY = self.y - forwardY * self.trailOffset
            table.insert(self.trail, {x = backX, y = backY, timer = self.trailLife})
        end
    end

    -- Обновление таймеров трейла и удаление старых
    for i = #self.trail, 1, -1 do
        local p = self.trail[i]
        p.timer = p.timer - dt
        if p.timer <= 0 then table.remove(self.trail, i) end
    end

    -- Стрельба
    if self.__bulletCoolDown > 0 then self.__bulletCoolDown = self.__bulletCoolDown - dt end
    if love.keyboard.isDown('space') and self.__bulletCoolDown <= 0 then
        self:shoot()
        self.__bulletCoolDown = ship.bulletConfig.coolDown
    end
end
function PlayerShip:draw()
    if self.deathEffect then
        love.graphics.setColor(1, 0.5, 0, self.deathEffect)
        love.graphics.circle("fill", self.x, self.y, 30 * (1 + self.deathEffect))
        return
    end
    if not self.active then return end

    -- Отрисовка следа (линия)
    if #self.trail > 1 then
        love.graphics.setLineWidth(6)
        love.graphics.setLineJoin("bevel")
        love.graphics.setLineStyle("smooth")
        for i = #self.trail, 2, -1 do
            local p1 = self.trail[i-1]
            local p2 = self.trail[i]
            if p1.timer and p2.timer then
                local alpha = (p1.timer + p2.timer) / (2 * self.trailLife)
                love.graphics.setColor(1, 1, 1, alpha)
                love.graphics.line(p1.x, p1.y, p2.x, p2.y)
            end
        end
    end

    -- Мигание при уроне
    if self.hitFlash > 0 and math.floor(self.hitFlash * 20) % 2 == 0 then
        love.graphics.setColor(1, 1, 1, 0.5)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Рисуем корабль
    if self.currentSprite then
        love.graphics.draw(self.currentSprite, self.x, self.y, self.angle,
            self.size_x, self.size_y,
            self.currentSprite:getWidth() * 0.5, self.currentSprite:getHeight() * 0.5)
    end

    -- Числа урона
    for _, dmg in ipairs(self.damageNumbers) do
        love.graphics.setColor(1, 0, 0, dmg.alpha)
        love.graphics.print("-" .. dmg.amount, dmg.x - 10, dmg.y)
    end
end

setmetatable(PlayerShip, { __call = function(cls, ...) return cls.new(...) end })

return PlayerShip