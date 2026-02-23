-- textbox.lua
-- Расширенный компонент ввода текста с поддержкой выделения, буфера обмена и горизонтальной прокрутки

local TextInput = {}
TextInput.__index = TextInput

local function clamp(low, val, high) return math.max(low, math.min(high, val)) end

-- UTF-8 helpers
local function utf8len(str)
    if not str then return 0 end
    local len = 0
    for _ in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
        len = len + 1
    end
    return len
end

local function utf8sub(str, start, finish)
    if not str then return "" end
    local chars = {}
    for char in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(chars, char)
    end
    start = start or 1
    finish = finish or #chars
    if start < 1 then start = 1 end
    if finish > #chars then finish = #chars end
    if start > finish then return "" end
    return table.concat(chars, "", start, finish)
end

--[[
TextInput.new(x, y, w, h, options)
    x, y, w, h – абсолютные координаты и размер поля ввода

    options = {
        text        = "",
        placeholder = "Enter text...",
        maxLength   = 0,                       -- 0 = без ограничений
        fontSize    = 16,
        fontPath    = nil,
        bgColor     = {0.2,0.2,0.2,0.9},
        textColor   = {1,1,1,1},
        placeholderColor = {0.5,0.5,0.5,1},
        cursorColor = {0.8,0.8,0.8,1},
        borderColor = {0.4,0.4,0.4,1},
        focusBorderColor = {0.3,0.7,1,1},
        borderRadius = 4,
        cursorWidth = 2,
        cursorBlinkTime = 0.5,
        selectionColor = {0.3,0.5,0.8,0.5},    -- цвет выделения
        onChange    = function(text) end,
        onEnter     = function(text) end,
        onFocus     = function() end,
        onBlur      = function() end,
        allowedChars = nil,                     -- строка разрешённых символов (напр. "%d" для цифр)
        numericOnly = false,                    -- только цифры
        password    = false,                     -- режим пароля (скрывать символы)
        readonly    = false,                     -- только чтение (нельзя редактировать)
        disabled    = false,                      -- отключён (не реагирует на события)
    }
]]

function TextInput.new(x, y, w, h, options)
    local self = setmetatable({}, TextInput)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.visible = true
    self.focused = false
    self.readonly = false
    self.disabled = false

    self.cursorPos = 1          -- позиция курсора (после символа с индексом)
    self.cursorVisible = true
    self.cursorTimer = 0

    self.selectionStart = nil    -- начало выделения (индекс)
    self.selectionEnd = nil      -- конец выделения
    self.offsetX = 0             -- горизонтальная прокрутка (в пикселях)

    options = options or {}
    self.text = options.text or ""
    self.placeholder = options.placeholder or ""
    self.maxLength = options.maxLength or 0
    self.fontSize = options.fontSize or 16
    self.font = options.fontPath and love.graphics.newFont(options.fontPath, self.fontSize) or love.graphics.getFont()

    self.bgColor = options.bgColor or {0.2,0.2,0.2,0.9}
    self.textColor = options.textColor or {1,1,1,1}
    self.placeholderColor = options.placeholderColor or {0.5,0.5,0.5,1}
    self.cursorColor = options.cursorColor or {0.8,0.8,0.8,1}
    self.borderColor = options.borderColor or {0.4,0.4,0.4,1}
    self.focusBorderColor = options.focusBorderColor or {0.3,0.7,1,1}
    self.borderRadius = options.borderRadius or 4
    self.cursorWidth = options.cursorWidth or 2
    self.cursorBlinkTime = options.cursorBlinkTime or 0.5
    self.selectionColor = options.selectionColor or {0.3,0.5,0.8,0.5}

    self.onChange = options.onChange
    self.onEnter = options.onEnter
    self.onFocus = options.onFocus
    self.onBlur = options.onBlur
    self.allowedChars = options.allowedChars
    self.numericOnly = options.numericOnly or false
    self.password = options.password or false
    self.readonly = options.readonly or false
    self.disabled = options.disabled or false

    return self
