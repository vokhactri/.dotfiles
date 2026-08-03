-- Reload: Hammerspoon menu -> Reload Config

local config = require("config")
local WindowHighlight = require("modules.window_highlight")

local windowHighlight = WindowHighlight.new(config.windowHighlight)
windowHighlight:start()

-- Keep module state and watchers alive until the next reload.
_G.hammerspoonModules = {
  windowHighlight = windowHighlight,
}

hs.alert.show("Hammerspoon config loaded")
