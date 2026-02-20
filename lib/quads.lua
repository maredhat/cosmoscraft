--[[
╔══════════════════════════════════════════════════════════════╗
║                    QuadWorld Library v1.0                    ║
║                   Простое квадрантное разбиение              ║
╚══════════════════════════════════════════════════════════════╝
--]]

QuadWorld = {}
QuadWorld.__index = QuadWorld

--[[
    Создание нового мира с квадрантным разбиением
    Параметры:
        width, height - размеры мира (обычно размер окна)
        minSize - минимальный размер квадранта (по умолчанию 100)
        maxDepth - максимальная глубина разбиения (по умолчанию 5)
]]
function QuadWorld.new(width, height, minSize, maxDepth)
    local self = setmetatable({}, QuadWorld)
    
    self.width = width or love.graphics.getWidth()
    self.height = height or love.graphics.getHeight()
    self.minSize = minSize or 100
    self.maxDepth = maxDepth or 5
    
    -- Корневой квадрант
    self.root = QuadWorld.Quadrant.new(0, 0, self.width, self.height, 1, self)
    self.root.id = "root"
    
    -- Все объекты в мире
    self.objects = {}
    
    -- Настройки отображения
    self.showGrid = true
    self.showIds = false
    self.showObjects = true
    self.highlightCurrent = true
    self.debugMode = false
    
    return self
end

--[[
    Класс квадранта
]]
QuadWorld.Quadrant = {}
QuadWorld.Quadrant.__index = QuadWorld.Quadrant

function QuadWorld.Quadrant.new(x, y, w, h, depth, world)
    local self = setmetatable({}, QuadWorld.Quadrant)
    
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.depth = depth
    self.world = world
    
    self.id = nil
    self.children = {}
    self.objects = {}
    self.isLeaf = true
    
    -- Для визуализации
    self.color = {
        math.random(0.3, 1),
        math.random(0.3, 1),
        math.random(0.3, 1)
    }
    self.visited = false
    
    return self
end

-- Проверка, содержит ли квадрант точку
function QuadWorld.Quadrant:contains(px, py)
    return px >= self.x and px <= self.x + self.w and
           py >= self.y and py <= self.y + self.h
end

-- Разбиение квадранта на 4 дочерних
function QuadWorld.Quadrant:subdivide()
    if not self.isLeaf or self.depth >= self.world.maxDepth then 
        return false 
    end
    
    if self.w/2 < self.world.minSize or self.h/2 < self.world.minSize then
        return false
    end
    
    local halfW = self.w / 2
    local halfH = self.h / 2
    local newDepth = self.depth + 1
    
    self.children[1] = QuadWorld.Quadrant.new(self.x, self.y, halfW, halfH, newDepth, self.world)
    self.children[2] = QuadWorld.Quadrant.new(self.x + halfW, self.y, halfW, halfH, newDepth, self.world)
    self.children[3] = QuadWorld.Quadrant.new(self.x, self.y + halfH, halfW, halfH, newDepth, self.world)
    self.children[4] = QuadWorld.Quadrant.new(self.x + halfW, self.y + halfH, halfW, halfH, newDepth, self.world)
    
    -- Присваиваем ID детям
    for i, child in ipairs(self.children) do
        child.id = self.id and (self.id .. "." .. i) or tostring(i)
    end
    
    self.isLeaf = false
    
    -- Перераспределяем объекты
    for _, obj in ipairs(self.objects) do
        self:addObjectToChildren(obj)
    end
    
    return true
end

-- Добавление объекта в дочерние квадранты
function QuadWorld.Quadrant:addObjectToChildren(obj)
    for _, child in ipairs(self.children) do
        if child:contains(obj.x, obj.y) then
            table.insert(child.objects, obj)
            obj.currentQuad = child
            break
        end
    end
end

-- Поиск квадранта по точке
function QuadWorld.Quadrant:find(px, py)
    if not self:contains(px, py) then
        return nil
    end
    
    if self.isLeaf then
        return self
    end
    
    for _, child in ipairs(self.children) do
        local found = child:find(px, py)
        if found then
            return found
        end
    end
    
    return self -- fallback
end

--[[
    Класс объекта для автоматического отслеживания
]]
QuadWorld.Object = {}
QuadWorld.Object.__index = QuadWorld.Object

