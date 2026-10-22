local _, ns = ...

local CHARACTER = ns.CHARACTER
local DYNAMIC_ICON = 134400

local Macros = {}
ns.Macros = Macros

local function LoadMacroSlotLimits()
    if not MAX_ACCOUNT_MACROS then
        local loadAddOn = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
        loadAddOn("Blizzard_MacroUI")
    end
    return MAX_ACCOUNT_MACROS or 120, MAX_CHARACTER_MACROS or 30
end

function Macros.GetPlayerSet()
    local _, classFile = UnitClass("player")
    return ns.Custom.GetSet(classFile)
end

local function FindGearSlot(key)
    local set = Macros.GetPlayerSet()
    for _, gearSlot in ipairs(set and set.gearSlots or {}) do
        if gearSlot.key == key then
            return gearSlot
        end
    end
end

function Macros.GetGearName(key)
    local saved = ClassMacrosCharacterDB and ClassMacrosCharacterDB.gear and ClassMacrosCharacterDB.gear[key]
    local gearSlot = FindGearSlot(key)
    return saved or (gearSlot and gearSlot.default)
end

function Macros.SetGearName(key, name)
    ClassMacrosCharacterDB = ClassMacrosCharacterDB or {}
    ClassMacrosCharacterDB.gear = ClassMacrosCharacterDB.gear or {}
    ClassMacrosCharacterDB.gear[key] = name
end

function Macros.GetGearIcon(key)
    return ClassMacrosCharacterDB and ClassMacrosCharacterDB.gearIcons and ClassMacrosCharacterDB.gearIcons[key]
end

function Macros.MoveGearSettings(oldKey, newKey)
    local store = ClassMacrosCharacterDB
    for _, field in ipairs({ "gear", "gearIcons" }) do
        local values = store and store[field]
        if values and values[oldKey] then
            values[newKey] = values[oldKey]
            values[oldKey] = nil
        end
    end
end

function Macros.SetGearIcon(key, icon)
    ClassMacrosCharacterDB = ClassMacrosCharacterDB or {}
    ClassMacrosCharacterDB.gearIcons = ClassMacrosCharacterDB.gearIcons or {}
    ClassMacrosCharacterDB.gearIcons[key] = icon
end

local function FillGearNames(body)
    return (body:gsub("<%w+>", function(key)
        if FindGearSlot(key) then
            return Macros.GetGearName(key)
        end
    end))
end

local function UsesGear(body)
    return body:find("<%w+>") ~= nil
end

local function FindMacroInTab(name, tab, accountSlots)
    local generalCount, characterCount = GetNumMacros()
    local first, count = 1, generalCount
    if tab == CHARACTER then
        first, count = accountSlots + 1, characterCount
    end
    for index = first, first + count - 1 do
        if GetMacroInfo(index) == name then
            return index
        end
    end
end

local function HasFreeSlot(tab, accountSlots, characterSlots)
    local generalCount, characterCount = GetNumMacros()
    if tab == CHARACTER then
        return characterCount < characterSlots
    end
    return generalCount < accountSlots
end

function Macros.AccountSlots()
    return (LoadMacroSlotLimits())
end

function Macros.FindIndex(name, tab)
    return FindMacroInTab(name, tab, LoadMacroSlotLimits())
end

function Macros.TabOfIndex(index)
    local accountSlots = LoadMacroSlotLimits()
    if index > accountSlots then
        return CHARACTER
    end
    return ns.GENERAL
end


function Macros.CountExisting(set, sectionKey)
    local accountSlots = LoadMacroSlotLimits()
    local section = set.sections[sectionKey]
    local existing = 0
    for _, macro in ipairs(section.macros) do
        if FindMacroInTab(macro[1], section.tab, accountSlots) then
            existing = existing + 1
        end
    end
    return existing, #section.macros
end

function Macros.MakeSelected(set, sectionKeys, selection)
    local accountSlots, characterSlots = LoadMacroSlotLimits()
    local counts = { created = 0, updated = 0, failed = 0 }
    for _, key in ipairs(sectionKeys) do
        local section = set.sections[key]
        local chosen = selection and selection[key]
        for _, replaced in ipairs(section.replaces or {}) do
            local index = FindMacroInTab(replaced[1], replaced[2], accountSlots)
            if index and (not chosen or chosen[replaced[1]]) then
                DeleteMacro(index)
            end
        end
        for _, macro in ipairs(section.macros) do
            local name, body = macro[1], FillGearNames(macro[2])
            if not chosen or chosen[name] then
                local index = FindMacroInTab(name, section.tab, accountSlots)
                if index then
                    EditMacro(index, name, DYNAMIC_ICON, body)
                    counts.updated = counts.updated + 1
                elseif HasFreeSlot(section.tab, accountSlots, characterSlots) then
                    CreateMacro(name, DYNAMIC_ICON, body, section.tab == CHARACTER)
                    counts.created = counts.created + 1
                else
                    print("Class Macros: cannot make " .. name .. ", your " .. section.tab .. " macro tab is full")
                    counts.failed = counts.failed + 1
                end
            end
        end
    end
    return counts
end

function Macros.MakeSections(set, sectionKeys)
    return Macros.MakeSelected(set, sectionKeys, nil)
end

function Macros.ExistsInGame(name, tab)
    return FindMacroInTab(name, tab, LoadMacroSlotLimits()) ~= nil
end

function Macros.NamesUsingGear(set)
    local names = {}
    for _, key in ipairs(set.order) do
        for _, macro in ipairs(set.sections[key].macros) do
            if UsesGear(macro[2]) then
                tinsert(names, macro[1])
            end
        end
    end
    return names
end

function Macros.UpdateMacrosUsingGear(set)
    local accountSlots = LoadMacroSlotLimits()
    local updated = 0
    for _, key in ipairs(set.order) do
        local section = set.sections[key]
        for _, macro in ipairs(section.macros) do
            local index = UsesGear(macro[2]) and FindMacroInTab(macro[1], section.tab, accountSlots)
            if index then
                EditMacro(index, macro[1], DYNAMIC_ICON, FillGearNames(macro[2]))
                updated = updated + 1
            end
        end
    end
    return updated
end

function Macros.UpdateInGame(oldName, tab, newName, body)
    local index = FindMacroInTab(oldName, tab, LoadMacroSlotLimits())
    if index then
        EditMacro(index, newName, DYNAMIC_ICON, FillGearNames(body))
        return true
    end
    return false
end

function Macros.DeleteInGame(name, tab)
    local index = FindMacroInTab(name, tab, LoadMacroSlotLimits())
    if index then
        DeleteMacro(index)
        return true
    end
    return false
end

local function DeleteByName(name, tab, accountSlots)
    local index = FindMacroInTab(name, tab, accountSlots)
    if index then
        DeleteMacro(index)
        return 1
    end
    return 0
end

function Macros.DeleteSections(set, sectionKeys, includeRetired)
    local accountSlots = LoadMacroSlotLimits()
    local deleted = 0
    for _, key in ipairs(sectionKeys) do
        local section = set.sections[key]
        for _, macro in ipairs(section.macros) do
            deleted = deleted + DeleteByName(macro[1], section.tab, accountSlots)
        end
    end
    if includeRetired then
        for _, macro in ipairs(set.retired or {}) do
            deleted = deleted + DeleteByName(macro[1], macro[2], accountSlots)
        end
    end
    return deleted
end
