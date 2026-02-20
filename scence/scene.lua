-- scene.lua
-- Простая система сцен для Love2D

local SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager.new()
    local self = setmetatable({}, SceneManager)
    self.scenes = {}           -- таблица всех зарегистрированных сцен
    self.current = nil         -- имя текущей сцены
    self.next = nil            -- следующая сцена (для перехода)
    self.transition = nil      -- эффект перехода
    self.transitionTimer = 0
    self.transitionDuration = 0.5
    self.globalData = {}       -- глобальные данные, доступные всем сценам
    return self
end

-- Регистрация сцены
function SceneManager:register(name, scene)
    self.scenes[name] = scene
    scene.manager = self
    scene.name = name
end

-- Переключение на сцену (мгновенно)
function SceneManager:switch(name, ...)
    if not self.scenes[name] then
        error("Scene '" .. name .. "' not found")
    end
    
    -- Вызываем onLeave для текущей сцены
    if self.current and self.scenes[self.current].onLeave then
        self.scenes[self.current]:onLeave()
    end
    
    -- Сохраняем аргументы для следующей сцены
    self.next = name
    self.nextArgs = {...}
end

-- Переключение с эффектом перехода
function SceneManager:switchWithTransition(name, transition, duration, ...)
    if not self.scenes[name] then
        error("Scene '" .. name .. "' not found")
    end
    
    self.transition = transition or "fade"  -- "fade", "slide", "zoom"
    self.transitionDuration = duration or 0.5
    self.transitionTimer = 0
    self.next = name
    self.nextArgs = {...}
end

-- Обновление сцен
function SceneManager:update(dt)
    -- Обработка перехода
    if self.next then
        self.transitionTimer = self.transitionTimer + dt
        
        if self.transitionTimer >= self.transitionDuration then
            -- Переход завершён
            self:_doSwitch()
        end
    end
    
    -- Обновляем текущую сцену
    if self.current then
        local scene = self.scenes[self.current]
        if scene.update then
            scene:update(dt)
        end
    end
end

-- Выполнить переключение
function SceneManager:_doSwitch()
    -- Вызываем onLeave для старой сцены
    if self.current and self.scenes[self.current].onLeave then
        self.scenes[self.current]:onLeave()
    end
    
    -- Переключаемся
    self.current = self.next
    self.next = nil
    
    -- Вызываем onEnter для новой сцены
    if self.scenes[self.current].onEnter then
        self.scenes[self.current]:onEnter(unpack(self.nextArgs or {}))
    end
    
    self.transition = nil
    self.nextArgs = nil
end

-- Отрисовка сцен
function SceneManager:draw()
    -- Рисуем текущую сцену
    if self.current then
        local scene = self.scenes[self.current]
        if scene.draw then
            scene:draw()
        end
    end
    
    -- Рисуем эффект перехода
    if self.transition and self.transitionTimer < self.transitionDuration then
        self:_drawTransition()
    end
end

-- Эффекты перехода
function SceneManager:_drawTransition()
    local alpha = self.transitionTimer / self.transitionDuration
    
    if self.transition == "fade" then
        -- Затемнение
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
    elseif self.transition == "slide" then
        -- Слайд
        local w = love.graphics.getWidth()
        local x = w * (1 - alpha)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", x, 0, w, love.graphics.getHeight())
        
    elseif self.transition == "zoom" then
        -- Зум
        local scale = 1 + (1 - alpha) * 0.5
        love.graphics.push()
        love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
        love.graphics.scale(scale, scale)
        love.graphics.translate(-love.graphics.getWidth()/2, -love.graphics.getHeight()/2)
        love.graphics.setColor(0, 0, 0, 1 - alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.pop()
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Обработка событий
function SceneManager:mousepressed(x, y, button)
    if self.current and self.scenes[self.current].mousepressed then
        self.scenes[self.current]:mousepressed(x, y, button)
    end
end

function SceneManager:mousereleased(x, y, button)
    if self.current and self.scenes[self.current].mousereleased then
        self.scenes[self.current]:mousereleased(x, y, button)
    end
end

function SceneManager:mousemoved(x, y, dx, dy)
    if self.current and self.scenes[self.current].mousemoved then
        self.scenes[self.current]:mousemoved(x, y, dx, dy)
    end
end

function SceneManager:keypressed(key)
    if self.current and self.scenes[self.current].keypressed then
        self.scenes[self.current]:keypressed(key)
    end
end

function SceneManager:keyreleased(key)
    if self.current and self.scenes[self.current].keyreleased then
        self.scenes[self.current]:keyreleased(key)
    end
end

function SceneManager:textinput(t)
    if self.current and self.scenes[self.current].textinput then
        self.scenes[self.current]:textinput(t)
    end
end

function SceneManager:wheelmoved(x, y)
    if self.current and self.scenes[self.current].wheelmoved then
        self.scenes[self.current]:wheelmoved(x, y)
    end
end

-- Получить текущую сцену
function SceneManager:getCurrentScene()
    return self.scenes[self.current]
end

-- Получить данные сцены
function SceneManager:getSceneData(name)
    return self.scenes[name] and self.scenes[name].data
end

return SceneManager