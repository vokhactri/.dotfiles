local WindowHighlight = {}
WindowHighlight.__index = WindowHighlight

local function sameFrame(a, b)
  if not a or not b then return false end

  return math.abs(a.x - b.x) < 0.1
    and math.abs(a.y - b.y) < 0.1
    and math.abs(a.w - b.w) < 0.1
    and math.abs(a.h - b.h) < 0.1
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function easeOutCubic(t)
  return 1 - math.pow(1 - t, 3)
end

function WindowHighlight.new(config, callbacks)
  local border = hs.drawing.rectangle(hs.geometry.rect(0, 0, 1, 1))
  border:setFill(false)
  border:setStroke(true)
  border:setStrokeWidth(config.borderWidth)
  border:setStrokeColor(config.color)
  border:setRoundedRectRadii(config.radius, config.radius)
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
    currentFrame = nil,
    animationTimer = nil,
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

  local left = math.max(frame.x - pad, screenFrame.x)
  local top = math.max(frame.y - pad, visibleFrame.y)
  local right = math.min(
    frame.x + frame.w + pad,
    screenFrame.x + screenFrame.w
  )
  local bottom = math.min(
    frame.y + frame.h + pad,
    screenFrame.y + screenFrame.h
  )

  return {
    x = left,
    y = top,
    w = right - left,
    h = bottom - top,
  }
end

function WindowHighlight:isValidWindow(win)
  if not win then return false end
  if not win:isStandard() then return false end
  if self.config.hideOnFullscreen and win:isFullScreen() then return false end

  return win:application() ~= nil
end

function WindowHighlight:hide()
  if self.animationTimer then
    self.animationTimer:stop()
    self.animationTimer = nil
  end

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
  self.border:show()
end

function WindowHighlight:animateTo(targetFrame)
  if self.animationTimer then
    self.animationTimer:stop()
    self.animationTimer = nil
  end

  if not self.config.animation or not self.currentFrame then
    self.currentFrame = targetFrame
    self:setFrame(targetFrame)
    return
  end

  local startFrame = self.currentFrame
  local step = 0
  local steps = self.config.animationSteps
  local interval = self.config.animationDuration / steps

  self.animationTimer = hs.timer.doEvery(interval, function()
    step = step + 1
    local t = easeOutCubic(step / steps)
    local frame = {
      x = lerp(startFrame.x, targetFrame.x, t),
      y = lerp(startFrame.y, targetFrame.y, t),
      w = lerp(startFrame.w, targetFrame.w, t),
      h = lerp(startFrame.h, targetFrame.h, t),
    }

    self.currentFrame = frame
    self:setFrame(frame)

    if step >= steps then
      self.animationTimer:stop()
      self.animationTimer = nil
      self.currentFrame = targetFrame
      self:setFrame(targetFrame)
    end
  end)
end

function WindowHighlight:update(immediate)
  if self.missionControlActive then
    self:hide()
    self.currentFrame = nil
    return
  end

  local win = hs.window.focusedWindow()
  if not self:isValidWindow(win) then
    self:hide()
    self.currentFrame = nil
    return
  end

  local targetFrame = self:rectForWindow(win)
  if not immediate then
    self:animateTo(targetFrame)
    return
  end

  if self.animationTimer then
    self.animationTimer:stop()
    self.animationTimer = nil
  end

  self.currentFrame = targetFrame
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
    if event == hs.uielement.watcher.windowMoved
      or event == hs.uielement.watcher.windowResized then
      self:update(true)
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
    self:update(false)
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
      self:update(false)
    end)
  end)
  applicationWatcher:start()

  local spacesWatcher = hs.spaces.watcher.new(function()
    hs.timer.doAfter(0.15, function()
      self:update(false)
    end)
  end)
  spacesWatcher:start()

  local missionControlWatcher = hs.timer.doEvery(0.1, function()
    local ok, isOpen = pcall(function()
      return self:isMissionControlOpen()
    end)
    if not ok or isOpen == self.missionControlActive then return end

    self.missionControlActive = isOpen
    self.currentFrame = nil

    if self.missionControlActive then
      self:hide()
    else
      hs.timer.doAfter(0.15, function()
        self:update(false)
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
        return
      end

      if not win then return end

      local frame = win:frame()
      if sameFrame(frame, self.lastPolledFrame) then return end

      self.lastPolledFrame = frame
      self:update(true)
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
    self:update(false)
    self:watchFocusedWindowLive()
  end)

  return self
end

return WindowHighlight
