require 'lib.util.math'

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

local Ships           = require 'assets.controller.ships'
local SpriteLoader    = require 'lib.util.animation.spriteloader' 

--------------------------------------------------------------------------------

local PlayerShip = {}
PlayerShip.__index = PlayerShip

--------------------------------------------------------------------------------

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
    
    self.stamina    = Ships[self.tier].staminaCounter
    self.staminaMax = Ships[self.tier].staminaCounter
    self.items = {} 

    self.health = Ships[self.tier].hitPoints
    self.maxHealth = Ships[self.tier].hitPoints
    self.armor = Ships[self.tier].armor
    self.maxArmor = Ships[self.tier].armor
    self.invincibleTimer = 0
    self.invincibleDuration = 1.0
    self.hitFlash = 0
    
    self.speedMult = 1
    self.damageNumbers = {}
    self.deathEffect = nil
    
    -- Бафы которые активны 
    self.inventory = 
    {
        companents     = {},
        resource       = {},
        temporary_bufs = {}
    }

    -- таблица анимаций 

    self.vx = 0
    self.vy = 0

    self.acceleration = Ships[self.tier].acceleration or 400
    self.friction = Ships[self.tier].friction or 2.0
    self.maxSpeed = Ships[self.tier].maxSpeed or 300

    self.sprintAcceleration = Ships[self.tier].sprintAcceleration or 800
    self.sprintMaxSpeed = Ships[self.tier].sprintMaxSpeed or 500

    self.animation = 
    {
        path = {
            idle        = Ships[self.tier].directSprite .. 'ship.png',
            engine_turn = Ships[self.tier].directSprite .. 'ship_turn_on.png',
            sprint      = Ships[self.tier].directSprite .. 'ship_sprint.png',
        },
        sprite = {}
    }
    
    self.angularVelocity = Ships[self.tier].angularVelocity or 0.3
    self.angularFriction = Ships[self.tier].angularFriction or 0.3   


    
    self.trail = {}                 
    self.trailTimer = 0             
    self.trailInterval = 0.05       
    self.trailOffset = self.size_y + 16
    return self
end
--------------------------------------------------------------------------------


-- Player effects

function PlayerShip:poisoning(time, damage) 
    -- создать систему отравления
end


-- Supportive function API for create items

function PlayerShip:setHealth(health) self.health = math.clamp(self.health + health, 0, self.maxHealth) end

function PlayerShip:setArmor(armor) self.armor = math.clamp(self.armor + armor, 0, self.maxArmor) end

function PlayerShip:getHealth() return self.health end
function PlayerShip:getArmor() return self.armor end

function PlayerShip:getMaxHealth() return self.maxHealth end
function PlayerShip:getMaxArmor() return self.maxArmor end

function PlayerShip:getTierShip() return self.tier end
function PlayerShip:getDataShip(Tier) return Ships[self.tier] end


function PlayerShip:addItemInvenroty(type, item) self.inventory[type][item.name] = self.inventory[type][item.name] + 1 end
function PlayerShip:deleteItemInvenroty(type, item) self.inventory[type][item.name] = self.inventory[type][item.name] - 1 end

function PlayerShip:getPosition() return self.x, self.y end
function PlayerShip:getRadius() return 20 end

function PlayerShip:setStamina(stamina) self.stamina = math.clamp(self.stamina + stamina, 0, self.staminaMax) end

function PlayerShip:getStamina() return self.stamina end
function PlayerShip:getStaminaMax() return self.staminaMax end

-- Function In this file

function PlayerShip:takeDamage(damage)
    if (not self.active) or ( self.invincibleTimer > 0 ) then return false end
    self.health = self.health - damage
end

function PlayerShip:bulletTakeDamage(bullet)
    if (not self.active) or ( self.invincibleTimer > 0 ) then return false end
    
    local actualDamage = bullet.damage

    if self.armor > 0 then
        actualDamage        = math.max(1, bullet.damage - self.armor * 0.5)
        self.armor          = math.max(0, self.armor - bullet.damage * bullet.penetration)
    end

    self:takeDamage( math.floor(actualDamage) )

    table.insert( self.damageNumbers, 
    {
        x      = self.x,
        y      = self.y,
        amount = math.floor(actualDamage),
        timer  = 0.5,
        alpha  = 1
    } )

    if self:getHealth() < 0 then self.active = false end
    return false
end


function PlayerShip:applyCollisionDamage(impact)
    if not self.active or self.invincibleTimer > 0 then return end
    local damage = math.floor(impact)
    if damage < 1 then damage = 1 end
    self.health = self.health - damage
    table.insert(self.damageNumbers, {x=self.x, y=self.y, amount=damage, timer=0.5, alpha=1})
    if self.health <= 0 then self.active = false end
    self.hitFlash = 0.2
    self.invincibleTimer = self.invincibleDuration
end


