


local math = math
local table = table
local ipairs = ipairs
local pairs = pairs
local type = type
local tostring = tostring
local love = love
local io = io
local os = os

local random = math.random
local abs    = math.abs
local sqrt   = math.sqrt
local max    = math.max
local min    = math.min
local floor  = math.floor
local ceil   = math.ceil
local insert = table.insert
local remove = table.remove

local lg = love.graphics
local timer = love.timer
local filesystem = love.filesystem



local Parallax       = require 'lib.effects.parallax'
local Camera         = require 'lib.system.camera'

local PlayerShip     = require 'assets.controller.player'
local Drone          = require 'assets.enemy.drone.drone'
local Asteroid       = require 'assets.decor.asteroid.asteroid'   
local Hud            = require 'assets.controller.hud'
local SpaceWorm      = require 'assets.enemy.spaceWorn.spaceWorn'

local BulletManager  = require 'assets.other.bulletmanager'
local ItemManager    = require 'assets.items.system.itemManager'

local Inventory      = require 'assets.inventory.inventory'

local BulletScene = {}
BulletScene.__index = BulletScene

local function setupParallaxSetting(parallax)
    parallax:addGalaxies(8, 0.005, 0.001)
    parallax:addNebula(15, 0.02, 0.003, "red")
    parallax:addNebula(12, 0.02, 0.003, "blue")
    parallax:addNebula(10, 0.02, 0.003, "purple")
    parallax:addPlanets(20, 0.01, 0.001)
    parallax:addStars(30000, 0.1, 1, 2, {0.5,0.5,0.8,0.3}, {0.9,0.9,1.0,0.6}, 0.01)
    parallax:addStars(5000, 0.15, 2, 4, {1.0,0.3,0.2,0.7}, {1.0,0.5,0.3,1.0}, 0.02, "red_giant")
    parallax:addStars(3000, 0.2, 2, 5, {0.4,0.6,1.0,0.7}, {0.6,0.8,1.0,1.0}, 0.03, "blue_giant")
    parallax:addPulsars(50, 0.25, 0.04)
    parallax:addComets(80, 0.2, 0.05, "ice")
    parallax:addComets(60, 0.3, 0.08, "fire")
    parallax:addAsteroids(200, 0.15, 0.02)
end

function BulletScene.new(manager, settings, saveSlot)
    local self = setmetatable({}, BulletScene)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    self.manager  = manager
    self.settings = settings
    self.saveSlot = saveSlot or 1

    self.saveData = self:loadSave(self.saveSlot)

    self.worldSize = { x = 10000, y = 10000 }
    self.worldBounds = {
        left   = -self.worldSize.x,
        right  =  self.worldSize.x,
        top    = -self.worldSize.y,
        bottom =  self.worldSize.y
    }

    self.parallax = Parallax.new(10000 * 2, 10000 * 2)
    self.camera   = Camera.new(0, 0, 0.80, 0)

    self.gridSize  = 200
    self.gridColor = {0.2, 0.2, 0.3, 0.15}

    self.itemManager = ItemManager.new()
    self.inventory   = Inventory.new()
    self.bullManager = BulletManager.new()

    self.player = PlayerShip(0, 0, 2, 2, 1, self.bullManager)
    self.drones = {}
    self.dronesChanged = true

    
    self.asteroids = {}
    self:spawnRandomAsteroids(30)   

    
    self:spawnRandomDrones(200, self.asteroids)   

    local spawnAngle = random() * 2 * math.pi
    local spawnDistance = 400 + random(0, 300)
    local spawnX = self.player.x + math.cos(spawnAngle) * spawnDistance
    local spawnY = self.player.y + math.sin(spawnAngle) * spawnDistance
    spawnX = max(self.worldBounds.left + 50, min(self.worldBounds.right - 50, spawnX))
    spawnY = max(self.worldBounds.top + 50, min(self.worldBounds.bottom - 50, spawnY))


    self.worm = SpaceWorm.new(spawnX, spawnY, self.player, self.bullManager, self)

    self.gameTime  = self.saveData.time or 0
    self.killCount = self.saveData.kills or 0

    self.prevX            = self.player.x
    self.prevY            = self.player.y
    self.updateInterval   = 3
    self.cameraBounds     = nil
    self.boundsCacheTimer = 0
    self.boundaryCrossed  = false
    self.exitDirection    = nil

    setupParallaxSetting(self.parallax)

    self.player:load()
    for _, drone in ipairs(self.drones) do
        drone:load()
    end

    self.hud = Hud.new(self.player, self.settings, self.camera, self.drones, self.worldBounds)

    return self
