local Camera = {}
Camera.__index = Camera

function Camera.new(x, y, zoom, angle)
    local self = setmetatable({}, Camera)
    self.x = x or 0
    self.y = y or 0
    self.zoom = zoom or 1
    self.angle = angle or 0
    self.smooth = false

    -- Параметры для тряски
    self.shakeIntensity = 0      -- текущая интенсивность (0 - нет тряски)
    self.shakeDuration = 0       -- длительность тряски (сек)
    self.shakeTimer = 0          -- таймер
    self.shakeOffsetX = 0        -- текущее смещение по X
    self.shakeOffsetY = 0        -- текущее смещение по Y

    return self
end

function Camera:setPosition(x, y)
    self.x = x or self.x
    self.y = y or self.y
end

function Camera:move(dx, dy)
    self.x = self.x + (dx or 0)
    self.y = self.y + (dy or 0)
end

function Camera:setZoom(zoom)
    self.zoom = math.max(0.1, zoom or 1)
end

function Camera:zoomBy(dz)
    self.zoom = math.max(0.1, self.zoom + (dz or 0))
end

function Camera:setAngle(angle)
    self.angle = angle or 0
end

function Camera:rotate(dr)
    self.angle = self.angle + (dr or 0)
end

function Camera:follow(target, smoothness)
    if not target then return end
    if smoothness and smoothness > 0 then
        self.x = self.x + (target.x - self.x) * smoothness
        self.y = self.y + (target.y - self.y) * smoothness
    else
        self.x = target.x
        self.y = target.y
    end
end

-- Запустить тряску камеры
-- duration: длительность в секундах
-- intensity: максимальная амплитуда смещения (в пикселях мира)
function Camera:shake(duration, intensity)
    self.shakeIntensity = intensity or 10
    self.shakeDuration = duration or 0.3
    self.shakeTimer = self.shakeDuration
end

-- Обновление состояния тряски (вызывать каждый кадр с dt)
function Camera:update(dt)
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
        if self.shakeTimer <= 0 then
            self.shakeTimer = 0
            self.shakeIntensity = 0
            self.shakeOffsetX = 0
            self.shakeOffsetY = 0
        else
            -- Затухание интенсивности пропорционально оставшемуся времени
            local intensity = self.shakeIntensity * (self.shakeTimer / self.shakeDuration)
            -- Случайное смещение в пределах круга радиуса intensity
            local angle = love.math.random() * 2 * math.pi
            self.shakeOffsetX = math.cos(angle) * intensity
            self.shakeOffsetY = math.sin(angle) * intensity
        end
    else
        self.shakeOffsetX = 0
        self.shakeOffsetY = 0
    end
end

function Camera:screenToWorld(screenX, screenY)
    local w, h = love.graphics.getDimensions()
    local cos = math.cos(-self.angle)
    local sin = math.sin(-self.angle)
    local dx = screenX - w/2
    local dy = screenY - h/2
    local rx = dx * cos - dy * sin
    local ry = dx * sin + dy * cos
    -- Обратное смещение тряски (если нужно преобразовывать координаты)
    -- Но для большинства случаев это не требуется, оставим без учёта тряски
    return rx / self.zoom + self.x, ry / self.zoom + self.y
end

function Camera:worldToScreen(worldX, worldY)
    local w, h = love.graphics.getDimensions()
    local dx = (worldX - self.x) * self.zoom
    local dy = (worldY - self.y) * self.zoom
    local cos = math.cos(self.angle)
    local sin = math.sin(self.angle)
    local rx = dx * cos - dy * sin
    local ry = dx * sin + dy * cos
    return rx + w/2, ry + h/2
end

function Camera:attach()
    local w, h = love.graphics.getDimensions()
    love.graphics.push()
    love.graphics.translate(w/2, h/2)
    love.graphics.scale(self.zoom, self.zoom)
    love.graphics.rotate(self.angle)
    love.graphics.translate(-self.x, -self.y)
    -- Применяем смещение от тряски (в мировых координатах)
    love.graphics.translate(-self.shakeOffsetX, -self.shakeOffsetY)
end

function Camera:detach()
    love.graphics.pop()
end

function Camera:getBounds()
    local w, h = love.graphics.getDimensions()
    -- При вычислении границ нужно учесть тряску? Обычно нет,
    -- так как тряска не меняет видимую область, а только сдвигает изображение.
    -- Оставим без учёта тряски, чтобы границы соответствовали реальному положению камеры.
    local x1, y1 = self:screenToWorld(0, 0)
    local x2, y2 = self:screenToWorld(w, h)
    return {
        left = math.min(x1, x2),
        right = math.max(x1, x2),
        top = math.min(y1, y2),
        bottom = math.max(y1, y2),
        width = math.abs(x2 - x1),
        height = math.abs(y2 - y1)
    }
end

return Camera