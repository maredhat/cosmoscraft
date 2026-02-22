
return {
    {
        speed = 60,
        patrolSpeed = 35,
        rotationSpeed = 3,
        
        shootCooldown = 0.6,
        bulletSpeed = 350,
        bulletDamage = 8,
        bulletSize = 6,
        bulletColor = {1, 0.3, 0.3, 1},
        bulletCount = 1,
        bulletSpread = 0.15,
        bulletPenetration = 0.5,

        size = 32,
        color = {1, 0.2, 0.2, 1},
        health = 80,
        
        detectionRange = 450,
        attackRange = 380,
        communicationRange = 400,
        
        separationDistance = 60,
        preferredDistance = 200,
        tooCloseDistance = 120,
        tooFarDistance = 350,
        
        patrolTime = 8,
        patrolRadius = 600,
        
        chaosIntensity = 0.4,
        zigzagFrequency = 3,
        zigzagAmplitude = 40,
        
        investigationTime = 5,
        investigationSpeed = 45,


        drops = require('assets.items.config.rates').drone,

        debug = false,
    },
}