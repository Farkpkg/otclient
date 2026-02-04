-- assignment.lua
-- Handles assignment of items, spells, texts, and presets to action buttons.

ActionBarAssignment = {}

local function setButtonLabels(button, action)
  local hotkeyLabel = button:getChildById('hotkeyLabel')
  local parameterLabel = button:getChildById('parameterLabel')

  if hotkeyLabel then
    hotkeyLabel:setText(action.hotkey or '')
  end

  if parameterLabel then
    parameterLabel:setText(action.parameter or '')
  end
end

local function setButtonItem(button, action)
  local itemWidget = button:getChildById('item')
  if not itemWidget then
    return
  end

  if action.type == 'item' and action.itemId then
    itemWidget:setItemId(action.itemId)
    if action.subType then
      itemWidget:setItemSubType(action.subType)
    end
  else
    itemWidget:clearItem()
  end
end

local function setButtonIcon(button, action)
  local iconWidget = button:getChildById('icon')
  if not iconWidget then
    return
  end

  if action.type == 'spell' then
    iconWidget:setImageSource(action.icon or '/images/ui/icons/skill')
    iconWidget:setVisible(true)
  elseif action.type == 'text' then
    iconWidget:setImageSource('/images/ui/icons/keyboard')
    iconWidget:setVisible(true)
  elseif action.type == 'preset' then
    iconWidget:setImageSource(action.icon or '/images/ui/icons/outfit')
    iconWidget:setVisible(true)
  else
    iconWidget:setVisible(false)
  end
end

function ActionBarAssignment.updateButton(button)
  if not button then
    return
  end

  local action = button.actionData or {}
  setButtonItem(button, action)
  setButtonIcon(button, action)
  setButtonLabels(button, action)
end

function ActionBarAssignment.assign(button, action)
  if not button or not action then
    return
  end

  button.actionData = action
  button.actionKey = action.key
  ActionBarState.setAssignment(button.barId, button.buttonId, action)
  ActionBarAssignment.updateButton(button)
end

function ActionBarAssignment.clear(button)
  if not button then
    return
  end

  button.actionData = nil
  button.actionKey = nil
  ActionBarState.clearAssignment(button.barId, button.buttonId)
  ActionBarAssignment.updateButton(button)
end

function ActionBarAssignment.loadFromSettings(button)
  if not button then
    return
  end

  local action = ActionBarState.getAssignment(button.barId, button.buttonId)
  if action then
    button.actionData = action
    button.actionKey = action.key
  end

  ActionBarAssignment.updateButton(button)
end
