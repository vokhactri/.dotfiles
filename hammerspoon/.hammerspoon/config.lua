local accentColor = {
  red = 0.25,
  green = 0.65,
  blue = 1.0,
  alpha = 0.95,
}

return {
  windowHighlight = {
    borderWidth = 5,
    padding = 4,
    radius = 10,
    color = accentColor,

    hideOnFullscreen = false,
    framePollingFps = 60,
  },

  appNameToast = {
    enabled = true,
    duration = 0.7,
    showOnFocus = true,
    showOnOption = true,

    style = {
      fillColor = { white = 0.08, alpha = 0.88 },
      strokeColor = accentColor,
      strokeWidth = 2,
      textColor = { white = 1, alpha = 1 },
      textSize = 20,
      padding = 10,
      radius = 10,
      fadeInDuration = 0.08,
      fadeOutDuration = 0.12,
    },
  },
}