end

function TextInput:getText() return self.text end

function TextInput:setText(newText)
    self.text = newText or ""
    if self.maxLength > 0 and utf8len(self.text) > self.maxLength then
        self.text = utf8sub(self.text, 1, self.maxLength)
    end
    self.cursorPos = utf8len(self.text) + 1
    self.selectionStart = nil
    self.selectionEnd = nil
    self:adjustOffset()
    if self.onChange then self.onChange(self.text) end
end

function TextInput:clear()
    self:setText("")
end

function TextInput:focus()
    if self.disabled or self.focused then return end
    self.focused = true
    self.cursorVisible = true
    self.cursorTimer = 0
    self.cursorPos = utf8len(self.text) + 1
    self.selectionStart = nil
    self.selectionEnd = nil
    self:adjustOffset()
    if self.onFocus then self.onFocus() end
end

function TextInput:blur()
    if not self.focused then return end
    self.focused = false
    self.selectionStart = nil
    self.selectionEnd = nil
    if self.onBlur then self.onBlur() end
end

-- Получить отображаемую строку (с учётом пароля)
function TextInput:getDisplayText()
    if #self.text == 0 then return "" end
    if self.password then
        return string.rep("*", utf8len(self.text))
    else
        return self.text
    end
end

-- Получить ширину подстроки (с учётом пароля)
function TextInput:getDisplayWidth(str)
    local display = str
    if self.password then
        display = string.rep("*", utf8len(str))
    end
    return self.font:getWidth(display)
end

-- Обновить offsetX так, чтобы курсор был виден
function TextInput:adjustOffset()
    local textBefore = utf8sub(self.text, 1, self.cursorPos - 1)
    local cursorX = self:getDisplayWidth(textBefore)
    local visibleWidth = self.w - 20   -- отступы по 10px

    if cursorX - self.offsetX < 10 then
        self.offsetX = math.max(0, cursorX - 10)
    elseif cursorX - self.offsetX > visibleWidth - 10 then
        self.offsetX = cursorX - visibleWidth + 10
    end
    self.offsetX = clamp(0, self.offsetX, math.max(0, self:getDisplayWidth(self.text) - visibleWidth))
end

-- Получить индекс символа по координате мыши (локальной относительно поля)
function TextInput:getCharIndexAtX(localX)
    local x = localX + self.offsetX
    local bestPos = 1
    local bestDist = math.huge
    local textLen = utf8len(self.text)
    for i = 0, textLen do
        local prefix = utf8sub(self.text, 1, i)
        local width = self:getDisplayWidth(prefix)
        local dist = math.abs(x - width)
        if dist < bestDist then
            bestDist = dist
            bestPos = i + 1
        end
    end
    return bestPos
end

-- Обработка выделения
function TextInput:setSelection(start, finish)
    if start and finish then
        self.selectionStart = math.min(start, finish)
        self.selectionEnd = math.max(start, finish)
    else
        self.selectionStart = nil
        self.selectionEnd = nil
    end
end

-- Получить выделенный текст
function TextInput:getSelectedText()
    if not self.selectionStart or not self.selectionEnd then return "" end
    return utf8sub(self.text, self.selectionStart, self.selectionEnd - 1)
end

-- Заменить выделенный текст на новый
function TextInput:replaceSelection(newText)
    if not self.selectionStart or not self.selectionEnd then
        -- вставить на позицию курсора
        local before = utf8sub(self.text, 1, self.cursorPos - 1)
        local after = utf8sub(self.text, self.cursorPos)
        self.text = before .. newText .. after
        self.cursorPos = self.cursorPos + utf8len(newText)
    else
        local before = utf8sub(self.text, 1, self.selectionStart - 1)
        local after = utf8sub(self.text, self.selectionEnd)
        self.text = before .. newText .. after
        self.cursorPos = self.selectionStart + utf8len(newText)
        self.selectionStart = nil
        self.selectionEnd = nil
    end

    if self.maxLength > 0 and utf8len(self.text) > self.maxLength then
        self.text = utf8sub(self.text, 1, self.maxLength)
        self.cursorPos = math.min(self.cursorPos, utf8len(self.text) + 1)
    end

    self:adjustOffset()
    if self.onChange then self.onChange(self.text) end