function QuadWorld.Object.new(x, y, options)
    options = options or {}
    
    local self = setmetatable({}, QuadWorld.Object)
    
    self.x = x or 0
    self.y = y or 0
    self.w = options.w or 20
    self.h = options.h or 20
    self.type = options.type or "default"
    self.color = options.color or {1, 1, 1}
    self.data = options.data or {}
    
    self.id = options.id or tostring(math.random(1000, 9999))
    self.currentQuad = nil
    self.visible = true
    
    return self
end

-- Обновление позиции объекта
function QuadWorld.Object:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Получение позиции
function QuadWorld.Object:getPosition()
    return self.x, self.y
end

--[[
    Методы библиотеки QuadWorld
]]

-- Добавление объекта в мир
function QuadWorld:addObject(obj)
    table.insert(self.objects, obj)
    
    -- Помещаем в корневой квадрант
    if not obj.currentQuad then
        table.insert(self.root.objects, obj)
        obj.currentQuad = self.root
    end
end

-- Удаление объекта из мира
function QuadWorld:removeObject(obj)
    for i, o in ipairs(self.objects) do
        if o == obj then
            table.remove(self.objects, i)
            break
        end
    end
    
    if obj.currentQuad then
        for i, o in ipairs(obj.currentQuad.objects) do
            if o == obj then
                table.remove(obj.currentQuad.objects, i)
                break
            end
        end
    end
end

-- Создание и добавление нового объекта
function QuadWorld:createObject(x, y, options)
    local obj = QuadWorld.Object.new(x, y, options)
    self:addObject(obj)
    return obj
end

-- Автоматическое разбиение мира
function QuadWorld:autoSubdivide(quad)
    quad = quad or self.root
    
    if quad.isLeaf then
        if #quad.objects > 4 and quad.depth < self.maxDepth then
            if quad:subdivide() then
                -- Рекурсивно разбиваем детей
                for _, child in ipairs(quad.children) do
                    self:autoSubdivide(child)
                end
            end
        end
    else
        for _, child in ipairs(quad.children) do
            self:autoSubdivide(child)
        end
    end
end

-- Обновление всех объектов (вызывать в love.update)
function QuadWorld:update(dt)
    for _, obj in ipairs(self.objects) do
        if obj.currentQuad then
            -- Проверяем, нужно ли обновить квадрант
            if not obj.currentQuad:contains(obj.x, obj.y) then
                -- Ищем новый квадрант
                local newQuad = self.root:find(obj.x, obj.y)
                
                if newQuad and newQuad ~= obj.currentQuad then
                    -- Удаляем из старого
                    for i, o in ipairs(obj.currentQuad.objects) do
                        if o == obj then
                            table.remove(obj.currentQuad.objects, i)
                            break
                        end
                    end
                    
                    -- Добавляем в новый
                    table.insert(newQuad.objects, obj)
                    obj.currentQuad = newQuad
                    newQuad.visited = true
                end
            end
        end
    end
end

-- Поиск объектов в радиусе
function QuadWorld:findObjectsInRadius(x, y, radius, quad)
    quad = quad or self.root
    local result = {}
    
    -- Проверяем, пересекается ли квадрант с кругом
    local closestX = math.max(quad.x, math.min(x, quad.x + quad.w))
    local closestY = math.max(quad.y, math.min(y, quad.y + quad.h))
    local dx = x - closestX
    local dy = y - closestY
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist > radius then
        return result
    end
    
    -- Если лист, проверяем объекты
    if quad.isLeaf then
        for _, obj in ipairs(quad.objects) do
            local dx = x - obj.x
            local dy = y - obj.y
            local d = math.sqrt(dx*dx + dy*dy)
            if d <= radius then
                table.insert(result, obj)
            end
        end
    else
        -- Рекурсивно проверяем детей
        for _, child in ipairs(quad.children) do
            local found = self:findObjectsInRadius(x, y, radius, child)
            for _, obj in ipairs(found) do
                table.insert(result, obj)
            end
        end
    end
    
    return result
end

-- Поиск объектов по типу
function QuadWorld:findObjectsByType(type)
    local result = {}
    for _, obj in ipairs(self.objects) do
        if obj.type == type then
            table.insert(result, obj)
        end
    end
    return result
end

-- Получение квадранта по точке
function QuadWorld:getQuadrantAt(x, y)
    return self.root:find(x, y)
end

-- Сброс посещенных квадрантов
function QuadWorld:resetVisited(quad)
    quad = quad or self.root
    quad.visited = false
    
    if not quad.isLeaf then
        for _, child in ipairs(quad.children) do
            self:resetVisited(child)
        end
    end
end

