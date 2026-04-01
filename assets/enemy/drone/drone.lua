-- Локализация глобальных библиотек для производительности
local math = math
local table = table
local ipairs = ipairs
local pairs = pairs
local type = type
local tostring = tostring
local love = love
local lg = love.graphics
local filesystem = love.filesystem

-- Локализация часто используемых математических функций
local random = math.random
local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local atan2 = math.atan2
local pi = math.pi
local max = math.max
local min = math.min

-- Локализация функций работы с таблицами
local insert = table.insert
local remove = table.remove

local SpriteLoader = require 'lib.util.animation.spriteloader'
local Rate = require 'assets.items.config.rates'
local Config = require 'assets.enemy.drone.config'

local Drone = {}
Drone.__index = Drone

local DroneSettings = Config

function Drone.new(x, y, bulletManager, player, tier, scene, debug, settingsOverride)
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
    self.bulletPenetration = s.bulletPenetration
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
    self.zigzagOffset = random() * 100
    
    self.bulletManager = bulletManager
    self.player = player
    
    self.shootTimer = 0
    
    self.damageNumbers = {}
    self.hitFlash = nil
    self.deathEffect = nil
    
    self.vx = 0
    self.vy = 0
    
    self.acceleration = s.acceleration or 200
    self.maxSpeed = s.maxSpeed or 150
    self.friction = s.friction or 3.0
    self.mass = s.mass or 1

    self.scale = s.scale or 1.2
    self.preferredDistance = s.preferredDistance or 80
    self.separationDistance = s.separationDistance or 60

    if settingsOverride and type(settingsOverride) == "table" then
        for k, v in pairs(settingsOverride) do
            self[k] = v
        end
    end

    return self
end

function Drone:load()
    self.animation = SpriteLoader('resource/other/enemy/drone/')
    if self.animation and self.animation.idle then
        self.width = self.animation.idle.width   * (self.scale / 2)
        self.height = self.animation.idle.height * (self.scale / 2)
    end
end

function Drone:takeDamage(amount, bullet)
    self.health = self.health - amount
    
    insert(self.damageNumbers, {
        x = self.x,
        y = self.y - 40,
        amount = amount,
        timer = 0.6,
        alpha = 1
    })
    
    self.hitFlash = 0.15
    
    if bullet and bullet.x and bullet.y then
        self:startInvestigation(bullet.x, bullet.y)
    end
    
    if self.health <= 0 then
        self.active = false
        self.deathEffect = 0.4
        
        if self.scene and self.scene.itemManager and self.drops then
            for _, drop in ipairs(self.drops) do
                if random() < drop.chance then
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

function Drone:applyCollisionDamage(impact)
    if not self.active then return end
    local damage = math.floor(impact)
    if damage < 1 then damage = 1 end
    self.health = self.health - damage
    insert(self.damageNumbers, {x=self.x, y=self.y-20, amount=damage, timer=0.6, alpha=1})
    self.hitFlash = 0.15
    if self.health <= 0 then
        self.active = false
        self.deathEffect = 0.4
        if self.scene and self.scene.itemManager and self.drops then
            for _, drop in ipairs(self.drops) do
                if random() < drop.chance then
                    self.scene.itemManager:addItem(self.x, self.y, drop.name)
                end
            end
        end
    end
end

function Drone:getRadius()
    return self.width / 2
end

function Drone:checkCollision(bullet)
    if not self.active then return false end
    local dx = bullet.x - self.x
    local dy = bullet.y - self.y
    local dist = sqrt(dx*dx + dy*dy)
    return dist < self.width/2 + bullet.size
end

function Drone:canSeePlayer()
    if not self.player or not self.player.active then return false end
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local dist = sqrt(dx*dx + dy*dy)
    return dist < self.detectionRange
end

function Drone:canAttackPlayer()
    if not self.player or not self.player.active then return false end
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local dist = sqrt(dx*dx + dy*dy)
    return dist < self.attackRange
end

function Drone:getDistanceToPlayer()
    if not self.player then return math.huge end
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    return sqrt(dx*dx + dy*dy)
end

function Drone:smoothRotate(targetAngle, dt)
    local angleDiff = targetAngle - self.angle
    while angleDiff > pi do angleDiff = angleDiff - 2*pi end
    while angleDiff < -pi do angleDiff = angleDiff + 2*pi end
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
            if not seesPlayer then self:startPatrol() end
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
                    local dist = sqrt(dx*dx + dy*dy)
                    if dist < self.communicationRange then alliesNearby = alliesNearby + 1 end
                end
            end
            self.currentState = (alliesNearby > 2) and "flank" or "chase"
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
                local dist = sqrt(dx*dx + dy*dy)
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
    local angle = random() * pi * 2
    local distance = random() * self.patrolRadius
    self.patrolTargetX = self.patrolStartX + cos(angle) * distance
    self.patrolTargetY = self.patrolStartY + sin(angle) * distance
    self.patrolWaitTimer = random() * 2
