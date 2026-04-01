-- assets/enemy/spaceWorn/spaceWorn.lua
-- Улучшенный червь с множеством способностей и фаз

local SpaceWorm = {}
SpaceWorm.__index = SpaceWorm

function SpaceWorm.new(x, y, player, bulletManager, scene)
    local self = setmetatable({}, SpaceWorm)
    self.player = player
    self.bulletManager = bulletManager
    self.scene = scene
    self.x = x or 0
    self.y = y or 0
    self.active = true
    self.health = 1500           -- увеличенное здоровье
    self.maxHealth = 1500
    self.hitFlash = 0
    self.deathEffect = nil

    -- Размеры и форма
    self.segmentCount = 40       -- больше сегментов
    self.segmentRadius = 44
    self.speed = 50
    self.turnSpeed = 0.55
    self.segmentDistance = 40

    self.history = {}
    self.maxHistory = 800

    self.segments = {}
    for i = 1, self.segmentCount do
        self.segments[i] = { x = self.x, y = self.y }
    end

    self.vx = 0
    self.vy = 0
    self.angle = 0
    self.currentSpeed = self.speed

    self.state = "wander"
    self.wanderTarget = nil
    self.wanderTimer = 0
    self.wanderInterval = 3.5
    self.chaseRange = 750
    self.attackRange = 400
    self.attackTimer = 0
    self.biteAnimation = 0
    self.biteCooldown = 0

    -- Фазы и переходы
    self.phase = 1
    self.phaseTransition = false
    self.phaseTransitionTimer = 0
    self.phaseTransitionDuration = 2.5

    -- Способности
    self.projectileCooldown = 0
    self.projectileCooldownMax = 2.2
    self.dashCooldown = 0
    self.dashCooldownMax = 5.0
    self.summonCooldown = 0
    self.summonCooldownMax = 14.0
    self.tailSlamCooldown = 0          -- удар хвостом
    self.tailSlamCooldownMax = 6.0
    self.poisonFieldCooldown = 0       -- ядовитое поле
    self.poisonFieldCooldownMax = 10.0
    self.teleportCooldown = 0          -- телепортация (подземный удар)
    self.teleportCooldownMax = 12.0
    self.rageActive = false             -- ярость при низком здоровье
    self.rageTimer = 0
    self.rageDuration = 8.0
    self.regenerationActive = false     -- регенерация
    self.regenerationTick = 0

    self.dashActive = false
    self.dashTimer = 0
    self.dashSpeed = 400
    self.dashDuration = 0.45

    self.shieldActive = false
    self.shieldTimer = 0
    self.shieldDuration = 3.5

    -- Новые поля для способностей
    self.tailSlamActive = false
    self.tailSlamTimer = 0
    self.teleportTarget = nil
    self.poisonFieldActive = false
    self.poisonFieldTimer = 0

    -- Касание телом
    self.bodyTouchCooldown = 0
    self.bodyTouchDamage = 15

    -- Визуальные эффекты
    self.phaseGlow = {0,0,0,0}
    self.abilityParticles = {}
    self.particles = {}
    self.particleTimer = 0
    self.particleInterval = 0.07

    self.glowIntensity = 0
    self.pulse = 0
    self.alertGlow = 0

    -- Дополнительные параметры для поведения
    self.enragedSpeedMult = 1.5
    self.enragedDamageMult = 1.5

    return self
end

