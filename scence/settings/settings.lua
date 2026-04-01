-- scenes/settings_scene.lua
local Frame     = require 'lib.gui.frame'
local Lists     = require 'lib.gui.lists'
local Button    = require 'lib.gui.button'
local TextInput = require 'lib.gui.textbox'

local ParallaxBackground
local hasParallax, parallaxLib = pcall(require, 'lib.effects.parallax')
if hasParallax then
    ParallaxBackground = parallaxLib
else
    ParallaxBackground = { new = function() return { update = function() end, draw = function() end } end }
end

local SettingsScene = {}
SettingsScene.__index = SettingsScene

function SettingsScene.new(manager, settings)
    local self = setmetatable({}, SettingsScene)
    self.manager = manager
    self.settings = settings

    self.tabs = {
        { name = "SOUNDS",   id = "sounds" },
        { name = "GRAPHICS", id = "graphics" },
        { name = "GAMEPLAY", id = "gameplay" },
    }
    self.activeTab = "sounds"

-- scenes/settings_scene.lua (добавленные опции)
-- Вставьте в соответствующие секции self.options

    self.options = {
        sounds = {
            { name = "Master Volume",  key = "masterVolume", type = "slider", min = 0, max = 1, default = 1.0 },
            { name = "Music Volume",   key = "musicVolume",  type = "slider", min = 0, max = 1, default = 0.7 },
            { name = "SFX Volume",     key = "sfxVolume",    type = "slider", min = 0, max = 1, default = 0.8 },
        },
        graphics = {
            { name = "Fullscreen",        key = "fullscreen", type = "toggle", default = false },
            { name = "VSync",              key = "vsync",      type = "toggle", default = false },
            { name = "Show FPS",           key = "showFPS",    type = "toggle", default = false },
            { name = "Screen Shake",        key = "screenShake",type = "toggle", default = true },
        },
        gameplay = {
            { name = "Auto Save",           key = "autoSave",   type = "toggle", default = true },
            { name = "Mouse Sensitivity",    key = "sensitivity",type = "slider", min = 0.1, max = 2.0, default = 1.0 },
            { name = "Camera Smoothness",    key = "cameraSmoothness", type = "slider", min = 0.01, max = 0.5, default = 0.1 },
            { name = "Invert Y",             key = "invertY",    type = "toggle", default = false },
            { name = "Show HUD",             key = "showHUD",    type = "toggle", default = true },
            { name = "Damage Numbers",       key = "damageNumbers", type = "toggle", default = true },
            { name = "Difficulty",           key = "difficulty", type = "dropdown", default = "Normal", options = {"Easy", "Normal", "Hard"} },
            { name = "Controller Vibration", key = "vibration",  type = "toggle", default = true },
        }
    }

    self.values = {}
    for cat, opts in pairs(self.options) do
        for _, opt in ipairs(opts) do
            self.values[opt.key] = settings:get(opt.key) or opt.default
        end
    end

    self.tempValues = {}
    for k, v in pairs(self.values) do
        self.tempValues[k] = v
    end

    self.fontLarge = love.graphics.newFont(64)
    self.fontMedium = love.graphics.newFont(28)
    self.fontSmall = love.graphics.newFont(22)

    self.colors = {
        deepSpace  = {0.02, 0.02, 0.04, 1},
        nebula1    = {0.1, 0.08, 0.15, 0.2},
        nebula2    = {0.08, 0.1, 0.18, 0.15},
        nebula3    = {0.15, 0.08, 0.15, 0.1},
        accentSoft = {0.5, 0.6, 0.8, 1},
        textBright = {0.9, 0.9, 0.95, 1},
        textSoft   = {0.6, 0.6, 0.7, 1},
        panelBg    = {0.03, 0.03, 0.06, 0.95},
        shadow     = {0, 0, 0, 0.6},
        applyColor = {0.2, 0.5, 0.2, 1},
        backColor  = {0.5, 0.2, 0.2, 1},
        tabInactive = {0.1, 0.1, 0.14, 0.8},
        tabActive   = {0.2, 0.2, 0.3, 1},
    }

    self.root = Frame.new(0, 0, love.graphics.getWidth(), love.graphics.getHeight(), {}, true)
    self.root.render = function() end

    self.parallax = ParallaxBackground.new({
        { color = self.colors.nebula1, speed = 0.03, size = 1.5 },
        { color = self.colors.nebula2, speed = 0.02, size = 2 },
        { color = self.colors.nebula3, speed = 0.01, size = 2.5 },
    })

    self.stars = {}
    for i = 1, 200 do
        table.insert(self.stars, {
            x = math.random(0, love.graphics.getWidth()),
            y = math.random(0, love.graphics.getHeight()),
            size = math.random(1, 3),
            speed = math.random(10, 30) / 100,
            phase = math.random() * 2 * math.pi,
        })
    end

    self.searchInput = TextInput.new(0, 0, 400, 50, {
        placeholder = "Search settings...",
        fontSize = 24,
        bgColor = self.colors.panelBg,
        textColor = self.colors.textBright,
        placeholderColor = self.colors.textSoft,
        focusBorderColor = self.colors.accentSoft,
    })

    local scene = self
    self.lists = {}
    for _, tab in ipairs(self.tabs) do
        self.lists[tab.id] = Lists.new(0, 0, 600, 400, {}, true, {
            padding = { left = 10, right = 10, top = 10, bottom = 10 },
            stretch = true,
            itemHeight = 70,
            spacing = 5,
            hoverToScroll = true,
            showScrollbar = true,
            scrollbarColor = self.colors.accentSoft,
            scrollbarThumbColor = self.colors.textBright,
        })

        self.lists[tab.id].render = function(self)
            love.graphics.setColor(scene.colors.panelBg)
            love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 12)
            love.graphics.setColor(scene.colors.accentSoft)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 12)
        end
    end

    self.tabButtons = {}
    local tabW, tabH = 200, 60
    for i, tab in ipairs(self.tabs) do
        self.tabButtons[tab.id] = Button.new(0, 0, tabW, tabH, tab.name, {
            bgColor = self.colors.tabInactive,
            hoverColor = self.colors.tabActive,
            pressColor = self.colors.accentSoft,
            textColor = self.colors.textBright,
            font = self.fontMedium,
            onClick = function()
                self.activeTab = tab.id
                self:updateTabButtons()
                self:updateAllLists()
            end
        })
    end

    self.btnApply = Button.new(0, 0, 200, 60, "APPLY", {
        bgColor    = self.colors.applyColor,
        hoverColor = {0.3,0.6,0.3,1},
        pressColor = {0.1,0.3,0.1,1},
        textColor  = self.colors.textBright,
        font = self.fontMedium,
        onClick = function()
            for k, v in pairs(self.tempValues) do
                self.values[k] = v
                self.settings:set(k, v)
            end
        end
    })

    self.btnBack = Button.new(0, 0, 200, 60, "BACK", {
        bgColor    = self.colors.backColor,
        hoverColor = {0.6,0.3,0.3,1},
        pressColor = {0.3,0.1,0.1,1},
        textColor  = self.colors.textBright,
        font = self.fontMedium,
        onClick = function()
            self.manager:switchWithTransition("menu", "fade", 0.8, self.settings)
        end
    })

    self:relayout()
    self:updateAllLists()

    self.draggingSlider = nil

    return self
