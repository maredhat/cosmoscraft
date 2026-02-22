-- lib/save.lua
local Save = {}

local saveDir = "saves/"

-- Инициализация: создаёт папку saves, если её нет
function Save.init()
    love.filesystem.createDirectory(saveDir)
end

-- Сохранить данные в файл с указанным именем (без расширения)
-- Возвращает true при успехе
function Save.save(filename, data, metadata)
    metadata = metadata or {}
    local fullData = {
        meta = {
            version = metadata.version or "1.0",
            timestamp = os.time(),
            date = os.date("%Y-%m-%d %H:%M:%S"),
            label = metadata.label or filename,
        },
        data = data
    }
    local json = love.data.encode("json", fullData)
    local path = saveDir .. filename .. ".json"
    love.filesystem.write(path, json)
    return true
end

-- Загрузить данные из файла. Возвращает (data, meta) или (nil, nil, errorMsg)
function Save.load(filename)
    local path = saveDir .. filename .. ".json"
    if not love.filesystem.getInfo(path) then
        return nil, nil, "File not found: " .. path
    end
    local content = love.filesystem.read(path)
    local ok, fullData = pcall(love.data.decode, "json", content)
    if not ok then
        return nil, nil, "Failed to decode JSON"
    end
    return fullData.data, fullData.meta
end

-- Получить список всех сохранений (таблица с именами файлов и метаданными)
function Save.list()
    local files = love.filesystem.getDirectoryItems(saveDir)
    local saves = {}
    for _, file in ipairs(files) do
        if file:match("%.json$") then
            local name = file:gsub("%.json$", "")
            local info = love.filesystem.getInfo(saveDir .. file)
            local data, meta = Save.load(name)
            saves[name] = {
                filename = file,
                modified = info.modtime,
                size = info.size,
                meta = meta or { label = name }
            }
        end
    end
    return saves
end

-- Удалить сохранение
function Save.delete(filename)
    local path = saveDir .. filename .. ".json"
    if love.filesystem.getInfo(path) then
        love.filesystem.remove(path)
        return true
    end
    return false
end

-- Проверить, существует ли сохранение
function Save.exists(filename)
    local path = saveDir .. filename .. ".json"
    return love.filesystem.getInfo(path) ~= nil
end

return Save