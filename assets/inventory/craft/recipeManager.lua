local RecipeManager = {}
RecipeManager.__index = RecipeManager


function RecipeManager.new()
    local self = setmetatable( {}, RecipeManager )

    return self
end


function RecipeManager:update( dt )
    
end

function RecipeManager:draw() end


return RecipeManager 