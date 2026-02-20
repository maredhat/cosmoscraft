local SimpleSettingsScene = {}
SimpleSettingsScene.__index = SimpleSettingsScene

function SimpleSettingsScene.new(manager, settings)
    local self = setmetatable({}, SimpleSettingsScene)
    self.manager = manager
    self.settings = settings

    self.title = "SETTINGS"

    -- текущие значения из настроек
    self.fullscreen = settings:get("fullscreen")
    self.vsync = settings:get("vsync")
    self.showFPS = settings:get("showFPS") or false
    self.masterVolume = settings:get("masterVolume") or 1.0
    self.musicVolume = settings:get("musicVolume") or 0.7
    self.sfxVolume = settings:get("sfxVolume") or 0.8

    -- временные копии (для отмены)
    self.tempFullscreen = self.fullscreen
    self.tempVsync = self.vsync
    self.tempShowFPS = self.showFPS
    self.tempMasterVolume = self.masterVolume
    self.tempMusicVolume = self.musicVolume
    self.tempSfxVolume = self.sfxVolume

    self.hoveredButton = nil
    self.activeSlider = nil

    self.fontLarge = love.graphics.newFont(48)
    self.fontMedium = love.graphics.newFont(24)
    self.fontSmall = love.graphics.newFont(18)

    self.colors = {
        bg = {0.05, 0.05, 0.12, 1},
        panel = {0.12, 0.12, 0.2, 0.95},
        border = {0.3, 0.4, 0.8, 0.5},
        button = {0.2, 0.2, 0.3, 1},
        buttonHover = {0.3, 0.3, 0.5, 1},
        text = {0.9, 0.9, 1, 1},
        textDim = {0.6, 0.6, 0.8, 1},
        sliderBg = {0.3, 0.3, 0.5, 1},
        sliderFill = {0.5, 0.7, 1, 1},
        sliderHandle = {0.9, 0.9, 1, 1},
        success = {0.3, 1, 0.3, 1},
        error = {1, 0.3, 0.3, 1},
    }

    self:updateButtonPositions()
    return self
end

function SimpleSettingsScene:updateButtonPositions()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local cx = w / 2
    local startY = h * 0.25

    self.buttons = {
        {
            type = "toggle",
            label = "FULLSCREEN",
            get = function() return self.tempFullscreen end,
            set = function(v) self.tempFullscreen = v end,
            x = cx,
            y = startY,
            width = 400,
            height = 50,
        },
        {
            type = "toggle",
            label = "V-SYNC",
            get = function() return self.tempVsync end,
            set = function(v) self.tempVsync = v end,
            x = cx,
            y = startY + 70,
            width = 400,
            height = 50,
        },
        {
            type = "toggle",
            label = "SHOW FPS",
            get = function() return self.tempShowFPS end,
            set = function(v) self.tempShowFPS = v end,
            x = cx,
            y = startY + 140,
            width = 400,
            height = 50,
        },
        {
            type = "slider",
            label = "MASTER VOLUME",
            get = function() return self.tempMasterVolume end,
            set = function(v) self.tempMasterVolume = v end,
            x = cx,
            y = startY + 230,
            width = 400,
            height = 50,
            min = 0, max = 1,
            format = function(v) return math.floor(v * 100) .. "%" end,
        },
        {
            type = "slider",
            label = "MUSIC VOLUME",
            get = function() return self.tempMusicVolume end,
            set = function(v) self.tempMusicVolume = v end,
            x = cx,
            y = startY + 300,
            width = 400,
            height = 50,
            min = 0, max = 1,
            format = function(v) return math.floor(v * 100) .. "%" end,
        },
        {
            type = "slider",
            label = "SFX VOLUME",
            get = function() return self.tempSfxVolume end,
            set = function(v) self.tempSfxVolume = v end,
            x = cx,
            y = startY + 370,
            width = 400,
            height = 50,
            min = 0, max = 1,
            format = function(v) return math.floor(v * 100) .. "%" end,
        },
        {
            type = "button",
            label = "APPLY",
            x = cx - 110,
            y = h * 0.8,
            width = 200,
            height = 60,
            action = function()
                -- применяем временные значения к реальным
                self.fullscreen = self.tempFullscreen
                self.vsync = self.tempVsync
                self.showFPS = self.tempShowFPS
                self.masterVolume = self.tempMasterVolume
                self.musicVolume = self.tempMusicVolume
                self.sfxVolume = self.tempSfxVolume

                self.settings:set("fullscreen", self.fullscreen)
                self.settings:set("vsync", self.vsync)
                self.settings:set("showFPS", self.showFPS)
                self.settings:set("masterVolume", self.masterVolume)
                self.settings:set("musicVolume", self.musicVolume)
                self.settings:set("sfxVolume", self.sfxVolume)
            end,
        },
        {
            type = "button",
            label = "BACK",
            x = cx + 110,
            y = h * 0.8,
            width = 200,
            height = 60,
            action = function()
                self.manager:switch("menu")
            end,
        },
    }
end

function SimpleSettingsScene:onEnter()
    -- сброс временных значений при входе
    self.tempFullscreen = self.fullscreen
    self.tempVsync = self.vsync
    self.tempShowFPS = self.showFPS
    self.tempMasterVolume = self.masterVolume
    self.tempMusicVolume = self.musicVolume
    self.tempSfxVolume = self.sfxVolume
    self:updateButtonPositions()
end

