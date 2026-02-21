function logic(player)
    local now, max = player:getHealth(), player:getMaxHealth()
    if now >= max then return false end

    local amount = math.floor(math.random(10, 30))
    local new = math.min(now + amount, max)

    player:setHealth(new)

    return new > now
end

return
{
    name         = "Iron",
    sprite       = "resource/item/iron.png",
    color_sphere = {r = 1, g = 0, b = 0, a = 0.3}, 
    logic        = logic,
    animation    = nil,
    information  = nil
}



