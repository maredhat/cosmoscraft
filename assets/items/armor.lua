function logic(player)
    local now, max = player:getArmor(), player:getMaxArmor()
    if now >= max then return false end

    local amount = math.floor(math.random(10, 30))
    local new = math.min(now + amount, max)

    player:setArmor(new)

    return new > now
end


return {
    name = "Armor",
    sprite = "resource/item/armor.png",
    color_sphere = {r = 0, g = 0, b = 0.5, a = 0.2}, 
    logic = logic,
    animation = nil
}




