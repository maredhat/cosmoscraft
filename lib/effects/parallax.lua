local SimpleParallax = {}
SimpleParallax.__index = SimpleParallax

local shaders = {
    starTwinkle = love.graphics.newShader([[
        extern float time;
        extern float speed;
        
        vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc) {
            vec4 pixel = Texel(texture, tc);
            float twinkle = sin(tc.x * 30.0 + time * speed) * cos(tc.y * 30.0 + time * speed * 0.5) * 0.3 + 0.7;
            float rnd = fract(sin(dot(tc, vec2(12.9898, 78.233))) * 43758.5453);
            twinkle = twinkle * (0.8 + rnd * 0.2);
            return pixel * color * vec4(1.0, 1.0, 1.0, twinkle);
        }
    ]]),
    
    nebulaPulse = love.graphics.newShader([[
        extern float time;
        extern float speed;
        extern vec3 colorShift;
        
        vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc) {
            vec4 pixel = Texel(texture, tc);
            float pulse1 = sin(time * speed + tc.x * 5.0) * 0.1 + 0.9;
            float pulse2 = cos(time * speed * 0.7 + tc.y * 5.0) * 0.1 + 0.9;
            float pulse = (pulse1 + pulse2) * 0.5;
            vec3 shifted = vec3(
                pixel.r * (1.0 + colorShift.r * 0.3 * sin(time)),
                pixel.g * (1.0 + colorShift.g * 0.3 * cos(time * 0.8)),
                pixel.b * (1.0 + colorShift.b * 0.3 * sin(time * 1.2))
            );
            return vec4(shifted, pixel.a * pulse) * color;
        }
    ]]),
    
    cometTail = love.graphics.newShader([[
        extern float time;
        
        vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc) {
            vec4 pixel = Texel(texture, tc);
            float blur = abs(tc.x - 0.5) * 2.0;
            blur = pow(blur, 1.5) * (0.5 + 0.5 * sin(time * 5.0));
            return pixel * color * vec4(1.0, 1.0, 1.0, 1.0 - blur * 0.7);
        }
    ]]),
    
    planetGlow = love.graphics.newShader([[
        extern float time;
        extern vec3 glowColor;
        
        vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc) {
            vec4 pixel = Texel(texture, tc);
            vec2 center = vec2(0.5, 0.5);
            float dist = distance(tc, center);
            float glow = exp(-dist * 3.0) * 0.5;
            glow = glow * (0.8 + 0.2 * sin(time * 2.0));
            return pixel * color + vec4(glowColor * glow, 0.0);
        }
    ]]),
    
    pulsarBeam = love.graphics.newShader([[
        extern float time;
        extern float pulseSpeed;
        
        vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc) {
            vec4 pixel = Texel(texture, tc);
            float pulse = abs(sin(time * pulseSpeed)) * 0.8 + 0.2;
            float beam = abs(sin(atan(tc.y - 0.5, tc.x - 0.5) * 8.0 + time * 10.0));
            beam = beam * 0.3;
            return pixel * color * vec4(1.0, 1.0, 1.0, pulse + beam);
        }
    ]]),
    
    chromatic = love.graphics.newShader([[
        extern float time;
        extern float strength;
        
        vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc) {
            float amount = strength * (0.5 + 0.5 * sin(time * 2.0));
            float r = Texel(texture, tc + vec2(amount * 0.01, 0.0)).r;
            float g = Texel(texture, tc).g;
            float b = Texel(texture, tc - vec2(amount * 0.01, 0.0)).b;
            return vec4(r, g, b, 1.0) * color;
        }
    ]]),
    
    deepSpace = love.graphics.newShader([[
        extern float time;
        
        float random(vec2 st) {
            return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453);
        }
        
        vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc) {
            vec4 pixel = Texel(texture, tc);
            float stars = random(tc * 1000.0 + time * 0.1);
            stars = step(0.995, stars) * 0.5;
            return pixel * color + vec4(vec3(stars), 1.0);
        }
    ]]),
}

