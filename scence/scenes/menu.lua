local MenuScene = {}
MenuScene.__index = MenuScene

function MenuScene.new(manager, settings)
    local self = setmetatable({}, MenuScene)
    self.manager = manager
    self.settings = settings
    self.title = "Cosmos Craft"
    self.version = "V 0.00d1 "
    
    self.buttons = nil
    self.hoveredButton = nil
    
    self.fontLarge = love.graphics.newFont(64)
    self.fontMedium = love.graphics.newFont(28)
    self.fontSmall = love.graphics.newFont(16)
    
    self.particles = {}
    for i = 1, 100 do
        table.insert(self.particles, {
            x = math.random(0, love.graphics.getWidth()),
            y = math.random(0, love.graphics.getHeight()),
            size = math.random(1, 4),
            speed = math.random(10, 50) / 100,
            alpha = math.random(20, 80) / 100
        })
    end
    
    return self
end

function MenuScene:createButtons()
    self.buttons = {
        {
            text = "START GAME",
            x = 0, y = 0,
            width = 300,
            height = 60,
            action = function() self.manager:switch("save_select", self.settings) end
        },
        {
            text = "SETTINGS",
            x = 0, y = 0,
            width = 300,
            height = 60,
            action = function() self.manager:switch("settings", self.settings) end
        },
        {
            text = "EXIT",
            x = 0, y = 0,
            width = 300,
            height = 60,
            action = function() love.event.quit() end
        }
    }
    self:updateButtonPositions()
end

function MenuScene:updateButtonPositions()
    if not self.buttons then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local centerX = w / 2
    self.buttons[1].x = centerX
    self.buttons[1].y = h/2 - 80
    self.buttons[2].x = centerX
    self.buttons[2].y = h/2
    self.buttons[3].x = centerX
    self.buttons[3].y = h/2 + 80
end

function MenuScene:onEnter()
    self:createButtons()
    self.hoveredButton = nil
end

function MenuScene:update(dt)
    if not self.buttons then return end
    local mx, my = love.mouse.getPosition()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    for _, p in ipairs(self.particles) do
        p.y = p.y + p.speed * dt * 60
        if p.y > h then
            p.y = 0
            p.x = math.random(0, w)
        end
    end
    
    self.hoveredButton = nil
    for i, button in ipairs(self.buttons) do
        local left = button.x - button.width / 2
        local right = button.x + button.width / 2
        local top = button.y - button.height / 2
        local bottom = button.y + button.height / 2
        if mx >= left and mx <= right and my >= top and my <= bottom then
            self.hoveredButton = i
            break
        end
    end
end

function MenuScene:draw()
    if not self.buttons then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    love.graphics.setColor(0.05, 0.05, 0.12, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1, 0.3)
    for _, p in ipairs(self.particles) do
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.fontLarge)
    local titleWidth = self.fontLarge:getWidth(self.title)
    love.graphics.print(self.title, w/2 - titleWidth/2, 150)
    
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print(self.version, w - 100, h - 30)
    
    love.graphics.setFont(self.fontMedium)
    for i, button in ipairs(self.buttons) do
        local x = button.x - button.width / 2
        local y = button.y - button.height / 2
        
        if i == self.hoveredButton then
            love.graphics.setColor(0.3, 0.3, 0.5, 1)
            love.graphics.rectangle("fill", x, y, button.width, button.height, 10)
        end
        
        love.graphics.setColor(0.6, 0.6, 0.8, 1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", x, y, button.width, button.height, 10)
        
        love.graphics.setColor(1, 1, 1, 1)
        local textWidth = self.fontMedium:getWidth(button.text)
        love.graphics.print(button.text, button.x - textWidth/2, button.y - 14)
    end
    
    love.graphics.setFont(self.fontSmall)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    local hint = "Use mouse to navigate"
    love.graphics.print(hint, w/2 - self.fontSmall:getWidth(hint)/2, h - 80)
end

function MenuScene:mousepressed(x, y, button)
    if button ~= 1 or not self.buttons then return end
    for _, btn in ipairs(self.buttons) do
        local left = btn.x - btn.width / 2
        local right = btn.x + btn.width / 2
        local top = btn.y - btn.height / 2
        local bottom = btn.y + btn.height / 2
        if x >= left and x <= right and y >= top and y <= bottom then
            btn.action()
            break
        end
    end
end

function MenuScene:keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

return MenuScene