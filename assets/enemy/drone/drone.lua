
local SpriteLoader = require 'lib.util.animation.spriteloader'
local Rate   = require 'assets.items.config.rates'
local Config = require 'assets.enemy.drone.config'
----------------------------
local Drone = {}
Drone.__index = Drone

local DroneSettings = Config

function Drone.new(x, y, bulletManager, player, tier, scene, debug)
    local self = setmetatable({}, Drone)
    
    self.x = x or 0
    self.y = y or 0
    self.tier = tier or 1
    
    local s = DroneSettings[self.tier]
    
    self.animation = {}
    self.scene = scene
    self.drops = s.drops
    self.width = s.size
    self.height = s.size
    self.speed = s.speed
    self.patrolSpeed = s.patrolSpeed
    self.rotationSpeed = s.rotationSpeed
    self.color = s.color
    
    self.shootCooldown = s.shootCooldown
    self.bulletSpeed = s.bulletSpeed
    self.bulletDamage = s.bulletDamage
    self.bulletSize = s.bulletSize
    self.bulletColor = s.bulletColor
    self.bulletCount = s.bulletCount
    self.bulletSpread = s.bulletSpread
    
    self.detectionRange = s.detectionRange
    self.attackRange = s.attackRange
    self.communicationRange = s.communicationRange
    self.separationDistance = s.separationDistance
    self.preferredDistance = s.preferredDistance
    self.tooCloseDistance = s.tooCloseDistance
    self.tooFarDistance = s.tooFarDistance
    
    self.health = s.health
    self.maxHealth = s.health
    
    self.patrolTime = s.patrolTime
    self.patrolRadius = s.patrolRadius
    self.patrolStartX = x
    self.patrolStartY = y
    
    self.chaosIntensity = s.chaosIntensity
    self.zigzagFrequency = s.zigzagFrequency
    self.zigzagAmplitude = s.zigzagAmplitude
    
    self.investigationTime = s.investigationTime
    self.investigationSpeed = s.investigationSpeed
    
    self.debug = debug or s.debug
    
    self.angle = 0
    self.active = true
    self.alerted = false
    self.patrolMode = false
    self.investigationMode = false
    self.investigationTimer = 0
    self.investigationTarget = nil
    self.timeSinceLastSeen = 0
    self.lastKnownPlayerPosition = nil
    self.currentState = "idle"
    
    self.targetAngle = 0
    self.currentSpeed = 0
    self.zigzagTimer = 0
    self.zigzagOffset = math.random() * 100
    
    self.bulletManager = bulletManager
    self.player = player
    
    self.shootTimer = 0
    
    self.damageNumbers = {}
    self.hitFlash = nil
    self.deathEffect = nil
    
    
    return self
end




function Drone:load()
    self.animation = SpriteLoader('resource/other/enemy/drone/')
end



function Drone:takeDamage(amount, bullet)
    self.health = self.health - amount
    
    table.insert(self.damageNumbers, {
        x = self.x,
        y = self.y - 40,
        amount = amount,
        timer = 0.6,
        alpha = 1
    })
    
    self.hitFlash = 0.15
    
    -- Начинаем исследование места, откуда прилетела пуля
    if bullet and bullet.x and bullet.y then
        self:startInvestigation(bullet.x, bullet.y)
    end
    
    if self.health <= 0 then
        self.active = false
        self.deathEffect = 0.4
        
        -- Дроп предметов
        if self.scene and self.scene.itemManager and self.drops then
            for _, drop in ipairs(self.drops) do
                if math.random() < drop.chance then
                    self.scene.itemManager:addItem(self.x, self.y, drop.name)
                end
            end
        end
    end
    return self.health <= 0
end

function Drone:startInvestigation(x, y)
    self.investigationMode = true
    self.alerted = false
    self.patrolMode = false
    self.investigationTimer = self.investigationTime
    self.investigationTarget = {x = x, y = y}
    self.currentState = "investigate"
end

function Drone:getPosition()
    return self.x, self.y
end

function Drone:getRadius()
    return self.width / 2
end

