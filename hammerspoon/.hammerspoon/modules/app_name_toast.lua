local AppNameToast = {}
AppNameToast.__index = AppNameToast

function AppNameToast.new(config)
  return setmetatable({
    config = config,
    alertId = nil,
    commandKeyDown = false,
    commandKeyWatcher = nil,
    shouldShow = nil,
  }, AppNameToast)
end

function AppNameToast:setShouldShow(predicate)
  self.shouldShow = predicate
end

function AppNameToast:show()
  if not self.config.enabled then return end
  if self.shouldShow and not self.shouldShow() then return end

  local win = hs.window.focusedWindow()
  local app = win and win:application() or nil
  if not app then return end

  if self.alertId then
    hs.alert.closeSpecific(self.alertId, 0)
  end

  self.alertId = hs.alert.show(
    app:name(),
    self.config.style,
    win:screen(),
    self.config.duration
  )
end

function AppNameToast:start()
  if not self.config.showOnCommand then return self end

  self.commandKeyWatcher = hs.eventtap.new({
    hs.eventtap.event.types.flagsChanged,
  }, function(event)
    local isCommandDown = event:getFlags().cmd == true

    if isCommandDown and not self.commandKeyDown then
      self:show()
    end

    self.commandKeyDown = isCommandDown
    return false
  end)
  self.commandKeyWatcher:start()

  return self
end

return AppNameToast
