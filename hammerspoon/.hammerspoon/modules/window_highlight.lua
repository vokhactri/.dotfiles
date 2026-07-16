local WindowHighlight = {}
WindowHighlight.__index = WindowHighlight

local function sameFrame(a, b)
  if not a or not b then return false end

  return math.abs(a.x - b.x) < 0.1
    and math.abs(a.y - b.y) < 0.1
    and math.abs(a.w - b.w) < 0.1
    and math.abs(a.h - b.h) < 0.1
end

function WindowHighlight.new(config, callbacks)
  local border = hs.drawing.rectangle(hs.geometry.rect(0, 0, 1, 1))
  border.canvas[1] = {
    type = "segments",
    action = "stroke",
    closed = true,
    clipToPath = true,
    coordinates = {
      { x = 0, y = 0 },
      { x = 1, y = 0 },
      { x = 1, y = 1 },
      { x = 0, y = 1 },
    },
  }
  border:setFill(false)
  border:setStroke(true)
  border:setStrokeWidth(config.borderWidth)
  border:setStrokeColor(config.color)
  border:setLevel(hs.drawing.windowLevels.screenSaver)
  border:setBehaviorByLabels({
    "canJoinAllSpaces",
    "stationary",
    "ignoresCycle",
    "fullScreenAuxiliary",
  })

  return setmetatable({
    config = config,
    callbacks = callbacks or {},
    border = border,
    borderRadius = config.radius + config.padding,
    missionControlActive = false,
    dockElement = nil,
    liveWindowWatcher = nil,
    watchedWindowId = nil,
    lastPolledWindowId = nil,
    lastPolledFrame = nil,
    watchers = {},
  }, WindowHighlight)
end

function WindowHighlight:isMissionControlActive()
  return self.missionControlActive
end

function WindowHighlight:rectForWindow(win)
  local frame = win:frame()
  local screen = win:screen()
  local screenFrame = screen:fullFrame()
  local visibleFrame = screen:frame()
  local pad = self.config.padding
  local left = frame.x - pad
  local top = frame.y - pad
  local right = frame.x + frame.w + pad
  local bottom = frame.y + frame.h + pad
  local touchesScreen = left <= screenFrame.x
    or top <= visibleFrame.y
    or right >= screenFrame.x + screenFrame.w
    or bottom >= screenFrame.y + screenFrame.h

  if touchesScreen then return frame, self.config.radius end

  return {
    x = left,
    y = top,
    w = right - left,
    h = bottom - top,
  }, self.config.radius + pad
end

function WindowHighlight:isValidWindow(win)
  if not win then return false end
  if not win:isStandard() then return false end
  if self.config.hideOnFullscreen and win:isFullScreen() then return false end

  return win:application() ~= nil
end

function WindowHighlight:hide()
  self.border:hide()
end

function WindowHighlight:isMissionControlOpen()
  if not (self.dockElement and self.dockElement:isValid()) then
    local dockApps = hs.application.applicationsForBundleID("com.apple.dock")
    local dockApp = dockApps and dockApps[1]

    if not dockApp then return false end
    self.dockElement = hs.axuielement.applicationElement(dockApp)
  end

  for _, element in ipairs(self.dockElement) do
    if element.AXIdentifier == "mc" then return true end
  end

  return false
end

function WindowHighlight:setFrame(frame)
  self.border:setFrame(frame)
  self:updateBorderPath(frame)
  self.border:show()
end

function WindowHighlight:updateBorderPath(frame)
  local width = frame.w
  local height = frame.h
  local radius = math.min(self.borderRadius, width / 2, height / 2)
  local bezier = 0.5522847498

  self.border.canvas[1].coordinates = {
    { x = radius, y = 0 },
    { x = width - radius, y = 0 },
    {
      x = width,
      y = radius,
      c1x = width - radius + bezier * radius,
      c1y = 0,
      c2x = width,
      c2y = radius - bezier * radius,
    },
    { x = width, y = height - radius },
    {
      x = width - radius,
      y = height,
      c1x = width,
      c1y = height - radius + bezier * radius,
      c2x = width - radius + bezier * radius,
      c2y = height,
    },
    { x = radius, y = height },
    {
      x = 0,
      y = height - radius,
      c1x = radius - bezier * radius,
      c1y = height,
      c2x = 0,
      c2y = height - radius + bezier * radius,
    },
    { x = 0, y = radius },
    {
      x = radius,
      y = 0,
      c1x = 0,
      c1y = radius - bezier * radius,
      c2x = radius - bezier * radius,
      c2y = 0,
    },
  }