function SpaceWorm:update(dt)
    if not self.active then
        if self.deathEffect then self.deathEffect = self.deathEffect - dt end
        return
    end

    if self.hitFlash then
        self.hitFlash = self.hitFlash - dt
        if self.hitFlash <= 0 then self.hitFlash = nil end
    end

    if self.health <= 0 then
        self.active = false
        self.deathEffect = 0.8
        for i = 1, 60 do
            table.insert(self.particles, {
                x = self.x + (math.random() - 0.5) * 300,
                y = self.y + (math.random() - 0.5) * 300,
                vx = (math.random() - 0.5) * 400,
                vy = (math.random() - 0.5) * 400,
                life = 1.2,
                color = {1, 0.3, 0.1, 1}
            })
        end
        if self.scene and self.scene.itemManager then
            self.scene.itemManager:addItem(self.x, self.y, "ancient_core")
            self.scene.itemManager:addItem(self.x, self.y, "worm_heart")
            self.scene.itemManager:addItem(self.x, self.y, "dark_matter", 2)
        end
        return
    end

    local healthPercent = self.health / self.maxHealth
    if healthPercent <= 0.25 and not self.rageActive and self.phase >= 2 then
        self:activateRage()
    end
    if self.rageActive then
        self.rageTimer = self.rageTimer - dt
        if self.rageTimer <= 0 then
            self.rageActive = false
        end
    end

    if self.phase >= 3 and not self.phaseTransition and self.health < self.maxHealth then
        self.regenerationTick = self.regenerationTick + dt
        if self.regenerationTick >= 1.0 then
            self.regenerationTick = 0
            self.health = math.min(self.maxHealth, self.health + 25)
            for i = 1, 5 do
                table.insert(self.abilityParticles, {
                    x = self.x + (math.random() - 0.5) * 100,
                    y = self.y + (math.random() - 0.5) * 100,
                    life = 0.6,
                    color = {0.2, 0.8, 0.2, 0.7},
                    size = 4
                })
            end
        end
    end

    local newPhase = 1
    if healthPercent <= 0.3 then
        newPhase = 3
    elseif healthPercent <= 0.65 then
        newPhase = 2
    end
    if newPhase > self.phase and not self.phaseTransition then
        self:enterPhase(newPhase)
    end

    if self.phaseTransition then
        self.phaseTransitionTimer = self.phaseTransitionTimer - dt
        if self.phaseTransitionTimer <= 0 then
            self.phaseTransition = false
            self.shieldActive = false
        end
    end

    if self.shieldActive then
        self.shieldTimer = self.shieldTimer - dt
        if self.shieldTimer <= 0 then
            self.shieldActive = false
        end
    end

    self.pulse = self.pulse + dt * 1.8
    self.glowIntensity = 0.5 + 0.5 * math.sin(self.pulse)

    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local distToPlayer = math.sqrt(dx*dx + dy*dy)

    if distToPlayer < self.chaseRange then
        self.state = "chase"
        self.alertGlow = math.min(1, self.alertGlow + dt * 2.5)
        if distToPlayer < self.attackRange then
            self.attackTimer = self.attackTimer + dt
            local speedBonus = math.min(50, self.attackTimer * 35)
            self.currentSpeed = self.speed + speedBonus
            self.biteAnimation = math.min(1, self.biteAnimation + dt * 7)
        else
            self.attackTimer = math.max(0, self.attackTimer - dt)
            self.currentSpeed = self.speed
            self.biteAnimation = math.max(0, self.biteAnimation - dt * 3)
        end
    else
        self.state = "wander"
        self.attackTimer = 0
        self.alertGlow = math.max(0, self.alertGlow - dt)
        self.currentSpeed = self.speed
        self.biteAnimation = math.max(0, self.biteAnimation - dt * 3)
    end

    local effectiveSpeed = self.currentSpeed
    if self.rageActive then
        effectiveSpeed = effectiveSpeed * self.enragedSpeedMult
    end

    self.projectileCooldown = math.max(0, self.projectileCooldown - dt)
    self.dashCooldown = math.max(0, self.dashCooldown - dt)
    self.summonCooldown = math.max(0, self.summonCooldown - dt)
    self.tailSlamCooldown = math.max(0, self.tailSlamCooldown - dt)
    self.poisonFieldCooldown = math.max(0, self.poisonFieldCooldown - dt)
    self.teleportCooldown = math.max(0, self.teleportCooldown - dt)
    self.bodyTouchCooldown = math.max(0, self.bodyTouchCooldown - dt)

    if self.tailSlamActive then
        self.tailSlamTimer = self.tailSlamTimer - dt
        if self.tailSlamTimer <= 0 then
            self.tailSlamActive = false
        end
    end
    if self.poisonFieldActive then
        self.poisonFieldTimer = self.poisonFieldTimer - dt
        if self.poisonFieldTimer <= 0 then
            self.poisonFieldActive = false
        else
            local tail = self.segments[#self.segments]
            local pdx = self.player.x - tail.x
            local pdy = self.player.y - tail.y
            if pdx*pdx + pdy*pdy < 150*150 then
                self.player:applyCollisionDamage(8)
                self.player.speedMultiplier = math.min(0.6, self.player.speedMultiplier or 1)
            end
        end
    end

    if self.active and self.player and self.player.active and not self.phaseTransition then
        if self.phase >= 1 and self.projectileCooldown <= 0 and distToPlayer < self.attackRange * 1.5 then
            self.projectileCooldown = self.projectileCooldownMax
            self:shootProjectile()
        end
        if self.phase >= 2 then
            if self.tailSlamCooldown <= 0 and distToPlayer < self.attackRange * 1.2 then
                self.tailSlamCooldown = self.tailSlamCooldownMax
                self:tailSlam()
            end
            if self.poisonFieldCooldown <= 0 and distToPlayer < self.attackRange * 1.8 then
                self.poisonFieldCooldown = self.poisonFieldCooldownMax
                self:createPoisonField()
            end
        end
        if self.phase >= 3 then
            if self.dashCooldown <= 0 and distToPlayer < self.attackRange * 1.3 and not self.dashActive then
                self.dashCooldown = self.dashCooldownMax
                self:startDash()
            end
            if self.teleportCooldown <= 0 and distToPlayer > self.attackRange * 0.8 then
                self.teleportCooldown = self.teleportCooldownMax
                self:teleportToPlayer()
            end
            if self.summonCooldown <= 0 then
                self.summonCooldown = self.summonCooldownMax
                self:summonMinions()
            end
        end
    end

    -- Движение: рывок или обычное
    if self.dashActive then
        self.dashTimer = self.dashTimer - dt
        if self.dashTimer <= 0 then
            self.dashActive = false
        else
            self.vx = math.cos(self.angle) * self.dashSpeed
            self.vy = math.sin(self.angle) * self.dashSpeed
            self.x = self.x + self.vx * dt
            self.y = self.y + self.vy * dt

            if math.random() < 0.5 then
                table.insert(self.abilityParticles, {
                    x = self.x - self.vx * dt * 0.5,
                    y = self.y - self.vy * dt * 0.5,
                    life = 0.3,
                    color = {1, 0.5, 0, 0.8},
                    size = 6
                })
            end
            self:updateSegmentsFromHistory(dt)
        end
    else
        -- обычное движение
        local targetAngle = self.angle
        if self.state == "chase" then
            if distToPlayer > 0 then
                targetAngle = math.atan2(dy, dx)
            end
            if distToPlayer < self.attackRange then
                local wiggle = math.sin(love.timer.getTime() * 5) * 0.5
                targetAngle = targetAngle + wiggle
            end
        else
            if not self.wanderTarget or self.wanderTimer <= 0 then
                local angle = math.random() * 2 * math.pi
                local radius = 500 + math.random() * 600
                self.wanderTarget = {
                    x = self.x + math.cos(angle) * radius,
                    y = self.y + math.sin(angle) * radius
                }
                self.wanderTimer = self.wanderInterval + math.random() * 2.5
            end
            self.wanderTimer = self.wanderTimer - dt
            local tx = self.wanderTarget.x - self.x
            local ty = self.wanderTarget.y - self.y
            local tdist = math.sqrt(tx*tx + ty*ty)
            if tdist > 0 then
                targetAngle = math.atan2(ty, tx)
            end
        end

        local angleDiff = targetAngle - self.angle
        while angleDiff > math.pi do angleDiff = angleDiff - 2*math.pi end
        while angleDiff < -math.pi do angleDiff = angleDiff + 2*math.pi end
        local maxTurn = self.turnSpeed * dt
        if math.abs(angleDiff) > maxTurn then
            self.angle = self.angle + (angleDiff > 0 and maxTurn or -maxTurn)
        else
            self.angle = targetAngle
        end

        self.vx = math.cos(self.angle) * effectiveSpeed
        self.vy = math.sin(self.angle) * effectiveSpeed
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt

        table.insert(self.history, 1, { x = self.x, y = self.y })
        if #self.history > self.maxHistory then table.remove(self.history) end
        self:updateSegmentsFromHistory(dt)
    end

    -- Общие действия после движения
    if self.scene and self.scene.worldBounds then
        self.x = math.max(self.scene.worldBounds.left + 80, math.min(self.scene.worldBounds.right - 80, self.x))
        self.y = math.max(self.scene.worldBounds.top + 80, math.min(self.scene.worldBounds.bottom - 80, self.y))
    end

    if self.active and self.player and self.player.active then
        local head = self.segments[1]
        local dxp = self.player.x - head.x
        local dyp = self.player.y - head.y
        local distToHead = math.sqrt(dxp*dxp + dyp*dyp)
        if distToHead < self.segmentRadius + self.player:getRadius() then
            self.biteAnimation = 1
            if self.biteCooldown <= 0 then
                local damage = 30
                if self.rageActive then damage = damage * self.enragedDamageMult end
                self.player:applyCollisionDamage(damage)
                local angleToPlayer = math.atan2(dyp, dxp)
                self.player.vx = self.player.vx + math.cos(angleToPlayer) * 220
                self.player.vy = self.player.vy + math.sin(angleToPlayer) * 220
                self.biteCooldown = 0.9
            end
        end
        self.biteCooldown = math.max(0, self.biteCooldown - dt)

        if self.bodyTouchCooldown <= 0 then
            for i = 2, self.segmentCount do
                local seg = self.segments[i]
                local dxp = self.player.x - seg.x
                local dyp = self.player.y - seg.y
                if dxp*dxp + dyp*dyp < (self.segmentRadius + self.player:getRadius())^2 then
                    local damage = self.bodyTouchDamage
                    if self.rageActive then damage = damage * self.enragedDamageMult end
                    self.player:applyCollisionDamage(damage)
                    self.bodyTouchCooldown = 0.5
                    break
                end
            end
        end
    end

    self.particleTimer = self.particleTimer - dt
    while self.particleTimer <= 0 do
        self.particleTimer = self.particleTimer + self.particleInterval
        if self.active then
            local head = self.segments[1]
            local angle = self.angle
            local offset = self.segmentRadius * 0.9
            local px = head.x + math.cos(angle) * offset
            local py = head.y + math.sin(angle) * offset
            table.insert(self.particles, {
                x = px, y = py,
                vx = math.cos(angle + (math.random() - 0.5) * 1.5) * (70 + math.random() * 50),
                vy = math.sin(angle + (math.random() - 0.5) * 1.5) * (70 + math.random() * 50),
                life = 0.8,
                color = {1, 0.4 + math.random()*0.3, 0.1, 0.9}
            })
            if math.random() < 0.3 then
                local segIdx = math.random(2, self.segmentCount)
                local seg = self.segments[segIdx]
                table.insert(self.particles, {
                    x = seg.x + (math.random() - 0.5) * self.segmentRadius,
                    y = seg.y + (math.random() - 0.5) * self.segmentRadius,
                    vx = (math.random() - 0.5) * 50,
                    vy = (math.random() - 0.5) * 50,
                    life = 0.5,
                    color = {0.8, 0.2, 0.1, 0.8}
                })
            end
        end
    end

    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
    for i = #self.abilityParticles, 1, -1 do
        local p = self.abilityParticles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.abilityParticles, i)
        end
    end
