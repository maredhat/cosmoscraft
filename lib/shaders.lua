local Shaders = {}

local cache = {}

-- ------------------------------------------------------------------------
-- Загрузка и кэширование
-- ------------------------------------------------------------------------

-- Загрузить шейдер из файла или строки
-- @param name  идентификатор (для кэша)
-- @param path  путь к файлу или таблица {vertex=..., fragment=...}
-- @return шейдер (love.Shader)
function Shaders.load(name, path)
    if cache[name] then
        return cache[name]
    end
    local shader
    if type(path) == "table" then
        -- таблица с vertex/fragment
        shader = love.graphics.newShader(path.vertex, path.fragment)
    elseif type(path) == "string" then
        -- если файл существует, читаем, иначе считаем строкой кодом
        local info = love.filesystem.getInfo(path)
        if info then
            shader = love.graphics.newShader(love.filesystem.read(path))
        else
            shader = love.graphics.newShader(path)
        end
    else
        error("Invalid shader path: " .. tostring(path))
    end
    cache[name] = shader
    return shader
end

-- Проверить, загружен ли шейдер
function Shaders.isLoaded(name)
    return cache[name] ~= nil
end

-- Выгрузить шейдер из кэша
function Shaders.unload(name)
    if cache[name] then
        cache[name]:release()
        cache[name] = nil
    end
end

-- Очистить весь кэш
function Shaders.clearCache()
    for name, shader in pairs(cache) do
        shader:release()
    end
    cache = {}
end

-- ------------------------------------------------------------------------
-- Применение шейдеров
-- ------------------------------------------------------------------------

-- Применить шейдер к текущему контексту рисования
-- @param name  идентификатор шейдера (или сам объект love.Shader)
-- @param uniforms  таблица с uniform-переменными {name=value, ...}
function Shaders.apply(name, uniforms)
    local shader
    if type(name) == "string" then
        shader = cache[name]
        if not shader then
            error("Shader not loaded: " .. name)
        end
    else
        shader = name
    end
    love.graphics.setShader(shader)
    if uniforms then
        for k, v in pairs(uniforms) do
            shader:send(k, v)
        end
    end
end

-- Сбросить шейдер (вернуть стандартный)
function Shaders.reset()
    love.graphics.setShader()
end

-- Выполнить функцию с временно применённым шейдером
-- @param name      идентификатор шейдера
-- @param uniforms  таблица uniform-ов
-- @param func      функция, которая будет вызвана с этим шейдером
function Shaders.with(name, uniforms, func)
    Shaders.apply(name, uniforms)
    local ok, err = pcall(func)
    Shaders.reset()
    if not ok then
        error(err)
    end
end

-- ------------------------------------------------------------------------
-- Встроенные шейдеры (эффекты)
-- ------------------------------------------------------------------------

-- Инверсия цветов
Shaders.invert = love.graphics.newShader([[
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 c = Texel(tex, tc) * color;
        return vec4(1.0 - c.rgb, c.a);
    }
]])

-- Чёрно-белый
Shaders.grayscale = love.graphics.newShader([[
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 c = Texel(tex, tc) * color;
        float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
        return vec4(gray, gray, gray, c.a);
    }
]])

-- Размытие (простое среднее 3x3)
Shaders.blur = love.graphics.newShader([[
    extern number size = 1.0;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 sum = vec4(0.0);
        for (float x = -1.0; x <= 1.0; x += 1.0) {
            for (float y = -1.0; y <= 1.0; y += 1.0) {
                sum += Texel(tex, tc + vec2(x, y) * size / love_ScreenSize.xy);
            }
        }
        return (sum / 9.0) * color;
    }
]])

-- Свечение (glow) – комбинация размытия и усиления ярких участков
-- (требуется два прохода, здесь только основа)
Shaders.glow = love.graphics.newShader([[
    extern number intensity = 1.0;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 c = Texel(tex, tc) * color;
        float bright = max(max(c.r, c.g), c.b);
        return c + c * bright * intensity;
    }
]])

-- Эффект статики (помехи)
Shaders.noise = love.graphics.newShader([[
    extern float time = 0.0;
    float rand(vec2 co) {
        return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
    }
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 c = Texel(tex, tc) * color;
        float n = rand(tc + time);
        return vec4(c.rgb * (0.8 + 0.4*n), c.a);
    }
]])

-- Пикселизация
Shaders.pixelate = love.graphics.newShader([[
    extern number size = 10.0;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec2 p = floor(tc * love_ScreenSize.xy / size) * size / love_ScreenSize.xy;
        return Texel(tex, p) * color;
    }
]])

-- Сепия
Shaders.sepia = love.graphics.newShader([[
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 c = Texel(tex, tc) * color;
        float r = dot(c.rgb, vec3(0.393, 0.769, 0.189));
        float g = dot(c.rgb, vec3(0.349, 0.686, 0.168));
        float b = dot(c.rgb, vec3(0.272, 0.534, 0.131));
        return vec4(r, g, b, c.a);
    }
]])

-- Размытие по направлению (motion blur)
Shaders.motionBlur = love.graphics.newShader([[
    extern vec2 direction = vec2(0.0, 0.0);
    extern int samples = 5;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 sum = vec4(0.0);
        for (int i = -samples/2; i <= samples/2; i++) {
            float t = float(i) / float(samples);
            sum += Texel(tex, tc + direction * t / love_ScreenSize.xy);
        }
        return (sum / float(samples)) * color;
    }
]])

-- ------------------------------------------------------------------------
-- Вспомогательные функции для uniform-ов
-- ------------------------------------------------------------------------

-- Установить uniform-переменную для активного шейдера
function Shaders.send(name, value)
    local shader = love.graphics.getShader()
    if shader then
        shader:send(name, value)
    end
end

-- Получить текущий шейдер
function Shaders.getCurrent()
    return love.graphics.getShader()
end

-- ------------------------------------------------------------------------
-- Работа с несколькими проходами (render to texture)
-- ------------------------------------------------------------------------

-- Применить шейдер к текстуре и вернуть результат как новое изображение
-- @param shader  идентификатор или объект шейдера
-- @param source  изображение или канвас
-- @param uniforms таблица uniform-ов
-- @return картинка (love.Image)
function Shaders.applyToImage(shader, source, uniforms)
    local w, h = source:getDimensions()
    local canvas = love.graphics.newCanvas(w, h)
    canvas:renderTo(function()
        love.graphics.setShader(shader)
        if uniforms then
            for k, v in pairs(uniforms) do
                shader:send(k, v)
            end
        end
        love.graphics.draw(source, 0, 0)
        love.graphics.setShader()
    end)
    return canvas:newImageData()
end

return Shaders