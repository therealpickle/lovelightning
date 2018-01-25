-- local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

math = require 'math'

class = require 'lib/middleclass/middleclass'
vector = require 'lib/hump.vector'
cpml = require 'lib/cpml'
fx = require 'fx'

-------------------------------------------------------------------------------
local LightningVertex = class('LightningVertex')

function LightningVertex:initialize(vec)
    self.v = vec
    self.is_fork_root = false
    self.fork = nil
end

function LightningVertex:createFork(fork_vec)
    self.fork = {
        LightningVertex:new(self.v),
        LightningVertex:new(self.v+fork_vec)
    }
    self.is_fork_root = true
end

-------------------------------------------------------------------------------
LightningSegment = class("LightningSegment")

function LightningSegment:initialize(start, stop, level)
    self.level = level or 1
    self.start = start
    self.stop = stop
    self.points = {self.start, self.stop}
end

-------------------------------------------------------------------------------
LoveLightning = class("LoveLightning")

function LoveLightning:initialize(r,g,b,power)
    if power ~= nil then self.power = power else self.power = 1.0 end
    self.jitter_factor = 0.5
    self.fork_chance = 0.75
    self.max_fork_angle = math.pi/4
    self.color = {['r']=r,['g']=g,['b']=b}
end

function LoveLightning:setPrimaryTarget(targ)
    if targ.x ~= nil and targ.y ~= nil then
        self.target = vector(targ.x, targ.y)
    end
end

function LoveLightning:setSource(source)
    if source.x ~= nil and source.y ~= nil then
        self.source = vector(source.x,source.y)
    end
end

function LoveLightning:setForkTargets(targets)
    if targets then
        local targs = {}
        for _, t in ipairs(targets) do
            if t.x and t.y then
                table.insert(targs,t)
            end
        end
        self.fork_targets = targs
    else
        self.fork_targets = {}
    end
end