end

-- Вспомогательная функция обновления сегментов по истории
function SpaceWorm:updateSegmentsFromHistory(dt)
    local totalBodyLength = (self.segmentCount - 1) * self.segmentDistance
    if #self.history > 1 then
        local step = totalBodyLength / #self.history
        for i = 1, self.segmentCount do
            local offset = (i - 1) * self.segmentDistance
            local idx = math.floor(offset / step) + 1
            if idx <= #self.history then
                self.segments[i].x = self.history[idx].x
                self.segments[i].y = self.history[idx].y
            else
                self.segments[i].x = self.history[#self.history].x
                self.segments[i].y = self.history[#self.history].y
            end
        end
    end
end

function SpaceWorm:draw()
    if self.deathEffect then
        love.graphics.setColor(1, 0.2, 0, self.deathEffect)
        for _, seg in ipairs(self.segments) do
            love.graphics.circle("fill", seg.x, seg.y, self.segmentRadius * (1 + self.deathEffect))
        end
        return
    end
    if not self.active then return end

    -- Рисуем сегменты от хвоста к голове
    for i = #self.segments, 1, -1 do
        local seg = self.segments[i]
        local t = (i - 1) / (self.segmentCount - 1)

        local r, g, b
        if self.phase == 1 then
            r, g, b = 0.3 + t*0.2, 0.2 + t*0.1, 0.2 + t*0.1
        elseif self.phase == 2 then
            r, g, b = 0.5 + t*0.2, 0.3 + t*0.1, 0.2 + t*0.1
        else
            r, g, b = 0.7 + t*0.2, 0.2 + t*0.1, 0.2 + t*0.1
        end

        if self.rageActive then
            r, g, b = r + 0.3, g + 0.1, b + 0.1
        end

        if self.hitFlash and math.floor(self.hitFlash * 20) % 2 == 0 then
            love.graphics.setColor(1, 0.5, 0.5, 0.8)
        else
            love.graphics.setColor(r, g, b, 1)
        end

        love.graphics.circle("fill", seg.x, seg.y, self.segmentRadius)

        -- Броня
        local plateSize = self.segmentRadius * 0.7
        local angle = math.atan2(seg.y - (self.segments[math.min(i+1, #self.segments)] or seg).y,
                                 seg.x - (self.segments[math.min(i+1, #self.segments)] or seg).x)
        for side = -1, 1, 2 do
            local plateX = seg.x + math.cos(angle + side * 0.6) * (self.segmentRadius * 0.65)
            local plateY = seg.y + math.sin(angle + side * 0.6) * (self.segmentRadius * 0.65)
            love.graphics.setColor(r * 0.7, g * 0.5, b * 0.4, 1)
            love.graphics.circle("fill", plateX, plateY, plateSize * 0.5)
            love.graphics.setColor(0.9, 0.6, 0.2, 0.5)
            love.graphics.circle("line", plateX, plateY, plateSize * 0.5)
        end

        if self.alertGlow > 0 then
            love.graphics.setColor(1, 0.3, 0.1, self.alertGlow * 0.4)
            love.graphics.circle("fill", seg.x, seg.y, self.segmentRadius + 8)
        end
        if self.shieldActive then
            love.graphics.setColor(0.3, 0.6, 1, 0.3)
            love.graphics.circle("fill", seg.x, seg.y, self.segmentRadius + 12)
            love.graphics.setColor(0.5, 0.8, 1, 0.5)
            love.graphics.circle("line", seg.x, seg.y, self.segmentRadius + 10)
        end
        if self.poisonFieldActive and i == #self.segments then
            love.graphics.setColor(0.5, 0.8, 0.2, 0.3)
            love.graphics.circle("fill", seg.x, seg.y, 150)
        end
    end

    -- Голова
    local head = self.segments[1]
    if head then
        local angle = self.angle
        local jawOpen = self.biteAnimation * 0.9
        local jawLength = self.segmentRadius * 1.2
        local jawBaseOffset = self.segmentRadius * 0.8

        -- Маска
        if self.phase == 1 then
            love.graphics.setColor(0.5, 0.3, 0.2, 1)
        elseif self.phase == 2 then
            love.graphics.setColor(0.7, 0.4, 0.2, 1)
        else
            love.graphics.setColor(0.9, 0.3, 0.2, 1)
        end
        love.graphics.arc("fill", head.x, head.y, self.segmentRadius * 1.0, angle - 0.9, angle + 0.9, 20)

        -- Жвалы
        for side = -1, 1, 2 do
            local baseAngle = angle + side * (0.4 + jawOpen * 0.2)
            local midAngle = angle + side * (0.7 + jawOpen * 0.3)
            local tipAngle = angle + side * (1.0 + jawOpen * 0.4)

            local baseX = head.x + math.cos(baseAngle) * jawBaseOffset
            local baseY = head.y + math.sin(baseAngle) * jawBaseOffset
            local midX = head.x + math.cos(midAngle) * (jawLength * 0.7)
            local midY = head.y + math.sin(midAngle) * (jawLength * 0.7)
            local tipX = head.x + math.cos(tipAngle) * jawLength
            local tipY = head.y + math.sin(tipAngle) * jawLength

            love.graphics.setColor(0.3, 0.15, 0.05, 1)
            love.graphics.setLineWidth(self.segmentRadius * 0.35)
            love.graphics.line(baseX, baseY, midX, midY)
            love.graphics.setLineWidth(self.segmentRadius * 0.25)
            love.graphics.line(midX, midY, tipX, tipY)

            for t = 0.2, 0.9, 0.1 do
                local spikeAngle = angle + side * (0.5 + t * 0.8 + jawOpen * 0.3)
                local spikeX = head.x + math.cos(spikeAngle) * (jawLength * t)
                local spikeY = head.y + math.sin(spikeAngle) * (jawLength * t)
                love.graphics.setColor(0.9, 0.5, 0.2, 1)
                love.graphics.circle("fill", spikeX, spikeY, 3.5)
            end

            love.graphics.setColor(0.8, 0.4, 0.1, 1)
            love.graphics.circle("fill", tipX, tipY, self.segmentRadius * 0.18)
        end

        -- Зубы
        for i = 1, 20 do
            local t = i / 20
            local toothAngle = angle + (t - 0.5) * 0.8
            local toothX = head.x + math.cos(toothAngle) * (self.segmentRadius * 0.85)
            local toothY = head.y + math.sin(toothAngle) * (self.segmentRadius * 0.85)
            love.graphics.setColor(0.8, 0.4, 0.1, 1)
            love.graphics.circle("fill", toothX, toothY, 3)
        end

        -- Свечение фазы
        if self.phase >= 2 then
            love.graphics.setColor(1, 0.2, 0.1, 0.4 + 0.3 * math.sin(love.timer.getTime() * 5))
            love.graphics.circle("fill", head.x, head.y, self.segmentRadius + 6)
        end
        if self.rageActive then
            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.circle("fill", head.x, head.y, self.segmentRadius + 10)
        end
    end

    -- Частицы
    for _, p in ipairs(self.particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.life * 0.8)
        love.graphics.circle("fill", p.x, p.y, 3 + p.life * 2)
    end
    for _, p in ipairs(self.abilityParticles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.life)
        love.graphics.circle("fill", p.x, p.y, p.size or 5)
    end
end

function SpaceWorm:checkCollision(bullet)
    if not self.active then return false end
    if self.phaseTransition then return false end
    for _, seg in ipairs(self.segments) do
        local dx = bullet.x - seg.x
        local dy = bullet.y - seg.y
        if dx*dx + dy*dy < (self.segmentRadius + bullet.size)^2 then
            return true
        end
    end
    return false
end

function SpaceWorm:takeDamage(amount, bullet)
    if not self.active then return false end
    if self.phaseTransition then return false end
    if self.shieldActive then
        amount = amount * 0.5
    end
    self.health = self.health - amount
    self.hitFlash = 0.2
    if self.health <= 0 then
        self.active = false
        self.deathEffect = 0.8
    end
    return self.health <= 0
end

function SpaceWorm:getRadius()
    return self.segmentRadius
end

-- СПОСОБНОСТИ

function SpaceWorm:enterPhase(newPhase)
    self.phase = newPhase
    self.phaseTransition = true
    self.phaseTransitionTimer = self.phaseTransitionDuration
    self.shieldActive = true
    self.shieldTimer = self.shieldDuration

    for i = 1, 50 do
        table.insert(self.abilityParticles, {
            x = self.x + (math.random() - 0.5) * 150,
            y = self.y + (math.random() - 0.5) * 150,
            life = 1.0,
            color = {1, 0.2, 0.1, 0.8},
            size = 7
        })
    end
    self.projectileCooldown = 0
    self.dashCooldown = 0
    self.summonCooldown = 0
    self.tailSlamCooldown = 0
    self.poisonFieldCooldown = 0
    self.teleportCooldown = 0
end

function SpaceWorm:shootProjectile()
    
end

function SpaceWorm:startDash()
    self.dashActive = true
    self.dashTimer = self.dashDuration
    self.vx = math.cos(self.angle) * self.dashSpeed
    self.vy = math.sin(self.angle) * self.dashSpeed
    for i = 1, 15 do
        table.insert(self.abilityParticles, {
            x = self.x, y = self.y,
            life = 0.4,
            color = {1, 0.6, 0, 0.9},
            size = 8
        })
    end
end

function SpaceWorm:summonMinions()
    if self.scene and self.scene.spawnEnemy then
        local count = 3 + (self.phase == 3 and 2 or 0)
        for i = 1, count do
            local angle = math.random() * 2 * math.pi
            local radius = 100
            local mx = self.x + math.cos(angle) * radius
            local my = self.y + math.sin(angle) * radius
            self.scene:spawnEnemy("wormling", mx, my)
        end
    end
    for i = 1, 25 do
        table.insert(self.abilityParticles, {
            x = self.x + (math.random() - 0.5) * 120,
            y = self.y + (math.random() - 0.5) * 120,
            life = 1.0,
            color = {0.6, 0.2, 0.8, 0.7},
            size = 6
        })
    end
end

function SpaceWorm:tailSlam()
    self.tailSlamActive = true
    self.tailSlamTimer = 0.5
    local tail = self.segments[#self.segments]
    -- Ударная волна от хвоста
    local dxp = self.player.x - tail.x
    local dyp = self.player.y - tail.y
    local dist = math.sqrt(dxp*dxp + dyp*dyp)
    if dist < 120 then
        local damage = 25
        if self.rageActive then damage = damage * 1.3 end
        self.player:applyCollisionDamage(damage)
        local angle = math.atan2(dyp, dxp)
        self.player.vx = self.player.vx + math.cos(angle) * 300
        self.player.vy = self.player.vy + math.sin(angle) * 300
    end
    -- Визуальный эффект
    for i = 1, 20 do
        table.insert(self.abilityParticles, {
            x = tail.x + (math.random() - 0.5) * 40,
            y = tail.y + (math.random() - 0.5) * 40,
            life = 0.5,
            color = {0.8, 0.4, 0.1, 1},
            size = 6
        })
    end
end

function SpaceWorm:createPoisonField()
    self.poisonFieldActive = true
    self.poisonFieldTimer = 5.0
    local tail = self.segments[#self.segments]
    for i = 1, 30 do
        table.insert(self.abilityParticles, {
            x = tail.x + (math.random() - 0.5) * 150,
            y = tail.y + (math.random() - 0.5) * 150,
            life = 1.2,
            color = {0.3, 0.9, 0.2, 0.6},
            size = 5
        })
    end
end

function SpaceWorm:teleportToPlayer()
    -- Телепортация к игроку (появление рядом)
    local angleToPlayer = math.atan2(self.player.y - self.y, self.player.x - self.x)
    local offset = 100
    local newX = self.player.x - math.cos(angleToPlayer) * offset
    local newY = self.player.y - math.sin(angleToPlayer) * offset
    -- Проверка границ
    if self.scene and self.scene.worldBounds then
        newX = math.max(self.scene.worldBounds.left + 60, math.min(self.scene.worldBounds.right - 60, newX))
        newY = math.max(self.scene.worldBounds.top + 60, math.min(self.scene.worldBounds.bottom - 60, newY))
    end
    -- Старая позиция для эффекта
    local oldX, oldY = self.x, self.y
    self.x = newX
    self.y = newY
    -- Обновляем историю и сегменты
    for i = 1, self.segmentCount do
        self.segments[i] = { x = self.x, y = self.y }
    end
    self.history = {}
    table.insert(self.history, 1, { x = self.x, y = self.y })
    -- Эффект телепортации
    for i = 1, 40 do
        table.insert(self.abilityParticles, {
            x = oldX + (math.random() - 0.5) * 80,
            y = oldY + (math.random() - 0.5) * 80,
            life = 0.7,
            color = {0.4, 0.2, 1, 0.8},
            size = 7
        })
        table.insert(self.abilityParticles, {
            x = self.x + (math.random() - 0.5) * 80,
            y = self.y + (math.random() - 0.5) * 80,
            life = 0.7,
            color = {0.4, 0.2, 1, 0.8},
            size = 7
        })
    end
end

function SpaceWorm:activateRage()
    self.rageActive = true
    self.rageTimer = self.rageDuration
    for i = 1, 40 do
        table.insert(self.abilityParticles, {
            x = self.x + (math.random() - 0.5) * 150,
            y = self.y + (math.random() - 0.5) * 150,
            life = 1.0,
            color = {1, 0, 0, 0.8},
            size = 8
        })
    end
end

return SpaceWorm