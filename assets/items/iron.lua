local function logic(player)
    local hp_now, hp_max = player:getHealth(), player:getMaxHealth() 
    local rand_hp = math.floor(math.random(10, 30))

    if hp_now < hp_max then player:setHealth( rand_hp ) return true end
    
    return false
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



