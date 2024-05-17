--[[
    Allows to draw two icons for each player that represent the powerups
    they can use only once during a game, since after using either aggressive
    or defensive power-up, the player can no longer use any for the rest of 
    the game.
]]
function drawPowerUps(icons, player1PU, player2PU, VIRTUAL_WIDTH, VIRTUAL_HEIGHT, smallFont)
    love.graphics.setFont(smallFont)

    -- Player 1 power-ups (left side)
    love.graphics.setColor(1, 1, 1, player1PU == 0 and 1 or 0.3)
    love.graphics.draw(icons["aggressiveIcon"], 105, 5, 0, 0.3, 0.3)
    love.graphics.print('A', 113, 5 + 20)
    
    love.graphics.setColor(1, 1, 1, player1PU == 0 and 1 or 0.3)
    love.graphics.draw(icons["defensiveIcon"], 135, 5, 0, 0.3, 0.3)
    love.graphics.print('D', 143, 5 + 20)

    -- Player 2 power-ups (right side)
    love.graphics.setColor(1, 1, 1, player2PU == 0 and 1 or 0.3)
    love.graphics.draw(icons["aggressiveIcon"], VIRTUAL_WIDTH - 150, 5, 0, 0.3, 0.3)
    love.graphics.print('Left', VIRTUAL_WIDTH - 148, 5 + 20)
    
    love.graphics.setColor(1, 1, 1, player2PU == 0 and 1 or 0.3)
    love.graphics.draw(icons["defensiveIcon"], VIRTUAL_WIDTH - 120, 5, 0, 0.3, 0.3)
    love.graphics.print('Right', VIRTUAL_WIDTH - 120, 5 + 20)

    -- Reset color to white for other drawings
    love.graphics.setColor(1, 1, 1, 1)
end

return drawPowerUps