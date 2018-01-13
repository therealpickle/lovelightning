local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

math = require 'math'

class = require(folderOfThisFile .. 'lib/middleclass/middleclass')
vector = require(folderOfThisFile .. 'lib/hump.vector')
fx = require(folderOfThisFile .. 'fx')

-------------------------------------------------------------------------------
local LightningVertex = class('LightningVertex')

function LightningVertex:initialize(vec)
    self.vec = vec
    self.is_fork_root = false
    self.fork = nil
end

function LightningVertex:createFork(fork_vec)
    self.fork = {
        LightningVertex:new(self.vec),
        LightningVertex:new(self.vec+fork_vec)
    }
    self.is_fork_root = true
end

-------------------------------------------------------------------------------
LoveLightning = class("LoveLightning")

function LoveLightning:initialize(r,g,b)
    self.iterations = 8
    self.jitter_factor = 0.5
    self.fork_chance = 0.25
    self.max_fork_angle = math.pi/4
    self.color = {['r']=r,['g']=g,['b']=b}
end

function LoveLightning:setTarget(x,y)
    self.target = vector(x,y)
end

function LoveLightning:setSource(x,y)
    self.source = vector(x,y)
end

function LoveLightning:_add_jitter(vertices, max_offset)
    local newpath = {}

    for j = 1, #vertices-1, 1 do
        
        local vsp = vertices[j].vec      -- start point
        local vep = vertices[j+1].vec    -- end point
        local vmp = (vep+vsp)/2             -- mid point
        local vseg = vep-vsp
        local vnorm = vseg:perpendicular():normalized()
        
        local voffset = (math.random()*2-1)*max_offset*vnorm
    
        table.insert(newpath, vertices[j])
        
        local lvmp = LightningVertex(vmp+voffset)

        -- chance to create a fork from the midpoint
        if math.random() < self.fork_chance then 
            lvmp:createFork((vep-lvmp.vec):rotated(
                math.random()*2*self.max_fork_angle-self.max_fork_angle))
        end

        table.insert(newpath, lvmp)

        -- if the start point is a fork, then add jitter to the fork
        if vertices[j].is_fork_root == true then
            vertices[j].fork = self:_add_jitter(vertices[j].fork, max_offset)
        end

    end
    table.insert(newpath, vertices[#vertices])
    
    return newpath
end

function LoveLightning:create(source_x, source_y, target_x, target_y)

    local vsource = vector(source_x, source_y)
    local vtarget = vector(target_x, target_y)
    
    self.vertices = {
        LightningVertex:new(vsource),
        LightningVertex:new(vtarget)
    }

    local max_offset = (vtarget-vsource):len()*0.5*self.jitter_factor

    for i = 1, self.iterations, 1 do
        
        self.vertices = self:_add_jitter(self.vertices, max_offset)

        max_offset = max_offset/2
    end
end

function LoveLightning:_createForks(num_forks)
    self.forks = {}

    for _ = 1, num_forks, 1 do
        
        local forigin = self.trunk_segments[math.random(1,
            #self.trunk_segments)]

        -- the distance between source and the target
        local dist = math.sqrt((self.source['x']-self.target['x'])^2 + 
            (self.source['y']-self.target['y'])^2)

        -- pick a random fork length up to the dist
        local flen = math.random()*dist*0.5

        -- create vectors for the start and endpoints and segment
        local vsp = vector(forigin['start']['x'], forigin['start']['y'])
        local vep = vector(forigin['end']['x'], forigin['end']['y'])

        -- create vector for the fork and add to the endpoint
        local vfork = flen*(vep-vsp):normalized() + vep

        local fork_target = {['x']=vfork.x, ['y']=vfork.y}

        -- create a new line segment from the fork origin end point to the targ
        fork_segs = {{['start']=forigin['end'],['end']=fork_target}}

        -- add jitter to the line
        fork_segs = add_jitter(fork_segs, self.iterations, self.jitter_factor)    

        table.insert(self.forks, fork_segs) 
    end
end

function LoveLightning:update(dt)

end

local function get_points_from_vertex_list( vlist )
    local points = {}
    for _, v in ipairs(vlist) do
        table.insert(points, v.vec.x)
        table.insert(points, v.vec.y)
    end
    return points
end

local function draw_path(vertex_list, color, alpha, width)
    local points = get_points_from_vertex_list(vertex_list)
    
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

function LoveLightning:draw()
    if self.vertices then

        local restore_mode = love.graphics.getBlendMode()
        local restore_canvas = love.graphics.getCanvas()
    
        local canvas = love.graphics.newCanvas()
        love.graphics.setCanvas(canvas)

        draw_path(self.vertices, self.color, 32, 17)
        draw_path(self.vertices, self.color, 64, 7)
        draw_path(self.vertices, self.color, 128, 5)

        canvas = fx.blur(canvas)

        love.graphics.setCanvas(restore_canvas)

        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.draw(canvas,0,0)
        love.graphics.setBlendMode(restore_mode)

        draw_path(self.vertices, self.color, 255, 2)

    end
end

return LoveLightning
