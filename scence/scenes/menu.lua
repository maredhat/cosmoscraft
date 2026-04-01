-- scenes/menu.lua
local Button = require 'lib.gui.button'

local ParallaxBackground
local hasParallax, parallaxLib = pcall(require, 'lib.effects.parallax')
if hasParallax then
    ParallaxBackground = parallaxLib
else
    ParallaxBackground = { new = function() return { update = function() end, draw = function() end } end }
end

local MenuScene = {}
MenuScene.__index = MenuScene

function MenuScene.new(manager, settings)
    local self = setmetatable({}, MenuScene)
    self.manager = manager
    self.settings = settings
    self.title = "Cosmos Craft"
    self.version = "V 0.00d1"

    self.buttons = {}
    self.buttonAlpha = 0
    self.titleScale = 0.8

    self.fontLarge = love.graphics.newFont(72)
    self.fontMedium = love.graphics.newFont(32)
    self.fontSmall = love.graphics.newFont(20)

    self.colors = {
        deepSpace  = {0.02, 0.02, 0.04, 1},
        nebula1    = {0.1, 0.08, 0.15, 0.2},
        nebula2    = {0.08, 0.1, 0.18, 0.15},
        nebula3    = {0.15, 0.08, 0.15, 0.1},
        accentSoft = {0.5, 0.6, 0.8, 1},
        textBright = {0.9, 0.9, 0.95, 1},
        textSoft   = {0.6, 0.6, 0.7, 1},
        buttonBg   = {0.1, 0.1, 0.14, 0.8},
        buttonHover = {0.2, 0.2, 0.3, 1},
        buttonPress = {0.05, 0.05, 0.1, 1},
    }

    self.parallax = ParallaxBackground.new({
        { color = self.colors.nebula1, speed = 0.02, size = 1.5 },
        { color = self.colors.nebula2, speed = 0.01, size = 2 },
        { color = self.colors.nebula3, speed = 0.005, size = 2.5 },
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

    return self
end

function MenuScene:createButtons()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btnW, btnH = 320, 70
    local centerX = w/2 - btnW/2

    self.buttons = {
        Button.new(centerX, h/2 - 90, btnW, btnH, "START GAME", {
            font = self.fontMedium,
            bgColor = self.colors.buttonBg,
            hoverColor = self.colors.buttonHover,
            pressColor = self.colors.buttonPress,
            textColor = self.colors.textBright,
            borderColor = self.colors.accentSoft,
            onClick = function() self.manager:switchWithTransition("save_select", "fade", 0.8, self.settings) end,
        }),
        Button.new(centerX, h/2, btnW, btnH, "SETTINGS", {
            font = self.fontMedium,
            bgColor = self.colors.buttonBg,
            hoverColor = self.colors.buttonHover,
            pressColor = self.colors.buttonPress,
            textColor = self.colors.textBright,
            borderColor = self.colors.accentSoft,
            onClick = function()  self.manager:switchWithTransition("settings", "fade", 0.8, self.settings) end,
        }),
        Button.new(centerX, h/2 + 90, btnW, btnH, "EXIT", {
            font = self.fontMedium,
            bgColor = self.colors.buttonBg,
            hoverColor = self.colors.buttonHover,
            pressColor = self.colors.buttonPress,
            textColor = self.colors.textBright,
            borderColor = self.colors.accentSoft,
            onClick = function() love.event.quit() end,
        }),
    }
end

function MenuScene:onEnter()
    self:createButtons()
    self.buttonAlpha = 0
    self.titleScale = 0.8
    self.timer = 0
end

function MenuScene:update(dt)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    self.parallax:update(dt)

    for _, s in ipairs(self.stars) do
        s.y = s.y + s.speed * dt * 60
        if s.y > h then
            s.y = 0
            s.x = math.random(0, w)
        end
    end

    self.timer = self.timer + dt
    self.buttonAlpha = math.min(1, self.buttonAlpha + dt * 2)
    self.titleScale = 0.8 + 0.2 * (1 - math.exp(-self.timer * 2))

    for _, btn in ipairs(self.buttons) do
        btn:update(dt)
    end
end

function MenuScene:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    self.parallax:draw()

    love.graphics.setColor(1, 1, 1, 0.4)
    for _, s in ipairs(self.stars) do
        local alpha = 0.3 + 0.5 * math.sin(love.timer.getTime() * 3 + s.phase)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.circle("fill", s.x, s.y, s.size)
    end

    love.graphics.setColor(self.colors.textBright)
    love.graphics.setFont(self.fontLarge)

    local titleScale = self.titleScale
    love.graphics.push()
    love.graphics.translate(w/2, 150)
    love.graphics.scale(titleScale, titleScale)
    local tw = self.fontLarge:getWidth(self.title)
    love.graphics.print(self.title, -tw/2, 0)
    love.graphics.pop()

    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(self.colors.textSoft)
    love.graphics.print(self.version, w - 120, h - 40)

    love.graphics.push()
    love.graphics.translate(0, 0)
    love.graphics.setColor(1, 1, 1, self.buttonAlpha)
    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end
    love.graphics.pop()

    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(self.colors.textSoft)
    local hint = "Use mouse to navigate"
    local hw = self.fontSmall:getWidth(hint)
    love.graphics.print(hint, w/2 - hw/2, h - 80)
end

function MenuScene:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:mousepressed(x, y, button)
    end
end

function MenuScene:mousereleased(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:mousereleased(x, y, button)
    end
end

function MenuScene:keypressed(key)

end

return MenuScene