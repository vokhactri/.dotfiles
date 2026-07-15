-- Active Window Highlight for Hammerspoon
-- Reload: Hammerspoon menu -> Reload Config

local config = {
  borderWidth = 5,
  padding = 4,
  radius = 10,

  -- blue border
  color = { red = 0.25, green = 0.65, blue = 1.0, alpha = 0.95 },

  -- animation
  animation = true,
  animationDuration = 0.10,
  animationSteps = 8,

  hideOnFullscreen = false,
}

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

local currentFrame = nil
local animationTimer = nil
local missionControlActive = false
local dockElement = nil
local liveWindowWatcher = nil
local watchedWindowId = nil
local lastPolledWindowId = nil
local lastPolledFrame = nil

local function rectForWindow(win)
  local f = win:frame()
  local screen = win:screen()
  local screenFrame = screen:fullFrame()
  local visibleFrame = screen:frame()
  local pad = config.padding

  -- Padding normally expands the highlight outside the window. When a window
  -- touches a screen edge, align left/right/bottom with the physical display.
  -- Align the center of the top stroke with the bottom edge of the menu bar so
  -- there is no visible gap between them.
  local left = math.max(f.x - pad, screenFrame.x)
  local top = math.max(f.y - pad, visibleFrame.y)
  local right = math.min(
    f.x + f.w + pad,
    screenFrame.x + screenFrame.w
  )
  local bottom = math.min(
    f.y + f.h + pad,
    screenFrame.y + screenFrame.h
  )

  return {
    x = left,
    y = top,
    w = right - left,
    h = bottom - top,
  }
end

local function isValidWindow(win)
  if not win then return false end
  if not win:isStandard() then return false end
  if config.hideOnFullscreen and win:isFullScreen() then return false end

  local app = win:application()
  if not app then return false end

  return true
end

local function hideHighlight()
  if animationTimer then
    animationTimer:stop()
    animationTimer = nil
  end

  border:hide()
end

local function isMissionControlOpen()
  if not (dockElement and dockElement:isValid()) then
    local dockApps = hs.application.applicationsForBundleID("com.apple.dock")
    local dockApp = dockApps and dockApps[1]

    if not dockApp then return false end
    dockElement = hs.axuielement.applicationElement(dockApp)
  end

  for _, element in ipairs(dockElement) do
    if element.AXIdentifier == "mc" then return true end
  end

  return false
end

local function setFrame(frame)
  border:setFrame(frame)
  border:show()
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function easeOutCubic(t)
  return 1 - math.pow(1 - t, 3)
end

local function animateTo(targetFrame)
  if animationTimer then
    animationTimer:stop()
    animationTimer = nil
  end

  if not config.animation or not currentFrame then
    currentFrame = targetFrame
    setFrame(targetFrame)
    return
  end

  local startFrame = currentFrame
  local step = 0
  local steps = config.animationSteps
  local interval = config.animationDuration / steps

  animationTimer = hs.timer.doEvery(interval, function()
    step = step + 1
    local t = easeOutCubic(step / steps)

    local frame = {
      x = lerp(startFrame.x, targetFrame.x, t),
      y = lerp(startFrame.y, targetFrame.y, t),
      w = lerp(startFrame.w, targetFrame.w, t),
      h = lerp(startFrame.h, targetFrame.h, t),
    }

    currentFrame = frame
    setFrame(frame)

    if step >= steps then
      animationTimer:stop()
      animationTimer = nil
      currentFrame = targetFrame
      setFrame(targetFrame)
    end
  end)
end

local function updateHighlight(immediate)
  if missionControlActive then
    hideHighlight()
    currentFrame = nil
    return
  end

  local win = hs.window.focusedWindow()

  if not isValidWindow(win) then
    hideHighlight()
    currentFrame = nil
    return
  end

  local targetFrame = rectForWindow(win)

  if immediate then
    if animationTimer then
      animationTimer:stop()
      animationTimer = nil
    end

    currentFrame = targetFrame
    setFrame(targetFrame)
  else
    animateTo(targetFrame)
  end
