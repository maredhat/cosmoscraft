local Lists = {}
Lists.__index = Lists

local function clamp(low, val, high) return math.max(low, math.min(high, val)) end


--[[
Lists.new(x, y, w, h, childrens, isVisible, options)
    x, y, w, h – абсолютные координаты и размер списка
    childrens   – начальные дочерние элементы (опционально)
    isVisible   – видимость (по умолчанию true)
    options = {
        stretch             = false,           -- растягивать элементы по ширине
        itemHeight          = 40,               -- высота каждого элемента
        spacing             = 5,                -- отступ между элементами
        hoverToScroll       = false,            -- прокрутка только при наведении
        showScrollbar       = true,             -- показывать полосу прокрутки
        scrollbarWidth      = 8,                -- ширина полосы
        scrollbarGap        = 2,                -- отступ от контента до полосы
        scrollbarColor      = {0.3,0.3,0.3,0.6}, -- цвет фона полосы
        scrollbarThumbColor = {0.6,0.6,0.6,0.9}, -- цвет ползунка
        scrollSpeed         = 5,                -- скорость плавной прокрутки
        scrollStep          = 40,               -- шаг прокрутки колесом
    }
]]

function Lists.new(x, y, w, h, childrens, isVisible, options)
    local self = setmetatable({}, Lists)
    self.x = x              
    self.y = y
    self.w = w
    self.h = h
    self.isVisible = (isVisible == nil) and true or isVisible
    self.childrens = childrens or {}
    self.event = { onScroll = nil }
    self.other = {}

    self.scrollY = 0
    self.targetScrollY = 0
    self.contentH = 0

    options = options or {}
    self.padding = options.padding or 0
    if type(self.padding) == "number" then
        self.padding = { left = self.padding, right = self.padding, top = self.padding, bottom = self.padding }
    end

    self.stretch = options.stretch or false
    self.itemHeight = options.itemHeight or 40
    self.spacing = options.spacing or 5
    self.hoverToScroll = options.hoverToScroll or false
    self.showScrollbar = options.showScrollbar ~= false
    self.scrollbarWidth = options.scrollbarWidth or 8
    self.scrollbarGap = options.scrollbarGap or 2
    self.scrollbarColor = options.scrollbarColor or {0.3, 0.3, 0.3, 0.6}
    self.scrollbarThumbColor = options.scrollbarThumbColor or {0.6, 0.6, 0.6, 0.9}
    self.scrollSpeed = options.scrollSpeed or 5
    self.scrollStep = options.scrollStep or 40

    self.draggingScrollbar = false
    self.dragStartY = 0
    self.dragStartScrollY = 0

    self:_relayout()
    return self
end

function Lists:_relayout()
    local padL = self.padding.left or 0
    local padR = self.padding.right or 0
    if self.showScrollbar then
        padR = padR + self.scrollbarWidth + self.scrollbarGap
    end
    local padT = self.padding.top or 0
    local innerW = self.w - padL - padR

    local items = {}
    for key, child in pairs(self.childrens) do
        table.insert(items, { key = key, child = child, order = child.order or 0 })
    end
    table.sort(items, function(a, b)
        if a.order == b.order then return tostring(a.key) < tostring(b.key) end
        return a.order < b.order
    end)

    local y = padT
    for _, entry in ipairs(items) do
        local child = entry.child
        child.x = padL
        child.y = y
        if self.stretch then child.w = innerW end
        child.h = self.itemHeight
        y = y + self.itemHeight + self.spacing
    end

    self:_updateContentSize()
end

function Lists:_updateContentSize()
    local maxY = 0
    for _, child in pairs(self.childrens) do
        if child.y and child.h then
            maxY = math.max(maxY, child.y + child.h)
        end
    end
    self.contentH = maxY
    local maxScroll = math.max(0, self.contentH - self.h)
    self.scrollY = clamp(0, self.scrollY, maxScroll)
    self.targetScrollY = clamp(0, self.targetScrollY, maxScroll)