end


function BulletScene:spawnRandomAsteroids(count)
    local maxAttempts = 100
    local minDistanceToCenter = 800        
    for i = 1, count do
        local attempts = 0
        local placed = false
        while not placed and attempts < maxAttempts do
            local x = random(-self.worldSize.x, self.worldSize.x)
            local y = random(-self.worldSize.y, self.worldSize.y)
            local distToCenter = sqrt(x*x + y*y)
            if distToCenter > minDistanceToCenter then
                
                local overlap = false
                for _, ast in ipairs(self.asteroids) do
                    local dx = ast.x - x
                    local dy = ast.y - y
                    local dist = sqrt(dx*dx + dy*dy)
                    if dist < (ast.radius + 120) then 
                        overlap = true
                        break
                    end
                end
                if not overlap then
                    local asteroid = Asteroid.new(x, y, self, self.bullManager)
                    insert(self.asteroids, asteroid)
                    placed = true
                end
            end
            attempts = attempts + 1
        end
        if not placed then
            
            local x = random(self.worldBounds.left + 1000, self.worldBounds.right - 1000)
            local y = random(self.worldBounds.top + 1000, self.worldBounds.bottom - 1000)
            local asteroid = Asteroid.new(x, y, self, self.bullManager)
            insert(self.asteroids, asteroid)
        end
    end
end


function BulletScene:spawnRandomDrones(count, asteroids)
    asteroids = asteroids or {}
    local droneRadius = 15   
    local maxAttempts = 50
    for i = 1, count do
        local attempts = 0
        local placed = false
        while not placed and attempts < maxAttempts do
            local x = random(-self.worldSize.x, self.worldSize.x)
            local y = random(-self.worldSize.y, self.worldSize.y)
            
            while abs(x) < 500 and abs(y) < 500 do
                x = random(-self.worldSize.x, self.worldSize.x)
                y = random(-self.worldSize.y, self.worldSize.y)
            end
            
            local collision = false
            for _, ast in ipairs(asteroids) do
                local dx = ast.x - x
                local dy = ast.y - y
                local dist = sqrt(dx*dx + dy*dy)
                if dist < (ast.radius + droneRadius) then
                    collision = true
                    break
                end
            end
            if not collision then
                local drone = Drone.new(x, y, self.bullManager, self.player, 1, self)
                insert(self.drones, drone)
                placed = true
            end
            attempts = attempts + 1
        end
        if not placed then
            
            local x = random(self.worldBounds.left + 1000, self.worldBounds.right - 1000)
            local y = random(self.worldBounds.top + 1000, self.worldBounds.bottom - 1000)
            local drone = Drone.new(x, y, self.bullManager, self.player, 1, self)
            insert(self.drones, drone)
        end
    end
end

function BulletScene:loadSave(slot)
    local filename = "save_" .. slot .. ".lua"
    if filesystem.getInfo(filename) then
        local data = filesystem.load(filename)()
        return data
    end
    return { time = 0, kills = 0, progress = 0, playerX = 0, playerY = 0 }
end

function BulletScene:saveGame()
    local saveData = {
        time     = self.gameTime,
        kills    = self.killCount,
        progress = 0,
        playerX  = self.player.x,
        playerY  = self.player.y,
        date     = os.date("%Y-%m-%d %H:%M:%S"),
        tier     = self.player.tier
    }
    local file = io.open("data/saves/save_" .. self.saveSlot .. ".lua", "w")
    if file then
        file:write("return {\n")
        for k, v in pairs(saveData) do
            local valueStr = type(v) == "string" and ('"' .. v .. '"') or tostring(v)
            file:write("    " .. k .. " = " .. valueStr .. ",\n")
        end
        file:write("}\n")
        file:close()
    end
end

