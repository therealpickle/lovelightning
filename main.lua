LoveLightning = require "lovelightning"
baton = require "lib/baton/baton"
class = require "lib/middleclass/middleclass"

-------------------------------------------------------------------------------
local controls = baton.new({
    controls = {
        primary = {'mouse:1'},
        secondary = {'mouse:2'},
        fire = {'key:space'},
        generate = {'key:lshift'},
        increase = {'key:kp+','key:+'},
        decrease = {'key:kp-','key:-'},
    }
})

-------------------------------------------------------------------------------
local Target = class("Target")

function Target:initialize(vector)
    self.x = vector.x
    self.y = vector.y
end

function Target:draw()
    love.graphics.setColor(255,50,50,127)
    love.graphics.circle('fill', self.x, self.y, 3)
    love.graphics.circle('line', self.x, self.y, 10)
    love.graphics.setColor(255,255,255,255)
end

-------------------------------------------------------------------------------
local MARGIN = 20
local sec_targs = {}
local n_targs = 3


function love.load()
    bolt = LoveLightning:new(255,255,255)
    bolt:setSource({x=20, y=love.graphics.getHeight()/2})
    bolt:setPrimaryTarget({x=love.graphics.getWidth()-20, y=love.graphics.getHeight()/2})
end

function love.update(dt)
    controls:update()
    if controls:pressed('increase') then
        n_targs = n_targs + 1
    end
    if controls:pressed('decrease') then
        n_targs = math.max(0, n_targs - 1)
    end

    if controls:pressed('generate') then
        sec_targs = {}
        for _ = 1 , n_targs do
            print(_)
            local tx = MARGIN+math.random()*(love.graphics.getWidth()-MARGIN*2)
            local ty = MARGIN+math.random()*(love.graphics.getHeight()-MARGIN*2)
            table.insert(sec_targs,Target:new({x=tx,y=ty}))
        end
    end        

    if controls:pressed('fire') then
        bolt:create()
    end
end

function love.draw()
    for _, t in ipairs(sec_targs) do
        t:draw()
    end
    bolt:draw()
end