end

function SettingsScene:updateTabButtons()
    for id, btn in pairs(self.tabButtons) do
        if id == self.activeTab then
            btn.bgColor = self.colors.accentSoft
            btn.hoverColor = self.colors.tabActive
        else
            btn.bgColor = self.colors.tabInactive
            btn.hoverColor = self.colors.tabActive
        end
    end
end

function SettingsScene:relayout()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local cx = w / 2
    local panelW, panelH = 1000, 750
    local panelX, panelY = cx - panelW/2, h/2 - panelH/2

    self.searchInput.x = panelX + 50
    self.searchInput.y = panelY + 90
    self.searchInput.w = panelW - 100

    local tabX, tabY = panelX + 50, panelY + 160
    for i, tab in ipairs(self.tabs) do
        self.tabButtons[tab.id].x = tabX + (i-1) * 210
        self.tabButtons[tab.id].y = tabY
    end

    local listX, listY = panelX + 50, panelY + 240
    local listW, listH = panelW - 100, panelH - 340
    for _, list in pairs(self.lists) do
        list.x = listX
        list.y = listY
        list.w = listW
        list.h = listH
    end

    self.btnApply.x = panelX + panelW/2 - 230
    self.btnApply.y = panelY + panelH - 80
    self.btnBack.x = panelX + panelW/2 + 30
    self.btnBack.y = panelY + panelH - 80

    if not self.root.childrens.search then
        self.root:addChildren("search", self.searchInput)
        for id, btn in pairs(self.tabButtons) do
            self.root:addChildren("tab_" .. id, btn)
        end
        for id, list in pairs(self.lists) do
            self.root:addChildren("list_" .. id, list)
        end
        self.root:addChildren("btnApply", self.btnApply)
        self.root:addChildren("btnBack", self.btnBack)
    end