function SimpleParallax.new(screenWidth, screenHeight)
    local self = setmetatable({}, SimpleParallax)
    self.width = screenWidth or love.graphics.getWidth()
    self.height = screenHeight or love.graphics.getHeight()
    self.layers = {}
    self.cameraX = 0
    self.cameraY = 0
    self.time = 0
    self.worldSize = 20000
    return self
end

function SimpleParallax:addStars(count, speed, minSize, maxSize, color1, color2, autoSpeed, starType)
    local stars = {}
    color1 = color1 or {0.8, 0.8, 1.0, 0.5}
    color2 = color2 or {1.0, 1.0, 1.0, 1.0}
    starType = starType or "normal"
    
    for i = 1, count do
        local star = {
            x = love.math.random(-self.worldSize, self.worldSize),
            y = love.math.random(-self.worldSize, self.worldSize),
            size = love.math.random(minSize or 1, maxSize or 4),
            baseSize = love.math.random(minSize or 1, maxSize or 4),
            color = {
                r = love.math.random(color1[1] * 100, color2[1] * 100) / 100,
                g = love.math.random(color1[2] * 100, color2[2] * 100) / 100,
                b = love.math.random(color1[3] * 100, color2[3] * 100) / 100,
                a = love.math.random(color1[4] * 100, color2[4] * 100) / 100
            },
            blinkSpeed = love.math.random(1, 20) / 20,
            blinkPhase = love.math.random(0, 628) / 100,
            type = starType
        }
        
        if starType == "red_giant" then
            star.size = star.size * 2
            star.color.r = star.color.r * 1.5
        elseif starType == "blue_giant" then
            star.size = star.size * 1.5
            star.color.b = 1.0
        end
        
        table.insert(stars, star)
    end
    
    local layer = {
        type = "stars",
        elements = stars,
        speed = speed or 0.2,
        autoSpeed = autoSpeed or 0,
        offsetX = 0,
        offsetY = 0,
        visible = true,
        drawDistance = 300,
        useShader = true,
        shader = shaders.starTwinkle,
        shaderParams = {speed = 2.0}
    }
    table.insert(self.layers, layer)
    return layer
end

function SimpleParallax:addNebula(count, speed, autoSpeed, nebulaType)
    local nebulae = {}
    nebulaType = nebulaType or "normal"
    
    for i = 1, count do
        local color
        if nebulaType == "red" then
            color = {0.8, 0.2, 0.2, love.math.random(3, 8) / 100}
        elseif nebulaType == "blue" then
            color = {0.2, 0.4, 0.9, love.math.random(3, 8) / 100}
        elseif nebulaType == "purple" then
            color = {0.7, 0.3, 0.9, love.math.random(3, 8) / 100}
        else
            color = {
                love.math.random(20, 60) / 100,
                love.math.random(10, 50) / 100,
                love.math.random(40, 90) / 100,
                love.math.random(3, 8) / 100
            }
        end
        
        table.insert(nebulae, {
            x = love.math.random(-self.worldSize, self.worldSize),
            y = love.math.random(-self.worldSize, self.worldSize),
            size = love.math.random(300, 1000),
            color = color,
            pulseSpeed = love.math.random(2, 8) / 10,
            pulsePhase = love.math.random(0, 628) / 100
        })
    end
    
    local layer = {
        type = "nebula",
        elements = nebulae,
        speed = speed or 0.03,
        autoSpeed = autoSpeed or 0.005,
        offsetX = 0,
        offsetY = 0,
        visible = true,
        drawDistance = 800,
        useShader = true,
        shader = shaders.nebulaPulse,
        shaderParams = {speed = 1.5, colorShift = {0.2, 0.1, 0.3}}
    }
    table.insert(self.layers, layer)
    return layer
end