end

local function watchFocusedWindowLive()
  local win = hs.window.focusedWindow()
  local windowId = win and win:id() or nil

  if liveWindowWatcher and watchedWindowId == windowId then return end

  if liveWindowWatcher then
    liveWindowWatcher:stop()
    liveWindowWatcher = nil
  end

  watchedWindowId = windowId
  if not win then return end

  liveWindowWatcher = win:newWatcher(function(_, event)
    if event == hs.uielement.watcher.windowMoved
      or event == hs.uielement.watcher.windowResized then
      updateHighlight(true)
    end
  end)

  liveWindowWatcher:start({
    hs.uielement.watcher.windowMoved,
    hs.uielement.watcher.windowResized,
    hs.uielement.watcher.elementDestroyed,
  })
end

local wf = hs.window.filter.new(nil)

-- window.filter reports both moves and resizes as windowMoved. The separate
-- windowResized event only exists on hs.uielement.watcher, so subscribing to
-- hs.window.filter.windowResized would pass nil and make subscribe() fail.
wf:subscribe({
  hs.window.filter.windowFocused,
  hs.window.filter.windowMoved,
  hs.window.filter.windowTitleChanged,
  hs.window.filter.windowUnfocused,
}, updateHighlight)

wf:subscribe(hs.window.filter.windowFocused, function()
  watchFocusedWindowLive()
end)

-- Keep watcher references alive for as long as the config is loaded.
local applicationWatcher = hs.application.watcher.new(function()
  hs.timer.doAfter(0.05, function()
    watchFocusedWindowLive()
    updateHighlight()
  end)
end)
applicationWatcher:start()

local spacesWatcher = hs.spaces.watcher.new(function()
  hs.timer.doAfter(0.15, updateHighlight)
end)
spacesWatcher:start()

-- macOS exposes Mission Control as the "mc" element in Dock's accessibility
-- tree. Polling this state also catches trackpad gestures and hot corners.
local missionControlWatcher = hs.timer.doEvery(0.1, function()
  local ok, isOpen = pcall(isMissionControlOpen)
  if not ok or isOpen == missionControlActive then return end

  missionControlActive = isOpen
  currentFrame = nil

  if missionControlActive then
    hideHighlight()
  else
    hs.timer.doAfter(0.15, updateHighlight)
  end
end)

local function sameFrame(a, b)
  if not a or not b then return false end

  return math.abs(a.x - b.x) < 0.1
    and math.abs(a.y - b.y) < 0.1
    and math.abs(a.w - b.w) < 0.1
    and math.abs(a.h - b.h) < 0.1
end

-- Some apps and window managers (including Rectangle on some macOS versions)
-- coalesce accessibility resize events. Polling the focused frame provides a
-- reliable realtime fallback with at most ~33 ms latency.
local framePollingWatcher = hs.timer.doEvery(1 / 30, function()
  if missionControlActive then return end

  local win = hs.window.focusedWindow()
  local windowId = win and win:id() or nil

  if windowId ~= lastPolledWindowId then
    lastPolledWindowId = windowId
    lastPolledFrame = win and win:frame() or nil
    return
  end

  if not win then return end

  local frame = win:frame()
  if sameFrame(frame, lastPolledFrame) then return end

  lastPolledFrame = frame
  updateHighlight(true)
end)

-- Running Hammerspoon objects must remain reachable after this file finishes.
_G.activeWindowHighlightWatchers = {
  windowFilter = wf,
  application = applicationWatcher,
  spaces = spacesWatcher,
  missionControl = missionControlWatcher,
  framePolling = framePollingWatcher,
}

hs.timer.doAfter(0.5, updateHighlight)
hs.timer.doAfter(0.5, watchFocusedWindowLive)

hs.alert.show("Active window highlight loaded")
