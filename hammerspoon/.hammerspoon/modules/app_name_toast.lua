local AppNameToast = {}
AppNameToast.__index = AppNameToast

function AppNameToast.new(config)
  return setmetatable({
    config = config,
    alertId = nil,
    optionKeyDown = false,
    optionKeyWatcher = nil,
    shouldShow = nil,
    focusedAppPid = nil,
  }, AppNameToast)
end

function AppNameToast:setShouldShow(predicate)
  self.shouldShow = predicate
end

function AppNameToast:_show(skipIfAppUnchanged)
  if not self.config.enabled then return end
  if self.shouldShow and not self.shouldShow() then return end

  local win = hs.window.focusedWindow()
  local app = win and win:application() or nil
  if not app then return end

  local appPid = app:pid()
  if skipIfAppUnchanged and appPid == self.focusedAppPid then return end
  self.focusedAppPid = appPid

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

function AppNameToast:show()
  self:_show(false)
end

function AppNameToast:showOnFocus()
  self:_show(true)
end

function AppNameToast:start()
  if not self.config.showOnOption then return self end

  self.optionKeyWatcher = hs.eventtap.new({
    hs.eventtap.event.types.flagsChanged,
  }, function(event)
    local isOptionDown = event:getFlags().alt == true

    if isOptionDown and not self.optionKeyDown then
      self:show()
    end

    self.optionKeyDown = isOptionDown
    return false
  end)
  self.optionKeyWatcher:start()

  return self
end

return AppNameToast
