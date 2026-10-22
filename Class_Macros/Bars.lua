local _, ns = ...

local LAST_ACTION_SLOT = 180
local FIRST_PROFILE_NAME = "Default"

local Bars = {}
ns.Bars = Bars

local function GetProfiles(classFile)
    ClassMacrosDB = ClassMacrosDB or {}
    ClassMacrosDB.profiles = ClassMacrosDB.profiles or {}
    local profiles = ClassMacrosDB.profiles[classFile]
    if not profiles then
        profiles = {}
        ClassMacrosDB.profiles[classFile] = profiles
    end
    local oldLayout = ClassMacrosDB.layouts and ClassMacrosDB.layouts[classFile]
    if oldLayout then
        profiles[FIRST_PROFILE_NAME] = profiles[FIRST_PROFILE_NAME] or oldLayout
        ClassMacrosDB.layouts[classFile] = nil
    end
    return profiles
end

local function GetWaitingSlots()
    ClassMacrosCharacterDB = ClassMacrosCharacterDB or {}
    ClassMacrosCharacterDB.waiting = ClassMacrosCharacterDB.waiting or {}
    return ClassMacrosCharacterDB.waiting
end

local function MacroTab(name, actionId)
    if GetMacroInfo(actionId) == name then
        return ns.Macros.TabOfIndex(actionId)
    end
    if ns.Macros.FindIndex(name, ns.CHARACTER) then
        return ns.CHARACTER
    end
    return ns.GENERAL
end

local function FindMacroShowing(subType, id)
    local generalCount, characterCount = GetNumMacros()
    local accountSlots = ns.Macros.AccountSlots()
    local indexes = {}
    for index = 1, generalCount do
        tinsert(indexes, index)
    end
    for index = accountSlots + 1, accountSlots + characterCount do
        tinsert(indexes, index)
    end
    for _, index in ipairs(indexes) do
        if subType == "spell" and GetMacroSpell and select(3, GetMacroSpell(index)) == id then
            return GetMacroInfo(index), index
        end
    end
end

local function MacroNameInSlot(slot, id, subType)
    local name = GetActionText(slot)
    if name then
        return name, id
    end
    name = GetMacroInfo(id)
    if name then
        return name, id
    end
    return FindMacroShowing(subType, id)
end

local function DescribeSlot(slot)
    local actionType, id, subType = GetActionInfo(slot)
    if actionType == "macro" then
        local name, index = MacroNameInSlot(slot, id, subType)
        if name then
            return { type = "macro", name = name, tab = MacroTab(name, index) }
        end
    elseif actionType == "spell" or actionType == "item" then
        return { type = actionType, id = id }
    end
end

local GetItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount
local PickupItem = (C_Item and C_Item.PickupItem) or PickupItem

local function ItemName(itemId)
    if C_Item and C_Item.GetItemNameByID then
        return C_Item.GetItemNameByID(itemId)
    end
    return (GetItemInfo(itemId))
end

local function SpellName(spellId)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellId)
    end
    return (GetSpellInfo(spellId))
end

local function SameAction(a, b)
    if not (a and b) or a.type ~= b.type then
        return false
    end
    if a.type == "macro" then
        return a.name == b.name
    end
    return a.id == b.id
end

local function CanWaitFor(action)
    return action.type == "spell" or action.type == "item"
end

local function PickUp(action)
    if action.type == "macro" then
        local otherTab = action.tab == ns.CHARACTER and ns.GENERAL or ns.CHARACTER
        local index = ns.Macros.FindIndex(action.name, action.tab) or ns.Macros.FindIndex(action.name, otherTab)
        if index then
            PickupMacro(index)
        end
    elseif action.type == "spell" then
        if IsPlayerSpell(action.id) then
            local pickupSpell = (C_Spell and C_Spell.PickupSpell) or PickupSpell
            pickupSpell(action.id)
        end
    elseif action.type == "item" then
        if GetItemCount(action.id) > 0 then
            PickupItem(action.id)
        end
    end
    return GetCursorInfo() ~= nil
end

local NOT_FOUND = "not found on this character"
local REFUSED = "the game did not accept it"

local function PlaceInSlot(slot, action)
    if not PickUp(action) then
        ClearCursor()
        return false, NOT_FOUND
    end
    PlaceAction(slot)
    ClearCursor()
    if SameAction(DescribeSlot(slot), action) then
        return true
    end
    return false, REFUSED
end

