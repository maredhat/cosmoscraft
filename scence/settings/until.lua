local Settings = {}
Settings.__index = Settings

function Settings.new()
    local self = setmetatable({}, Settings)
    self.filename = "data/gamedata.lua"
    self.defaults = {
        fullscreen = false,
        width = 1600,
        height = 1000,
        vsync = true,
        musicVolume = 0.7,
        sfxVolume = 0.8,
    }
    self.current = {}
    self:load()
    return self
end

function Settings:load()
    local success, config = pcall(dofile, self.filename)
    if success and config then
        self.current = config
    else
        self.current = {}
        for k, v in pairs(self.defaults) do
            self.current[k] = v
        end
        self:save()
    end
end

function Settings:save()
    local file = io.open(self.filename, "w")
    if file then
        file:write("return {\n")
        for k, v in pairs(self.current) do
            local valueStr = type(v) == "string" and ('"' .. v .. '"') or tostring(v)
            file:write("    " .. k .. " = " .. valueStr .. ",\n")
        end
        file:write("}\n")
        file:close()
    end
end

function Settings:set(key, value)
    self.current[key] = value
    self:save()
    self:apply()
end

function Settings:get(key)
    return self.current[key]
end

function Settings:apply()
    local w, h = self.current.width, self.current.height
    local fullscreen = self.current.fullscreen
    love.window.setMode(w, h, {fullscreen = fullscreen, vsync = self.current.vsync, resizable = true})
end

function Settings:getResolutions()
    return {
        {width = 1280, height = 720, name = "720p (1280x720)"},
        {width = 1366, height = 768, name = "768p (1366x768)"},
        {width = 1600, height = 900, name = "900p (1600x900)"},
        {width = 1920, height = 1080, name = "1080p (1920x1080)"},
        {width = 2560, height = 1440, name = "1440p (2560x1440)"},
    }
end

return Settings