end

-- Удалить выделенное или символ слева (backspace)
function TextInput:backspace()
    if self.selectionStart and self.selectionEnd then
        self:replaceSelection("")
    elseif self.cursorPos > 1 then
        local before = utf8sub(self.text, 1, self.cursorPos - 2)
        local after = utf8sub(self.text, self.cursorPos)
        self.text = before .. after
        self.cursorPos = self.cursorPos - 1
        self:adjustOffset()
        if self.onChange then self.onChange(self.text) end
    end
end

-- Удалить выделенное или символ справа (delete)
function TextInput:delete()
    if self.selectionStart and self.selectionEnd then
        self:replaceSelection("")
    elseif self.cursorPos <= utf8len(self.text) then
        local before = utf8sub(self.text, 1, self.cursorPos - 1)
        local after = utf8sub(self.text, self.cursorPos + 1)
        self.text = before .. after
        self:adjustOffset()
        if self.onChange then self.onChange(self.text) end
    end
end

-- Вставить текст (из буфера обмена или другого)
function TextInput:insertText(newText)
    if self.readonly then return end
    -- Фильтр символов
    if self.numericOnly then
        newText = newText:gsub("%D", "")
    elseif self.allowedChars then
        local filtered = ""
        for c in newText:gmatch(".") do
            if c:match("[" .. self.allowedChars .. "]") then
                filtered = filtered .. c
            end
        end
        newText = filtered
    end

    if #newText == 0 then return end

    self:replaceSelection(newText)
end

-- Обработка событий мыши
function TextInput:mousepressed(mx, my, button)
    if self.disabled or not self.visible or button ~= 1 then return end

    local inside = mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h

    if inside then
        self:focus()
        local localX = mx - (self.x + 10)
        self.cursorPos = self:getCharIndexAtX(localX)
        self.selectionStart = nil
        self.selectionEnd = nil
        self:adjustOffset()
    else
        self:blur()
    end
end

-- Обработка ввода текста
function TextInput:textinput(t)
    if self.disabled or self.readonly or not self.focused or not self.visible then return end
    self:insertText(t)
end

-- Обработка клавиш
function TextInput:keypressed(key, scancode, isrepeat)
    if self.disabled or not self.focused or not self.visible then return end

    local shift = love.keyboard.isDown("lshift", "rshift")
    local ctrl = love.keyboard.isDown("lctrl", "rctrl")

    if ctrl then
        if key == "a" then
            -- Выделить всё
            self.selectionStart = 1
            self.selectionEnd = utf8len(self.text) + 1
            return
        elseif key == "c" then
            -- Копировать
            local selected = self:getSelectedText()
            if #selected > 0 then
                love.system.setClipboardText(selected)
            end
            return
        elseif key == "x" then
            -- Вырезать
            local selected = self:getSelectedText()
            if #selected > 0 then
                love.system.setClipboardText(selected)
                if not self.readonly then
                    self:replaceSelection("")
                end
            end
            return
        elseif key == "v" then
            -- Вставить
            if not self.readonly then
                local clip = love.system.getClipboardText()
                if clip then
                    self:insertText(clip)
                end
            end
            return
        end
    end

    if self.readonly then return end

    if key == "backspace" then
        self:backspace()
    elseif key == "delete" then
        self:delete()
    elseif key == "left" then
        if shift then
            -- Расширение выделения
            if not self.selectionStart then
                self.selectionStart = self.cursorPos
            end
            if self.cursorPos > 1 then
                self.cursorPos = self.cursorPos - 1
            end
            self.selectionEnd = self.cursorPos
        else
            -- Просто перемещение
            if self.cursorPos > 1 then
                self.cursorPos = self.cursorPos - 1
            end
            self.selectionStart = nil
            self.selectionEnd = nil
        end
        self:adjustOffset()
    elseif key == "right" then
        if shift then
            if not self.selectionStart then
                self.selectionStart = self.cursorPos
            end
            if self.cursorPos <= utf8len(self.text) then
                self.cursorPos = self.cursorPos + 1
            end
            self.selectionEnd = self.cursorPos
        else
            if self.cursorPos <= utf8len(self.text) then
                self.cursorPos = self.cursorPos + 1
            end
            self.selectionStart = nil
            self.selectionEnd = nil
        end
        self:adjustOffset()
    elseif key == "home" then
        if shift then
            if not self.selectionStart then
                self.selectionStart = self.cursorPos
            end
            self.cursorPos = 1
            self.selectionEnd = self.cursorPos
        else
            self.cursorPos = 1
            self.selectionStart = nil
            self.selectionEnd = nil
        end
        self:adjustOffset()
    elseif key == "end" then
        if shift then
            if not self.selectionStart then
                self.selectionStart = self.cursorPos
            end
            self.cursorPos = utf8len(self.text) + 1
            self.selectionEnd = self.cursorPos
        else
            self.cursorPos = utf8len(self.text) + 1
            self.selectionStart = nil
            self.selectionEnd = nil
        end
        self:adjustOffset()
    elseif key == "return" or key == "kpenter" then
        if self.onEnter then self.onEnter(self.text) end
    end

    self.cursorVisible = true
    self.cursorTimer = 0