-- Полная очистка
function QuadWorld:clear()
    self.objects = {}
    self.root = QuadWorld.Quadrant.new(0, 0, self.width, self.height, 1, self)
    self.root.id = "root"
end

-- Визуализация (вызывать в love.draw)
function QuadWorld:draw(highlightX, highlightY)
    self:drawQuadrant(self.root, highlightX, highlightY)
    
    if self.showObjects then
        self:drawObjects()
    end
    
    if self.debugMode then
        self:drawDebug()
    end
end

function QuadWorld:drawQuadrant(quad, highlightX, highlightY)
    -- Определяем, нужно ли подсвечивать
    local highlight = false
    if self.highlightCurrent and highlightX and highlightY then
        highlight = quad:contains(highlightX, highlightY)
    end
    
    -- Рисуем заливку
    if quad.visited then
        love.graphics.setColor(quad.color[1], quad.color[2], quad.color[3], 0.2)
        love.graphics.rectangle("fill", quad.x, quad.y, quad.w, quad.h)
    end
    
    if highlight then
        love.graphics.setColor(1, 1, 0, 0.3)
        love.graphics.rectangle("fill", quad.x, quad.y, quad.w, quad.h)
    end
    
    -- Рисуем сетку
    if self.showGrid then
        local alpha = 0.2 + (quad.depth * 0.1)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", quad.x, quad.y, quad.w, quad.h)
    end
    
    -- Рисуем ID
    if self.showIds and quad.id then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.print(quad.id, quad.x + 2, quad.y + 2)
    end
    
    -- Количество объектов
    if self.debugMode and #quad.objects > 0 then
        love.graphics.setColor(0, 1, 0, 0.7)
        love.graphics.print(#quad.objects, quad.x + quad.w - 15, quad.y + 2)
    end
    
    -- Рекурсивно рисуем детей
    if not quad.isLeaf then
        for _, child in ipairs(quad.children) do
            self:drawQuadrant(child, highlightX, highlightY)
        end
    end
end

function QuadWorld:drawObjects()
    for _, obj in ipairs(self.objects) do
        if obj.visible then
            love.graphics.setColor(obj.color[1], obj.color[2], obj.color[3])
            
            if obj.type == "player" then
                love.graphics.circle("fill", obj.x, obj.y, obj.w/2)
                love.graphics.setColor(1, 1, 1)
                love.graphics.circle("line", obj.x, obj.y, obj.w/2)
            else
                love.graphics.rectangle("fill", obj.x - obj.w/2, obj.y - obj.h/2, obj.w, obj.h)
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", obj.x - obj.w/2, obj.y - obj.h/2, obj.w, obj.h)
            end
            
            if self.debugMode then
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.print(obj.id, obj.x - 10, obj.y - 20)
            end
        end
    end
end

function QuadWorld:drawDebug()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("QuadWorld Debug:", 10, 100)
    love.graphics.print("Всего объектов: " .. #self.objects, 10, 120)
    love.graphics.print("Глубина: " .. self.maxDepth, 10, 140)
    love.graphics.print("Мин. размер: " .. self.minSize, 10, 160)
    
    -- Статистика по квадрантам
    local leafCount = 0
    local function countLeaves(quad)
        if quad.isLeaf then
            leafCount = leafCount + 1
        else
            for _, child in ipairs(quad.children) do
                countLeaves(child)
            end
        end
    end
    countLeaves(self.root)
    love.graphics.print("Листьев: " .. leafCount, 10, 180)
end

--[[
    Пример использования библиотеки
]]
function example()
    -- Создаем мир
    local world = QuadWorld.new(800, 600, 50, 4)
    
    -- Настройки отображения
    world.showIds = true
    world.debugMode = true
    
    -- Создаем игрока
    local player = world:createObject(400, 300, {
        type = "player",
        color = {1, 1, 1},
        w = 30,
        h = 30
    })
    
    -- Создаем врагов
    for i = 1, 10 do
        world:createObject(
            math.random(50, 750),
            math.random(50, 550),
            {
                type = "enemy",
                color = {1, 0, 0},
                w = 20,
                h = 20,
                data = {health = 100}
            }
        )
    end
    
    -- Создаем бонусы
    for i = 1, 5 do
        world:createObject(
            math.random(50, 750),
            math.random(50, 550),
            {
                type = "powerup",
                color = {0, 1, 0},
                w = 15,
                h = 15
            }
        )
    end
    
    -- Автоматическое разбиение
    world:autoSubdivide()
    
    return world, player
end

-- Возвращаем библиотеку
return QuadWorld