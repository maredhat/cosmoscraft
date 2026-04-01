-- assets/enemy/asteroid/asteroid.lua
-- Неразрушаемый астероид с реалистичными кратерами (следы комет)
-- Пули разбиваются об астероид, он не двигается, только медленно вращается и дрейфует

local Asteroid = {}
Asteroid.__index = Asteroid

function Asteroid.new(x, y, scene)
    local self = setmetatable({}, Asteroid)
    self.x = x or 0
    self.y = y or 0
    self.scene = scene
    self.active = true

    -- Размер: от 80 до 350 (огромные астероиды)
    self.radius = 80 + math.random() * 270

    -- Статический объект (не сдвигается)
    self.isStatic = true
    self.mass = math.huge

    -- Медленное вращение и дрейф
    self.vx = (math.random() - 0.5) * 1.2
    self.vy = (math.random() - 0.5) * 1.2
    self.rotation = math.random() * 2 * math.pi
    self.rotSpeed = (math.random() - 0.5) * 0.15

    -- Генерация вершин (неровная форма)
    self.vertices = {}
    local segments = 32 + math.random(32)   -- 32–64 вершины
    for i = 1, segments do
        local angle = (i - 1) / segments * 2 * math.pi
        local r = self.radius * (0.65 + math.random() * 0.45)
        local vx = math.cos(angle) * r
        local vy = math.sin(angle) * r
        table.insert(self.vertices, {x = vx, y = vy})
    end

    -- --------------------------------------------------------------------
    -- Кратеры (следы комет)
    -- --------------------------------------------------------------------
    self.craters = {}
    local craterCount = 4 + math.random(2)
    for i = 1, craterCount do
        local angle = math.random() * 2 * math.pi
        local dist = math.random() * (self.radius - 15)
        local size = 6 + math.random() * (self.radius * 0.28)
        table.insert(self.craters, {
            x = math.cos(angle) * dist,
            y = math.sin(angle) * dist,
            r = size
        })
    end

    -- Трещины, расходящиеся от некоторых кратеров
    self.cracks = {}
    for _, crater in ipairs(self.craters) do
        if math.random() < 0.4 then
            local crackCount = 1 + math.random(2)
            for j = 1, crackCount do
                local angle = math.random() * 2 * math.pi
                local len = crater.r * (0.5 + math.random() * 1.2)
                local x1 = crater.x + math.cos(angle) * crater.r * 0.7
                local y1 = crater.y + math.sin(angle) * crater.r * 0.7
                local x2 = crater.x + math.cos(angle + (math.random()-0.5)*0.8) * (crater.r + len)
                local y2 = crater.y + math.sin(angle + (math.random()-0.5)*0.8) * (crater.r + len)
                table.insert(self.cracks, {x1 = x1, y1 = y1, x2 = x2, y2 = y2})
            end
        end
    end

    -- Мелкие вмятины (покмарки) для текстуры
    self.pockmarks = {}
    local pockCount = 10 + math.random(30)
    for i = 1, pockCount do
        local angle = math.random() * 2 * math.pi
        local dist = math.random() * (self.radius - 5)
        local size = 1.5 + math.random() * 5
        table.insert(self.pockmarks, {
            x = math.cos(angle) * dist,
            y = math.sin(angle) * dist,
            r = size
        })
    end

    -- Блестящие кристаллические включения
    self.crystals = {}
    local crystalCount = 15 + math.random(30)
    for i = 1, crystalCount do
        local angle = math.random() * 2 * math.pi
        local dist = math.random() * (self.radius - 8)
        local size = 1 + math.random() * 4
        table.insert(self.crystals, {
            x = math.cos(angle) * dist,
            y = math.sin(angle) * dist,
            r = size,
            brightness = 0.5 + math.random() * 0.5
        })
    end

    -- Цвета (реалистичные каменистые оттенки)
    local brown = 0.45 + math.random() * 0.25
    local gray = 0.4 + math.random() * 0.3
    self.baseColor = {brown, brown*0.8, gray*0.7}
    self.lightColor = {self.baseColor[1]*1.3, self.baseColor[2]*1.2, self.baseColor[3]*1.2}
    self.darkColor = {self.baseColor[1]*0.6, self.baseColor[2]*0.5, self.baseColor[3]*0.5}

    return self
end

-- ------------------------------------------------------------------------
-- Коллизии
-- ------------------------------------------------------------------------

-- Проверка, находится ли точка внутри многоугольника (для пуль)
function Asteroid:pointInside(px, py)
    local inside = false
    local dx = px - self.x
    local dy = py - self.y
    local cosR = math.cos(-self.rotation)
    local sinR = math.sin(-self.rotation)
    local lx = dx * cosR - dy * sinR
    local ly = dx * sinR + dy * cosR

    local verts = self.vertices
    for i = 1, #verts do
        local j = i % #verts + 1
        local xi, yi = verts[i].x, verts[i].y
        local xj, yj = verts[j].x, verts[j].y
        local intersect = ((yi > ly) ~= (yj > ly)) and
            (lx < (xj - xi) * (ly - yi) / (yj - yi) + xi)
        if intersect then inside = not inside end
    end
    return inside
end

