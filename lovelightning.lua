math = require 'math'
class = require 'lib/middleclass/middleclass'
vector = require "lib/hump.vector"


LoveLighting = class("LoveLighting")

--[[
A point is a table in the form of {['x']=x,['y']=y}

A line segment is a table with two points in the form of {['start']=startpoint,
    ['end']=endpoint}

--]]

function LoveLighting:initialize(r,g,b)
    self.iterations = 6
    self.jitter_factor = 0.25
    self.color = {['r']=r,['g']=g,['b']=b}
end

function LoveLighting:setTarget(x,y)
    self.target = {['x']=x, ['y']=y}
end

function LoveLighting:setSource(x,y)
    self.source = {['x']=x, ['y']=y}
end

-- takes a list of line segments and for each iteration breaks each segment
-- in half and moves the midpoint a distance according to the jitter factor
-- and creates 2 new lines segments for each segment
local function add_jitter(segments, iterations, jitter_factor)
    for _ = 1, iterations, 1 do
        local newsegs = {}
        for i, segment in ipairs(segments) do
            
            local sp = segment['start'] -- start point
            local ep = segment['end'] -- end point

            -- the midpoint between the two points
            local mp = {
                ['x']=(sp['x']+ep['x'])/2,
                ['y']=(sp['y']+ep['y'])/2
            }

            -- the distance between the two points
            local dist = math.sqrt((sp['x']-ep['x'])^2 + (sp['y']-ep['y'])^2)
            
            -- pick a random offset for the midpoint based on the distance
            -- between the 2 points
            local offset = math.random()*jitter_factor*dist*2-jitter_factor*dist

            -- find the angle of the line (from horizontal)
            local hangle = math.tan((sp['y']-ep['y'])/(sp['x']-ep['x']))
            
            -- Add 90 deg for perpendicular
            hangle = hangle + math.pi/2

            local np = { -- new midpoint
                ['x'] = mp['x']+offset*math.cos(hangle),
                ['y'] = mp['y']+offset*math.sin(hangle)
            }

            table.insert(newsegs,{['start']=sp, ['end']=np})
            table.insert(newsegs,{['start']=np, ['end']=ep})


        end
        segments = newsegs
    end
    return segments
end

function LoveLighting:_createForks(num_forks)
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

function LoveLighting:update(dt)
    -- generate main trunk 
    self.trunk_segments = add_jitter({{['start']=self.source, ['end']=self.target}}, 
        self.iterations, self.jitter_factor)
    self:_createForks(math.random(3,8))
end

local function get_points_from_segments( segments )
    local points = {}
    for i, segment in ipairs(segments) do
        table.insert(points, segment['start']['x'])
        table.insert(points, segment['start']['y'])
    end
    table.insert(points, segments[#segments]['end']['x'])
    table.insert(points, segments[#segments]['end']['y'])

    return points
end

local function draw_segments(segments, color, alpha, width)
    local points = get_points_from_segments(segments)
    love.graphics.line(unpack(points))

    --love.graphics.setLineJoin('miter')
    love.graphics.setLineWidth(width)
    love.graphics.setColor(color['r'], color['g'], color['b'], alpha)
    love.graphics.line(unpack(points))
end

function LoveLighting:draw()
    if self.trunk_segments then
        draw_segments(self.trunk_segments, self.color, 255, 1)
    end

    if self.forks then
        for i,fork in ipairs(self.forks) do
            draw_segments(fork, self.color, 255, 1)
        end
    end
end

return LoveLighting