function BulletScene:respawn()
    self.player.x = 0
    self.player.y = 0
    self.player.health = self.player.maxHealth
    self.player.armor = self.player.maxArmor
    self.player.active = true
    self.player.deathEffect = nil

    self.drones = {}
    self:spawnRandomDrones(20, self.asteroids)
    for _, drone in ipairs(self.drones) do
        drone:load()
    end
    self.dronesChanged = true
    self.boundaryCrossed = false
end

function BulletScene:resize(w, h) end
function BulletScene:onEnter() end
function BulletScene:onLeave()
    self:saveGame()
end
function BulletScene:updateCameraBounds() end

function BulletScene:isOnScreen(x, y, margin)
    if not self.cameraBounds then return true end
    margin = margin or 200
    return x > self.cameraBounds.left - margin and
           x < self.cameraBounds.right + margin and
           y > self.cameraBounds.top - margin and
           y < self.cameraBounds.bottom + margin
end

function BulletScene:isInWorldBounds(x, y)
    return x > self.worldBounds.left and
           x < self.worldBounds.right and
           y > self.worldBounds.top and
           y < self.worldBounds.bottom
end

function BulletScene:checkWorldBoundaries()
    local margin = 50
    local player = self.player
    if player.x <= self.worldBounds.left + margin then
        self.boundaryCrossed = true
        self.exitDirection = "left"
    elseif player.x >= self.worldBounds.right - margin then
        self.boundaryCrossed = true
        self.exitDirection = "right"
    elseif player.y <= self.worldBounds.top + margin then
        self.boundaryCrossed = true
        self.exitDirection = "top"
    elseif player.y >= self.worldBounds.bottom - margin then
        self.boundaryCrossed = true
        self.exitDirection = "bottom"
    end
end

function BulletScene:clampPlayerToWorld()
    self.player.x = max(self.worldBounds.left + 50, min(self.worldBounds.right - 50, self.player.x))
    self.player.y = max(self.worldBounds.top + 50, min(self.worldBounds.bottom - 50, self.player.y))
end


function BulletScene:simplifiedDroneUpdate(drone, dt)
    if not drone.active then return end
    if drone.patrolMode then
        local dx = drone.patrolTargetX - drone.x
        local dy = drone.patrolTargetY - drone.y
        local dist = sqrt(dx*dx + dy*dy)
        if dist > 30 then
            local moveX = dx / dist
            local moveY = dy / dist
            drone.x = drone.x + moveX * drone.patrolSpeed * dt
            drone.y = drone.y + moveY * drone.patrolSpeed * dt
        elseif drone.patrolWaitTimer then
            drone.patrolWaitTimer = drone.patrolWaitTimer - dt
            if drone.patrolWaitTimer <= 0 then
                drone:generatePatrolPath()
            end
        end
    elseif drone.investigationMode and drone.investigationTarget then
        drone.investigationTimer = drone.investigationTimer - dt
        if drone.investigationTimer <= 0 then
            drone.investigationMode = false
            drone:startPatrol()
        else
            local tx = drone.investigationTarget.x - drone.x
            local ty = drone.investigationTarget.y - drone.y
            local tdist = sqrt(tx*tx + ty*ty)
            if tdist > 0 then
                local moveX = tx / tdist
                local moveY = ty / tdist
                drone.x = drone.x + moveX * drone.investigationSpeed * dt
                drone.y = drone.y + moveY * drone.investigationSpeed * dt
            end
        end
    elseif drone.alerted and drone.lastKnownPlayerPosition then
        local tx = drone.lastKnownPlayerPosition.x - drone.x
        local ty = drone.lastKnownPlayerPosition.y - drone.y
        local tdist = sqrt(tx*tx + ty*ty)
        if tdist > 0 then
            local moveX = tx / tdist
            local moveY = ty / tdist
            drone.x = drone.x + moveX * drone.speed * dt * 0.7
            drone.y = drone.y + moveY * drone.speed * dt * 0.7
        end
    end
    drone.timeSinceLastSeen = drone.timeSinceLastSeen + dt * self.updateInterval
    if drone.timeSinceLastSeen >= drone.patrolTime and not drone.patrolMode and not drone.investigationMode then
        drone:startPatrol()
    end
end

