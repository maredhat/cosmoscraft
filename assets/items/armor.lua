function logic(player)
    local armor_now, armor_max = player:getArmor(), player:getMaxArmor() 
    local rand_armor = math.floor(math.random(10, 30))

    if armor_now < armor_max then player:setArmor( rand_armor ) return true end
    
    return false
end

function animation() 

end


return {
    name = "Armor",
    sprite = "resource/item/armor.png",
    color_sphere = {r = 0, g = 0, b = 0.5, a = 0.2}, 
    logic = logic,
    animation = nil
}