local function DescribeAction(action)
    if action.type == "macro" then
        return "macro " .. action.name
    elseif action.type == "spell" then
        return "spell " .. (SpellName(action.id) or tostring(action.id))
    end
    return "item " .. (ItemName(action.id) or tostring(action.id))
end

function Bars.ListProfiles(classFile)
    local names = {}
    for name in pairs(GetProfiles(classFile)) do
        tinsert(names, name)
    end
    table.sort(names)
    return names
end

function Bars.GetProfile(classFile, profileName)
    return profileName and GetProfiles(classFile)[profileName]
end

function Bars.DeleteProfile(classFile, profileName)
    GetProfiles(classFile)[profileName] = nil
end

function Bars.GetSelectedProfile(classFile)
    local profiles = GetProfiles(classFile)
    ClassMacrosDB.selected = ClassMacrosDB.selected or {}
    local selected = ClassMacrosDB.selected[classFile]
    if selected and profiles[selected] then
        return selected
    end
    return Bars.ListProfiles(classFile)[1]
end

function Bars.SelectProfile(classFile, profileName)
    GetProfiles(classFile)
    ClassMacrosDB.selected = ClassMacrosDB.selected or {}
    ClassMacrosDB.selected[classFile] = profileName
end

function Bars.ImportProfile(classFile, profileName, layout)
    local profiles = GetProfiles(classFile)
    local finalName, number = profileName, 2
    while profiles[finalName] do
        finalName = format("%s (%d)", profileName, number)
        number = number + 1
    end
    profiles[finalName] = layout
    return finalName
end

function Bars.Save(classFile, profileName)
    local slots, saved = {}, 0
    for slot = 1, LAST_ACTION_SLOT do
        local action = DescribeSlot(slot)
        if action then
            slots[slot] = action
            saved = saved + 1
        end
    end
    GetProfiles(classFile)[profileName] = { slots = slots, savedBy = UnitName("player"), savedAt = time() }
    return saved
end

function Bars.Load(classFile, profileName)
    local layout = Bars.GetProfile(classFile, profileName)
    if not layout then
        return nil
    end
    ClearCursor()
    local waiting = GetWaitingSlots()
    wipe(waiting)
    local result = { placed = 0, unchanged = 0, waiting = 0, problems = {} }
    local function LoadSlot(slot, action)
        local before = DescribeSlot(slot)
        if SameAction(before, action) then
            result.unchanged = result.unchanged + 1
            return
        end
        local placed, reason = PlaceInSlot(slot, action)
        if placed then
            result.placed = result.placed + 1
        elseif reason == NOT_FOUND and CanWaitFor(action) then
            waiting[slot] = action
            result.waiting = result.waiting + 1
        else
            tinsert(result.problems, format("%s (slot %d, %s)", DescribeAction(action), slot, reason))
        end
    end
    for slot, action in pairs(layout.slots) do
        local ok, errorText = pcall(LoadSlot, slot, action)
        if not ok then
            ClearCursor()
            tinsert(result.problems, format("%s (slot %d, error: %s)", DescribeAction(action), slot, tostring(errorText)))
        end
    end
    return result
end

function Bars.PrintSlots()
    for slot = 1, LAST_ACTION_SLOT do
        local actionType, id, subType = GetActionInfo(slot)
        if actionType then
            local action = DescribeSlot(slot)
            print(format("slot %d: %s %s %s | text %s | saved as %s", slot, tostring(actionType), tostring(id),
                tostring(subType), tostring(GetActionText(slot)), action and DescribeAction(action) or "NOTHING"))
        end
    end
end

function Bars.CountWaiting()
    local count = 0
    for _ in pairs(GetWaitingSlots()) do
        count = count + 1
    end
    return count
end

local function PlaceWaitingActions()
    if InCombatLockdown() then
        return
    end
    local waiting = GetWaitingSlots()
    for slot, action in pairs(waiting) do
        local current = DescribeSlot(slot)
        if SameAction(current, action) then
            waiting[slot] = nil
        elseif current then
            print(format("Class Macros: %s was not placed in slot %d, because the slot is in use", DescribeAction(action), slot))
            waiting[slot] = nil
        elseif PlaceInSlot(slot, action) then
            print(format("Class Macros: placed %s in slot %d", DescribeAction(action), slot))
            waiting[slot] = nil
        end
    end
end

local pendingCheck = false

local function SchedulePlaceWaitingActions()
    if pendingCheck then
        return
    end
    pendingCheck = true
    C_Timer.After(1, function()
        pendingCheck = false
        PlaceWaitingActions()
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", SchedulePlaceWaitingActions)