function PlayerShip:bulletTakeDamage(bullet)
    if (not self.active) or (self.invincibleTimer > 0) then return false end
    
    local actualDamage = bullet.damage

    if self.armor > 0 then
         self.armor = math.max(0, self.armor - bullet.damage * bullet.penetration)
         local armorReduction = self.armor * 0.5
         actualDamage = math.max(1, actualDamage - armorReduction)
         self.health = self.health - actualDamage
    else
        self.health = self.health - actualDamage
        table.insert(self.damageNumbers, {
            x = self.x,
            y = self.y,
            amount = math.floor(actualDamage),
            timer = 0.5,
            alpha = 1
        })
    end

    if self.health <= 0 then
        self.health = 0
        self.active = false
    end

    return true
end



function PlayerShip:checkCollision(bullet)
    if not self.active then return false end
    
    local dx = bullet.x - self.x
    local dy = bullet.y - self.y
    local dist = math.dot(dx, dy)
    
    return dist < 25 + bullet.size
end

function PlayerShip:shoot()
    local bulletdata = Ships[self.tier].bulletConfig
    local offset = 25
    local directionAngle = self.angle - math.pi/2
    local directionX = math.cos(directionAngle)
    local directionY = math.sin(directionAngle)
    local bulletX = self.x + directionX * offset
    local bulletY = self.y + directionY * offset
    local bulletSpeed = bulletdata.speed
    local vx = directionX * bulletSpeed + self.vx
    local vy = directionY * bulletSpeed + self.vy
    self.bulletManager:shoot({
        x = bulletX,
        y = bulletY,
        vx = vx,
        vy = vy,
        angle = directionAngle,
        speed = bulletSpeed,
        damage = bulletdata.damage,
        penetration = bulletdata.penetration,
        size = bulletdata.size,
        color = bulletdata.color,
        lifeTime = bulletdata.lifetime,
        owner = "player"
    })
end

-- Main functions




function PlayerShip:load()
    local shipPath = Ships[self.tier].directSprite
    self.animation = SpriteLoader(shipPath)
    self.currentSprite = self.animation['idle'].sprite
end


function PlayerShip:update(dt)
    if not self.active then
        if self.deathEffect then self.deathEffect = self.deathEffect - dt end
        return
    end

    if self.invincibleTimer > 0 then self.invincibleTimer = self.invincibleTimer - dt end
    if self.hitFlash > 0 then self.hitFlash = self.hitFlash - dt end
    local i = 1
    while i <= #self.damageNumbers do
        local dmg = self.damageNumbers[i]
        dmg.timer = dmg.timer - dt
        dmg.alpha = dmg.timer * 2
        dmg.y = dmg.y - 20 * dt
        if dmg.timer <= 0 then table.remove(self.damageNumbers, i) else i = i + 1 end
    end

    local ship = Ships[self.tier]

    local dx, dy = 0, 0
    self.isEngineOn = love.keyboard.isDown('w') or love.keyboard.isDown('s')
    if love.keyboard.isDown('w') then dy = dy - 1 end
    if love.keyboard.isDown('s') then dy = dy + 1 end

    local speed = math.sqrt(self.vx^2 + self.vy^2)
    local minSpeedForTurn = 20

    local angularAccel = 0
    if speed > minSpeedForTurn then
        if love.keyboard.isDown('a') then
            angularAccel = angularAccel - ship.speedRotation * 2
        end
        if love.keyboard.isDown('d') then
            angularAccel = angularAccel + ship.speedRotation * 2
        end
    end

    self.angularVelocity = (self.angularVelocity or 0) + angularAccel * dt
    self.angularVelocity = self.angularVelocity * (1 - (self.angularFriction or 3.0) * dt)
    self.angle = self.angle + self.angularVelocity * dt

    if angularAccel ~= 0 then
        local rightX = math.cos(self.angle)
        local rightY = math.sin(self.angle)
        local impulseStrength = 40 * dt
        if love.keyboard.isDown('a') then
            self.vx = self.vx + rightX * impulseStrength
            self.vy = self.vy + rightY * impulseStrength
        elseif love.keyboard.isDown('d') then
            self.vx = self.vx - rightX * impulseStrength
            self.vy = self.vy - rightY * impulseStrength
        end
    end

    local currentAccel = self.acceleration
    local currentMaxSpeed = self.maxSpeed

    if love.keyboard.isDown('lshift') and self.stamina > 0 and self.isEngineOn then
        currentAccel = self.sprintAcceleration
        currentMaxSpeed = self.sprintMaxSpeed
        self.stamina = self.stamina - (ship.staminaExpenditure or 0) * dt
        if self.stamina < 0 then self.stamina = 0 end
        self.currentSprite = self.animation.sprint.sprite
    else
        if self.stamina < self.staminaMax then
            self.stamina = math.min(self.stamina + (ship.staminaTimeRegen or 1.5) * dt, self.staminaMax)
        end
        self.currentSprite = self.isEngineOn and self.animation.engine_turn.sprite or self.animation.idle.sprite
    end

    if self.isEngineOn then
        local forwardX = math.cos(self.angle - math.pi/2)
        local forwardY = math.sin(self.angle - math.pi/2)
        local accelX = forwardX * (-dy) * currentAccel * dt
        local accelY = forwardY * (-dy) * currentAccel * dt
        self.vx = self.vx + accelX
        self.vy = self.vy + accelY
    end

    local forwardX = math.cos(self.angle - math.pi/2)
    local forwardY = math.sin(self.angle - math.pi/2)
    local rightX = math.cos(self.angle)
    local rightY = math.sin(self.angle)

    local forwardSpeed = self.vx * forwardX + self.vy * forwardY
    local rightSpeed = self.vx * rightX + self.vy * rightY

    forwardSpeed = forwardSpeed * (1 - ship.friction * dt)
    rightSpeed = rightSpeed * (1 - ship.friction * dt * 1.5)

    self.vx = forwardSpeed * forwardX + rightSpeed * rightX
    self.vy = forwardSpeed * forwardY + rightSpeed * rightY

    speed = math.sqrt(self.vx^2 + self.vy^2)
    if speed > currentMaxSpeed then
        self.vx = self.vx / speed * currentMaxSpeed
        self.vy = self.vy / speed * currentMaxSpeed
    end

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt


    local speed = math.sqrt(self.vx^2 + self.vy^2)
    self.trailTimer = self.trailTimer - dt
    if speed > 20 and self.trailTimer <= 0 then
        self.trailTimer = self.trailTimer + self.trailInterval  
        local backDirX = -math.cos(self.angle - math.pi/2)
        local backDirY = -math.sin(self.angle - math.pi/2)
        local backX = self.x + backDirX * self.trailOffset
        local backY = self.y + backDirY * self.trailOffset
        table.insert(self.trail, {x = backX, y = backY, alpha = 1})
    end

    for i = #self.trail, 1, -1 do
        local p = self.trail[i]
        p.alpha = p.alpha - dt * 2  
        if p.alpha <= 0 then
            table.remove(self.trail, i)
        end
    end

    self.__bulletCoolDown = (self.__bulletCoolDown > 0) and self.__bulletCoolDown - dt or self.__bulletCoolDown
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
    

    for _, p in ipairs(self.trail) do
        love.graphics.setColor(1, 1, 1, p.alpha)
        love.graphics.circle("fill", p.x, p.y, 4)
    end

    if self.hitFlash > 0 and math.floor(self.hitFlash * 20) % 2 == 0 then
        love.graphics.setColor(1, 1, 1, 0.5)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    if self.currentSprite then
        love.graphics.draw(
            self.currentSprite,
            self.x, self.y, self.angle,
            self.size_x, self.size_y,
            self.currentSprite:getWidth() * 0.5, self.currentSprite:getHeight() * 0.5
        )
    else
        error("Sprite not loaded for ship")
    end

    for _, dmg in ipairs(self.damageNumbers) do
        love.graphics.setColor(1, 0, 0, dmg.alpha)
        love.graphics.print("-" .. dmg.amount, dmg.x - 10, dmg.y)
    end
