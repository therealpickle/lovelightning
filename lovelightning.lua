require "requires"

LoveLighting = class("LoveLighting")


function LoveLighting:initialize(r,g,b)
    self.iterations = 6
    self.jitter = 0.25
    self.color = {['r']=r,['g']=g,['b']=b}
end

function LoveLighting:setTarget(x,y)
    self.target = {['x']=x, ['y']=y}
end

function LoveLighting:setSource(x,y)
    self.source = {['x']=x, ['y']=y}
end


function LoveLighting:update(dt)
    -- generate main trunk
    self.trunk_segments = {{['start']=self.source, ['end']=self.target}}
    for _ = 1, self.iterations, 1
    do
        local newsegs = {}
        for i = 1, #self.trunk_segments, 1
        do
            local sp = self.trunk_segments[i]['start'] -- start point
            local ep = self.trunk_segments[i]['end'] -- end point

            -- the midpoint between the two points
            local mp = {
                ['x']=(sp['x']+ep['x'])/2,
                ['y']=(sp['y']+ep['y'])/2
            }

            -- the distance between the two points
            local dist = math.sqrt((sp['x']-ep['x'])^2 + (sp['y']-ep['y'])^2)
            
            -- pick a random offset for the midpoint based on the distance
            -- between the 2 points
            local offset = math.random()*self.jitter*dist*2-self.jitter*dist

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
        self.trunk_segments = newsegs
    end    
end

local function draw_segments(segments, color)
    local current_blend_mode = love.graphics.getBlendMode()
    love.graphics.setBlendMode('alpha')
    
    for i = 1, #segments, 1
    do
        local sp = segments[i]['start']
        local ep = segments[i]['end']


        love.graphics.setLineWidth(5)
        love.graphics.setColor(color['r'], color['g'], color['b'], 64)
        love.graphics.line(sp['x'], sp['y'], ep['x'], ep['y'])
        love.graphics.setLineWidth(3)
        love.graphics.setColor(color['r'], color['g'], color['b'], 128)
        love.graphics.line(sp['x'], sp['y'], ep['x'], ep['y'])
        love.graphics.setLineWidth(1)
        love.graphics.setColor(color['r'], color['g'], color['b'], 255)
        love.graphics.line(sp['x'], sp['y'], ep['x'], ep['y'])
        -- love.graphics.circle('fill', sp['x'], sp['y'],2)
        -- love.graphics.circle('fill', ep['x'], ep['y'],2)

    end
    love.graphics.setBlendMode(current_blend_mode)
end

function LoveLighting:draw()
    if self.trunk_segments then
        draw_segments(self.trunk_segments, self.color)
    end
end

return LoveLighting