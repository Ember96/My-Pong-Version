--[[
    Pong Remake

    -- Main Program --

    Author: Jose Garcia
            linuxfanboy@outlook.com

            Carlos E. Torres
            hello@sanchezcarlosjr.com

    This implementation is based on the "GD50 2018 Pong Remake"
    as part of the "CS50's Intro to Game Development" Harvard 
    free course.

    Originally programmed by Atari in 1972. Features two
    paddles, controlled by players, with the goal of getting
    the ball past your opponent's edge. First to 10 points wins.

    This version is built to more closely resemble the NES than
    the original Pong machines or the Atari 2600 in terms of
    resolution, though in widescreen (16:9) so it looks nicer on 
    modern systems.

    Some of the code has been re-written to improve organization
    and readability. Some features have been added to improve and
    accelerate the gameplay experience. New sounds effects has been
    added to enhance the inmersibility.

    New features:   Paddles are larger now but decrease in size
                    everytime they hit the ball.
                    ................................
]]

-- Using Löve2D framework
Love = require("love")

--[[
    "push" is a library that will allow us to draw our game at a virtual
    resolution, instead of however large our window is; used to provide
    a more retro aesthetic.
    https://github.com/Ulydev/push
]]
Push = require 'Utils/push'

--[[
    Adding classes support for our code to encapsulate functions and
    atributes in their own objects.
    https://github.com/vrld/hump/blob/master/class.lua
]]
Class = require 'Utils/class'

--[[
    Importing the "Paddle" class, where the atributes and behavior of the
    paddles are defined.
]]
Paddle = require 'GameObjects/Paddle'

--[[
    Importing the "Ball" class, where the atributes and behavior of the
    ball is defined.
]]
Ball = require 'GameObjects/Ball'

----------------------------Global Variables------------------------------

-- The width and height of the game window.
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

--[[
    The rendered width and height of the game window, reduced to provide
    a more retro aesthetic.
]]
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- Paddle movement speed
PADDLE_SPEED = 200

-- Ball movement speed