function Drone:checkCollision(bullet)
    if not self.active then return false end
    
    local dx = bullet.x - self.x
    local dy = bullet.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    return dist < self.width/2 + bullet.size
end

function Drone:canSeePlayer()
    if not self.player or not self.player.active then return false end
    
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    return dist < self.detectionRange
end

function Drone:canAttackPlayer()
    if not self.player or not self.player.active then return false end
    
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    return dist < self.attackRange
end

function Drone:getDistanceToPlayer()
    if not self.player then return math.huge end
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    return math.sqrt(dx*dx + dy*dy)
end

function Drone:smoothRotate(targetAngle, dt)
    local angleDiff = targetAngle - self.angle
    
    while angleDiff > math.pi do
        angleDiff = angleDiff - 2 * math.pi
    end
    while angleDiff < -math.pi do
        angleDiff = angleDiff + 2 * math.pi
    end
    
    local maxRotation = self.rotationSpeed * dt
    if math.abs(angleDiff) > maxRotation then
        self.angle = self.angle + (angleDiff > 0 and 1 or -1) * maxRotation
    else
        self.angle = targetAngle
    end
end

function Drone:updateIntelligence(dt, allDrones)
    if not self.active then return end
    
    local seesPlayer = self:canSeePlayer()
    local distToPlayer = self:getDistanceToPlayer()
    
    if seesPlayer then
        self.investigationMode = false
    end
    
    if self.investigationMode then
        self.currentState = "investigate"
        self.investigationTimer = self.investigationTimer - dt
        
        if self.investigationTimer <= 0 or seesPlayer then
            self.investigationMode = false
            if not seesPlayer then
                self:startPatrol()
            end
        end
    elseif not seesPlayer and not self.alerted and not self.patrolMode then
        self.currentState = "idle"
    elseif self.patrolMode then
        self.currentState = "patrol"
    elseif seesPlayer then
        if distToPlayer < self.attackRange then
            self.currentState = "attack"
        elseif distToPlayer < self.tooCloseDistance then
            self.currentState = "retreat"
        elseif distToPlayer > self.tooFarDistance then
            self.currentState = "chase"
        else
            local alliesNearby = 0
            for _, drone in ipairs(allDrones) do
                if drone ~= self and drone.active then
                    local dx = drone.x - self.x
                    local dy = drone.y - self.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist < self.communicationRange then
                        alliesNearby = alliesNearby + 1
                    end
                end
            end
            if alliesNearby > 2 then
                self.currentState = "flank"
            else
                self.currentState = "chase"
            end
        end
    elseif self.alerted then
        self.currentState = "search"
    end
    
    if seesPlayer then
        self.alerted = true
        self.patrolMode = false
        self.investigationMode = false
        self.timeSinceLastSeen = 0
        self.lastKnownPlayerPosition = {x = self.player.x, y = self.player.y}
        
        for _, drone in ipairs(allDrones) do
            if drone ~= self and drone.active then
                local dx = drone.x - self.x
                local dy = drone.y - self.y
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist < self.communicationRange then
                    drone:receiveIntel(self.lastKnownPlayerPosition)
                end
            end
        end
        
    else
        self.timeSinceLastSeen = self.timeSinceLastSeen + dt
        
        if self.timeSinceLastSeen >= self.patrolTime and not self.patrolMode and not self.investigationMode then
            self:startPatrol()
        end
    end
end

function Drone:receiveIntel(playerPosition)
    if not self.active or self:canSeePlayer() then return end
    
    self.alerted = true
    self.patrolMode = false
    self.investigationMode = false
    self.timeSinceLastSeen = 0
    self.lastKnownPlayerPosition = playerPosition
end

function Drone:startPatrol()
    self.patrolMode = true
    self.alerted = false
    self.investigationMode = false
    self:generatePatrolPath()
end

function Drone:generatePatrolPath()
    local angle = math.random() * math.pi * 2
    local distance = math.random() * self.patrolRadius
    
    self.patrolTargetX = self.patrolStartX + math.cos(angle) * distance
    self.patrolTargetY = self.patrolStartY + math.sin(angle) * distance
    
    self.patrolWaitTimer = math.random() * 2
