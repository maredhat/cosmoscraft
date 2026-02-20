local SceneManager = require('scence.scene')
local Settings = require('scence.settings.until')
local MenuScene = require('scence.scenes.menu')
local SettingsScene = require('scence.settings.settings')
local SaveSelectScene = require('scence.saves.saveSelectionScene')
local BulletScene = require('scence.scenes.devblog.bullet')

function love.load()
    settings = Settings.new()
    
    local w, h = settings:get("width"), settings:get("height")
    love.window.setMode(w, h, {
        fullscreen = settings:get("fullscreen"),
        vsync = settings:get("vsync"),
        resizable = false
    })
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    
    scenes = SceneManager.new()
    
    scenes:register('menu', MenuScene.new(scenes, settings))
    scenes:register('save_select', SaveSelectScene.new(scenes, settings))
    scenes:register('settings', SettingsScene.new(scenes, settings))
    scenes:register('bullet', BulletScene.new(scenes, settings, saveSelectionScene))
    
    scenes:switch("menu", settings)
end

function love.update(dt)
    scenes:update(dt)
end

function love.draw()
    scenes:draw()
end

function love.mousepressed(x, y, button)
    scenes:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    scenes:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    scenes:mousemoved(x, y, dx, dy)
end

function love.keypressed(key)
    scenes:keypressed(key)
end

function love.keyreleased(key)
    scenes:keyreleased(key)
end

function love.textinput(t)
    scenes:textinput(t)
end

function love.wheelmoved(x, y)
    scenes:wheelmoved(x, y)
end

function love.resize(w, h)
    if scenes and scenes.getCurrentScene then
        local scene = scenes:getCurrentScene()
        if scene and scene.resize then
            scene:resize(w, h)
        end
    end
end

function love.quit()
    if scenes and scenes.getCurrentScene then
        local scene = scenes:getCurrentScene()
        if scene and scene.onLeave then
            scene:onLeave()
        end
    end
end