end

function Lists:scroll(dy)
    if not self.isVisible then return end
    local maxScroll = math.max(0, self.contentH - self.h)
    self.targetScrollY = clamp(0, self.targetScrollY + dy, maxScroll)
    if self.event.onScroll then
        self.event.onScroll(self.targetScrollY)
    end
end

function Lists:onWheelMoved(_, y)
    if self.hoverToScroll then
        local mx, my = love.mouse.getPosition()
        if mx < self.x or mx > self.x + self.w or my < self.y or my > self.y + self.h then return end
    end
    self:scroll(-y * self.scrollStep)
end

function Lists:mousepressed(mx, my, button)
    if not self.isVisible or button ~= 1 then return end
    if not self.showScrollbar or self.contentH <= self.h then return end

    local barX   = self.x + self.w - self.scrollbarWidth - 2
    local barY   = self.y + 2
    local barH   = self.h - 4
    local thumbH = math.max(20, barH * (self.h / self.contentH))
    local thumbY = barY + (self.scrollY / (self.contentH - self.h)) * (barH - thumbH)

    if mx >= barX and mx <= barX + self.scrollbarWidth and
       my >= thumbY and my <= thumbY + thumbH then
        self.draggingScrollbar = true
        self.dragStartY = my
        self.dragStartScrollY = self.targetScrollY
    end
end

function Lists:mousereleased(_, _, button)
    if button == 1 then self.draggingScrollbar = false end
end

function Lists:addChildren(key, child)
    self.childrens[key] = child
    self:_relayout()
    return self
end

function Lists:removeChildren(key)
    self.childrens[key] = nil
    self:_relayout()
    return self
end

function Lists:update(dt)
    if not self.isVisible then return end

    if self.draggingScrollbar then
        local _, my = love.mouse.getPosition()
        local dy = my - self.dragStartY
        local barH = self.h - 4
        local thumbH = math.max(20, barH * (self.h / self.contentH))
        local scrollRange = barH - thumbH
        if scrollRange > 0 then
            local deltaScroll = (dy / scrollRange) * (self.contentH - self.h)
            self.targetScrollY = clamp(0, self.dragStartScrollY + deltaScroll, self.contentH - self.h)
        end
    end

    local diff = self.targetScrollY - self.scrollY
    if math.abs(diff) > 0.1 then
        self.scrollY = self.scrollY + diff * math.min(1, self.scrollSpeed * dt)
    else
        self.scrollY = self.targetScrollY
    end
end

function Lists:draw()
    if not self.isVisible then return self end

    self:render()

    love.graphics.stencil(function()
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    love.graphics.push("all")
    love.graphics.translate(self.x, self.y)
    love.graphics.translate(0, -self.scrollY)

    for _, child in pairs(self.childrens) do
        if child.draw then
            local y1 = child.y - self.scrollY
            if y1 < self.h and y1 + child.h > 0 then
                child:draw()
            end
        end
    end

    love.graphics.pop()
    love.graphics.setStencilTest()

    if self.showScrollbar and self.contentH > self.h then
        local barX = self.x + self.w - self.scrollbarWidth - 2
        local barY = self.y + 2
        local barH = self.h - 4
        local thumbH = math.max(20, barH * (self.h / self.contentH))
        local thumbY = barY + (self.scrollY / (self.contentH - self.h)) * (barH - thumbH)

        love.graphics.setColor(self.scrollbarColor)
        love.graphics.rectangle("fill", barX, barY, self.scrollbarWidth, barH, 4)
        love.graphics.setColor(self.scrollbarThumbColor)
        love.graphics.rectangle("fill", barX, thumbY, self.scrollbarWidth, thumbH, 4)
    end

    return self
end

function Lists:render()
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

function Lists:_event(key, cb) self.event[key] = cb; return self end
function Lists:SelectChidren(key) return self.childrens[key] end

return Lists