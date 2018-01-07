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
    for _ = 0, self.iterations, 1
    do
        for i = 1, #self.points-1, 1
        do
            -- calculate the midpoint between the two points
            local midpoint = {
                ['x']=(self.points[i]['x']+self.points[i+1]['x'])/2,
                ['y']=(self.points[i]['y']+self.points[i+1]['y'])/2,
            }

            -- add random jitter in x and y based on the distance between
            -- the points and percentage of jitter
            local xjitter_max = self.jitter*(midpoint['x']-self.points[i]['x'])
            local yjitter_max = self.jitter*(midpoint['y']-self.points[i]['y'])

            midpoint['x'] = midpoint['x'] + math.random(-xjitter_max, xjitter_max)
            midpoint['y'] = midpoint['y'] + math.random(-yjitter_max, yjitter_max)

            table.insert(self.points,i+1,midpoint)
            
        end
    end    
end

function LoveLighting:draw()
    if self.points then
        for i = 1, #self.points-1, 1
        do
            love.graphics.line(self.points[i]['x'], self.points[i]['y'],
                self.points[i+1]['x'], self.points[i+1]['y'])
        end
    end
end

return LoveLighting