end

function PlayerShip:hud()
    local centerOx = function(size_w1, size_w2) return (size_w1 / 2) - size_w2 / 2 end    


    local w_screen, h_screen = love.graphics.getWidth(), love.graphics.getHeight()

    -- HITPOINTS
    do
        local health_w = w_screen / 3
        local health_h = 5.5 * 2
        local health = self:getHealth()

        local hitpoints = math.clamp(health * (health_w / self:getMaxHealth()), 0, health_w)
        local center_health = centerOx(w_screen, health_w)
        

        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.setLineWidth(0.2)
        love.graphics.rectangle("line", center_health, health_h, health_w, health_h, 5, 8.5)
        love.graphics.setColor(1, 0, 0, 0.75)
        love.graphics.rectangle("fill", center_health, health_h, hitpoints, health_h, 5, 8.5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(self:getHealth() .. '/' .. self:getMaxHealth(), health_w * 2.01, health_h - 2)
    end
    

    --ARMOR 
    do
        local health_w = w_screen / 3
        local health_h = 8.5 * 4

        local hitpoints = math.clamp(self:getArmor() * (health_w / self:getMaxArmor()), 0, health_w)
        local center_health = centerOx(w_screen, health_w)
        

        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.setLineWidth(0.2)
        love.graphics.rectangle("line", center_health, health_h, health_w, 6, 5, 6)
        love.graphics.setColor(0, 0.5, 1, 0.75)
        love.graphics.rectangle("fill", center_health, health_h, hitpoints, 6, 5, 6)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(math.floor(self:getArmor()) .. '/' .. self:getMaxArmor(), health_w * 2.01, health_h - 2)
    end


    -- Stamina
    do
    local health_w = w_screen / 3
        local health_h = 8.5 * 6

        local hitpoints = math.clamp(self:getStamina() * (health_w / self:getStaminaMax()), 0, health_w)
        local center_health = centerOx(w_screen, health_w)
        

        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.setLineWidth(0.2)
        love.graphics.rectangle("line", center_health, health_h, health_w, 6, 5, 6)
        love.graphics.setColor(1, 0.5, 0, 0.75)
        love.graphics.rectangle("fill", center_health, health_h, hitpoints, 6, 5, 6)
        love.graphics.setColor(1, 1, 1, 1)
    end


end

setmetatable(PlayerShip, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

return PlayerShip