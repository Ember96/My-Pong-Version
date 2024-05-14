-- push.lua v0.2
-- Updated for LÖVE 11.x compatibility

-- Copyright (c) 2017 Ulysse Ramage
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local push = {
  
  defaults = {
    fullscreen = false,
    resizable = false,
    pixelperfect = false,
    highdpi = true,
    canvas = true
  }
  
}
setmetatable(push, push)

-- Apply settings to the push instance
function push:applySettings(settings)
  for k, v in pairs(settings) do
    self["_" .. k] = v
  end
end

-- Reset settings to default values
function push:resetSettings() 
  return self:applySettings(self.defaults) 
end

-- Setup the screen with the given dimensions and settings
function push:setupScreen(WWIDTH, WHEIGHT, RWIDTH, RHEIGHT, settings)
  settings = settings or {}

  self._WWIDTH, self._WHEIGHT = WWIDTH, WHEIGHT
  self._RWIDTH, self._RHEIGHT = RWIDTH, RHEIGHT

  self:applySettings(self.defaults) -- Set defaults first
  self:applySettings(settings) -- Then fill with custom settings
  
  love.window.setMode(self._RWIDTH, self._RHEIGHT, {
    fullscreen = self._fullscreen,
    resizable = self._resizable,
    highdpi = self._highdpi
  })

  self:initValues()

  if self._canvas then
    self:setupCanvas({"default"}) -- Setup canvas
  end

  self._borderColor = {0, 0, 0}

  self._drawFunctions = {
    ["start"] = self.start,
    ["end"] = self.finish
  }

  return self
end

-- Setup the canvas
function push:setupCanvas(canvases)
  table.insert(canvases, {name = "_render"}) -- Final render

  self._canvas = true
  self.canvases = {}

  for i = 1, #canvases do
    self.canvases[i] = {
      name = canvases[i].name,
      shader = canvases[i].shader,
      canvas = love.graphics.newCanvas(self._WWIDTH, self._WHEIGHT)
    }
  end

  return self
end

-- Set the active canvas
function push:setCanvas(name)
  if not self._canvas then return true end
  return love.graphics.setCanvas(self:getCanvasTable(name).canvas)
end

-- Get the canvas table by name
function push:getCanvasTable(name)
  for i = 1, #self.canvases do
    if self.canvases[i].name == name then
      return self.canvases[i]
    end
  end
end

-- Set the shader for a canvas
function push:setShader(name, shader)
  if not shader then
    self:getCanvasTable("_render").shader = name
  else
    self:getCanvasTable(name).shader = shader
  end
end

-- Initialize internal values based on current settings
function push:initValues()
  self._PSCALE = self._highdpi and love.window.getDPIScale() or 1
  
  self._SCALE = {
    x = self._RWIDTH / self._WWIDTH * self._PSCALE,
    y = self._RHEIGHT / self._WHEIGHT * self._PSCALE
  }
  
  if self._stretched then -- If stretched, no need to apply offset
    self._OFFSET = {x = 0, y = 0}
  else
    local scale = math.min(self._SCALE.x, self._SCALE.y)
    if self._pixelperfect then scale = math.floor(scale) end
    
    self._OFFSET = {
      x = (self._SCALE.x - scale) * (self._WWIDTH / 2),
      y = (self._SCALE.y - scale) * (self._WHEIGHT / 2)
    }
    self._SCALE.x, self._SCALE.y = scale, scale -- Apply same scale to X and Y
  end
  
  self._GWIDTH = self._RWIDTH * self._PSCALE - self._OFFSET.x * 2
  self._GHEIGHT = self._RHEIGHT * self._PSCALE - self._OFFSET.y * 2
end

-- Deprecated apply method
function push:apply(operation, shader)
  if operation == "start" then
    self:start()
  elseif operation == "finish" or operation == "end" then
    self:finish(shader)
  end
end