end

function TextInput:update(dt)
    if self.focused then
        self.cursorTimer = self.cursorTimer + dt
        if self.cursorTimer >= self.cursorBlinkTime then
            self.cursorVisible = not self.cursorVisible
            self.cursorTimer = 0
        end
    end
end

function TextInput:draw()
    if not self.visible then return end

    -- Фон
    love.graphics.setColor(self.bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, self.borderRadius)

    -- Рамка
    love.graphics.setLineWidth(1)
    if self.focused then
        love.graphics.setColor(self.focusBorderColor)
    else
        love.graphics.setColor(self.borderColor)
    end
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, self.borderRadius)

    -- Шрифт
    love.graphics.setFont(self.font)
    local fontHeight = self.font:getHeight()
    local centerY = self.y + self.h/2 - fontHeight/2

    -- Область отсечения
    love.graphics.push("all")
    love.graphics.intersectScissor(self.x, self.y, self.w, self.h)

    -- Сдвиг для прокрутки
    love.graphics.translate(self.x + 10 - self.offsetX, centerY)

    local displayText = self:getDisplayText()

    -- Рисуем выделение, если есть
    if self.selectionStart and self.selectionEnd then
        local beforeSel = utf8sub(displayText, 1, self.selectionStart - 1)
        local selText = utf8sub(displayText, self.selectionStart, self.selectionEnd - 1)
        local selX = self.font:getWidth(beforeSel)
        local selW = self.font:getWidth(selText)
        love.graphics.setColor(self.selectionColor)
        love.graphics.rectangle("fill", selX, -fontHeight/2, selW, fontHeight * 2)
    end

    -- Текст
    if #self.text > 0 then
        love.graphics.setColor(self.textColor)
    else
        love.graphics.setColor(self.placeholderColor)
        displayText = self.placeholder
    end
    love.graphics.print(displayText, 0, 0)

    -- Курсор
    if self.focused and self.cursorVisible and not self.readonly then
        local textBefore = utf8sub(self.text, 1, self.cursorPos - 1)
        local beforeDisplay = self.password and string.rep("*", utf8len(textBefore)) or textBefore
        local cursorX = self.font:getWidth(beforeDisplay)
        love.graphics.setColor(self.cursorColor)
        love.graphics.setLineWidth(self.cursorWidth)
        love.graphics.line(cursorX, -fontHeight/2 + 2, cursorX, fontHeight)
    end

    love.graphics.pop()
end

return TextInput