-- local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

math = require 'math'

class = require 'lib/middleclass/middleclass'
vector = require 'lib/hump.vector'
cpml = require 'lib/cpml'
fx = require 'fx'



local vertex = {}

function vertex.new() 
    return {vector=vector.new(0,0), last=nil, next=nil, fork=nil}
end

function vertex.break_links(vrtx)
    vrtx.last=nil
    vrtx.next=nil
    vrtx.fork=nil
    return vrtx
end 

function vertex.clear(vrtx)
    vrtx.vector.x=0
    vrtx.vector.y=0
    vertex.break_links(vrtx)
    return vrtx
end

function vertex.insert_fork(from_this, fork_this)
    if fork_this.last then print("Cannot fork to vertex with last") return end
    from_this.fork = fork_this
    fork_this.last = from_this
end

-- inserts X after A
function vertex.insert_after(A, X)
    X.next = A.next
    if X.next then X.next.last = X end
    A.next = X
    X.last = A
end

function vertex.insert_before(before_this, this)
    -- body
end

vertex.pool = {}

function vertex.pool.new(size)
    local noo_poo = {}
    for i=1,size do
        table.insert(noo_poo, vertex.new())
    end
    return noo_poo
end

function vertex.pool.get(from_pool)
    local this = from_pool[#from_pool]
    from_pool[#from_pool] = nil
    if this then return this else return vertex.new() end
end

function vertex.pool.put(to_pool, this)
    -- also put it's children back in the pool
    if this.fork then vertex.pool.put(to_pool, this.fork) end
    if this.next then vertex.pool.put(to_pool, this.next) end
    
    if this.last and this.last.next == this then
        -- this is a next of last
        this.last.next = nil
    elseif this.last and this.last.fork == thes then
        -- this is a fork of last
        this.last.fork = nil
    end
    to_pool[#to_pool+1] = vertex.clear(this)
end

------------------------------------------------------------------------------
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
LoveLightning = class("LoveLightning")

function LoveLightning:initialize(r,g,b,power)
    if power ~= nil then self.power = power else self.power = 1.0 end
    self.displacement_factor = 0.5
    self.fork_chance = 0.75
    self.max_fork_angle = math.pi/4
    self.color = {['r']=r,['g']=g,['b']=b}

    self.max_fork_depth = 1000000 -- can probably get removed eventually
    self.max_forks = 1000000 -- same
    self.max_iterations = 11
    self.min_iterations = 4
    self.min_seg_len = 3

    -- vertex shit
    self.vpool = vertex.pool.new(1000)
    self.source_vertex = vertex.new()
    self.target_vertex = vertex.new()
end

function LoveLightning:setPrimaryTarget(targ)
    if targ.x ~= nil and targ.y ~= nil then
        self.target_vertex.vector.x = targ.x
        self.target_vertex.vector.y = targ.y
    end
end

function LoveLightning:setSource(source)
    if source.x ~= nil and source.y ~= nil then
        self.source_vertex.vector.x = source.x
        self.source_vertex.vector.y = source.y
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

-- adds an offset midpoint between 
function LoveLightning:_add_midpoint_displacement(A, B, max_offset)
    assert(B.last == A)
    -- need to check and see if B is a fork of A
    if A.fork == B.last then local is_fork = true else local is_fork = false end

        
    if (B.vector-A.vector):len() > 2*self.min_seg_len then    
        M = vertex.pool.get(self.vpool)

        -- offset the midpoint along a line perpendicular to the line segment
        -- from start to end a random ammount from -max_offset to max_offset
        M.vector = (B.vector+A.vector)/2 + 
            (B.vector-A.vector):perpendicular():normalized() *
            max_offset*(math.random()*2-1)

        vertex.insert_after(A, M)

    end
end

-- will create a fork at vertex by rotating a vector from vertex to it's next
-- a random ammount
function LoveLightning:_fork(at_vertex, targets, target_hit_handler)

end

-- root : root vertex to start with
-- max_offset : maximum distance to offset the midpoint
-- level : the depth of forking (1 being the main trunk)
-- targets: a list of potential targets for the forks to hit (anything with 
--      an x and a y)
-- target_hit_handler : called when a target is selected for a fork to hit
--      in the form of function(target_hit, level_of_fork_that_hit)
function LoveLightning:_add_jitter(root, max_offset, level, targets, target_hit_handler)
    local newpath = {} -- new list of vertices after jitter is added

    if level > self.max_fork_depth then
        return vertices
    end

    for j = 1, #vertices-1, 1 do

        local vsp = vertices[j].v   -- start point
        local vep = vertices[j+1].v -- end point
        
        table.insert(newpath, vertices[j])
        
        if (vep-vsp):len() > 2*self.min_seg_len then
            
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
            
            local mp_vertex = LightningVertex(vnewmp)

            -- chance to create a fork from the midpoint
            if not vertices[j].is_fork_root and self.num_forks < self.max_forks and 
                    math.random() < self.fork_chance/(level^2)  then
                self.num_forks = self.num_forks + 1
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
                        if vfork:angleTo(vt) < self.max_fork_angle/2 and 
                                vmp:dist(vt) < vfork:len() then

                            selected_target = t
                            index = i
                            break
                        end
                    end
                end
                
                if selected_target then
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
        end

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

local function countIt(vrtx)
    local count = 1
    
    if vrtx.next then
        count = count + countIt(vrtx.next)
    end

    if vrtx.fork then
        count = count + countIt(vrtx.fork)
    end

    return count
end

function LoveLightning:verticeCount()
    return countIt(self.source_vertex)
end

function LoveLightning:generate( fork_hit_handler )

    self.num_forks = 0
    self.fork_hit_handler = fork_hit_handler

    self:clear()

    self.distance = (self.target_vertex.vector-self.source_vertex.vector):len()
    local max_displacement = self.distance*0.5*self.displacement_factor
    local iterations = math.min(self.max_iterations, math.max(
        self.min_iterations,math.floor(self.distance/50)))

    local iters = 0
    for i = 1, iterations do
        iters = iters+1
        local vrtx = self.source_vertex
        while vrtx.next do
            vrtx = vrtx.next
            self:_add_midpoint_displacement(vrtx.last, vrtx, max_displacement)
        end
        -- self.vertices = self:_add_jitter(self.vertices, max_displacement, 1, 
        --     self.fork_targets, fork_hit_handler)

        max_displacement = max_displacement*0.5
    end

    self.canvas = nil -- will trigger a redraw
    self.last_iteration_count = iters -- for debugging
end



function LoveLightning:clear()
    -- break the target vertex off the tree
    if self.target_vertex.last then self.target_vertex.last.next = nil end

    -- put the source's fork and next back in the pool (and their children in tree)
    if self.source_vertex.next then vertex.pool.put(self.vpool, self.source_vertex.next) end
    if self.source_vertex.fork then vertex.pool.put(self.vpool, self.source_vertex.fork) end

    vertex.insert_after(self.source_vertex, self.target_vertex)
end

function LoveLightning:update(dt)

end

local function draw_path(start_vertex, color, alpha, width)
    local points = {} -- list of x and y s of the points of the lines to draw
    
    -- check to see if the start vertex is the start of a fork
    if start_vertex.last and start_vertex.last.fork == start_vertex then
        -- add the point from it's last vertex to start the fork
        points[#points+1] = start_vertex.last.vector.x
        points[#points+1] = start_vertex.last.vector.y
    end

    -- add the start vertex points
    points[#points+1] = start_vertex.vector.x
    points[#points+1] = start_vertex.vector.y

    local vrtx = start_vertex
    while vrtx.next do
        points[#points+1] = vrtx.next.vector.x
        points[#points+1] = vrtx.next.vector.y
        vrtx = vrtx.next
    end

    love.graphics.setLineJoin('miter')
    love.graphics.setLineWidth(width)
    love.graphics.setColor(color['r'], color['g'], color['b'], alpha)
    love.graphics.line(unpack(points))

    love.graphics.setColor(255,255,255)

    local vrtx = start_vertex
    while vrtx.next do
        if vrtx.fork then
            draw_path(vrtx.fork, color, alpha*0.75, width*.75)
        end    
        vrtx = vrtx.next
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

function LoveLightning:draw()
    local restore_mode = love.graphics.getBlendMode()
    local restore_canvas = love.graphics.getCanvas()
    
    if self.source_vertex.next then 
        if not self.canvas then
    
            self.canvas = love.graphics.newCanvas()
            love.graphics.setCanvas(self.canvas)

            -- draw_path(self.vertices, self.color, 32*self.power, 17*self.power)
            -- draw_path(self.vertices, self.color, 64*self.power, 7*self.power)
            -- draw_path(self.vertices, self.color, 128*self.power, 5*self.power)

            -- canvas = fx.blur(canvas)

            draw_path(self.source_vertex, self.color, 255*self.power, 2*self.power)


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
