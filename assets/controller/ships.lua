local Ships = {
    [1] = {
        directSprite = 'resource/playership/1/',  
        hitPoints = 100,
        armor = 100,
        speedMovement = 100,
        speedRotation = 2,
        speedAttack = 1,
        speedSprint = 2.5,
        bulletConfig = {
            speed = 250,                -- Скорость пули
            damage = 500,                 -- Урон 
            penetration = 5,            -- Пробитие
            size = 5,                   -- Размер пули
            color = {0.8, 0.4, 0, 1},   -- Цвет пули RGBA
            timefactor = 10,            -- Скорострельность в сек
            lifetime = 5,               -- Время жизни пули
            multi = false,              -- Мультивыстрел
            coolDown = 0.70             -- Время для выстрела в сек
        },
        staminaTimeRegen   = 5,
        staminaExpenditure = 0, 
        staminaCounter     = 100
    },
    [2] = 
    {

    }
}

return Ships