function SimpleParallax:addComets(count, speed, autoSpeed, cometType)
    local comets = {}
    cometType = cometType or "normal"
    
    for i = 1, count do
        local angle = love.math.random(0, 628) / 100
        local length = love.math.random(60, 150)
        local thickness = love.math.random(3, 8)
        
        local color
        if cometType == "ice" then
            color = {0.5, 0.8, 1.0, love.math.random(40, 70) / 100}
        elseif cometType == "fire" then
            color = {1.0, 0.6, 0.2, love.math.random(40, 70) / 100}
        else
            color = {
                love.math.random(70, 100) / 100,
                love.math.random(60, 90) / 100,
                1.0,
                love.math.random(30, 60) / 100
            }
        end
        
        table.insert(comets, {
            x = love.math.random(-self.worldSize, self.worldSize),
            y = love.math.random(-self.worldSize, self.worldSize),
            angle = angle,
            length = length,
            thickness = thickness,
            moveSpeed = love.math.random(20, 60) / 10,
            color = color,
            pulsePhase = love.math.random(0, 628) / 100
        })
    end
    
    local layer = {
        type = "comets",
        elements = comets,
        speed = speed or 0.2,
        autoSpeed = autoSpeed or 0.05,
        offsetX = 0,
        offsetY = 0,
        visible = true,
        drawDistance = 400,
        useShader = true,
        shader = shaders.cometTail,
        shaderParams = {}
    }
    table.insert(self.layers, layer)
    return layer
end

function SimpleParallax:addPlanets(count, speed, autoSpeed)
    local planets = {}
    
    for i = 1, count do
        local planetType = love.math.random(1, 4)
        local color, glowColor
        
        if planetType == 1 then
            color = {0.2, 0.4, 0.8, 0.3}
            glowColor = {0.2, 0.5, 1.0}
        elseif planetType == 2 then
            color = {0.8, 0.3, 0.2, 0.3}
            glowColor = {1.0, 0.4, 0.2}
        elseif planetType == 3 then
            color = {0.9, 0.7, 0.4, 0.3}
            glowColor = {1.0, 0.8, 0.4}
        else
            color = {0.6, 0.8, 1.0, 0.3}
            glowColor = {0.6, 0.9, 1.0}
        end
        
        table.insert(planets, {
            x = love.math.random(-self.worldSize, self.worldSize),
            y = love.math.random(-self.worldSize, self.worldSize),
            size = love.math.random(800, 2000),
            color = color,
            glowColor = glowColor,
            rotation = love.math.random(0, 628) / 100,
            rotationSpeed = love.math.random(1, 5) / 100,
            hasRing = love.math.random() > 0.7,
            ringSize = love.math.random(1200, 2500)
        })
    end
    
    local layer = {
        type = "planets",
        elements = planets,
        speed = speed or 0.01,
        autoSpeed = autoSpeed or 0.001,
        offsetX = 0,
        offsetY = 0,
        visible = true,
        drawDistance = 2000,
        useShader = true,
        shader = shaders.planetGlow,
        shaderParams = {glowColor = {1.0, 1.0, 1.0}}
    }
    table.insert(self.layers, layer)
    return layer
end

function SimpleParallax:addPulsars(count, speed, autoSpeed)
    local pulsars = {}
    
    for i = 1, count do
        table.insert(pulsars, {
            x = love.math.random(-self.worldSize, self.worldSize),
            y = love.math.random(-self.worldSize, self.worldSize),
            size = love.math.random(20, 50),
            color = {0.2, 0.8, 1.0, 0.8},
            pulseSpeed = love.math.random(20, 50) / 10,
            pulsePhase = love.math.random(0, 628) / 100
        })
    end
    
    local layer = {
        type = "pulsars",
        elements = pulsars,
        speed = speed or 0.2,
        autoSpeed = autoSpeed or 0.03,
        offsetX = 0,
        offsetY = 0,
        visible = true,
        drawDistance = 500,
        useShader = true,
        shader = shaders.pulsarBeam,
        shaderParams = {pulseSpeed = 5.0}
    }
    table.insert(self.layers, layer)
    return layer