end

function Drone:advancedCollisionAvoidance(allDrones, dt)
    local avoidanceX, avoidanceY = 0, 0
    
    for _, drone in ipairs(allDrones) do
        if drone ~= self and drone.active then
            local dx = self.x - drone.x
            local dy = self.y - drone.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist < self.separationDistance and dist > 0 then
                local strength = (self.separationDistance - dist) / self.separationDistance
                avoidanceX = avoidanceX + (dx / dist) * strength * 2
                avoidanceY = avoidanceY + (dy / dist) * strength * 2
            end
        end
    end
    
    return avoidanceX, avoidanceY
end

function Drone:tacticalPositioning(dt)
    if not self.player or not self.player.active then return 0, 0 end
    
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    local dirX, dirY = 0, 0
    
    if dist > 0 then
        dirX = dx / dist
        dirY = dy / dist
    end
    
    local perpX = -dirY
    local perpY = dirX
    
    local moveX, moveY = 0, 0
    
    if self.currentState == "investigate" and self.investigationTarget then
        local tx = self.investigationTarget.x - self.x
        local ty = self.investigationTarget.y - self.y
        local tdist = math.sqrt(tx*tx + ty*ty)
        if tdist > 0 then
            moveX = tx / tdist
            moveY = ty / tdist
        end
    elseif self.currentState == "attack" then
        self.zigzagTimer = self.zigzagTimer + dt * self.zigzagFrequency
        local zigzag = math.sin(self.zigzagTimer + self.zigzagOffset) * self.zigzagAmplitude
        
        moveX = dirX * 0.3 + perpX * zigzag * 0.01
        moveY = dirY * 0.3 + perpY * zigzag * 0.01
        
    elseif self.currentState == "retreat" then
        moveX = -dirX
        moveY = -dirY
        
    elseif self.currentState == "chase" then
        moveX = dirX
        moveY = dirY
        
    elseif self.currentState == "flank" then
        local side = (self.zigzagOffset > 0.5) and 1 or -1
        moveX = perpX * side * 0.7 + dirX * 0.3
        moveY = perpY * side * 0.7 + dirY * 0.3
        
    elseif self.currentState == "search" and self.lastKnownPlayerPosition then
        local tx = self.lastKnownPlayerPosition.x - self.x
        local ty = self.lastKnownPlayerPosition.y - self.y
        local tdist = math.sqrt(tx*tx + ty*ty)
        if tdist > 0 then
            moveX = tx / tdist
            moveY = ty / tdist
        end
    end
    
    return moveX, moveY
end

function Drone:patrolMovement(dt)
    local dx = self.patrolTargetX - self.x
    local dy = self.patrolTargetY - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist < 30 then
        if self.patrolWaitTimer then
            self.patrolWaitTimer = self.patrolWaitTimer - dt
            if self.patrolWaitTimer <= 0 then
                self:generatePatrolPath()
            end
        end
        return 0, 0
    else
        return dx / dist, dy / dist
    end
end

