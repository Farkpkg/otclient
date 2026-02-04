-- actionbar.lua
-- Main controller for the clean action bar module.

ActionBar = {
  rootPanel = nil,
  bottomContainer = nil,
  leftContainer = nil,
  rightContainer = nil,
  updateEvent = nil,
  updateIntervalMs = 100,
}

local function getRootPanel()
  return modules.game_interface.getRootPanel()
end

local function createActionButton(barId, buttonId)
  local button = g_ui.createWidget('ActionButton', ActionBarState.bars[barId])
  button.barId = barId
  button.buttonId = buttonId
  button.actionData = nil
  button.actionKey = nil
  button:setDraggable(true)

  button.onMouseRelease = function(widget, mousePos, mouseButton)
    if mouseButton == MouseLeftButton then
      ActionBar.execute(widget)
      return true
    end

    if mouseButton == MouseRightButton then
      ActionBar.openContextMenu(widget, mousePos)
      return true
    end

    return false
  end

  button.onDrop = function(widget, mousePos)
    ActionBar.handleDrop(widget)
    return true
  end

  return button
end

local function createBar(container, barId)
  local bar = g_ui.createWidget('ActionBarRow', container)
  bar:setId(barId)
  ActionBarState.bars[barId] = bar

  for buttonId = 1, ActionBarState.settings.buttonsPerBar do
    local button = createActionButton(barId, buttonId)
    ActionBarState.buttons[barId .. ':' .. buttonId] = button
    ActionBarAssignment.loadFromSettings(button)
  end
end

local function rebuildBars()
  ActionBar.bottomContainer:destroyChildren()
  ActionBar.leftContainer:destroyChildren()
  ActionBar.rightContainer:destroyChildren()

  for index = 1, ActionBarState.settings.barPositions.bottom do
    createBar(ActionBar.bottomContainer, 'bottom_' .. index)
  end

  for index = 1, ActionBarState.settings.barPositions.left do
    createBar(ActionBar.leftContainer, 'left_' .. index)
  end

  for index = 1, ActionBarState.settings.barPositions.right do
    createBar(ActionBar.rightContainer, 'right_' .. index)
  end
end

function ActionBar.openContextMenu(button, mousePos)
  local menu = g_ui.createWidget('PopupMenu')

  menu:addOption(tr('Assign Text'), function()
    displayTextInputBox(tr('Assign Text'), tr('Enter text to send in chat:'), function(text)
      ActionBarAssignment.assign(button, {
        type = 'text',
        key = 'text:' .. text,
        parameter = text,
        text = text,
      })
    end)
  end)

  menu:addOption(tr('Open Equipment Preset'), function()
    ActionBarPreset.show()
  end)

  menu:addOption(tr('Clear'), function()
    ActionBarAssignment.clear(button)
  end)

  menu:display(mousePos)
end

function ActionBar.handleDrop(button)
  local draggingWidget = g_ui.getDraggingWidget()
  if not draggingWidget then
    return
  end

  if draggingWidget == button then
    return
  end

  if draggingWidget:getClassName() == 'UIItem' and draggingWidget:getItem() then
    local item = draggingWidget:getItem()
    ActionBarAssignment.assign(button, {
      type = 'item',
      key = 'item:' .. item:getId(),
      itemId = item:getId(),
      subType = item:getSubType(),
      parameter = item:getName(),
    })
    return
  end

  if draggingWidget.actionData then
    ActionBarAssignment.assign(button, draggingWidget.actionData)
    return
  end

  if draggingWidget.spellName then
    ActionBarAssignment.assign(button, {
      type = 'spell',
      key = 'spell:' .. draggingWidget.spellName,
      spellName = draggingWidget.spellName,
      icon = draggingWidget.spellIcon,
      parameter = draggingWidget.spellName,
    })
  end
end

