-- preset.lua
-- Manages equipment preset window and data serialization.

ActionBarPreset = {
  window = nil,
  iconWindow = nil,
  selectedPresetId = nil,
  slots = {
    head = InventorySlotHead,
    body = InventorySlotBody,
    legs = InventorySlotLeg,
    feet = InventorySlotFeet,
    left = InventorySlotLeft,
    right = InventorySlotRight,
    ammo = InventorySlotAmmo,
    ring = InventorySlotFinger,
    necklace = InventorySlotNeck,
  }
}

local function getInventoryItem(slotId)
  local inventory = g_game.getLocalPlayer():getInventoryItem(slotId)
  if not inventory then
    return nil
  end

  return inventory
end

local function setSlotItem(widget, item)
  if item then
    widget:setItem(item)
  else
    widget:clearItem()
  end
end

function ActionBarPreset.show()
  if ActionBarPreset.window then
    ActionBarPreset.window:raise()
    ActionBarPreset.window:focus()
    return
  end

  ActionBarPreset.window = g_ui.loadUI('ui/equippreset', modules.game_interface.getRootPanel())
  ActionBarPreset.window:raise()
  ActionBarPreset.window:focus()

  ActionBarPreset.refresh()
end

function ActionBarPreset.hide()
  if not ActionBarPreset.window then
    return
  end

  ActionBarPreset.window:destroy()
  ActionBarPreset.window = nil
end

function ActionBarPreset.refresh()
  if not ActionBarPreset.window then
    return
  end

  for slotName, slotId in pairs(ActionBarPreset.slots) do
    local slotWidget = ActionBarPreset.window:recursiveGetChildById(slotName .. 'Slot')
    if slotWidget then
      setSlotItem(slotWidget, getInventoryItem(slotId))
    end
  end
end

function ActionBarPreset.apply()
  if not g_game.isOnline() then
    return
  end

  local items = {}
  for slotName, slotId in pairs(ActionBarPreset.slots) do
    local slotWidget = ActionBarPreset.window:recursiveGetChildById(slotName .. 'Slot')
    if slotWidget then
      local item = slotWidget:getItem()
      if item then
        items[slotId] = item:getId()
      end
    end
  end

  g_game.sendEquipmentPreset(items)
end

function ActionBarPreset.setSlot(slotName, item)
  if not ActionBarPreset.window then
    return
  end

  local slotWidget = ActionBarPreset.window:recursiveGetChildById(slotName .. 'Slot')
  if slotWidget then
    setSlotItem(slotWidget, item)
  end
end
