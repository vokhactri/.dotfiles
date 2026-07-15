-- Reload: Hammerspoon menu -> Reload Config

local config = require("config")
local AppNameToast = require("modules.app_name_toast")
local WindowHighlight = require("modules.window_highlight")

local appNameToast = AppNameToast.new(config.appNameToast)
local windowHighlight = WindowHighlight.new(config.windowHighlight, {
  onWindowFocused = function()
    if config.appNameToast.showOnFocus then
      appNameToast:show()
    end
  end,
})

appNameToast:setShouldShow(function()
  return not windowHighlight:isMissionControlActive()
end)

appNameToast:start()
windowHighlight:start()

-- Keep module state and watchers alive until the next reload.
_G.hammerspoonModules = {
  appNameToast = appNameToast,
  windowHighlight = windowHighlight,
}

hs.alert.show("Hammerspoon config loaded")
