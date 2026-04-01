-- assets/controller/hud.lua
-- Добавлена всегда видимая опасная зона, значение скорости вынесено из круга

local HUD = {}
HUD.__index = HUD

function HUD.new(player, settings, camera, drones, worldBounds)
    local self = setmetatable({}, HUD)
    self.player = player
    self.settings = settings
    self.camera = camera
    self.drones = drones
    self.worldBounds = worldBounds or { left = -5000, right = 5000, top = -5000, bottom = 5000 }

    self.fontMain = love.graphics.newFont(14)
    self.fontValue = love.graphics.newFont(24)
    self.fontSmall = love.graphics.newFont(11)
    self.fontWarning = love.graphics.newFont(16)

    self.colors = {
        bg          = {0.03, 0.03, 0.06, 0.7},
        panelBg     = {0.05, 0.05, 0.1, 0.6},
        health      = {0.85, 0.25, 0.25, 1},
        armor       = {0.25, 0.65, 0.95, 1},
        stamina     = {0.35, 0.85, 0.55, 1},
        speedArcBg  = {0.15, 0.15, 0.25, 0.9},
        dangerZone  = {1, 0.2, 0.2, 0.1},
        dangerZoneOutline = {1, 0.4, 0.4, 0.8},
        text        = {0.9, 0.9, 1, 1},
        textDim     = {0.6, 0.7, 0.9, 1},
        border      = {0.4, 0.5, 0.7, 0.5},
        minimapBg   = {0.02, 0.02, 0.05, 0.85},
        minimapBorder = {0.5, 0.6, 0.8, 0.9},
        playerDot   = {0.9, 0.9, 1, 1},
        droneDot    = {1, 0.4, 0.4, 0.9},
        cameraRect  = {0.7, 0.8, 1, 0.7},
        overheat    = {1, 0.2, 0.2, 0.5},
        warning     = {1, 0.5, 0.2, 1},
    }

    self.smoothSpeed = 0
    self.shakeIntensity = 0
    self.overheatPulse = 0
    self.warningTextTimer = 0
    self.gameTime = 0
    return self
end

function HUD:update(dt)
    if not self.player then return end

    self.gameTime = self.gameTime + dt

    local rawSpeed = math.sqrt(self.player.vx^2 + self.player.vy^2)
    local maxSpeed = self.player.maxSpeed + 75
    local percent = math.min(1, rawSpeed / maxSpeed)

    self.smoothSpeed = self.smoothSpeed + (rawSpeed - self.smoothSpeed) * math.min(1, dt * 8)

    local isOver = rawSpeed > maxSpeed
    if isOver then
        self.overheatPulse = self.overheatPulse + dt * 8
        self.shakeIntensity = math.min(12, self.shakeIntensity + dt * 35)
        self.warningTextTimer = math.min(2, self.warningTextTimer + dt)
    else
        self.overheatPulse = 0
        self.shakeIntensity = math.max(0, self.shakeIntensity - dt * 25)
        self.warningTextTimer = math.max(0, self.warningTextTimer - dt)
    end
end

function HUD:getCameraShake()
    if self.shakeIntensity <= 0 then return 0, 0 end
    local shakeX = (math.random() - 0.5) * self.shakeIntensity
    local shakeY = (math.random() - 0.5) * self.shakeIntensity
    return shakeX, shakeY
end