function Drone:update(dt, allDrones)
    if not self.active or not self.player then 
        if self.deathEffect then
            self.deathEffect = self.deathEffect - dt
        end
        return 
    end
    
    if self.hitFlash then
        self.hitFlash = self.hitFlash - dt
        if self.hitFlash <= 0 then
            self.hitFlash = nil
        end
    end
    
    local i = 1
    while i <= #self.damageNumbers do
        local dmg = self.damageNumbers[i]
        dmg.timer = dmg.timer - dt
        dmg.alpha = dmg.timer * 1.67
        dmg.y = dmg.y - 30 * dt
        
        if dmg.timer <= 0 then
            table.remove(self.damageNumbers, i)
        else
            i = i + 1
        end
    end
    
    self:updateIntelligence(dt, allDrones)
    
    if not self.patrolMode and not self.investigationMode and self:canAttackPlayer() then
        if self.shootTimer > 0 then
            self.shootTimer = self.shootTimer - dt
        end
        
        if self.shootTimer <= 0 then
            self.shootTimer = self.shootCooldown
            self:shoot()
        end
    end
    
    local moveX, moveY = 0, 0
    local currentSpeed = self.speed
    
    if self.patrolMode then
        moveX, moveY = self:patrolMovement(dt)
        currentSpeed = self.patrolSpeed
    elseif self.investigationMode then
        moveX, moveY = self:tacticalPositioning(dt)
        currentSpeed = self.investigationSpeed
    else
        moveX, moveY = self:tacticalPositioning(dt)
        
        local avoidX, avoidY = self:advancedCollisionAvoidance(allDrones, dt)
        moveX = moveX + avoidX
        moveY = moveY + avoidY
        
        local len = math.sqrt(moveX*moveX + moveY*moveY)
        if len > 0 then
            moveX = moveX / len
            moveY = moveY / len
        end
    end
    
    if moveX ~= 0 or moveY ~= 0 then
        local targetAngle = math.atan2(moveY, moveX)
        self:smoothRotate(targetAngle, dt)
        
        self.x = self.x + math.cos(self.angle) * currentSpeed * dt
        self.y = self.y + math.sin(self.angle) * currentSpeed * dt
    end
end

function Drone:shoot()
    if not self.bulletManager or not self.player then return end
    
    local offset = 25
    local predictTime = 0.15
    local playerVx = 0
    local playerVy = 0
    
    if self.player.vx and self.player.vy then
        playerVx = self.player.vx
        playerVy = self.player.vy
    elseif self.player.velocityX and self.player.velocityY then
        playerVx = self.player.velocityX
        playerVy = self.player.velocityY
    end
    
    local targetX = self.player.x + playerVx * predictTime
    local targetY = self.player.y + playerVy * predictTime
    
    local dx = targetX - self.x
    local dy = targetY - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    local shootAngle
    if dist > 0 then
        shootAngle = math.atan2(dy, dx)
    else
        shootAngle = self.angle
    end
    
    local spread = (math.random() * 2 - 1) * self.bulletSpread * 0.7
    local bulletAngle = shootAngle + spread
    
    local dirX = math.cos(bulletAngle)
    local dirY = math.sin(bulletAngle)
    
    local bulletX = self.x + dirX * offset
    local bulletY = self.y + dirY * offset
    
    self.bulletManager:shoot(
        bulletX, bulletY,
        bulletAngle,
        self.bulletSpeed,
        self.bulletDamage,
        self.bulletSize,
        self.bulletColor,
        3.5,
        "enemy"
    )
end

function Drone:draw()
    if self.deathEffect then
        love.graphics.setColor(1, 0.8, 0, self.deathEffect)
        love.graphics.circle("fill", self.x, self.y, self.width * (1 + self.deathEffect * 2))
        return
    end
    
    if not self.active then return end
    
    -- Отрисовка спрайта дрона
    if self.animation and self.animation.idle and self.animation.idle.sprite then
        love.graphics.draw(
            self.animation.idle.sprite,
            self.x, self.y,
            self.angle + math.pi/2 ,
            2, 2,  -- масштаб (можно изменить при необходимости)
            self.animation.idle.width / 2,
            self.animation.idle.height / 2
        )
    else
        -- Запасной вариант (красный квадрат)
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("fill", self.x - self.width/2, self.y - self.height/2, self.width, self.height)
    end
    
    -- Глаз (показывает направление)
    love.graphics.setColor(1, 1, 1, 1)

    -- Полоска здоровья
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", self.x - self.width/2, self.y - self.height/2 - 12, self.width, 4)
    love.graphics.setColor(1, 0, 0, 1)
    local healthWidth = (self.health / self.maxHealth) * self.width
    love.graphics.rectangle("fill", self.x - self.width/2, self.y - self.height/2 - 12, healthWidth, 4)

    -- Числа урона
    for _, dmg in ipairs(self.damageNumbers) do
        love.graphics.setColor(1, 1, 0, dmg.alpha)
        love.graphics.print("-" .. dmg.amount, dmg.x - 15, dmg.y)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

setmetatable(Drone, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

return Drone