local SaveSelectScene = {}
SaveSelectScene.__index = SaveSelectScene

function SaveSelectScene.new(manager, settings)
    local self = setmetatable({}, SaveSelectScene)
    self.manager = manager
    self.settings = settings
    self.title = "SELECT SAVE FILE"
    
    self.saves = {
        {name = "Save Slot 1", exists = false, time = 0, kills = 0, progress = 0},
        {name = "Save Slot 2", exists = false, time = 0, kills = 0, progress = 0},
        {name = "Save Slot 3", exists = false, time = 0, kills = 0, progress = 0},
    }
    
    self.hoveredSlot = nil
    self.hoveredDelete = nil
    self.hoveredBack = false
    
    self.fontLarge = love.graphics.newFont(48)
    self.fontMedium = love.graphics.newFont(28)
    self.fontSmall = love.graphics.newFont(18)
    
    self:loadSaves()
    
    return self
end

function SaveSelectScene:loadSaves()
    for i = 1, 3 do
        local filename = "data/saves/save_" .. i .. ".lua"
        local success, data = pcall(dofile, filename)
        if success and data then
            self.saves[i].exists = true
            self.saves[i].time = data.time or 0
            self.saves[i].kills = data.kills or 0
            self.saves[i].progress = data.progress or 0
        else
            self.saves[i].exists = false
            self.saves[i].time = 0
            self.saves[i].kills = 0
            self.saves[i].progress = 0
        end
    end
end

function SaveSelectScene:createSave(slot)
    local saveData = {
        time = 0,
        kills = 0,
        progress = 0,
        playerX = 0,
        playerY = 0,
        date = os.date("%Y-%m-%d %H:%M:%S")
    }
    local file = io.open("data/saves/save_" .. slot .. ".lua", "w")
    if file then
        file:write("return {\n")
        for k, v in pairs(saveData) do
            local valueStr = type(v) == "string" and ('"' .. v .. '"') or tostring(v)
            file:write("    " .. k .. " = " .. valueStr .. ",\n")
        end
        file:write("}\n")
        file:close()
    end
    self.saves[slot].exists = true
    self.saves[slot].time = 0
    self.saves[slot].kills = 0
    self.saves[slot].progress = 0
end

function SaveSelectScene:deleteSave(slot)
    local filename = "data/saves/save_" .. slot .. ".lua"
    os.remove(filename)
    self.saves[slot].exists = false
    self.saves[slot].time = 0
    self.saves[slot].kills = 0
    self.saves[slot].progress = 0
end

function SaveSelectScene:onEnter()
    self:loadSaves()
    self.hoveredSlot = nil
    self.hoveredDelete = nil
    self.hoveredBack = false
end

function SaveSelectScene:update(dt)
    local mx, my = love.mouse.getPosition()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    self.hoveredSlot = nil
    self.hoveredDelete = nil
    
    local slotWidth = 300
    local slotHeight = 200
    local startX = w/2 - (slotWidth * 3 + 80) / 2
    local y = h/2 - 100
    
    for i = 1, 3 do
        local x = startX + (i-1) * (slotWidth + 40)
        if mx >= x and mx <= x + slotWidth and my >= y and my <= y + slotHeight then
            self.hoveredSlot = i
        end
        local delX = x + slotWidth - 30
        local delY = y + 20
        if mx >= delX - 15 and mx <= delX + 15 and my >= delY - 15 and my <= delY + 15 then
            self.hoveredDelete = i
        end
    end
    
    local backX = w/2 - 100
    local backY = h - 80
    local backW = 200
    local backH = 50
    self.hoveredBack = (mx >= backX and mx <= backX + backW and my >= backY and my <= backY + backH)
end

