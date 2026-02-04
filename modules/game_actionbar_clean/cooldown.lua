-- cooldown.lua
-- Handles cooldown tracking and UI updates for action buttons.

ActionBarCooldown = {}

local function nowMillis()
  return g_clock.millis()
end

local function ensureCooldownTable(key)
  ActionBarState.cooldowns[key] = ActionBarState.cooldowns[key] or {}
  return ActionBarState.cooldowns[key]
end

function ActionBarCooldown.setCooldown(key, durationMs, startTime)
  local cooldown = ensureCooldownTable(key)
  cooldown.startTime = startTime or nowMillis()
  cooldown.durationMs = durationMs
end

function ActionBarCooldown.clearCooldown(key)
  ActionBarState.cooldowns[key] = nil
end

function ActionBarCooldown.getRemaining(key)
  local cooldown = ActionBarState.cooldowns[key]
  if not cooldown then
    return 0
  end

  local elapsed = nowMillis() - cooldown.startTime
  local remaining = cooldown.durationMs - elapsed
  if remaining <= 0 then
    ActionBarCooldown.clearCooldown(key)
    return 0
  end

  return remaining
end

function ActionBarCooldown.updateButton(button)
  if not button or not button.actionKey then
    return
  end

  local remaining = ActionBarCooldown.getRemaining(button.actionKey)
  local cooldownWidget = button:getChildById('cooldown')
  if not cooldownWidget then
    return
  end

  if remaining <= 0 then
    cooldownWidget:setVisible(false)
    return
  end

  local cooldown = ActionBarState.cooldowns[button.actionKey]
  local percent = 0
  if cooldown and cooldown.durationMs > 0 then
    percent = math.floor((remaining / cooldown.durationMs) * 100)
  end

  cooldownWidget:setVisible(true)
  cooldownWidget:setPercent(percent)
  cooldownWidget:setText(string.format('%.1f', remaining / 1000))
end

function ActionBarCooldown.updateAllButtons()
  for _, button in pairs(ActionBarState.buttons) do
    ActionBarCooldown.updateButton(button)
  end
end
