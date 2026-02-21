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
    self.items = {} -- Таблица активных подобранных предметов

    -- Новые поля для получения урона
    self.health = Ships[self.tier].hitPoints
    self.maxHealth = Ships[self.tier].hitPoints
    self.armor = Ships[self.tier].armor
    self.maxArmor = Ships[self.tier].armor
    self.invincibleTimer = 0
    self.invincibleDuration = 1.0
    self.hitFlash = 0
    
    self.speedMult = 1
    -- Для отображения урона
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

    self.animation = 
    {
        path = {
            idle        = Ships[self.tier].directSprite .. 'ship.png',
            engine_turn = Ships[self.tier].directSprite .. 'ship_turn_on.png',
            sprint      = Ships[self.tier].directSprite .. 'ship_sprint.png',
        },
        sprite = {}
    }
    
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
function PlayerShip:takeDamage(amount, bullet)
    if not self.active then return false end
    
    -- Проверка на неуязвимость
    if self.invincibleTimer > 0 then
        return false
    end
    
    -- Учитываем броню
    local actualDamage = amount
    if self.armor > 0 then
        local armorReduction = self.armor * 0.5
        actualDamage = math.max(1, amount - armorReduction)
        self.armor = math.max(0, self.armor - amount * 0.3)
    end
    
    self.health = self.health - actualDamage
    
    -- Визуальный эффект
    self.invincibleTimer = self.invincibleDuration
    self.hitFlash = 0.2
    
    -- Число урона
    table.insert(self.damageNumbers, {
        x = self.x,
        y = self.y - 40,
        amount = math.floor(actualDamage),
        timer = 0.5,
        alpha = 1
    })
    
    if self.health <= 0 then
        self.active = false
        self.deathEffect = 0.5
        return true
    end
    return false
end

function PlayerShip:checkCollision(bullet)
    if not self.active then return false end
    
    local dx = bullet.x - self.x
    local dy = bullet.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    return dist < 25 + bullet.size
end

function PlayerShip:shoot(config)
    local bulletdata = config or Ships[self.tier].bulletConfig

    local offset = 25
    local directionAngle = self.angle - math.pi/2
    
    local directionX = math.cos(directionAngle)
    local directionY = math.sin(directionAngle)
    
    local bulletX = self.x + directionX * offset
    local bulletY = self.y + directionY * offset

    return self.bulletManager:shoot(
        bulletX, bulletY,
        directionAngle,
        bulletdata.speed,
        bulletdata.damage,
        bulletdata.size,
        bulletdata.color,
        bulletdata.lifetime,
        "player"        
    )
end

-- Main functions


function PlayerShip:load()
    local shipPath = Ships[self.tier].directSprite
    self.animation = SpriteLoader(shipPath)
    self.currentSprite = self.animation['idle'].sprite
end


function PlayerShip:update(dt)
    if not self.active then
        if self.deathEffect then
            self.deathEffect = self.deathEffect - dt
        end
        return
    end
    
    -- Обновление неуязвимости
    if self.invincibleTimer > 0 then
        self.invincibleTimer = self.invincibleTimer - dt
    end
    
    -- Обновление вспышки
    if self.hitFlash > 0 then
        self.hitFlash = self.hitFlash - dt
    end
    
    -- Обновление чисел урона
    local i = 1
    while i <= #self.damageNumbers do
        local dmg = self.damageNumbers[i]
        dmg.timer = dmg.timer - dt
        dmg.alpha = dmg.timer * 2
        dmg.y = dmg.y - 20 * dt
        
        if dmg.timer <= 0 then
            table.remove(self.damageNumbers, i)
        else
            i = i + 1
        end
    end
    
    -- Движение
    do
        local shipCurrent = Ships[self.tier]
        local dx, dy = 0, 0
        

        self.isEngineOn = love.keyboard.isDown('w') or love.keyboard.isDown('s')
        self.angle = (love.keyboard.isDown('a')) and self.angle - shipCurrent.speedRotation * dt or love.keyboard.isDown('d') and self.angle + shipCurrent.speedRotation * dt or self.angle
        dy = love.keyboard.isDown('w') and dy - 1 or love.keyboard.isDown('s') and dy + 1 or dy
        
        
                
        if (love.keyboard.isDown('lshift') and self.stamina > 0) and self.isEngineOn then
           self.speedMult     = Ships[self.tier].speedSprint 
           self.stamina       = self.stamina - Ships[self.tier].staminaExpenditure * dt
           self.currentSprite = self.animation.sprint.sprite 
        else
            if self.stamina == 0 or self.stamina < Ships[self.tier].staminaCounter then 
                self.stamina = self.stamina + Ships[self.tier].staminaTimeRegen * dt  
            end
            self.speedMult = 1
            self.currentSprite = self.isEngineOn and self.animation.engine_turn.sprite or self.animation.idle.sprite
        end
        



        local cosA, sinA = math.cos(self.angle), math.sin(self.angle)
        local moveX = cosA * dx - sinA * dy
        local moveY = sinA * dx + cosA * dy

        local len = moveX * moveX + moveY * moveY
        if len > 0 then
            len = math.sqrt(len)
            moveX = moveX / len
            moveY = moveY / len
        end

        local baseSpeed = shipCurrent.speedMovement * self.speedMult * dt
        self.x = self.x + moveX * baseSpeed
        self.y = self.y + moveY * baseSpeed

    end

    -- Стрельба
    do
        self.__bulletCoolDown = (self.__bulletCoolDown > 0) and self.__bulletCoolDown - dt or self.__bulletCoolDown

        if love.keyboard.isDown('space') and self.__bulletCoolDown <= 0 then
            self:shoot()
            self.__bulletCoolDown = Ships[self.tier].bulletConfig.coolDown
        end
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

function PlayerShip:draw()
    if self.deathEffect then
        love.graphics.setColor(1, 0.5, 0, self.deathEffect)
        love.graphics.circle("fill", self.x, self.y, 30 * (1 + self.deathEffect))
        return
    end
    
    if not self.active then return end
    
    -- Мигание при получении урона
    if self.hitFlash > 0 and math.floor(self.hitFlash * 20) % 2 == 0 then
        love.graphics.setColor(1, 1, 1, 0.5)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Рисуем корабль
    do
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
    end

    -- Рисуем числа урона
    for _, dmg in ipairs(self.damageNumbers) do
        love.graphics.setColor(1, 0, 0, dmg.alpha)
        love.graphics.print("-" .. dmg.amount, dmg.x - 10, dmg.y)
    end

end

setmetatable(PlayerShip, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

return PlayerShip