-- Проверка пересечения окружности (игрок, дрон) с многоугольником
function Asteroid:circleCollision(cx, cy, r)
    local dx = cx - self.x
    local dy = cy - self.y
    local distToCenter = math.sqrt(dx*dx + dy*dy)
    if distToCenter > self.radius + r then
        return false
    end

    local cosR = math.cos(-self.rotation)
    local sinR = math.sin(-self.rotation)
    local lx = dx * cosR - dy * sinR
    local ly = dx * sinR + dy * cosR

    if self:pointInside(cx, cy) then
        return true
    end

    local verts = self.vertices
    for i = 1, #verts do
        local j = i % #verts + 1
        local x1, y1 = verts[i].x, verts[i].y
        local x2, y2 = verts[j].x, verts[j].y

        local ax = lx - x1
        local ay = ly - y1
        local bx = x2 - x1
        local by = y2 - y1
        local dot = ax * bx + ay * by
        local len2 = bx * bx + by * by
        local t = dot / len2
        if t < 0 then t = 0 end
        if t > 1 then t = 1 end
        local closestX = x1 + t * bx
        local closestY = y1 + t * by
        local distSq = (lx - closestX)^2 + (ly - closestY)^2
        if distSq < r * r then
            return true
        end
    end
    return false
end

-- Для пуль: возвращаем true, если пуля попала (пуля уничтожится)
function Asteroid:checkCollision(bullet)
    if not self.active then return false end
    return self:pointInside(bullet.x, bullet.y)
end

-- Астероид не получает урон
function Asteroid:takeDamage(amount, bullet)
    return false
end

-- При столкновении с игроком/дроном наносим урон (реализуется в сцене)
function Asteroid:applyCollisionDamage(impact)
    -- астероид не получает урон
end

function Asteroid:getRadius()
    return self.radius
end

-- ------------------------------------------------------------------------
-- Обновление (дрейф + вращение)
-- ------------------------------------------------------------------------
function Asteroid:update(dt)
    if not self.active then return end

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.rotation = self.rotation + self.rotSpeed * dt

    if self.scene and self.scene.worldBounds then
        local wb = self.scene.worldBounds
        if self.x - self.radius < wb.left then self.x = wb.left + self.radius end
        if self.x + self.radius > wb.right then self.x = wb.right - self.radius end
        if self.y - self.radius < wb.top then self.y = wb.top + self.radius end
        if self.y + self.radius > wb.bottom then self.y = wb.bottom - self.radius end
    end
end

-- ------------------------------------------------------------------------
-- Отрисовка (красивая, реалистичная)
-- ------------------------------------------------------------------------
function Asteroid:draw()
    if not self.active then return end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)

    -- 1. Основная форма
    local polyPoints = {}
    for _, v in ipairs(self.vertices) do
        polyPoints[#polyPoints+1] = v.x
        polyPoints[#polyPoints+1] = v.y
    end
    love.graphics.setColor(self.baseColor[1], self.baseColor[2], self.baseColor[3], 1)
    love.graphics.polygon("fill", polyPoints)

    -- 2. Кратеры (с реалистичным затенением)
    for _, crater in ipairs(self.craters) do
        -- тёмное дно
        love.graphics.setColor(self.darkColor[1], self.darkColor[2], self.darkColor[3], 1)
        love.graphics.circle("fill", crater.x, crater.y, crater.r)

        -- светлая часть (блик на краю)
        love.graphics.setColor(self.lightColor[1]*0.8, self.lightColor[2]*0.8, self.lightColor[3]*0.8, 1)
        love.graphics.circle("fill", crater.x - crater.r*0.15, crater.y - crater.r*0.15, crater.r*0.5)

        -- дополнительный отблеск
        love.graphics.setColor(self.lightColor[1], self.lightColor[2], self.lightColor[3], 0.6)
        love.graphics.circle("fill", crater.x + crater.r*0.2, crater.y + crater.r*0.2, crater.r*0.3)
    end

    -- 3. Мелкие вмятины
    love.graphics.setColor(self.darkColor[1], self.darkColor[2], self.darkColor[3], 0.9)
    for _, pm in ipairs(self.pockmarks) do
        love.graphics.circle("fill", pm.x, pm.y, pm.r)
        love.graphics.setColor(self.lightColor[1]*0.7, self.lightColor[2]*0.7, self.lightColor[3]*0.7, 0.7)
        love.graphics.circle("fill", pm.x - pm.r*0.3, pm.y - pm.r*0.3, pm.r*0.4)
        love.graphics.setColor(self.darkColor[1], self.darkColor[2], self.darkColor[3], 0.9)
    end

    -- 4. Трещины
    love.graphics.setLineWidth(2)
    for _, crack in ipairs(self.cracks) do
        love.graphics.setColor(0.1, 0.08, 0.05, 0.9)
        love.graphics.line(crack.x1, crack.y1, crack.x2, crack.y2)
        love.graphics.setColor(0.5, 0.4, 0.3, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.line(crack.x1 + 0.5, crack.y1 + 0.5, crack.x2 + 0.5, crack.y2 + 0.5)
    end

    -- 5. Кристаллы (мерцающие)
    for _, crys in ipairs(self.crystals) do
        local shine = 0.4 + math.sin(love.timer.getTime() * 3 + crys.x + crys.y) * 0.3
        love.graphics.setColor(0.9, 0.85, 0.7, crys.brightness * shine)
        love.graphics.circle("fill", crys.x, crys.y, crys.r)
        love.graphics.setColor(1, 1, 0.9, crys.brightness * 0.5)
        love.graphics.circle("fill", crys.x - crys.r*0.3, crys.y - crys.r*0.3, crys.r*0.4)
    end

    -- 6. Общая дымка (атмосфера)
    love.graphics.setColor(0.7, 0.65, 0.6, 0.08)
    for i = 1, 50 do
        local angle = math.random() * 2 * math.pi
        local rad = self.radius * (0.7 + math.random() * 0.5)
        local x = math.cos(angle) * rad
        local y = math.sin(angle) * rad
        love.graphics.circle("fill", x, y, 4 + math.random() * 10)
    end



    love.graphics.pop()
end

return Asteroid