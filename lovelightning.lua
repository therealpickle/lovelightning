require "requires"

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
            local hangle = math.tan((sp['x']-ep['x'])/(sp['y']-ep['y']))
            
            -- Add 90 deg for perpendicular
            hangle = hangle + math.pi/2

            local np = { -- new midpoint
                ['x'] = mp['x']+offset*math.sin(hangle),
                ['y'] = mp['y']+offset*math.cos(hangle)
            }

            table.insert(newsegs,{['start']=sp, ['end']=np})
            table.insert(newsegs,{['start']=np, ['end']=ep})           
        end
        segments = newsegs
    end
    return segments
end

local function create_forks(segments, num_forks)
    
end

function LoveLighting:update(dt)
    -- generate main trunk 
    self.trunk_segments = add_jitter({{['start']=self.source, ['end']=self.target}}, 
        self.iterations, self.jitter_factor)
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

local function draw_segments(segments, color, max_alpha, max_width)
    local points = get_points_from_segments(segments)
    love.graphics.line(unpack(points))

    love.graphics.setLineJoin('miter')
    love.graphics.setLineWidth(max_width)
    love.graphics.setColor(color['r'], color['g'], color['b'], max_alpha/4)
    love.graphics.line(unpack(points))
    love.graphics.setLineWidth(max_width/2)
    love.graphics.setColor(color['r'], color['g'], color['b'], max_alpha/2)
    love.graphics.line(unpack(points))
    love.graphics.setLineWidth(max_width/5)
    love.graphics.setColor(color['r'], color['g'], color['b'], max_alpha)
    love.graphics.line(unpack(points))
end

function LoveLighting:draw()
    if self.trunk_segments then
        draw_segments(self.trunk_segments, self.color, 255, 10)
    end
end

return LoveLighting