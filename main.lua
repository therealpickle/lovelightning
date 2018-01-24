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
        capture = {'key:v'},
        toggle = {'key:b'},
    }
})

-------------------------------------------------------------------------------
local Target = class("Target")
local SEC_TARG_DEF_COLOR = {255,50,50,127}

function Target:initialize(vector)
    self.x = vector.x
    self.y = vector.y
    self.r, self.g, self.b, self.a = unpack(SEC_TARG_DEF_COLOR)
end

function Target:setColor(r, g, b, a)
    self.r = r
    self.g = g
    self.b = b 
    self.a = a
end

function Target:draw()
    love.graphics.setColor(self.r,self.g,self.b,self.a)
    love.graphics.circle('fill', self.x, self.y, 3)
    love.graphics.circle('line', self.x, self.y, 10)
    love.graphics.setColor(255,255,255,255)
end

-------------------------------------------------------------------------------
local DEFAULT_MARGIN = 20
local margin = DEFAULT_MARGIN

local source_targ = Target:new({x=margin, y=love.graphics.getHeight()/2})
source_targ:setColor(0,255,0)

local prim_targ = Target:new({x=love.graphics.getWidth()-margin, 
    y=love.graphics.getHeight()/2})
prim_targ:setColor(255,0,0)

local sec_targs = {}
local n_sec_targs = 0

local function generate_sec_targs()
    sec_targs = {}
    for _ = 1 , n_sec_targs do
        local tx = margin+math.random()*(love.graphics.getWidth()-margin*2)
        local ty = margin+math.random()*(love.graphics.getHeight()-margin*2)
        table.insert(sec_targs,Target:new({x=tx,y=ty}))
    end
end

function love.load()
    bolt = LoveLightning:new(255,255,255)
    bolt:setSource(source_targ)
    bolt:setPrimaryTarget(prim_targ)

    for _ = 1 , n_sec_targs do
        local tx = margin+math.random()*(love.graphics.getWidth()-margin*2)
        local ty = margin+math.random()*(love.graphics.getHeight()-margin*2)
        table.insert(sec_targs,Target:new({x=tx,y=ty}))
    end
end

function love.resize(w, h)

    source_targ.x = margin
    source_targ.y = h/2

    prim_targ.x = w-margin
    prim_targ.y = h/2

    bolt:setSource(source_targ)
    bolt:setPrimaryTarget(prim_targ)
    bolt:setForkTargets()
    bolt:clear()

    generate_sec_targs()

end

local create_time = 0
function love.update(dt)
    local st = love.timer.getTime()
    
    local force_gen_sec_targs = false
    
    controls:update()
    
    if controls:pressed('toggle') then
        if margin == DEFAULT_MARGIN then 
            margin = 0 
        else 
            margin = DEFAULT_MARGIN 
        end 
        love.resize(love.graphics.getWidth(),love.graphics.getHeight())
    end

    if controls:pressed('increase') then
        n_sec_targs = n_sec_targs + 1
        force_gen_sec_targs = true
    end
    if controls:pressed('decrease') then
        n_sec_targs = math.max(0, n_sec_targs - 1)
        force_gen_sec_targs = true
    end
    if controls:pressed('generate') or force_gen_sec_targs then
        generate_sec_targs()
        force_gen_sec_targs = true
    end        

    if controls:pressed('fire') or force_gen_sec_targs then
        -- reset the color on the targets
        for _, t in ipairs(sec_targs) do
            t:setColor(unpack(SEC_TARG_DEF_COLOR))
        end

        local st = love.timer.getTime()
        bolt:setForkTargets(sec_targs)
        bolt:generate(function(t,level)
                t:setColor(255,255,25,255)
            end)

        create_time = love.timer.getTime() - st
    end

    if bolt.canvas and controls:pressed('capture') then
        love.filesystem.remove('capture.png')
        bolt.canvas:newImageData():encode('png', 'capture.png')
    end
end

function love.draw()
    local st = love.timer.getTime()
  
    source_targ:draw()
    prim_targ:draw()
    for _, t in ipairs(sec_targs) do
        t:draw()
    end
    bolt:draw()

    love.graphics.print(
        "V: Capture Image || B: Toggle Border",
        20, love.graphics.getHeight()-60)
    love.graphics.print(
        "plus: Increase Targets || minus: Decrease Targets",
        20, love.graphics.getHeight()-40)
    love.graphics.print(
        "Space: Generate Lightning || L Shift: Generate Targets",
        20, love.graphics.getHeight()-20)
    -- debug
    love.graphics.setFont(love.graphics.newFont())
    love.graphics.setColor(50, 200, 100, 200)
    love.graphics.print("FPS: "..love.timer.getFPS(), 20, 20)
    local dc = love.graphics.getStats()
    love.graphics.print("draws: "..dc.drawcalls, 20, 40)
    love.graphics.print("switches: "..dc.canvasswitches.." / "..dc.shaderswitches, 20, 60)
    love.graphics.print(math.floor((love.timer.getTime() - st) * 1000000) / 1000 .. " ms", 20, 80)
    love.graphics.print(math.floor(create_time * 1000000) / 1000 .. " ms", 20, 100)
    love.graphics.setColor(255,255,255,255)
end



