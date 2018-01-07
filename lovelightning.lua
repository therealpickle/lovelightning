require "requires"

LoveLighting = class("LoveLighting")


function LoveLighting:initialize()
    self.iterations = 3
    self.jitter = 0.2
end

function LoveLighting:setTarget(x,y)
    self.target = {['x']=x, ['y']=y}
end

function LoveLighting:setSource(x,y)
    self.source = {['x']=x, ['y']=y}
end

function LoveLighting:update(dt)
    self.points = {self.source, self.target}
    for _ = 1, self.iterations, 1
    do
        local newpoints = {}
        for i = 1, #self.points-1, 1
        do
            -- the midpoint between the two points
            local midpoint = {
                ['x']=(self.points[i]['x']+self.points[i+1]['x'])/2,
                ['y']=(self.points[i]['y']+self.points[i+1]['y'])/2,
            }

            -- the distance between the two points
            local dist = math.sqrt((self.points[i]['x']-self.points[i+1]['x'])^2 + 
                (self.points[i]['y']-self.points[i+1]['y'])^2)
            
            -- pick a random offset for the midpoint based on the distance
            -- between the 2 points
            local offset = 0
            if math.random() > 0.5 then
                offset = self.jitter*dist*math.random()
            else
                offset = -self.jitter*dist*math.random()
            end

            -- find the angle of the line (from horizontal)
            local hangle = math.tan((self.points[i]['x']-self.points[i+1]['x'])/
                (self.points[i]['y']-self.points[i+1]['y']))
            
            -- Add 90 deg for perpendicular
            hangle = hangle + math.pi/2

            local newpoint = {
                ['x'] = midpoint['x']+offset*math.sin(hangle),
                ['y'] = midpoint['y']+offset*math.cos(hangle)
            }

            table.insert(newpoints,self.points[i])
            table.insert(newpoints,newpoint)           
        end
        table.insert(newpoints,self.target)
        self.points = newpoints
    end    
end

function LoveLighting:draw()
    if self.points then
        for i = 1, #self.points-1, 1
        do
            love.graphics.line(self.points[i]['x'], self.points[i]['y'],
                self.points[i+1]['x'], self.points[i+1]['y'])
            -- love.graphics.circle('fill', self.points[i]['x'], self.points[i]['y'],2)
        end
    end
end

return LoveLighting