function ActionBar.execute(button)
  if not button or not button.actionData then
    return
  end

  local action = button.actionData
  if action.type == 'item' and action.itemId then
    g_game.useInventoryItem(action.itemId)
    return
  end

  if action.type == 'spell' and action.spellName then
    g_game.talk(action.spellName)
    return
  end

  if action.type == 'text' and action.text then
    modules.game_console.sendMessage(action.text)
    return
  end

  if action.type == 'preset' and action.presetItems then
    g_game.sendEquipmentPreset(action.presetItems)
  end
end

function ActionBar.updateCooldowns()
  ActionBarCooldown.updateAllButtons()
end

function ActionBar.onSpellCooldown(spellId, delay)
  if not spellId or not delay then
    return
  end

  ActionBarCooldown.setCooldown('spell:' .. spellId, delay)
end

function ActionBar.onSpellGroupCooldown(groupId, delay)
  if not groupId or not delay then
    return
  end

  ActionBarCooldown.setCooldown('spellgroup:' .. groupId, delay)
end

function ActionBar.onMultiUseCooldown(delay)
  if not delay then
    return
  end

  ActionBarCooldown.setCooldown('multiuse', delay)
end

function ActionBar.onPlayerUpdate()
  ActionBarCooldown.updateAllButtons()
end

function ActionBar.online()
  ActionBarState.runtime.isOnline = true
  ActionBarState.resetRuntime()
  rebuildBars()

  if ActionBar.updateEvent then
    removeEvent(ActionBar.updateEvent)
  end

  ActionBar.updateEvent = cycleEvent(ActionBar.updateCooldowns, ActionBar.updateIntervalMs)
end

function ActionBar.offline()
  ActionBarState.runtime.isOnline = false
  if ActionBar.updateEvent then
    removeEvent(ActionBar.updateEvent)
    ActionBar.updateEvent = nil
  end

  if ActionBar.rootPanel then
    ActionBar.rootPanel:destroy()
    ActionBar.rootPanel = nil
  end

  ActionBarState.resetRuntime()
end

function ActionBar.initUi()
  ActionBar.rootPanel = g_ui.loadUI('ui/actionbar', getRootPanel())
  ActionBar.bottomContainer = ActionBar.rootPanel:recursiveGetChildById('bottomContainer')
  ActionBar.leftContainer = ActionBar.rootPanel:recursiveGetChildById('leftContainer')
  ActionBar.rightContainer = ActionBar.rootPanel:recursiveGetChildById('rightContainer')

  if not ActionBarState.settings.visible then
    ActionBar.rootPanel:setVisible(false)
  end
end

function init()
  ActionBarState.loadSettings()
  ActionBar.initUi()

  connect(g_game, {
    onGameStart = ActionBar.online,
    onGameEnd = ActionBar.offline,
    onSpellCooldown = ActionBar.onSpellCooldown,
    onSpellGroupCooldown = ActionBar.onSpellGroupCooldown,
    onMultiUseCooldown = ActionBar.onMultiUseCooldown,
  })

  connect(LocalPlayer, {
    onManaChange = ActionBar.onPlayerUpdate,
    onLevelChange = ActionBar.onPlayerUpdate,
    onSpellsChange = ActionBar.onPlayerUpdate,
  })

  if g_game.isOnline() then
    ActionBar.online()
  end
end

function terminate()
  ActionBar.offline()

  disconnect(g_game, {
    onGameStart = ActionBar.online,
    onGameEnd = ActionBar.offline,
    onSpellCooldown = ActionBar.onSpellCooldown,
    onSpellGroupCooldown = ActionBar.onSpellGroupCooldown,
    onMultiUseCooldown = ActionBar.onMultiUseCooldown,
  })

  disconnect(LocalPlayer, {
    onManaChange = ActionBar.onPlayerUpdate,
    onLevelChange = ActionBar.onPlayerUpdate,
    onSpellsChange = ActionBar.onPlayerUpdate,
  })

  ActionBarState.saveSettings()
end