function BulletScene:updateDroneNetwork()
    local dronesThatSeePlayer = {}
    for _, drone in ipairs(self.drones) do
        if drone.active and drone:canSeePlayer() then
            insert(dronesThatSeePlayer, drone)
        end
        if drone.active then
            drone.alerted = false
        end
    end
    for _, drone in ipairs(dronesThatSeePlayer) do
        drone.alerted = true
    end
    local changed = true
    while changed do
        changed = false
        for _, drone in ipairs(self.drones) do
            if drone.active and drone.alerted then
                for _, otherDrone in ipairs(self.drones) do
                    if otherDrone ~= drone and otherDrone.active and not otherDrone.alerted then
                        local dx = otherDrone.x - drone.x
                        local dy = otherDrone.y - drone.y
                        local dist = sqrt(dx*dx + dy*dy)
                        if dist < drone.detectionRange then
                            otherDrone.alerted = true
                            changed = true
                        end
                    end
                end
            end
        end
    end
end


local function resolveCollision(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    local dist = sqrt(dx*dx + dy*dy)
    local radA = a:getRadius()
    local radB = b:getRadius()
    local minDist = radA + radB
    if dist < minDist and dist > 0 then
        local overlap = minDist - dist
        local nx = dx / dist
        local ny = dy / dist
        a.x = a.x - nx * overlap * 0.5
        a.y = a.y - ny * overlap * 0.5
        b.x = b.x + nx * overlap * 0.5
        b.y = b.y + ny * overlap * 0.5

        local vRel = (a.vx - b.vx) * nx + (a.vy - b.vy) * ny
        if vRel < 0 then
            local impact = abs(vRel) * 1.5
            if a.applyCollisionDamage then a:applyCollisionDamage(impact) end
            if b.applyCollisionDamage then b:applyCollisionDamage(impact) end
        end
    end
end

function BulletScene:update(dt)
    self.bullManager:update(dt)
    self.itemManager:update(dt, self.player, self.inventory)

    if self.worm and self.worm.active then
        self.worm:update(dt)
    elseif self.worm and not self.worm.active and self.worm.deathEffect then
        self.worm:update(dt)
    end


    
    for _, ast in ipairs(self.asteroids) do
        ast:update(dt)
    end

    self.camera:follow(self.player, self.settings:get("cameraSmoothness") or 0.1)
    if self.hud then
        local shakeX, shakeY = self.hud:getCameraShake()
        self.camera.x = self.camera.x + shakeX
        self.camera.y = self.camera.y + shakeY
    end

    if self.hud then
        self.hud:update(dt)
    end
    if not self.player.active then
        self:respawn()
    end

    self.gameTime = self.gameTime + dt

    if self.dronesChanged then
        self:updateDroneNetwork()
        self.dronesChanged = false
    end

    
    for _, drone in ipairs(self.drones) do
        if drone.active then
            if self:isOnScreen(drone.x, drone.y) then
                drone:update(dt, self.drones)
            else
                self:simplifiedDroneUpdate(drone, dt)
            end
            drone.x = max(self.worldBounds.left + 30, min(self.worldBounds.right - 30, drone.x))
            drone.y = max(self.worldBounds.top + 30, min(self.worldBounds.bottom - 30, drone.y))
        else
            drone:update(dt)
            if not drone.deathEffect then
                self.killCount = self.killCount + 1
            end
        end

        
        if drone and drone.active and self:isOnScreen(drone.x, drone.y, 300) then
            for k, bullet in pairs(self.bullManager.bullets) do
                if bullet.owner == "player" and drone:checkCollision(bullet) then
                    drone:takeDamage(bullet.damage, bullet)
                    bullet.active = false
                end
            end
        end

        
        if not drone.active and not drone.deathEffect then
            for idx, d in ipairs(self.drones) do
                if d == drone then
                    remove(self.drones, idx)
                    self.dronesChanged = true
                    break
                end
            end
        end
    end

    
    for i = #self.bullManager.bullets, 1, -1 do
        local bullet = self.bullManager.bullets[i]
        if bullet.owner == "player" then
            for j, ast in ipairs(self.asteroids) do
                if ast.active and ast:checkCollision(bullet) then
                    ast:takeDamage(bullet.damage, bullet)
                    bullet.active = false
                    break
                end
            end
        end
    end

    
    if self.player and self.player.active then
        for _, ast in ipairs(self.asteroids) do
            if ast.active then
                resolveCollision(self.player, ast)
            end
        end
        for _, drone in ipairs(self.drones) do
            if drone.active then
                for _, ast in ipairs(self.asteroids) do
                    if ast.active then
                        resolveCollision(drone, ast)
                    end
                end
            end
        end
    end

    
    if self.player and self.player.active then
        for k, bullet in pairs(self.bullManager.bullets) do
            if bullet.owner == 'enemy' and self.player:checkCollision(bullet) then
                bullet.active = false
            end
        end
        for _, drone in ipairs(self.drones) do
            if drone.active then
                resolveCollision(self.player, drone)
            end
        end
    end

    
    for i = 1, #self.drones do
        for j = i+1, #self.drones do
            local a = self.drones[i]
            local b = self.drones[j]
            if a.active and b.active then
                resolveCollision(a, b)
            end
        end
    end

    
    self.player:update(dt)
    self:clampPlayerToWorld()
    self:checkWorldBoundaries()

    if self.boundaryCrossed then
        self.manager:switch('menu')
        return
    end

    self.camera:follow(self.player, self.settings:get("cameraSmoothness") or 0.1)
    self.prevX, self.prevY = self.player.x, self.player.y

    
    self.parallax:updateTime(dt)
    self.parallax:update(self.player.x - self.prevX, self.player.y - self.prevY)
    self.parallax:autoUpdate(dt)

    
    for i = #self.asteroids, 1, -1 do
        if not self.asteroids[i].active then
            remove(self.asteroids, i)
        end
    end
end

function BulletScene:draw()
    local w, h = lg.getWidth(), lg.getHeight()
    local brightness = self.settings:get("brightness") or 1.0

    lg.setColor(brightness, brightness, brightness, 1)
    self.camera:attach()
    self.parallax:draw()
    self.itemManager:draw()

    
    if self.settings:get("showGrid") then
        lg.setColor(self.gridColor)
        local bounds = self.cameraBounds or self.camera:getBounds()
        local startX = max(self.worldBounds.left, floor(bounds.left / self.gridSize) * self.gridSize)
        local endX = min(self.worldBounds.right, ceil(bounds.right / self.gridSize) * self.gridSize)
        local startY = max(self.worldBounds.top, floor(bounds.top / self.gridSize) * self.gridSize)
        local endY = min(self.worldBounds.bottom, ceil(bounds.bottom / self.gridSize) * self.gridSize)

        for x = startX, endX, self.gridSize do
            lg.line(x, bounds.top - 100, x, bounds.bottom + 100)
        end
        for y = startY, endY, self.gridSize do
            lg.line(bounds.left - 100, y, bounds.right + 100, y)
        end
    end

    

    
    lg.setLineWidth(5)
    lg.setColor(0, 0.8, 0.0, 0.70)
    lg.rectangle("line", self.worldBounds.left, self.worldBounds.top,
                 self.worldBounds.right - self.worldBounds.left,
                 self.worldBounds.bottom - self.worldBounds.top)

    self.bullManager:draw()
    self.player:draw()

    
    for _, ast in ipairs(self.asteroids) do
        if self:isOnScreen(ast.x, ast.y, 150) then
            ast:draw()
        end
    end

    
    for _, drone in ipairs(self.drones) do
        if drone.active and not drone.deathEffect and self:isOnScreen(drone.x, drone.y) then
            drone:draw()
        end
    end
    for _, drone in ipairs(self.drones) do
        if drone.deathEffect or drone.hitFlash then
            if self:isOnScreen(drone.x, drone.y, 300) or drone.deathEffect then
                drone:draw()
            end
        end
    end

    
    if self.worm then
        if self:isOnScreen(self.worm.x, self.worm.y, 300) or self.worm.deathEffect then
            self.worm:draw()
        end
    end

    self.camera:detach()

    
    if self.hud then self.hud:draw() end
    lg.setColor(1, 1, 1, 1)
    lg.setFont(lg.newFont(12))
    lg.setColor(1, 1, 1, 0.5)
    lg.print("WASD - move | SPACE - shoot | ESC - menu", 10, h - 30)
end

function BulletScene:keypressed(key)
    if key == "m" then
        self.showMinimap = not self.showMinimap
    end
    if key == "escape" then
        self:saveGame()
        self.manager:switchWithTransition("menu", "fade", 0.8, self.settings)
    end
end

return BulletScene