end

function SimpleParallax:addGalaxies(count, speed, autoSpeed)
    local galaxies = {}
    
    for i = 1, count do
        table.insert(galaxies, {
            x = love.math.random(-self.worldSize, self.worldSize),
            y = love.math.random(-self.worldSize, self.worldSize),
            size = love.math.random(1500, 3000),
            color = {
                love.math.random(20, 50) / 100,
                love.math.random(10, 40) / 100,
                love.math.random(40, 80) / 100,
                love.math.random(2, 5) / 100
            },
            angle = love.math.random(0, 628) / 100,
            rotationSpeed = love.math.random(1, 3) / 100
        })
    end
    
    local layer = {
        type = "galaxies",
        elements = galaxies,
        speed = speed or 0.005,
        autoSpeed = autoSpeed or 0.001,
        offsetX = 0,
        offsetY = 0,
        visible = true,
        drawDistance = 3000,
        useShader = false
    }
    table.insert(self.layers, layer)
    return layer
end

function SimpleParallax:addAsteroids(count, speed, autoSpeed)
    local asteroids = {}
    
    for i = 1, count do
        table.insert(asteroids, {
            x = love.math.random(-self.worldSize, self.worldSize),
            y = love.math.random(-self.worldSize, self.worldSize),
            size = love.math.random(10, 40),
            color = {0.5, 0.4, 0.3, love.math.random(30, 60) / 100},
            angle = love.math.random(0, 628) / 100,
            rotationSpeed = love.math.random(1, 5) / 100
        })
    end
    
    local layer = {
        type = "asteroids",
        elements = asteroids,
        speed = speed or 0.15,
        autoSpeed = autoSpeed or 0.02,
        offsetX = 0,
        offsetY = 0,
        visible = true,
        drawDistance = 300,
        useShader = false
    }
    table.insert(self.layers, layer)
    return layer
end

function SimpleParallax:getVisibleElements(layer, cameraX, cameraY)
    local visible = {}
    local margin = layer.drawDistance or 300
    local left = cameraX - self.width/2 - margin
    local right = cameraX + self.width/2 + margin
    local top = cameraY - self.height/2 - margin
    local bottom = cameraY + self.height/2 + margin
    
    for _, element in ipairs(layer.elements) do
        local worldX = element.x + (layer.offsetX or 0)
        local worldY = element.y + (layer.offsetY or 0)
        
        if worldX > left and worldX < right and worldY > top and worldY < bottom then
            table.insert(visible, element)
        end
    end
    
    return visible
end

function SimpleParallax:updateTime(dt)
    self.time = self.time + dt
end

function SimpleParallax:update(dx, dy)
    self.cameraX = self.cameraX + (dx or 0)
    self.cameraY = self.cameraY + (dy or 0)
end

function SimpleParallax:autoUpdate(dt)
    for _, layer in ipairs(self.layers) do
        if layer.autoSpeed and layer.autoSpeed ~= 0 then
            layer.offsetX = (layer.offsetX or 0) + layer.autoSpeed * dt * 60
            layer.offsetY = (layer.offsetY or 0) + layer.autoSpeed * dt * 60
        end
        
        if layer.type == "comets" then
            for _, comet in ipairs(layer.elements) do
                comet.x = comet.x + math.cos(comet.angle) * comet.moveSpeed * dt * 30
                comet.y = comet.y + math.sin(comet.angle) * comet.moveSpeed * dt * 30
                if math.abs(comet.x) > self.worldSize then comet.x = -comet.x * 0.8 end
                if math.abs(comet.y) > self.worldSize then comet.y = -comet.y * 0.8 end
            end
        end
        
        if layer.type == "planets" then
            for _, planet in ipairs(layer.elements) do
                planet.rotation = planet.rotation + planet.rotationSpeed * dt
            end
        end
        
        if layer.type == "galaxies" then
            for _, galaxy in ipairs(layer.elements) do
                galaxy.angle = galaxy.angle + galaxy.rotationSpeed * dt
            end
        end
    end
