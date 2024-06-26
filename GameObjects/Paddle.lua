--[[
    GD50 2018
    Pong Remake

    -- Paddle Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a paddle that can move up and down. Used in the main
    program to deflect the ball back toward the opponent.
]]
Paddle = Class{}

--[[
    The `init` function on our class is called just once, when the object
    is first created. Used to set up all variables in the class and get it
    ready for use.

    Our Paddle should take an X and a Y, for positioning, as well as a width
    and height for its dimensions.

    Note that `self` is a reference to *this* object, whichever object is
    instantiated at the time this function is called. Different objects can
    have their own x, y, width, and height values, thus serving as containers
    for data. In this sense, they're very similar to structs in C.
]]
function Paddle:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.dy = 0
    self.speed = 200
end

--[[
    Updates the paddle's position, ensuring it stays within the screen bounds.
]]
function Paddle:update(dt)
    if self.dy < 0 then
        self.y = math.max(0, self.y + self.dy * dt)
    else
        self.y = math.min(VIRTUAL_HEIGHT - self.height, self.y + self.dy * dt)
    end
end

--[[
    Gets and sets to encapsulate object properties in order to avoid
    direct modifications to those, thus providing encapsulation and
    modularity to improve maintainability and readability.
]]
-- Returns the current speed of the paddle
function Paddle:getSpeed()
    return self.speed
end

-- Sets the current speed of the paddle
function Paddle:setSpeed(speed)
    self.speed = speed
end

-- Sets the current height of the paddle
function Paddle:setHeight(height)
    self.height = height
end

--[[
    Functions related to features that affect the Paddle properties and
    are meant to be called by the main function in 'love.draw'.
]]
-- Shrinks the paddle by 5 units of its height
function Paddle:shrink()
    self.height = math.max(5, self.height - 5)
end

-- Duplicates the Paddle height
function Paddle:grow()
    self.height = math.min(VIRTUAL_HEIGHT, self.height + 20)
end

-- Moves the paddle up
function Paddle:moveUp()
    self.dy = -self.speed
end

-- Moves the paddle down
function Paddle:moveDown()
    self.dy = self.speed
end

-- Stops the paddle
function Paddle:stop()
    self.dy = 0
end

--[[
    To be called by our main function in `love.draw` to draw the paddle
]]
function Paddle:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end