-- vertices : a list of LightningVertex
-- max_offset : maximum distance to offset the midpoint
-- level : the depth of forking (1 being the main trunk)
-- targets: a list of potential targets for the forks to hit (anything with 
--      an x and a y)
-- target_hit_handler : called when a target is selected for a fork to hit
--      in the form of function(target_hit, level_of_fork_that_hit)
function LoveLightning:_add_jitter(vertices, max_offset, level, targets, target_hit_handler)
    local newpath = {} -- new list of vertices after jitter is added

    for j = 1, #vertices-1, 1 do
        
        local vsp = vertices[j].v   -- start point
        local vep = vertices[j+1].v -- end point
        local vmp = (vep+vsp)/2     -- mid point
        local vseg = vep-vsp        -- vector from start to end point    
        
        -- offset the midpoint along a line perpendicular to the line segment
        -- from start to end a random ammount from -max_offset to max_offset
        local vnewmp = vmp + vseg:perpendicular():normalized()*max_offset*(
            math.random()*2-1)

        -- vectors of the new line segments
        local vseg1 = vnewmp-vsp
        local vseg2 = vep-vnewmp

        -- add the starting point to the new path
        table.insert(newpath, vertices[j])
        
        local mp_vertex = LightningVertex(vnewmp)

        -- chance to create a fork from the midpoint
        if math.random() < self.fork_chance/(level^2) then
            local selected_target = nil
            local index = nil
            local vt = nil

            -- generate the fork from the second segment buy randomly rotating
            local vfork = vseg2:rotated((math.random()-0.5)*2*self.max_fork_angle)
            
            -- can that fork hit a potential target?
            if targets then
                for i, t in ipairs(targets) do
                    vt = vector(t.x, t.y)

                    -- if the target is in the fork firing arc and is in range
                    if vfork:angleTo(vt) < self.max_fork_angle and 
                            vmp:dist(vt) < vfork:len()*2 then

                        selected_target = t
                        index = i
                        break
                    end
                end
            end
            
            if selected_target then
                print("target hit", selected_target.x, selected_target.y)
                table.remove(targets, index)
                mp_vertex:createFork(vt-vnewmp)
            
                -- call the handler if we hit something
                target_hit_handler(selected_target, level)
            else
                mp_vertex:createFork(vfork)
            end
            

        end

        -- add the new midpoint to the new path
        table.insert(newpath, mp_vertex)

        -- if the start point is a fork, then add jitter to the fork
        if vertices[j].is_fork_root == true then
            vertices[j].fork = self:_add_jitter(vertices[j].fork, max_offset, level+1)
        end



    end

    -- create the new path of LighningVertex's from start to newmidpoint to end
    table.insert(newpath, mp_vertex)
    table.insert(newpath, vertices[#vertices])
    
    return newpath
end

function LoveLightning:generate( fork_hit_handler )

    self.fork_hit_handler = fork_hit_handler

    local vsource = vector(self.source.x, self.source.y)
    local vtarget = vector(self.target.x, self.target.y)
    
    self.vertices = {
        LightningVertex:new(vsource),
        LightningVertex:new(vtarget)
    }

    self.distance = (vtarget-vsource):len()
    local max_jitter = self.distance*0.5*self.jitter_factor
    local iterations = math.min(11, math.max(6,math.floor(self.distance/50)))

    for i = 1, iterations, 1 do
        self.vertices = self:_add_jitter(self.vertices, max_jitter, 1, 
            self.fork_targets, fork_hit_handler)

        max_jitter = max_jitter*0.5
    end

    self.canvas = nil
end

function LoveLightning:clear()
    self.vertices = nil
    self.canvas = nil
end

function LoveLightning:update(dt)

end

local function draw_path(vertex_list, color, alpha, width)
    -- get points from vertex list
    local points = {}
    for _, v in ipairs(vertex_list) do
        table.insert(points, v.v.x)
        table.insert(points, v.v.y)
    end

    love.graphics.setLineJoin('miter')
    love.graphics.setLineWidth(width)
    love.graphics.setColor(color['r'], color['g'], color['b'], alpha)
    love.graphics.line(unpack(points))
    love.graphics.setColor(255,255,255)

    for _, v in ipairs(vertex_list) do
        if v.is_fork_root then
            draw_path(v.fork, color, alpha*0.5, width-1)
        end
    end
end

local function draw_segment(lightning_segment, color)
    local function points_of(lsegment)
        local p = {}
        for _, point in ipairs(lsegment.points) do
            table.insert(p, point.x)
            table.insert(p, point.y)
        end
        return p 
    end

    local alpha = 255 / lightning_segment.level
    local width = 2 / lightning_segment.level

    love.graphics.setLineJoin('miter')
    love.graphics.setLineWidth(width)
    love.graphics.setColor(color['r'], color['g'], color['b'], alpha)
    love.graphics.line(points_of(lightning_segment))
    love.graphics.setColor(255,255,255)    
end

-- function LoveLightning:draw()
--     local restore_mode = love.graphics.getBlendMode()
--     local restore_canvas = love.graphics.getCanvas()
    
--     if self.segments then 
--         if not self.canvas then
    
--             self.canvas = love.graphics.newCanvas()
--             love.graphics.setCanvas(self.canvas)

--             -- draw_path(self.vertices, self.color, 32*self.power, 17*self.power)
--             -- draw_path(self.vertices, self.color, 64*self.power, 7*self.power)
--             -- draw_path(self.vertices, self.color, 128*self.power, 5*self.power)

--             -- canvas = fx.blur(canvas)

--             -- draw_path(self.vertices, self.color, 255*self.power, 2*self.power)

--             for _, seg in ipairs(self.segments) do
--                 print("!!")
--                 draw_segment(seg, self.color)
--             end

--             love.graphics.setCanvas(restore_canvas)
--         else
--             love.graphics.setBlendMode("alpha", "premultiplied")
--             love.graphics.draw(self.canvas,0,0)
--             love.graphics.setBlendMode(restore_mode)
--         end
--     end
-- end

function LoveLightning:draw()
    local restore_mode = love.graphics.getBlendMode()
    local restore_canvas = love.graphics.getCanvas()
    
    if self.vertices then 
        if not self.canvas then
    
            self.canvas = love.graphics.newCanvas()
            love.graphics.setCanvas(self.canvas)

            -- draw_path(self.vertices, self.color, 32*self.power, 17*self.power)
            -- draw_path(self.vertices, self.color, 64*self.power, 7*self.power)
            -- draw_path(self.vertices, self.color, 128*self.power, 5*self.power)

            -- canvas = fx.blur(canvas)

            draw_path(self.vertices, self.color, 255*self.power, 2*self.power)


            love.graphics.setCanvas(restore_canvas)
        end
        
        if self.canvas then
            love.graphics.setBlendMode("alpha", "premultiplied")
            love.graphics.draw(self.canvas,0,0)
            love.graphics.setBlendMode(restore_mode)
        end
    end
end

return LoveLightning