function HUD:draw()
    if not self.player then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    -- Левая нижняя панель
    local barX = 20
    local barY = h - 155
    local barWidth = 180
    local barHeight = 6
    local spacing = 40
    local panelW = barWidth + 30
    local panelH = 3 * (barHeight + spacing) + 15

    self:drawStatBar(barX, barY, barWidth, barHeight, "HEALTH",
        self.player:getHealth(), self.player:getMaxHealth(), self.colors.health)

    self:drawStatBar(barX, barY + spacing, barWidth, barHeight, "ARMOR",
        self.player:getArmor(), self.player:getMaxArmor(), self.colors.armor)

    self:drawStatBar(barX, barY + 2*spacing, barWidth, barHeight, "ENERGY",
        self.player:getStamina(), self.player:getStaminaMax(), self.colors.stamina)

    -- Мини‑карта
    local mapX = 16
    local mapY = 16
    local mapSize = 140
    self:drawPanel(mapX, mapY, mapSize + 8, mapSize + 8, 0.7)
    self:drawMinimap(mapX + 4, mapY + 4, mapSize, mapSize)

    -- Спидометр (круг)
    local radius = 70
    local centerX = w - radius - 30
    local centerY = h - radius - 30
    local panelSize = radius * 2 + 20
    self:drawPanel(centerX - radius - 10, centerY - radius - 10, panelSize, panelSize, 0.7)
    self:drawSpeedometer(centerX, centerY, radius)

    -- Значение скорости вне круга
    love.graphics.setColor(self.colors.text)
    love.graphics.setFont(self.fontValue)
    local speedStr = math.floor(self.smoothSpeed)
    local tw = self.fontValue:getWidth(speedStr)
    love.graphics.print(speedStr, centerX - tw/2, centerY + radius + 8)

    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("SPEED", centerX - 20, centerY + radius + 15)

    -- Предупреждения
    if self.player.overheated then
        love.graphics.setColor(self.colors.warning)
        love.graphics.setFont(self.fontWarning)
        local text = "CRITICAL TEMPERATURE! COOLING..."
        local tw = self.fontWarning:getWidth(text)
        love.graphics.print(text, w/2 - tw/2, h - 80)
    elseif self.warningTextTimer > 0 then
        local alpha = math.min(1, self.warningTextTimer * 2)
        love.graphics.setColor(self.colors.warning[1], self.colors.warning[2], self.colors.warning[3], alpha)
        love.graphics.setFont(self.fontWarning)
        local text = "HIGH LOAD! SLOW DOWN"
        local tw = self.fontWarning:getWidth(text)
        love.graphics.print(text, w/2 - tw/2, h - 60)
         self.player.health = self.player.health - 0.1
    end

    -- Красное свечение при перегреве
    if self.overheatPulse > 0 then
        local intensity = math.sin(self.overheatPulse) * 0.5 + 0.5
        intensity = intensity * 0.6
        love.graphics.setColor(1, 0.2, 0.2, intensity)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
end

function HUD:drawPanel(x, y, w, h, alpha)
    love.graphics.setColor(self.colors.panelBg[1], self.colors.panelBg[2], self.colors.panelBg[3], alpha)
    love.graphics.rectangle("fill", x, y, w, h, 6)
    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, 6)
end

function HUD:drawStatBar(x, y, width, height, label, value, maxValue, color)
    local percent = math.min(1, value / maxValue)
    local fillWidth = width * percent

    love.graphics.setColor(self.colors.bg)
    love.graphics.rectangle("fill", x, y, width, height, 2)

    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, fillWidth, height, 2)

    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, width, height, 2)

    love.graphics.setColor(self.colors.text)
    love.graphics.setFont(self.fontMain)
    love.graphics.print(label, x, y - 14)

    local valueText = string.format("%d / %d", math.floor(value), math.floor(maxValue))
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(valueText, x + width + 8, y + height/2 - 6)
end

