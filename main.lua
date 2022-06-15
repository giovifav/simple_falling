lg = love.graphics
lm = love.mouse
lr = love.math.random
lkd = love.keyboard.isDown
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
Player = {}
Player.radius = 20
Player.color = { 0.7,0.7,0.7 }
local w, h = love.graphics.getDimensions()
Player.x = w/2
Player.y = h/2
Player.direction = 1
Player.speed = 200
function Player:draw()
    lg.setLineWidth(1)
    lg.setColor(unpack(self.color))
    lg.circle("fill", self.x, self.y, self.radius * 1)
     --calcoliamo l'arco corrispondente alla vita
    local angle = math.rad(((Game.lives * 360) / Game.initialLives) - 90)
    --disegnamo barra della vita
    if Game.lives <= Game.initialLives / 2 then
        lg.setColor(1,0,0,1)
        lg.arc("fill", self.x, self.y, self.radius * 0.8, math.rad(-90), angle, 20)
    else
        lg.setColor(0,1,0,1)
        lg.arc("fill", self.x, self.y, self.radius * 0.8, math.rad(-90), angle, 20)
    end
    lg.setColor(unpack(self.color))
    lg.circle("fill", self.x, self.y, self.radius * 0.5)

end
function Player:update( dt)
    if lkd("s") then
        self.direction = 1
    elseif lkd("w") then
        self.direction = 2
    elseif lkd("a") then
        self.direction = 3
    elseif lkd("d") then
        self.direction = 4
    else
        self.direction = 0
    end

    if self.direction == 1 then
        self.y = self.y + self.speed * dt
    elseif self.direction == 2 then
        self.y = self.y - self.speed * dt
    elseif self.direction == 3 then
        self.x = self.x - self.speed * dt
    elseif self.direction == 4 then
        self.x = self.x + self.speed * dt
    end
    if self.x > Game.w + self.radius then
        self.x = - self.radius
    elseif self.x < - self.radius then
        self.x = Game.w + self.radius
    elseif self.y > Game.h + self.radius then
        self.y = - self.radius
    elseif self.y < - self.radius then
        self.y = Game.h  + self.radius
    end
end
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
Objects = {}
Objects.list = {}
Objects.minSpeed, Objects.maxSpeed = 100, 400
Objects.minR, Objects.maxR = 15, 70
Objects.direction = 1 -- down - 2 up - 3 left - 4 right
function Objects:draw()
    for k, v in ipairs(self.list) do
        if v.enemy == true then
            lg.setColor(unpack(v.color))
            lg.circle("fill", v.x, v.y, v.radius)
            lg.setColor(0,0,0,1)
            lg.setLineWidth(2)
            lg.circle("line", v.x, v.y, v.radius)
        else 
            lg.setColor(unpack(v.color))
            lg.setLineWidth(4)
            lg.circle("line", v.x, v.y, v.radius)
        end
    end
end
function Objects:update(dt)
    local function distance(x1, y1, x2, y2)
        return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
    end
    local w, h = lg.getDimensions()
    -- reverse iteration order to properly delete object
    for i = #self.list, 1, -1 do
        local v = self.list[i]
        if not Game.paused then
            -- set Objects position
            self.updateMovement(v, dt)
            --check collision with Player
            local dist = distance(v.x, v.y, Player.x, Player.y)
            if dist < v.radius + Player.radius then
                if not v.enemy then
                    Game:add(10)
                    table.remove(self.list, i)
                    break
                else
                    Game:remove(10)
                    Game:removeLife()
                    table.remove(self.list, i)
                    Game:setBackground(Objects.direction)
                    break
                end
            end
            --remove when outside the screen
            local offset = v.radius * 3
            if v.y > h + offset or v.y < -offset or v.x > w + offset or v.y < -offset then
                table.remove(self.list, i)
                break
            end
        end
    end
end
function Objects.updateMovement(v, dt)
    if v.direction == 1 then
        v.y = v.y + v.speed * dt
    elseif v.direction == 2 then
        v.y = v.y - v.speed * dt
    elseif v.direction == 3 then
        v.x = v.x - v.speed * dt
    elseif v.direction == 4 then
        v.x = v.x + v.speed * dt
    end