end

local function drawStars(layer, elements, cameraX, cameraY, time, screenWidth, screenHeight)
    for _, star in ipairs(elements) do
        local worldX = star.x + (layer.offsetX or 0)
        local worldY = star.y + (layer.offsetY or 0)
        local screenX = worldX - cameraX + screenWidth/2
        local screenY = worldY - cameraY + screenHeight/2
        local blink = math.sin(time * star.blinkSpeed + star.blinkPhase) * 0.2 + 0.8
        love.graphics.setColor(star.color.r, star.color.g, star.color.b, star.color.a * blink)
        love.graphics.circle("fill", screenX, screenY, star.size)
    end
end

local function drawNebula(layer, elements, cameraX, cameraY, time, screenWidth, screenHeight)
    for _, nebula in ipairs(elements) do
        local worldX = nebula.x + (layer.offsetX or 0)
        local worldY = nebula.y + (layer.offsetY or 0)
        local screenX = worldX - cameraX + screenWidth/2
        local screenY = worldY - cameraY + screenHeight/2
        local pulse = math.sin(time * nebula.pulseSpeed + nebula.pulsePhase) * 0.1 + 0.9
        for i = 1, 3 do
            local alpha = nebula.color[4] * pulse / i
            love.graphics.setColor(nebula.color[1], nebula.color[2], nebula.color[3], alpha)
            love.graphics.circle("fill", screenX, screenY, nebula.size * (1 + i * 0.2))
        end
    end
end

local function drawComets(layer, elements, cameraX, cameraY, time, screenWidth, screenHeight)
    for _, comet in ipairs(elements) do
        local worldX = comet.x + (layer.offsetX or 0)
        local worldY = comet.y + (layer.offsetY or 0)
        local baseX = worldX - cameraX + screenWidth/2
        local baseY = worldY - cameraY + screenHeight/2
        local dx = math.cos(comet.angle)
        local dy = math.sin(comet.angle)
        local pulse = math.sin(time * 3 + comet.pulsePhase) * 0.2 + 0.8
        
        for i = 5, 1, -1 do
            local t = i / 5
            local alpha = comet.color[4] * t * 0.7 * pulse
            local size = comet.thickness * t
            love.graphics.setColor(comet.color[1], comet.color[2], comet.color[3], alpha)
            local x = baseX - dx * comet.length * t
            local y = baseY - dy * comet.length * t
            love.graphics.circle("fill", x, y, size)
        end
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", baseX, baseY, comet.thickness * 1.5)
    end
end

local function drawPlanets(layer, elements, cameraX, cameraY, screenWidth, screenHeight)
    for _, planet in ipairs(elements) do
        local worldX = planet.x + (layer.offsetX or 0)
        local worldY = planet.y + (layer.offsetY or 0)
        local screenX = worldX - cameraX + screenWidth/2
        local screenY = worldY - cameraY + screenHeight/2
        love.graphics.setColor(planet.color[1], planet.color[2], planet.color[3], planet.color[4])
        love.graphics.circle("fill", screenX, screenY, planet.size)
        if planet.hasRing then
            love.graphics.setColor(planet.color[1], planet.color[2], planet.color[3], planet.color[4] * 0.3)
            love.graphics.ellipse("line", screenX, screenY, planet.ringSize, planet.ringSize * 0.2, 50)
        end
    end
end

local function drawPulsars(layer, elements, cameraX, cameraY, time, screenWidth, screenHeight)
    for _, pulsar in ipairs(elements) do
        local worldX = pulsar.x + (layer.offsetX or 0)
        local worldY = pulsar.y + (layer.offsetY or 0)
        local screenX = worldX - cameraX + screenWidth/2
        local screenY = worldY - cameraY + screenHeight/2
        local pulse = math.abs(math.sin(time * pulsar.pulseSpeed + pulsar.pulsePhase))
        love.graphics.setColor(pulsar.color[1], pulsar.color[2], pulsar.color[3], pulse)
        love.graphics.circle("fill", screenX, screenY, pulsar.size)
    end