function HUD:drawSpeedometer(x, y, radius)
    local speed = self.smoothSpeed
    local maxSpeed = self.player.maxSpeed + 75
    local percent = math.min(1, speed / maxSpeed)
    local rawSpeed = math.sqrt(self.player.vx^2 + self.player.vy^2)
    local isOver = rawSpeed > maxSpeed

    -- Цвет для безопасной зоны
    local hue = percent
    local r = math.min(1, 0.2 + hue * 1.2)
    local g = math.min(1, 0.3 + hue * 0.7)
    local b = math.min(1, 1.0 - hue * 0.6)

    -- Фон дуги
    love.graphics.setColor(self.colors.speedArcBg)
    love.graphics.arc("fill", x, y, radius, 0, 2 * math.pi, 60)
    love.graphics.setColor(self.colors.speedArcBg)
    love.graphics.setLineWidth(2)
    love.graphics.arc("line", x, y, radius, 0, 2 * math.pi, 60)

    -- Опасная зона (всегда видна)
    local dangerStart = 0.8
    love.graphics.setColor(self.colors.dangerZone)
    love.graphics.arc("fill", x, y, radius - 3, -math.pi/2 + dangerStart * 2 * math.pi, -math.pi/2 + 2 * math.pi, 60)
    love.graphics.setColor(self.colors.dangerZoneOutline)
    love.graphics.setLineWidth(1)
    love.graphics.arc("line", x, y, radius - 3, -math.pi/2 + dangerStart * 2 * math.pi, -math.pi/2 + 2 * math.pi, 60)

    -- Заполнение безопасной зоны (не закрашивает опасную)
    local safePercent = math.min(percent, dangerStart)
    if safePercent > 0 then
        love.graphics.setColor(r, g, b, 1)
        love.graphics.arc("fill", x, y, radius - 3, -math.pi/2, -math.pi/2 + 2 * math.pi * safePercent, 60)
    end

    -- Если скорость превышает опасную зону, закрашиваем её красным
    if percent > dangerStart then
        local startAngle = -math.pi/2 + dangerStart * 2 * math.pi
        local endAngle = -math.pi/2 + percent * 2 * math.pi
        love.graphics.setColor(self.colors.dangerZone)
        love.graphics.arc("fill", x, y, radius - 3, startAngle, endAngle, 60)
    end

    -- Стрелка
    local angle = -math.pi/2 + percent * 2 * math.pi
    local arrowLen = radius - 8
    local arrowX = x + math.cos(angle) * arrowLen
    local arrowY = y + math.sin(angle) * arrowLen

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.line(x + 2, y + 2, arrowX + 2, arrowY + 2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.line(x, y, arrowX, arrowY)

    love.graphics.setColor(r, g, b, 1)
    love.graphics.circle("fill", x, y, 5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", x, y, 3)

    -- Эффект перегрузки
    if isOver then
        local pulse = 0.5 + 0.5 * math.sin(self.overheatPulse * 8)
        love.graphics.setColor(1, 0.3, 0.3, 0.5 * pulse)
        love.graphics.circle("fill", x, y, radius + 4)
        love.graphics.setColor(1, 0.6, 0.6, 0.8 * pulse)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", x, y, radius + 3)
    end
end

function HUD:drawMinimap(x, y, width, height)
    local worldLeft = self.worldBounds.left
    local worldRight = self.worldBounds.right
    local worldTop = self.worldBounds.top
    local worldBottom = self.worldBounds.bottom
    local worldW = worldRight - worldLeft
    local worldH = worldBottom - worldTop

    if worldW <= 0 or worldH <= 0 then return end

    love.graphics.setColor(self.colors.minimapBg)
    love.graphics.rectangle("fill", x, y, width, height, 4)

    love.graphics.setColor(self.colors.minimapBorder)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, width, height, 4)

    local function worldToMinimap(px, py)
        local mx = x + (px - worldLeft) / worldW * width
        local my = y + (py - worldTop) / worldH * height
        return mx, my
    end

    if self.drones then
        for _, drone in ipairs(self.drones) do
            if drone and type(drone) == "table" and drone.active then
                local mx, my = worldToMinimap(drone.x, drone.y)
                if mx >= x and mx <= x + width and my >= y and my <= y + height then
                    love.graphics.setColor(self.colors.droneDot)
                    love.graphics.circle("fill", mx, my, 2)
                end
            end
        end
    end

    local px, py = worldToMinimap(self.player.x, self.player.y)
    love.graphics.setColor(self.colors.playerDot)
    love.graphics.circle("fill", px, py, 4)
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.circle("fill", px, py, 2)

    if self.camera and self.camera.getBounds then
        local camBounds = self.camera:getBounds()
        if camBounds then
            local left, top = worldToMinimap(camBounds.left, camBounds.top)
            local right, bottom = worldToMinimap(camBounds.right, camBounds.bottom)
            local camW = right - left
            local camH = bottom - top
            love.graphics.setColor(self.colors.cameraRect)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", left, top, camW, camH)
        end
    end
end

return HUD