end

function Drone:advancedCollisionAvoidance(allDrones)
    local avoidanceX, avoidanceY = 0, 0
    for _, drone in ipairs(allDrones) do
        if drone ~= self and drone.active then
            local dx = self.x - drone.x
            local dy = self.y - drone.y
            local dist = sqrt(dx*dx + dy*dy)
            if dist < self.separationDistance and dist > 0 then
                local strength = (self.separationDistance - dist) / self.separationDistance
                avoidanceX = avoidanceX + (dx / dist) * strength * 2
                avoidanceY = avoidanceY + (dy / dist) * strength * 2
            end
        end
    end
    return avoidanceX, avoidanceY
end

function Drone:avoidCollisions(allDrones, dt)
    local avoidanceX, avoidanceY = 0, 0
    local timeHorizon = 2.0

    for _, other in ipairs(allDrones) do
        if other ~= self and other.active then
            local dx = other.x - self.x
            local dy = other.y - self.y
            local dist = sqrt(dx*dx + dy*dy)
            if dist < self.separationDistance * 2 then
                local dvx = other.vx - self.vx
                local dvy = other.vy - self.vy
                local a = dvx*dvx + dvy*dvy
                if a > 0 then
                    local b = 2 * (dx*dvx + dy*dvy)
                    local c = dx*dx + dy*dy - (self.width/2 + other.width/2)^2
                    local discriminant = b*b - 4*a*c
                    if discriminant >= 0 then
                        local t = (-b - sqrt(discriminant)) / (2*a)
                        if t > 0 and t < timeHorizon then
                            local predX = self.x + self.vx * t
                            local predY = self.y + self.vy * t
                            local otherPredX = other.x + other.vx * t
                            local otherPredY = other.y + other.vy * t
                            local dxPred = otherPredX - predX
                            local dyPred = otherPredY - predY
                            local distPred = sqrt(dxPred*dxPred + dyPred*dyPred)
                            if distPred > 0 then
                                local strength = (self.separationDistance - distPred) / self.separationDistance
                                strength = max(0, min(1, strength))
                                avoidanceX = avoidanceX - (dxPred / distPred) * strength * 5
                                avoidanceY = avoidanceY - (dyPred / distPred) * strength * 5
                            end
                        end
                    end
                end
                if dist < self.separationDistance and dist > 0 then
                    local strength = (self.separationDistance - dist) / self.separationDistance
                    avoidanceX = avoidanceX + (dx / dist) * strength * 2
                    avoidanceY = avoidanceY + (dy / dist) * strength * 2
                end
            end
        end
    end
    return avoidanceX, avoidanceY
end

function Drone:maintainFormation(allDrones)
    local cohesionX, cohesionY = 0, 0
    local count = 0
    for _, other in ipairs(allDrones) do
        if other ~= self and other.active then
            local dx = other.x - self.x
            local dy = other.y - self.y
            local dist = sqrt(dx*dx + dy*dy)
            if dist > 0 then
                if dist > self.preferredDistance then
                    local strength = min(1, (dist - self.preferredDistance) / self.preferredDistance)
                    cohesionX = cohesionX + (dx / dist) * strength * 0.5
                    cohesionY = cohesionY + (dy / dist) * strength * 0.5
                elseif dist < self.preferredDistance then
                    local strength = min(1, (self.preferredDistance - dist) / self.preferredDistance)
                    cohesionX = cohesionX - (dx / dist) * strength * 0.5
                    cohesionY = cohesionY - (dy / dist) * strength * 0.5
                end
                count = count + 1
            end
        end
    end
    if count > 0 then
        return cohesionX / count, cohesionY / count
    else
        return 0, 0
    end
end