function SimpleSettingsScene:update(dt)
    local mx, my = love.mouse.getPosition()

    self.hoveredButton = nil
    for i, btn in ipairs(self.buttons) do
        if btn.type ~= "slider" then
            local left = btn.x - btn.width/2
            local right = btn.x + btn.width/2
            local top = btn.y - btn.height/2
            local bottom = btn.y + btn.height/2
            if mx >= left and mx <= right and my >= top and my <= bottom then
                self.hoveredButton = i
                break
            end
        end
    end

    if self.activeSlider then
        local btn = self.buttons[self.activeSlider]
        local left = btn.x - btn.width/2
        local right = btn.x + btn.width/2
        local t = (mx - left) / (right - left)
        t = math.max(0, math.min(1, t))
        local val = btn.min + (btn.max - btn.min) * t
        btn.set(val)  -- обновляем временное значение
    end
end

function SimpleSettingsScene:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    love.graphics.setColor(self.colors.bg)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(self.colors.panel)
    love.graphics.rectangle("fill", w*0.1, h*0.1, w*0.8, h*0.8, 20)
    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", w*0.1, h*0.1, w*0.8, h*0.8, 20)

    love.graphics.setColor(self.colors.text)
    love.graphics.setFont(self.fontLarge)
    local titleW = self.fontLarge:getWidth(self.title)
    love.graphics.print(self.title, w/2 - titleW/2, h*0.12)

    love.graphics.setFont(self.fontMedium)

    for i, btn in ipairs(self.buttons) do
        local x = btn.x - btn.width/2
        local y = btn.y - btn.height/2

        if btn.type == "slider" then
            local val = btn.get()
            -- текст слайдера
            love.graphics.setColor(self.colors.text)
            love.graphics.print(btn.label, x, y - 25)

            -- фон
            love.graphics.setColor(self.colors.sliderBg)
            love.graphics.rectangle("fill", x, y + 15, btn.width, 8, 4)

            -- заполнение
            local fillW = val * btn.width
            love.graphics.setColor(self.colors.sliderFill)
            love.graphics.rectangle("fill", x, y + 15, fillW, 8, 4)

            -- ручка
            local handleX = x + fillW
            if i == self.activeSlider then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.circle("fill", handleX, y + 19, 10)
            else
                love.graphics.setColor(self.colors.sliderHandle)
                love.graphics.circle("fill", handleX, y + 19, 8)
            end

            -- значение справа
            love.graphics.setColor(self.colors.textDim)
            love.graphics.print(btn.format(val), x + btn.width + 20, y + 8)

        elseif btn.type == "toggle" then
            local val = btn.get()
            local color = (i == self.hoveredButton) and self.colors.buttonHover or self.colors.button
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", x, y, btn.width, btn.height, 10)

            love.graphics.setColor(self.colors.border)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, btn.width, btn.height, 10)

            love.graphics.setColor(self.colors.text)
            love.graphics.print(btn.label, x + 20, y + 15)

            local state = val and "ON" or "OFF"
            local stateColor = val and self.colors.success or self.colors.error
            love.graphics.setColor(stateColor)
            love.graphics.print(state, x + btn.width - 70, y + 15)

        elseif btn.type == "button" then
            local color = (i == self.hoveredButton) and self.colors.buttonHover or self.colors.button
            if btn.label == "APPLY" then
                color = self.colors.success
            elseif btn.label == "BACK" then
                color = self.colors.error
            end
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", x, y, btn.width, btn.height, 10)

            love.graphics.setColor(self.colors.border)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, btn.width, btn.height, 10)

            love.graphics.setColor(self.colors.text)
            local textW = self.fontMedium:getWidth(btn.label)
            love.graphics.print(btn.label, btn.x - textW/2, y + 18)
        end
    end

    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(self.colors.textDim)
    local hint = "ESC to return • Changes apply after APPLY"
    local hintW = self.fontSmall:getWidth(hint)
    love.graphics.print(hint, w/2 - hintW/2, h - 40)
end

function SimpleSettingsScene:mousepressed(x, y, button)
    if button ~= 1 then return end

    for i, btn in ipairs(self.buttons) do
        local left = btn.x - btn.width/2
        local right = btn.x + btn.width/2
        local top = btn.y - btn.height/2
        local bottom = btn.y + btn.height/2
        if x >= left and x <= right and y >= top and y <= bottom then
            if btn.type == "slider" then
                self.activeSlider = i
                local t = (x - left) / (right - left)
                t = math.max(0, math.min(1, t))
                local val = btn.min + (btn.max - btn.min) * t
                btn.set(val)
            elseif btn.type == "toggle" then
                btn.set(not btn.get())
            elseif btn.type == "button" then
                btn.action()
            end
            return
        end
    end
    self.activeSlider = nil
end

function SimpleSettingsScene:mousereleased(x, y, button)
    if button == 1 then self.activeSlider = nil end
end

function SimpleSettingsScene:mousemoved(x, y, dx, dy)
    if self.activeSlider then
        local btn = self.buttons[self.activeSlider]
        local left = btn.x - btn.width/2
        local right = btn.x + btn.width/2
        local t = (x - left) / (right - left)
        t = math.max(0, math.min(1, t))
        local val = btn.min + (btn.max - btn.min) * t
        btn.set(val)
    end
end

function SimpleSettingsScene:keypressed(key)
    if key == "escape" then
        self.manager:switch("menu")
    end
end

return SimpleSettingsScene