function SaveSelectScene:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    love.graphics.setColor(0.05, 0.05, 0.12, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.fontLarge)
    local titleWidth = self.fontLarge:getWidth(self.title)
    love.graphics.print(self.title, w/2 - titleWidth/2, 80)
    
    local slotWidth = 300
    local slotHeight = 200
    local startX = w/2 - (slotWidth * 3 + 80) / 2
    local y = h/2 - 100
    
    for i = 1, 3 do
        local x = startX + (i-1) * (slotWidth + 40)
        local slot = self.saves[i]
        
        if i == self.hoveredSlot then
            love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
        else
            love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
        end
        love.graphics.rectangle("fill", x, y, slotWidth, slotHeight, 20)
        
        love.graphics.setColor(0.5, 0.5, 0.8, 1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", x, y, slotWidth, slotHeight, 20)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(self.fontMedium)
        love.graphics.print(slot.name, x + 20, y + 20)
        
        if slot.exists then
            -- Форматируем время в минуты и секунды
            local minutes = math.floor(slot.time / 60)
            local seconds = math.floor(slot.time % 60)
            love.graphics.setFont(self.fontSmall)
            love.graphics.print("Time: " .. minutes .. "m " .. seconds .. "s", x + 20, y + 70)
            love.graphics.print("Kills: " .. slot.kills, x + 20, y + 100)
            love.graphics.print("Progress: " .. math.floor(slot.progress * 100) .. "%", x + 20, y + 130)
            
            if i == self.hoveredDelete then
                love.graphics.setColor(1, 0.5, 0.5, 1)
            else
                love.graphics.setColor(1, 0.3, 0.3, 1)
            end
            love.graphics.circle("fill", x + slotWidth - 30, y + 30, 12)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(self.fontSmall)
            love.graphics.print("X", x + slotWidth - 35, y + 23)
        else
            love.graphics.setFont(self.fontSmall)
            love.graphics.print("Empty slot", x + 20, y + 90)
            love.graphics.setColor(0.3, 1, 0.3, 1)
            love.graphics.print("+ NEW GAME", x + 20, y + 140)
        end
    end
    
    local backX = w/2 - 100
    local backY = h - 80
    local backW = 200
    local backH = 50
    if self.hoveredBack then
        love.graphics.setColor(0.3, 0.3, 0.5, 1)
    else
        love.graphics.setColor(0.2, 0.2, 0.3, 1)
    end
    love.graphics.rectangle("fill", backX, backY, backW, backH, 10)
    love.graphics.setColor(0.5, 0.5, 0.8, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", backX, backY, backW, backH, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.fontMedium)
    local backText = "BACK TO MENU"
    local backTextWidth = self.fontMedium:getWidth(backText)
    love.graphics.print(backText, w/2 - backTextWidth/2, backY + 12)
end

function SaveSelectScene:mousepressed(x, y, button)
    if button ~= 1 then return end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    local backX = w/2 - 100
    local backY = h - 80
    local backW = 200
    local backH = 50
    if x >= backX and x <= backX + backW and y >= backY and y <= backY + backH then
        self.manager:switch("menu", self.settings)
        return
    end
    
    local slotWidth = 300
    local slotHeight = 200
    local startX = w/2 - (slotWidth * 3 + 80) / 2
    local slotY = h/2 - 100
    
    for i = 1, 3 do
        local slotX = startX + (i-1) * (slotWidth + 40)
        local delX = slotX + slotWidth - 30
        local delY = slotY + 30
        if x >= delX - 15 and x <= delX + 15 and y >= delY - 15 and y <= delY + 15 then
            if self.saves[i].exists then
                self:deleteSave(i)
                self:loadSaves()
            end
            return
        end
        
        if x >= slotX and x <= slotX + slotWidth and y >= slotY and y <= slotY + slotHeight then
            if not self.saves[i].exists then
                self:createSave(i)
            end
            self.manager:switch("bullet", self.settings, i)
            return
        end
    end
end

function SaveSelectScene:keypressed(key)
    if key == "escape" then
        self.manager:switch("menu", self.settings)
    end
end

return SaveSelectScene