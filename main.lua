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
    accelerate the gameplay experience. New sounds effects have been
    added to enhance the immersibility.

    New features:   Paddles are larger now but decrease in size
                    every time they hit the ball.
                    ................................
]]

-- Using Löve2D framework
local love = require("love")

--[[
    "Push" is a library that will allow us to draw our game at a virtual
    resolution, instead of however large our window is; used to provide
    a more retro aesthetic.
    https://github.com/Ulydev/push
]]
Push = require 'Utils/push'

--[[
    Adding classes support for our code to encapsulate functions and
    attributes in their own objects.
    https://github.com/vrld/hump/blob/master/class.lua
]]
Class = require 'Utils/class'

--[[
    Importing the "Paddle" class, where the attributes and behavior of the
    paddles are defined.
]]
require 'GameObjects/Paddle'

--[[
    Importing the "Ball" class, where the attributes and behavior of the
    ball are defined.
]]
require 'GameObjects/Ball'

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

--[[
    Called just once at the beginning of the game; used to set up
    game objects, variables, etc. and prepare the game world.
]]
function love.load()
    -- Setting the title for the application window
    love.window.setTitle('My Pong')

    -- Initializing the RNG with an always changing value
    math.randomseed(os.time())

    -- Setting the different font sizes
    smallFont = love.graphics.newFont('Resources/fonts/font.ttf', 8)
    largeFont = love.graphics.newFont('Resources/fonts/font.ttf', 16)
    scoreFont = love.graphics.newFont('Resources/fonts/font.ttf', 32)
    love.graphics.setFont(smallFont)

    -- Creating a dictionary with the game sound effects
    sounds = {
        ['paddle_hit'] = love.audio.newSource('Resources/audio/soundEffects/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('Resources/audio/soundEffects/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('Resources/audio/soundEffects/wall_hit.wav', 'static')
    }
    
    --[[
        Initialize our virtual resolution, which will be rendered within our
        actual window no matter its dimensions
    ]]
    Push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    --[[
        Draw our player paddles; make them global so that they can be
        detected by other functions and modules
    ]]
    player1 = Paddle(10, 30, 5, 50)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 50)

    -- Draw a ball in the middle of the screen
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    -- Initialize score variables
    player1Score = 0
    player2Score = 0

    -- Powerups usage track
    player1PU = 0

    -- Setting serving player to Player 1 by default
    servingPlayer = 1

    -- Create a variable to store the number of the winning player
    winningPlayer = 0

    -- The state of our game; can be any of the following:
    -- 1. 'start' (the beginning of the game, before first serve)
    -- 2. 'serve' (waiting on a key press to serve the ball)
    -- 3. 'play' (the ball is in play, bouncing between paddles)
    -- 4. 'done' (the game is over, with a victor, ready for restart)
    gameState = 'start'
end

--[[
    Called whenever we change the dimensions of our window, as by dragging
    out its bottom corner, for example. In this case, we only need to worry
    about calling out to `Push` to handle the resizing. Takes in a `w` and
    `h` variable representing width and height, respectively.
]]
function love.resize(w, h)
    Push:resize(w, h)
end

--[[
    Called every frame, passing in `dt` since the last frame. `dt`
    is short for `deltaTime` and is measured in seconds. Multiplying
    this by any changes we wish to make in our game will allow our
    game to perform consistently across all hardware; otherwise, any
    changes we make will be applied as fast as possible and will vary
    across system hardware.
]]
function love.update(dt)
    if gameState == 'serve' then
        -- When reached "serve" state, the paddles size must be reset.
        player1:setHeight(50)
        player2:setHeight(50)

        -- before switching to play, initialize ball's velocity based
        -- on player who last scored
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        --[[ 
            Detect ball collision with paddles, reversing dx if true and
            slightly increasing it, then altering the dy based on the position
            at which it collided, then playing a sound effect
        ]]
        if ball:collides(player1) then
            player1:shrink()
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5

            -- Keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            player2:shrink()
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            -- Keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        --[[
            Detect upper and lower screen boundary collision, playing a sound
            effect and reversing dy if true
        ]]
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        --[[
            Checking if the ball is 4 units left to reach the bottom of the screen
            in which case it should bounce already since the ball is 4 units sized
        ]]
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- if we reach the left edge of the screen, go back to serve
        -- and update the score and serving player
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            -- if we've reached a score of 10, the game is over; set the
            -- state to done so we can show the victory message
            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                -- places the ball in the middle of the screen, no velocity
                ball:reset()
            end
        end

        --[[
            If we reach the right edge of the screen, go back to serve
            and update the score and serving player
        ]]    
        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            -- if we've reached a score of 10, the game is over; set the
            -- state to done so we can show the victory message
            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                -- places the ball in the middle of the screen, no velocity
                ball:reset()
            end
        end
    end

    --
    -- paddles can move no matter what state we're in
    --
    -- player 1
    if love.keyboard.isDown('w') then
        player1:moveUp()
    elseif love.keyboard.isDown('s') then
        player1:moveDown()
    else --fix this to only access methods from paddle
        player1.dy = 0
    end

    -- player 2
    if love.keyboard.isDown('up') then
        player2:moveUp()
    elseif love.keyboard.isDown('down') then
        player2:moveDown()
    else
        player2.dy = 0
    end

    -- update our ball based on its DX and DY only if we're in play state;
    -- scale the velocity by dt so movement is framerate-independent
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

--[[
    A callback that processes key strokes as they happen, just the once.
    Does not account for keys that are held down, which is handled by a
    separate function (`love.keyboard.isDown`). Useful for when we want
    things to happen right away, just once, like when we want to quit.
]]
function love.keypressed(key)
    -- `key` will be whatever key this callback detected as pressed
    if key == 'escape' then
        -- the function LÖVE2D uses to quit the application
        love.event.quit()
    
    -- if we press enter during either the start or serve phase, it should
    -- transition to the next appropriate state
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            -- game is simply in a restart phase here, but will set the serving
            -- player to the opponent of whomever won for fairness!
            gameState = 'serve'

            ball:reset()

            -- reset scores to 0
            player1Score = 0
            player2Score = 0

            -- decide serving player as the opposite of who won
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

--[[
    Called each frame after update; is responsible simply for
    drawing all of our game objects and more to the screen.
]]
function love.draw()
    -- begin drawing with Push, in our virtual resolution
    Push:apply('start')

    love.graphics.clear(0.16, 0.18, 0.20, 1.0)
    
    -- render different things depending on which part of the game we're in
    if gameState == 'start' then
        -- UI messages
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        -- UI messages
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- no UI messages to display in play
    elseif gameState == 'done' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end

    -- Show the score before ball is rendered so it can move over the text
    displayScore()
    
    player1:render()
    player2:render()
    ball:render()

    -- Display FPS for debugging; simply comment out to remove
    displayFPS()

    -- End our drawing to Push
    Push:apply('end')
end

-- Simple function for rendering the scores.
function displayScore()
    -- score display
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end

-- Renders the current FPS.
function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 1, 0, 1) -- use normalized RGBA values
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(1, 1, 1, 1) -- reset color to white
end