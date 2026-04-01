local Recipe = {}
Recipe.__index = Recipe


function Recipe.new(recipeConfig)
    local self = setmetatable({}, Recipe)

    self.index       = recipeConfig.index       
    self.name        = recipeConfig.name        
    self.description = recipeConfig.description 
    self.craftCost   = recipeConfig.craftCost   
    self.craftTime   = recipeConfig.craftTime   

    self.icon      = love.graphics.newImage( recipeConfig.icon ) 
    self.instance  = recipeConfig.instance 

    return self
end


function Recipe:update( dt )
    
end

function Recipe:draw() end



return Recipe