end

function WindowHighlight:update()
  if self.missionControlActive then
    self:hide()
    return
  end

  local win = hs.window.focusedWindow()
  if not self:isValidWindow(win) then
    self:hide()
    return
  end

  local targetFrame, targetRadius = self:rectForWindow(win)
  self.borderRadius = targetRadius
  self:setFrame(targetFrame)
end

function WindowHighlight:watchFocusedWindowLive()
  local win = hs.window.focusedWindow()
  local windowId = win and win:id() or nil

  if self.liveWindowWatcher and self.watchedWindowId == windowId then return end

  if self.liveWindowWatcher then
    self.liveWindowWatcher:stop()
    self.liveWindowWatcher = nil
  end

  self.watchedWindowId = windowId
  if not win then return end

  self.liveWindowWatcher = win:newWatcher(function(_, event)
    if event == hs.uielement.watcher.elementDestroyed then
      if self.liveWindowWatcher then
        self.liveWindowWatcher:stop()
        self.liveWindowWatcher = nil
      end

      self.watchedWindowId = nil
      self:hide()

      hs.timer.doAfter(0.05, function()
        self:watchFocusedWindowLive()
        self:update()
      end)
    elseif event == hs.uielement.watcher.windowMoved
      or event == hs.uielement.watcher.windowResized then
      self:update()
    end
  end)

  self.liveWindowWatcher:start({
    hs.uielement.watcher.windowMoved,
    hs.uielement.watcher.windowResized,
    hs.uielement.watcher.elementDestroyed,
  })
end

function WindowHighlight:start()
  local windowFilter = hs.window.filter.new(nil)
  windowFilter:subscribe({
    hs.window.filter.windowFocused,
    hs.window.filter.windowMoved,
    hs.window.filter.windowTitleChanged,
    hs.window.filter.windowUnfocused,
  }, function()
    self:update()
  end)

  windowFilter:subscribe(hs.window.filter.windowFocused, function()
    self:watchFocusedWindowLive()
    if self.callbacks.onWindowFocused then
      self.callbacks.onWindowFocused()
    end
  end)

  local applicationWatcher = hs.application.watcher.new(function()
    hs.timer.doAfter(0.05, function()
      self:watchFocusedWindowLive()
      self:update()
    end)
  end)
  applicationWatcher:start()

  local spacesWatcher = hs.spaces.watcher.new(function()
    hs.timer.doAfter(0.15, function()
      self:update()
    end)
  end)
  spacesWatcher:start()

  local missionControlWatcher = hs.timer.doEvery(0.1, function()
    local ok, isOpen = pcall(function()
      return self:isMissionControlOpen()
    end)
    if not ok or isOpen == self.missionControlActive then return end

    self.missionControlActive = isOpen

    if self.missionControlActive then
      self:hide()
    else
      hs.timer.doAfter(0.15, function()
        self:update()
      end)
    end
  end)

  local framePollingWatcher = hs.timer.doEvery(
    1 / self.config.framePollingFps,
    function()
      if self.missionControlActive then return end

      local win = hs.window.focusedWindow()
      local windowId = win and win:id() or nil

      if windowId ~= self.lastPolledWindowId then
        self.lastPolledWindowId = windowId
        self.lastPolledFrame = win and win:frame() or nil
        self:watchFocusedWindowLive()
        self:update()
        return
      end

      if not win then return end

      local frame = win:frame()
      if sameFrame(frame, self.lastPolledFrame) then return end

      self.lastPolledFrame = frame
      self:update()
    end
  )

  self.watchers = {
    windowFilter = windowFilter,
    application = applicationWatcher,
    spaces = spacesWatcher,
    missionControl = missionControlWatcher,
    framePolling = framePollingWatcher,
  }

  hs.timer.doAfter(0.5, function()
    self:update()
    self:watchFocusedWindowLive()
  end)

  return self
end

return WindowHighlight