end
function Objects:add()
    local w, h = lg.getDimensions()
    local function br() -- boolean random
        if lr() <= 0.5 then return false else return true end
    end
    local radius = lr(self.minR, self.maxR)
    local x, y
    local direction = lr(1,4)
    if direction == 1 then -- down
        x = lr(radius / 2, w - radius / 2)
        y = -radius * 2
    elseif direction == 2 then -- up
        x = lr(radius / 2, w - radius / 2)
        y = h + radius * 2
    elseif direction == 3 then -- left
        x = w + radius * 2
        y = lr(radius / 2, h - radius / 2)
    elseif direction == 4 then --right
        x = -radius * 2
        y = lr(radius / 2, h - radius / 2)
    end
    local object = {
        x = x,
        y = y,
        speed = lr(self.minSpeed, self.maxSpeed),
        color = { lr(), lr(), lr() },
        enemy = br(),
        radius = radius,
        direction = direction,
    }
    table.insert(self.list, object)
end
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
Game = {}
Game.paused = false
Game.spawnRate = 1
Game.spawnMin, Game.spawnMax = 0.3, 0.5
Game.spawnTimer = 0
Game.dirRate = 5
Game.dirMin, Game.dirMax = 1, 3
Game.dirTimer = 0
Game.score = 50
Game.multiplier = 1
Game.lives = 4
Game.initialLives = 4
Game.fullSceen = false
Game.w, Game.h = lg.getDimensions()
function Game:setBackground(direction)
    self.backgroundDirection = direction
    local t = 0.4
    if direction < 3 then
        local img = love.image.newImageData(1, 2)
        img:setPixel(0, 0, lr(),lr(),lr(),t)
        img:setPixel(0, 1, lr(),lr(),lr(),t)
        self.backgroundData = love.graphics.newImage(img)
    else
        local img = love.image.newImageData(2, 1)
        img:setPixel(0, 0, lr(),lr(),lr(),t)
        img:setPixel(1, 0, lr(),lr(),lr(),t)
        self.backgroundData = love.graphics.newImage(img)
    end
end
Game:setBackground(1)
function Game:drawBackground()
    if self.backgroundDirection  < 3 then
        lg.draw(self.backgroundData, 0, 0, 0, Game.w, Game.h/2)
    else
        lg.draw(self.backgroundData, 0, 0, 0, Game.w/2, Game.h)
    end
end
function Game:addLife()
    self.lives = self.lives + 1
end
function Game:removeLife()
    self.lives = self.lives - 1
    if self.lives <= 0 then
        self:restart()
    end
end


function Game:restart()
    Objects.list = {}
    self.lives = 4
    self.score = 50
    self.multiplier = 1
    self.spawnTimer = 0
    self.dirTimer = 0
end
function Game:draw()
    --self:drawBackground()
    Objects:draw()
    Player:draw()
    lg.setColor(1, 1, 1)
    lg.print("Score: " .. self.score.." X " .. self.multiplier, 20, 20)
    lg.print("Lives: ".. self.lives, 20,40)
end
function Game:update(dt)
    if not self.paused then
        Player:update(dt)
        self.spawnTimer = self.spawnTimer + dt
        if self.spawnTimer >= self.spawnRate then
            Objects:add()
            self.spawnTimer = 0
            self.spawnRate = lr(self.spawnMin, self.spawnMax)
        end
        
        --update Objects
        Objects:update(dt)
    end
end
function Game:add(number)
    self.score = self.score + number * self.multiplier
    self:increaseMultiplier()
end
function Game:remove(number)
    self.score = self.score - number * self.multiplier
    self:resetMultiplier()
end

function Game:increaseMultiplier()
    self.multiplier = self.multiplier + 1
end

function Game:decreaseMultiplier()
    if self.multiplier > 1 then
        self.multiplier = self.multiplier - 1
    end
end
function Game:resetMultiplier()
    self.multiplier = 0
end
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
function love.load()
    lm.setVisible(false)
    lg.setBackgroundColor(0,0,0,1)
    love.math.setRandomSeed(os.time())
    for i = 1, lr(5000) do
        lr()
    end

end
function love.draw()
    Game:draw()
end
function love.update(dt)
    Game:update(dt)
end
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "f11" then
		Game.fullscreen = not Game.fullscreen
		love.window.setFullscreen(Game.fullscreen)
		love.resize(love.graphics.getDimensions())
    elseif key == "p" then
        Game.paused = not Game.paused
    end
end
function love.resize(w,h)
    Game.w, Game.h = w , h
end
-----------------------------------------------------------------------------------