end

local function drawGalaxies(layer, elements, cameraX, cameraY, screenWidth, screenHeight)
    for _, galaxy in ipairs(elements) do
        local worldX = galaxy.x + (layer.offsetX or 0)
        local worldY = galaxy.y + (layer.offsetY or 0)
        local screenX = worldX - cameraX + screenWidth/2
        local screenY = worldY - cameraY + screenHeight/2
        love.graphics.setColor(galaxy.color[1], galaxy.color[2], galaxy.color[3], galaxy.color[4])
        love.graphics.circle("fill", screenX, screenY, galaxy.size)
    end
end

local function drawAsteroids(layer, elements, cameraX, cameraY, screenWidth, screenHeight)
    for _, asteroid in ipairs(elements) do
        local worldX = asteroid.x + (layer.offsetX or 0)
        local worldY = asteroid.y + (layer.offsetY or 0)
        local screenX = worldX - cameraX + screenWidth/2
        local screenY = worldY - cameraY + screenHeight/2
        love.graphics.setColor(asteroid.color[1], asteroid.color[2], asteroid.color[3], asteroid.color[4])
        love.graphics.circle("fill", screenX, screenY, asteroid.size)
    end
end

function SimpleParallax:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    for _, layer in ipairs(self.layers) do
        if layer.visible then
            if layer.useShader and layer.shader then
                love.graphics.setShader(layer.shader)
                if layer.shader:hasUniform("time") then
                    layer.shader:send("time", self.time)
                end
                if layer.shaderParams.speed and layer.shader:hasUniform("speed") then
                    layer.shader:send("speed", layer.shaderParams.speed)
                end
                if layer.shaderParams.colorShift and layer.shader:hasUniform("colorShift") then
                    layer.shader:send("colorShift", layer.shaderParams.colorShift)
                end
                if layer.shaderParams.glowColor and layer.shader:hasUniform("glowColor") then
                    layer.shader:send("glowColor", layer.shaderParams.glowColor)
                end
                if layer.shaderParams.pulseSpeed and layer.shader:hasUniform("pulseSpeed") then
                    layer.shader:send("pulseSpeed", layer.shaderParams.pulseSpeed)
                end
            end
            
            local visible = self:getVisibleElements(layer, self.cameraX, self.cameraY)
            
            if #visible > 0 then
                if layer.type == "stars" then
                    drawStars(layer, visible, self.cameraX, self.cameraY, self.time, screenWidth, screenHeight)
                elseif layer.type == "nebula" then
                    drawNebula(layer, visible, self.cameraX, self.cameraY, self.time, screenWidth, screenHeight)
                elseif layer.type == "comets" then
                    drawComets(layer, visible, self.cameraX, self.cameraY, self.time, screenWidth, screenHeight)
                elseif layer.type == "planets" then
                    drawPlanets(layer, visible, self.cameraX, self.cameraY, screenWidth, screenHeight)
                elseif layer.type == "pulsars" then
                    drawPulsars(layer, visible, self.cameraX, self.cameraY, self.time, screenWidth, screenHeight)
                elseif layer.type == "galaxies" then
                    drawGalaxies(layer, visible, self.cameraX, self.cameraY, screenWidth, screenHeight)
                elseif layer.type == "asteroids" then
                    drawAsteroids(layer, visible, self.cameraX, self.cameraY, screenWidth, screenHeight)
                end
            end
            
            love.graphics.setShader()
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function SimpleParallax:reset()
    self.cameraX = 0
    self.cameraY = 0
    for _, layer in ipairs(self.layers) do
        layer.offsetX = 0
        layer.offsetY = 0
    end
end

return SimpleParallax