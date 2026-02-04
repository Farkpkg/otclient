-- state.lua
-- Centralized state and persistence for the clean action bar module.

ActionBarState = {
  settings = {},
  bars = {},
  buttons = {},
  hotkeys = {},
  cooldowns = {},
  runtime = {
    loaded = false,
    isOnline = false,
  }
}

local SETTINGS_KEY = 'actionbar_clean'

local function defaultSettings()
  return {
    visible = true,
    locked = false,
    buttonsPerBar = 10,
    barPositions = {
      bottom = 3,
      left = 3,
      right = 3,
    },
    assignments = {},
  }
end

function ActionBarState.loadSettings()
  local node = g_settings.getNode(SETTINGS_KEY)
  if not node then
    ActionBarState.settings = defaultSettings()
    return
  end

  local defaults = defaultSettings()
  defaults.visible = node.visible ~= false
  defaults.locked = node.locked == true
  defaults.buttonsPerBar = tonumber(node.buttonsPerBar) or defaults.buttonsPerBar
  defaults.barPositions = node.barPositions or defaults.barPositions
  defaults.assignments = node.assignments or {}
  ActionBarState.settings = defaults
end

function ActionBarState.saveSettings()
  g_settings.setNode(SETTINGS_KEY, ActionBarState.settings)
end

function ActionBarState.resetRuntime()
  ActionBarState.bars = {}
  ActionBarState.buttons = {}
  ActionBarState.hotkeys = {}
  ActionBarState.cooldowns = {}
  ActionBarState.runtime.loaded = false
end

function ActionBarState.getAssignment(barId, buttonId)
  local barAssignments = ActionBarState.settings.assignments[barId]
  if not barAssignments then
    return nil
  end

  return barAssignments[buttonId]
end

function ActionBarState.setAssignment(barId, buttonId, data)
  ActionBarState.settings.assignments[barId] = ActionBarState.settings.assignments[barId] or {}
  ActionBarState.settings.assignments[barId][buttonId] = data
end

function ActionBarState.clearAssignment(barId, buttonId)
  if not ActionBarState.settings.assignments[barId] then
    return
  end

  ActionBarState.settings.assignments[barId][buttonId] = nil
end
