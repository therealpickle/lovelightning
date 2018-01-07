LoveLightning = require "lovelightning"


function love.load()
    bolt = LoveLightning:new(255,255,255)
    bolt:setSource(love.graphics.getWidth()/2,love.graphics.getHeight()/2)
end

function love.update(dt)
    bolt:setTarget(love.mouse.getPosition())
    if love.mouse.isDown(1) then
        bolt:update(dt)
    end
end

function love.draw()
    -- if love.mouse.isDown(1) then
        bolt:draw()
    -- end
end