-- Start drawing to the push canvas
function push:start()
  if self._canvas then
    love.graphics.push()
    love.graphics.setCanvas(self.canvases[1].canvas)
  else
    love.graphics.translate(self._OFFSET.x, self._OFFSET.y)
    love.graphics.setScissor(self._OFFSET.x, self._OFFSET.y, self._WWIDTH * self._SCALE.x, self._WHEIGHT * self._SCALE.y)
    love.graphics.push()
    love.graphics.scale(self._SCALE.x, self._SCALE.y)
  end
end

-- Finish drawing to the push canvas
function push:finish(shader)
  love.graphics.setBackgroundColor(self._borderColor)
  if self._canvas then
    local _render = self:getCanvasTable("_render")

    love.graphics.pop()

    love.graphics.setColor(1, 1, 1) -- Normalized color values for LÖVE 11.x

    -- Draw canvas
    love.graphics.setCanvas(_render.canvas)
    for i = 1, #self.canvases - 1 do -- Do not draw _render yet
      local _table = self.canvases[i]
      love.graphics.setShader(_table.shader)
      love.graphics.draw(_table.canvas)
    end
    love.graphics.setCanvas()

    -- Draw render
    love.graphics.translate(self._OFFSET.x, self._OFFSET.y)
    love.graphics.setShader(shader or self:getCanvasTable("_render").shader)
    love.graphics.draw(self:getCanvasTable("_render").canvas, 0, 0, 0, self._SCALE.x, self._SCALE.y)

    -- Clear canvas
    for i = 1, #self.canvases do
      love.graphics.setCanvas(self.canvases[i].canvas)
      love.graphics.clear()
    end

    love.graphics.setCanvas()
    love.graphics.setShader()
  else
    love.graphics.pop()
    love.graphics.setScissor()
  end
end

-- Set the border color
function push:setBorderColor(color, g, b)
  self._borderColor = g and {color, g, b} or color
end

-- Convert coordinates from screen to game
function push:toGame(x, y)
  x, y = x - self._OFFSET.x, y - self._OFFSET.y
  local normalX, normalY = x / self._GWIDTH, y / self._GHEIGHT
  
  x = (x >= 0 and x <= self._WWIDTH * self._SCALE.x) and normalX * self._WWIDTH or nil
  y = (y >= 0 and y <= self._WHEIGHT * self._SCALE.y) and normalY * self._WHEIGHT or nil
  
  return x, y
end

-- Convert coordinates from game to real
function push:toReal(x, y)
  return x + self._OFFSET.x, y + self._OFFSET.y
end

-- Toggle fullscreen mode
function push:switchFullscreen(winw, winh)
  self._fullscreen = not self._fullscreen
  local windowWidth, windowHeight = love.window.getDesktopDimensions()
  
  if self._fullscreen then -- Save windowed dimensions for later
    self._WINWIDTH, self._WINHEIGHT = self._RWIDTH, self._RHEIGHT
  elseif not self._WINWIDTH or not self._WINHEIGHT then
    self._WINWIDTH, self._WINHEIGHT = windowWidth * .5, windowHeight * .5
  end
  
  self._RWIDTH = self._fullscreen and windowWidth or winw or self._WINWIDTH
  self._RHEIGHT = self._fullscreen and windowHeight or winh or self._WINHEIGHT
  
  self:initValues()
  
  love.window.setFullscreen(self._fullscreen, "desktop")
  if not self._fullscreen and (winw or winh) then
    love.window.setMode(self._RWIDTH, self._RHEIGHT) -- Set window dimensions
  end
end

-- Resize the screen
function push:resize(w, h)
  local pixelScale = love.window.getDPIScale()
  if self._highdpi then w, h = w / pixelScale, h / pixelScale end
  self._RWIDTH = w
  self._RHEIGHT = h
  self:initValues()
end

-- Get the game width
function push:getWidth() 
  return self._WWIDTH 
end

-- Get the game height
function push:getHeight() 
  return self._WHEIGHT 
end

-- Get the game dimensions
function push:getDimensions() 
  return self._WWIDTH, self._WHEIGHT 
end

return push
