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
    cornerRadii = nil,
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
  self:updateBorderPath(frame)
  self.border:show()
end

function WindowHighlight:updateCornerRadii(win, borderFrame)
  local frame = win:frame()
  local radius = self.config.radius
  local leftPadding = math.max(frame.x - borderFrame.x, 0)
  local topPadding = math.max(frame.y - borderFrame.y, 0)
  local rightPadding = math.max(
    borderFrame.x + borderFrame.w - (frame.x + frame.w),
    0
  )
  local bottomPadding = math.max(
    borderFrame.y + borderFrame.h - (frame.y + frame.h),
    0
  )
  local topLeftRadius = radius + math.min(leftPadding, topPadding)
  local topRightRadius = radius + math.min(rightPadding, topPadding)
  local bottomRightRadius = radius
    + math.min(rightPadding, bottomPadding)
  local bottomLeftRadius = radius
    + math.min(leftPadding, bottomPadding)

  self.cornerRadii = {
    topLeft = { x = topLeftRadius, y = topLeftRadius },
    topRight = { x = topRightRadius, y = topRightRadius },
    bottomRight = {
      x = bottomRightRadius,
      y = bottomRightRadius,
    },
    bottomLeft = {
      x = bottomLeftRadius,
      y = bottomLeftRadius,
    },
  }
end

function WindowHighlight:updateBorderPath(frame)
  local radii = self.cornerRadii
  if not radii then return end

  local width = frame.w
  local height = frame.h
  local maxXRadius = width / 2
  local maxYRadius = height / 2
  local bezier = 0.5522847498

  local topLeft = {
    x = math.min(radii.topLeft.x, maxXRadius),
    y = math.min(radii.topLeft.y, maxYRadius),
  }
  local topRight = {
    x = math.min(radii.topRight.x, maxXRadius),
    y = math.min(radii.topRight.y, maxYRadius),
  }
  local bottomRight = {
    x = math.min(radii.bottomRight.x, maxXRadius),
    y = math.min(radii.bottomRight.y, maxYRadius),
  }
  local bottomLeft = {
    x = math.min(radii.bottomLeft.x, maxXRadius),
    y = math.min(radii.bottomLeft.y, maxYRadius),
  }

  self.border.canvas[1].coordinates = {
    { x = topLeft.x, y = 0 },
    { x = width - topRight.x, y = 0 },
    {
      x = width,
      y = topRight.y,
      c1x = width - topRight.x + bezier * topRight.x,
      c1y = 0,
      c2x = width,
      c2y = topRight.y - bezier * topRight.y,
    },
    { x = width, y = height - bottomRight.y },
    {
      x = width - bottomRight.x,
      y = height,
      c1x = width,
      c1y = height - bottomRight.y + bezier * bottomRight.y,
      c2x = width - bottomRight.x + bezier * bottomRight.x,
      c2y = height,
    },
    { x = bottomLeft.x, y = height },
    {
      x = 0,
      y = height - bottomLeft.y,
      c1x = bottomLeft.x - bezier * bottomLeft.x,
      c1y = height,
      c2x = 0,
      c2y = height - bottomLeft.y + bezier * bottomLeft.y,
    },
    { x = 0, y = topLeft.y },
    {
      x = topLeft.x,
      y = 0,
      c1x = 0,
      c1y = topLeft.y - bezier * topLeft.y,
      c2x = topLeft.x - bezier * topLeft.x,
      c2y = 0,
    },
  }
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
  self:updateCornerRadii(win, targetFrame)
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
    if event == hs.uielement.watcher.elementDestroyed then
      if self.liveWindowWatcher then
        self.liveWindowWatcher:stop()
        self.liveWindowWatcher = nil
      end

      self.watchedWindowId = nil
      self.currentFrame = nil
      self:hide()

      hs.timer.doAfter(0.05, function()
        self:watchFocusedWindowLive()
        self:update(true)
      end)
    elseif event == hs.uielement.watcher.windowMoved
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
        self:watchFocusedWindowLive()
        self:update(true)
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