end

function SettingsScene:updateAllLists()
    local filter = self.filterText or ""
    local scene = self

    for cat, list in pairs(self.lists) do
        list.childrens = {}
        list.isVisible = (cat == self.activeTab)

        local visible = {}
        for _, opt in ipairs(self.options[cat]) do
            if opt.name:lower():match(filter) then
                table.insert(visible, opt)
            end
        end

        for idx, opt in ipairs(visible) do
            local key = opt.key
            local checked = scene.tempValues[key]

            local item = {
                parent = list,
                order = idx,
                opt = opt,
                key = key,
                hovered = false,

                update = function(self, dt)
                    local parent = self.parent
                    local mx, my = love.mouse.getPosition()
                    local localX = mx - parent.x
                    local localY = my - parent.y + parent.scrollY
                    self.hovered = localX >= self.x and localX <= self.x + self.w and localY >= self.y and localY <= self.y + self.h
                end,

                draw = function(self)
                    local x, y = self.x, self.y
                    local w, h = self.w, self.h

                    if self.hovered then
                        love.graphics.setColor({0.2,0.18,0.25,0.95})
                    else
                        love.graphics.setColor({0.12,0.1,0.16,0.9})
                    end
                    love.graphics.rectangle("fill", x, y, w, h, 12)

                    love.graphics.setColor(scene.colors.accentSoft)
                    love.graphics.setLineWidth(1)
                    love.graphics.line(x, y, x+w, y)

                    if opt.type == "toggle" then
                        love.graphics.setColor(scene.colors.accentSoft)
                        love.graphics.setLineWidth(2)
                        love.graphics.rectangle("line", x + 15, y + 20, 30, 30, 5)

                        if checked then
                            love.graphics.setColor(scene.colors.accentSoft)
                            love.graphics.setLineWidth(5)
                            love.graphics.line(x + 20, y + 35, x + 30, y + 45, x + 45, y + 20)
                        end

                        love.graphics.setColor(scene.colors.textBright)
                        love.graphics.setFont(scene.fontMedium)
                        love.graphics.print(opt.name, x + 65, y + 24)

                        local stateText = checked and "ENABLED" or "DISABLED"
                        local stateColor = scene.colors.textSoft
                        love.graphics.setColor(stateColor)
                        love.graphics.setFont(scene.fontSmall)
                        local tw = scene.fontSmall:getWidth(stateText)
                        love.graphics.print(stateText, x + w - tw - 20, y + 26)

                    elseif opt.type == "slider" then
                        love.graphics.setColor(scene.colors.textBright)
                        love.graphics.setFont(scene.fontMedium)
                        love.graphics.print(opt.name, x + 15, y + 8)

                        local sliderX = x + 15
                        local sliderY = y + 45
                        local sliderW = w - 30
                        local sliderH = 10

                        love.graphics.setColor(scene.colors.panelBg)
                        love.graphics.rectangle("fill", sliderX, sliderY, sliderW, sliderH, 5)

                        local t = (checked - opt.min) / (opt.max - opt.min)
                        local fillW = t * sliderW
                        love.graphics.setColor(scene.colors.accentSoft)
                        love.graphics.rectangle("fill", sliderX, sliderY, fillW, sliderH, 5)

                        local thumbX = sliderX + fillW
                        love.graphics.setColor(scene.colors.textBright)
                        love.graphics.circle("fill", thumbX, sliderY + sliderH/2, 12)

                        love.graphics.setColor(scene.colors.textSoft)
                        love.graphics.setFont(scene.fontSmall)
                        love.graphics.print(string.format("%.2f", checked), sliderX + sliderW + 20, sliderY - 3)

                    elseif opt.type == "dropdown" then
                        love.graphics.setColor(scene.colors.textBright)
                        love.graphics.setFont(scene.fontMedium)
                        love.graphics.print(opt.name, x + 15, y + 20)

                        love.graphics.setColor(scene.colors.accentSoft)
                        love.graphics.setFont(scene.fontSmall)
                        local value = checked or opt.default
                        love.graphics.print("[" .. value .. "]", x + w - 100, y + 24)
                    end
                end,

                mousepressed = function(self, lx, ly, btn)
                    if btn == 1 then
                        if opt.type == "toggle" then
                            local parent = self.parent
                            local mx, my = love.mouse.getPosition()
                            local absLeft = parent.x + self.x + 15
                            local absRight = parent.x + self.x + 45
                            local absTop = parent.y + self.y + 20
                            local absBottom = parent.y + self.y + 50
                            if mx >= absLeft and mx <= absRight and my >= absTop and my <= absBottom then
                                scene.tempValues[key] = not scene.tempValues[key]
                                scene:updateAllLists()
                            end
                        elseif opt.type == "slider" then
                            local parent = self.parent
                            local mx, my = love.mouse.getPosition()
                            local absSliderX = parent.x + self.x + 15
                            local absSliderY1 = parent.y + self.y + 35
                            local absSliderY2 = parent.y + self.y + 60
                            local sliderW = self.w - 30
                            if mx >= absSliderX and mx <= absSliderX + sliderW and my >= absSliderY1 and my <= absSliderY2 then
                                local t = (mx - absSliderX) / sliderW
                                t = math.max(0, math.min(1, t))
                                local newVal = opt.min + t * (opt.max - opt.min)
                                scene.tempValues[key] = newVal
                                scene.draggingSlider = {
                                    key = key,
                                    sliderX = absSliderX,
                                    sliderW = sliderW,
                                    min = opt.min,
                                    max = opt.max
                                }
                                scene:updateAllLists()
                            end
                        elseif opt.type == "dropdown" then
                            local opts = opt.options or {}
                            local current = scene.tempValues[key] or opt.default
                            local nextIdx = 1
                            for i, v in ipairs(opts) do
                                if v == current then
                                    nextIdx = i % #opts + 1
                                    break
                                end
                            end
                            scene.tempValues[key] = opts[nextIdx]
                            scene:updateAllLists()
                        end
                    end
                end
            }

            list:addChildren("item" .. idx, item)
        end
    end
