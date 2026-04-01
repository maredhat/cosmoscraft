local Ships = {
    [1] = {
        directSprite = 'resource/playership/1/',  
        hitPoints = 100,
        armor = 100,
        speedMovement = 100,
        speedRotation = 3,
        speedAttack = 1,
        speedSprint = 1.5,
        bulletConfig = {
            speed = 800,                -- Скорость пули
            damage = 100,                 -- Урон 
            penetration = 5,            -- Пробитие
            size = 5,                   -- Размер пули
            color = {0.7, 0.7, 0, 1},   -- Цвет пули RGBA
            timefactor = 10,            -- Скорострельность в сек
            lifetime = 5,               -- Время жизни пули
            multi = false,              -- Мультивыстрел
            coolDown = 0.35            -- Время для выстрела в сек
        },
        staminaTimeRegen   = 1.5,
        staminaExpenditure = 15,
        staminaCounter     = 150,
        acceleration       = 400,  
        maxSpeed           = 600,   
        friction           = 0.5,
        sprintAcceleration = 400,
        sprintMaxSpeed     = 700,   
        angularVelocity    = 0.2,
        angularFriction    = 0.5
    },
    [2] = 
    {

    }
}

return Ships