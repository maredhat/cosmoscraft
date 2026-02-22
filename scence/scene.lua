local SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager.new()
    local self = setmetatable({}, SceneManager)
    self.scenes = {}
    self.current = nil
    self.next = nil
    self.transition = nil
    self.transitionTimer = 0
    self.transitionDuration = 0.5
    self.globalData = {}
    return self
end

function SceneManager:register(name, scene)
    self.scenes[name] = scene
    scene.manager = self
    scene.name = name
end

function SceneManager:unregister(name)
    if self.scenes[name] then
        if self.current == name then
            self.current = nil
        end
        self.scenes[name] = nil
    end
end

function SceneManager:switch(name, ...)
    if not self.scenes[name] then
        error("Scene '" .. name .. "' not found")
    end
    if self.current and self.scenes[self.current].onLeave then
        self.scenes[self.current]:onLeave()
    end
    self.next = name
    self.nextArgs = {...}
    self:_doSwitch()
end

function SceneManager:switchWithTransition(name, transition, duration, ...)
    if not self.scenes[name] then
        error("Scene '" .. name .. "' not found")
    end
    self.transition = transition or "fade"
    self.transitionDuration = duration or 0.5
    self.transitionTimer = 0
    self.next = name
    self.nextArgs = {...}
end

function SceneManager:update(dt)
    if self.next then
        self.transitionTimer = self.transitionTimer + dt
        if self.transitionTimer >= self.transitionDuration then
            self:_doSwitch()
        end
    end
    if self.current then
        local scene = self.scenes[self.current]
        if scene and scene.update then
            scene:update(dt)
        end
    end
end

function SceneManager:_doSwitch()
    if self.current and self.scenes[self.current] and self.scenes[self.current].onLeave then
        self.scenes[self.current]:onLeave()
    end
    self.current = self.next
    self.next = nil
    if self.scenes[self.current] and self.scenes[self.current].onEnter then
        self.scenes[self.current]:onEnter(unpack(self.nextArgs or {}))
    end
    self.transition = nil
    self.nextArgs = nil
end

function SceneManager:draw()
    if self.current then
        local scene = self.scenes[self.current]
        if scene and scene.draw then
            scene:draw()
        end
    end
    if self.transition and self.transitionTimer < self.transitionDuration then
        self:_drawTransition()
    end
end

function SceneManager:_drawTransition()
    local alpha = self.transitionTimer / self.transitionDuration
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    if self.transition == "fade" then
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)
    elseif self.transition == "slide" then
        local x = w * (1 - alpha)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", x, 0, w, h)
    elseif self.transition == "zoom" then
        local scale = 1 + (1 - alpha) * 0.5
        love.graphics.push()
        love.graphics.translate(w/2, h/2)
        love.graphics.scale(scale, scale)
        love.graphics.translate(-w/2, -h/2)
        love.graphics.setColor(0, 0, 0, 1 - alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.pop()
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function SceneManager:mousepressed(x, y, button)
    if self.current and self.scenes[self.current] and self.scenes[self.current].mousepressed then
        self.scenes[self.current]:mousepressed(x, y, button)
    end
end

function SceneManager:mousereleased(x, y, button)
    if self.current and self.scenes[self.current] and self.scenes[self.current].mousereleased then
        self.scenes[self.current]:mousereleased(x, y, button)
    end
end

function SceneManager:mousemoved(x, y, dx, dy)
    if self.current and self.scenes[self.current] and self.scenes[self.current].mousemoved then
        self.scenes[self.current]:mousemoved(x, y, dx, dy)
    end
end

function SceneManager:keypressed(key)
    if self.current and self.scenes[self.current] and self.scenes[self.current].keypressed then
        self.scenes[self.current]:keypressed(key)
    end
end

function SceneManager:keyreleased(key)
    if self.current and self.scenes[self.current] and self.scenes[self.current].keyreleased then
        self.scenes[self.current]:keyreleased(key)
    end
end

function SceneManager:textinput(t)
    if self.current and self.scenes[self.current] and self.scenes[self.current].textinput then
        self.scenes[self.current]:textinput(t)
    end
end

function SceneManager:wheelmoved(x, y)
    if self.current and self.scenes[self.current] and self.scenes[self.current].wheelmoved then
        self.scenes[self.current]:wheelmoved(x, y)
    end
end

function SceneManager:getCurrentScene()
    return self.scenes[self.current]
end

function SceneManager:getScene(name)
    return self.scenes[name]
end

function SceneManager:getSceneData(name)
    return self.scenes[name] and self.scenes[name].data
end

function SceneManager:setGlobal(key, value)
    self.globalData[key] = value
end

function SceneManager:getGlobal(key)
    return self.globalData[key]
end

return SceneManager