end

function SettingsScene:onEnter()
    for k, v in pairs(self.values) do
        self.tempValues[k] = v
    end
    self.filterText = ""
    self.searchInput:setText("")
    self.activeTab = "sounds"
    self:updateAllLists()
    self:relayout()
end

function SettingsScene:onResize(w, h)
    self.root.w = w
    self.root.h = h
    self:relayout()
    self:updateAllLists()
end

function SettingsScene:update(dt)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    for _, s in ipairs(self.stars) do
        s.y = s.y + s.speed * dt * 60
        if s.y > h then
            s.y = 0
            s.x = math.random(0, w)
        end
    end

    self.root:update(dt)
    self.parallax:update(dt)

    if self.draggingSlider then
        if love.mouse.isDown(1) then
            local mx, my = love.mouse.getPosition()
            local d = self.draggingSlider
            local t = (mx - d.sliderX) / d.sliderW
            t = math.max(0, math.min(1, t))
            local newVal = d.min + t * (d.max - d.min)
            self.tempValues[d.key] = newVal
            self:updateAllLists()
        else
            self.draggingSlider = nil
        end
    end
end

function SettingsScene:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    self.parallax:draw()

    love.graphics.setColor(1, 1, 1, 0.4)
    for _, s in ipairs(self.stars) do
        local alpha = 0.3 + 0.5 * math.sin(love.timer.getTime() * 3 + s.phase)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.circle("fill", s.x, s.y, s.size)
    end

    local panelW, panelH = 1000, 750
    local panelX, panelY = w/2 - panelW/2, h/2 - panelH/2

    love.graphics.setColor(self.colors.panelBg)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 30)

    love.graphics.setColor(self.colors.accentSoft)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 30)

    love.graphics.setColor(self.colors.textBright)
    love.graphics.setFont(self.fontLarge)
    local title = "SETTINGS"
    local tw = self.fontLarge:getWidth(title)
    love.graphics.print(title, w/2 - tw/2, panelY + 20)

    self.root:draw()
end

function SettingsScene:mousepressed(x, y, button)
    self.root:mousepressed(x, y, button)
end

function SettingsScene:mousereleased(x, y, button)
    self.root:mousereleased(x, y, button)
    if button == 1 then
        self.draggingSlider = nil
    end
end

function SettingsScene:wheelmoved(x, y)
    self.root:wheelmoved(x, y)
end

function SettingsScene:keypressed(key, sc, rep)
    self.root:keypressed(key, sc, rep)
    if key == "escape" then
        self.manager:switchWithTransition("menu", "fade", 0.8, self.settings)
    end
end

function SettingsScene:textinput(t)
    self.root:textinput(t)
end

return SettingsScene