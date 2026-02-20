local formatSpriteContent = '.png'


local function  __loadSpritesFromDirectory(directory)
    local sprites = {}
    local files = love.filesystem.getDirectoryItems(directory)
    for _, file in ipairs(files) do
        if file:match("%".. formatSpriteContent .."$") then
            local name = file:gsub("%".. formatSpriteContent .."$", "")
            local path = directory .. "/" .. file
            sprites[name] = path
        end
    end
    return sprites
end

local function __loadDirectSprites( path, filters )
    filters = filters or 'noarest'  
    local animation = {}
    local data_direct = __loadSpritesFromDirectory(path) 

    if not data_direct then return end
    for key, item in pairs(data_direct) do
        animation[key]               = {}
        animation[key].sprite        = love.graphics.newImage(item)
        animation[key].height        = animation[key].sprite:getHeight()
        animation[key].width         = animation[key].sprite:getWidth()
        animation[key].sprite:setFilter('nearest', 'nearest')
    end

    return animation
end


-- path: путь к изображению атласа
-- frameWidth, frameHeight: размер кадра (если nil, вычисляются из cols/rows)
-- cols: количество кадров по горизонтали
-- rows: количество кадров по вертикали
-- names: опциональная таблица имён для кадров (если nil, используются индексы)
-- filter: фильтр текстуры
local function __atlasSpriteLoad(path, frameWidth, frameHeight, cols, rows, names, filter)
    filter = filter or 'nearest'
    local atlas = love.graphics.newImage(path)
    if not atlas then
        print("Failed to load atlas:", path)
        return {}
    end
    atlas:setFilter(filter, filter)

    local atlasWidth = atlas:getWidth()
    local atlasHeight = atlas:getHeight()

    if not frameWidth then frameWidth = atlasWidth / cols end
    if not frameHeight then frameHeight = atlasHeight / rows end

    local frames = {}
    local index = 1
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local x = col * frameWidth
            local y = row * frameHeight
            local quad = love.graphics.newQuad(x, y, frameWidth, frameHeight, atlasWidth, atlasHeight)

            local name
            if names and names[index] then
                name = names[index]
            else
                name = tostring(index)
            end

            frames[name] = {
                sprite = atlas,
                quad = quad,
                width = frameWidth,
                height = frameHeight,
            }
            index = index + 1
        end
    end

    return frames
end


return __loadDirectSprites, __atlasSpriteLoad