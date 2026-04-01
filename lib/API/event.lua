local Event = {}
Event.__index = Event

function Event.new()
    local self = setmetatable({}, Event)
    self.listeners = {}   -- обязательно инициализировать
    return self
end

function Event:on(event, callback)
    if not self.listeners[event] then
        self.listeners[event] = {}
    end
    table.insert(self.listeners[event], callback)
end

function Event:off(event, callback)
    if self.listeners[event] then
        for i, cb in ipairs(self.listeners[event]) do
            if cb == callback then
                table.remove(self.listeners[event], i)
                break
            end
        end
    end
end

function Event:emit(event, ...)
    if self.listeners[event] then
        for _, cb in ipairs(self.listeners[event]) do
            cb(...)
        end
    end
end

return Event