function logic(player)
    local stamina_now, stamina_max = player:getStamina(), player:getStaminaMax()
    if stamina_now < stamina_max then
        local rand_stamina = math.floor(math.random(25, 50))
        local new_stamina = math.min(stamina_now + rand_stamina, stamina_max)
        player:setStamina(new_stamina)
        return true
    end
    return false
end


return {
    name = "Fuel",
    sprite = "resource/item/fuel.png",
    color_sphere = {r = 0.5, g = 0.5, b = 0, a = 0.2}, 
    logic = logic,
    animation = nil
}