function Drone:getDesiredDirection(dt)
    if not self.player or not self.player.active then return 0, 0 end
    
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local dist = sqrt(dx*dx + dy*dy)
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
        local tdist = sqrt(tx*tx + ty*ty)
        if tdist > 0 then
            moveX = tx / tdist
            moveY = ty / tdist
        end
    elseif self.currentState == "attack" then
        self.zigzagTimer = self.zigzagTimer + dt * self.zigzagFrequency
        local zigzag = sin(self.zigzagTimer + self.zigzagOffset) * self.zigzagAmplitude
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
        local tdist = sqrt(tx*tx + ty*ty)
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
    local dist = sqrt(dx*dx + dy*dy)
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
        if self.deathEffect then self.deathEffect = self.deathEffect - dt end
        return
    end

    local oldX, oldY = self.x, self.y

    if self.hitFlash then
        self.hitFlash = self.hitFlash - dt
        if self.hitFlash <= 0 then self.hitFlash = nil end
    end

    local i = 1
    while i <= #self.damageNumbers do
        local dmg = self.damageNumbers[i]
        dmg.timer = dmg.timer - dt
        dmg.alpha = dmg.timer * 1.67
        dmg.y = dmg.y - 30 * dt
        if dmg.timer <= 0 then
            remove(self.damageNumbers, i)
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

    local desiredX, desiredY = 0, 0
    local targetSpeed = self.speed

    if self.patrolMode then
        desiredX, desiredY = self:patrolMovement(dt)
        targetSpeed = self.patrolSpeed
    elseif self.investigationMode then
        desiredX, desiredY = self:getDesiredDirection(dt)
        targetSpeed = self.investigationSpeed
    else
        desiredX, desiredY = self:getDesiredDirection(dt)
    end

    local avoidX, avoidY = self:avoidCollisions(allDrones, dt)
    local formX, formY = self:maintainFormation(allDrones)
    desiredX = desiredX + avoidX + formX
    desiredY = desiredY + avoidY + formY

    local len = sqrt(desiredX*desiredX + desiredY*desiredY)
    if len > 0 then
        desiredX = desiredX / len
        desiredY = desiredY / len
    end

    if desiredX ~= 0 or desiredY ~= 0 then
        local targetAngle = atan2(desiredY, desiredX)
        self:smoothRotate(targetAngle, dt)
        local forwardX = cos(self.angle)
        local forwardY = sin(self.angle)
        local accelX = forwardX * self.acceleration * dt
        local accelY = forwardY * self.acceleration * dt
        self.vx = self.vx + accelX
        self.vy = self.vy + accelY
    else
        self.vx = self.vx * (1 - self.friction * dt)
        self.vy = self.vy * (1 - self.friction * dt)
    end

    local speed = sqrt(self.vx^2 + self.vy^2)
    if speed > self.maxSpeed then
        self.vx = self.vx / speed * self.maxSpeed
        self.vy = self.vy / speed * self.maxSpeed
    end

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    if dt > 0 then
        self.vx = (self.x - oldX) / dt
        self.vy = (self.y - oldY) / dt
    end
end

function Drone:shoot()
    if not self.bulletManager or not self.player then return end
    
    local offset = 25

    local bulletAngle = self.angle  
    
    local dirX = cos(bulletAngle)
    local dirY = sin(bulletAngle)
    
    local bulletX = self.x + dirX * offset
    local bulletY = self.y + dirY * offset
    
    local bulletVx = dirX * self.bulletSpeed + self.vx
    local bulletVy = dirY * self.bulletSpeed + self.vy
    
    self.bulletManager:shoot({
        x = bulletX,
        y = bulletY,
        vx = bulletVx,
        vy = bulletVy,
        angle = bulletAngle,
        speed = self.bulletSpeed,
        damage = self.bulletDamage,
        penetration = self.bulletPenetration,
        size = self.bulletSize,
        color = self.bulletColor,
        lifeTime = 3.5,
        owner = "enemy"
    })
end

function Drone:draw()
    if self.deathEffect then
        lg.setColor(1, 0.8, 0, self.deathEffect)
        lg.circle("fill", self.x, self.y, self.width * (1 + self.deathEffect * 2))
        return
    end
    
    if not self.active then return end
    
    if self.animation and self.animation.idle and self.animation.idle.sprite then
        lg.draw(
            self.animation.idle.sprite,
            self.x, self.y,
            self.angle + pi/2,
            self.scale, self.scale,
            self.animation.idle.width / 2,
            self.animation.idle.height / 2
        )
    else
        lg.setColor(1, 0, 0, 1)
        lg.rectangle("fill", self.x - self.width/2, self.y - self.height/2, self.width, self.height)
    end
    
    lg.setColor(1, 1, 1, 1)
    lg.setColor(0.2, 0.2, 0.2, 1)
    lg.rectangle("fill", self.x - self.width/2, self.y - self.height/2 - 12, self.width, 4)
    lg.setColor(1, 0, 0, 1)
    local healthWidth = (self.health / self.maxHealth) * self.width
    lg.rectangle("fill", self.x - self.width/2, self.y - self.height/2 - 12, healthWidth, 4)

    for _, dmg in ipairs(self.damageNumbers) do
        lg.setColor(1, 1, 0, dmg.alpha)
        lg.print("-" .. dmg.amount, dmg.x - 15, dmg.y)
    end
    
    lg.setColor(1, 1, 1, 1)
end

setmetatable(Drone, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

return Drone