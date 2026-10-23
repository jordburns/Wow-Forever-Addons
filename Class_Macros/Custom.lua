local _, ns = ...

local Custom = {}
ns.Custom = Custom

local MAX_NAME_LENGTH = 16
local MAX_BODY_LENGTH = 255

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, item in pairs(value) do
        copy[key] = DeepCopy(item)
    end
    return copy
end
Custom.DeepCopy = DeepCopy

local function Database()
    ClassMacrosDB = ClassMacrosDB or {}
    ClassMacrosDB.characterSets = ClassMacrosDB.characterSets or {}
    ClassMacrosDB.importedSets = ClassMacrosDB.importedSets or {}
    return ClassMacrosDB
end

local function CharacterKey()
    return UnitName("player") .. " - " .. GetRealmName()
end

local function PlayerClassFile()
    local _, classFile = UnitClass("player")
    return classFile
end

local function OwnSets(classFile)
    local entry = Database().characterSets[CharacterKey()]
    if entry and entry.class == classFile then
        return entry
    end
end

local function WithBuiltInExtras(classFile, sets)
    local builtIn = ns.ClassSets[classFile]
    return {
        gearSlots = sets.gearSlots or (builtIn and builtIn.gearSlots) or {},
        retired = builtIn and builtIn.retired,
        order = sets.order,
        sections = sets.sections,
    }
end

local function BuiltInMacroId(sectionKey, macroName)
    return sectionKey .. "/" .. macroName
end

local function FindMacroIndex(section, macroName)
    for index, macro in ipairs(section.macros) do
        if macro[1] == macroName then
            return index
        end
    end
end

local function RecordBuiltIn(sets, builtIn)
    sets.builtInTexts = {}
    sets.knownSections = {}
    for key, section in pairs(builtIn and builtIn.sections or {}) do
        sets.knownSections[key] = true
        for _, macro in ipairs(section.macros) do
            sets.builtInTexts[BuiltInMacroId(key, macro[1])] = macro[2]
        end
    end
end

local function StartTrackingOldCopy(sets, builtIn)
    sets.builtInTexts = {}
    sets.knownSections = {}
    for key, section in pairs(builtIn.sections) do
        sets.knownSections[key] = true
        local own = sets.sections[key]
        for _, macro in ipairs(section.macros) do
            if own and FindMacroIndex(own, macro[1]) then
                sets.builtInTexts[BuiltInMacroId(key, macro[1])] = macro[2]
            end
        end
    end
end

local function AddNewBuiltInSections(sets, builtIn, changes)
    for _, key in ipairs(builtIn.order) do
        if not sets.knownSections[key] then
            sets.knownSections[key] = true
            if not sets.sections[key] then
                sets.sections[key] = DeepCopy(builtIn.sections[key])
                tinsert(sets.order, key)
                tinsert(changes.added, builtIn.sections[key].title)
                for _, macro in ipairs(builtIn.sections[key].macros) do
                    sets.builtInTexts[BuiltInMacroId(key, macro[1])] = macro[2]
                end
            end
        end
    end
end

local function ApplyBuiltInMacroChanges(sets, builtIn, changes)
    for key, section in pairs(builtIn.sections) do
        local own = sets.sections[key]
        for _, macro in ipairs(section.macros) do
            local id = BuiltInMacroId(key, macro[1])
            local recorded = sets.builtInTexts[id]
            local index = own and FindMacroIndex(own, macro[1])
            if recorded == nil then
                if own and not index then
                    tinsert(own.macros, { macro[1], macro[2] })
                    tinsert(changes.added, macro[1])
                end
            elseif recorded ~= macro[2] and index and own.macros[index][2] == recorded then
                own.macros[index][2] = macro[2]
                tinsert(changes.updated, macro[1])
            end
            sets.builtInTexts[id] = macro[2]
        end
    end
end

local function RemoveDroppedBuiltInMacros(sets, builtIn, changes)
    for id, recorded in pairs(sets.builtInTexts) do
        local key, name = id:match("^(.-)/(.*)$")
        local builtInSection = builtIn.sections[key]
        if not (builtInSection and FindMacroIndex(builtInSection, name)) then
            local own = sets.sections[key]
            local index = own and FindMacroIndex(own, name)
            if index and own.macros[index][2] == recorded then
                tremove(own.macros, index)
                tinsert(changes.removed, name)
            end
            sets.builtInTexts[id] = nil
        end
    end
end

local function SyncWithBuiltIn(classFile, sets)
    local builtIn = ns.ClassSets[classFile]
    if not builtIn then
        return
    end
    if not sets.builtInTexts then
        StartTrackingOldCopy(sets, builtIn)
    end
    local changes = { added = {}, updated = {}, removed = {} }
    AddNewBuiltInSections(sets, builtIn, changes)
    ApplyBuiltInMacroChanges(sets, builtIn, changes)
    RemoveDroppedBuiltInMacros(sets, builtIn, changes)
    local messages = {
        added = "Class Macros: new built-in macros added to your own sets: %s. Click Make to create them.",
        updated = "Class Macros: built-in macros updated in your own sets: %s. Click Make to update /macro.",
        removed = "Class Macros: built-in macros removed from your own sets: %s. Delete them in /macro if you do not need them.",
    }
    for _, kind in ipairs({ "added", "updated", "removed" }) do
        if #changes[kind] > 0 then
            print(format(messages[kind], table.concat(changes[kind], ", ")))
        end
    end
end

local syncedThisSession = {}

local function BuiltInCopy(classFile)
    local builtIn = ns.ClassSets[classFile]
    local copy = {
        order = DeepCopy(builtIn and builtIn.order or {}),
        sections = DeepCopy(builtIn and builtIn.sections or {}),
    }
    RecordBuiltIn(copy, builtIn)
    return copy
end

function Custom.IsCustomized(classFile)
    return OwnSets(classFile) ~= nil
end

function Custom.HasBuiltIn(classFile)
    return ns.ClassSets[classFile] ~= nil
end

function Custom.GetSet(classFile)
    local own = OwnSets(classFile)
    if own then
        if not syncedThisSession[classFile] then
            syncedThisSession[classFile] = true
            SyncWithBuiltIn(classFile, own)
        end
        return WithBuiltInExtras(classFile, own)
    end
    return ns.ClassSets[classFile]
end

function Custom.GetEditable(classFile)
    local database = Database()
    if classFile ~= PlayerClassFile() then
        database.importedSets[classFile] = database.importedSets[classFile] or BuiltInCopy(classFile)
        return database.importedSets[classFile]
    end
    local own = OwnSets(classFile)
    if not own then
        own = BuiltInCopy(classFile)
        own.class = classFile
        database.characterSets[CharacterKey()] = own
    end
    return own
end

function Custom.ResetClass(classFile)
    if OwnSets(classFile) then
        Database().characterSets[CharacterKey()] = nil
    end
end

function Custom.ListCopySources(classFile)
    local database = Database()
    local sources = {}
    for characterKey, entry in pairs(database.characterSets) do
        if entry.class == classFile and characterKey ~= CharacterKey() then
            tinsert(sources, { label = characterKey, sets = entry })
        end
    end
    table.sort(sources, function(a, b) return a.label < b.label end)
    if database.importedSets[classFile] then
        tinsert(sources, { label = "Imported sets", sets = database.importedSets[classFile] })
    end
    local oldShared = database.customSets and database.customSets[classFile]
    if oldShared then
        tinsert(sources, { label = "Shared sets (old)", sets = oldShared })
    end
    return sources
end

function Custom.CopyFrom(classFile, sets)
    local copy = {
        class = classFile,
        order = DeepCopy(sets.order),
        sections = DeepCopy(sets.sections),
        gearSlots = DeepCopy(sets.gearSlots),
        builtInTexts = DeepCopy(sets.builtInTexts),
        knownSections = DeepCopy(sets.knownSections),
    }
    if not copy.builtInTexts then
        RecordBuiltIn(copy, ns.ClassSets[classFile])
    end
    Database().characterSets[CharacterKey()] = copy
end

function Custom.NewSectionKey(sets)
    local number = 1
    while sets.sections["custom" .. number] do
        number = number + 1
    end
    return "custom" .. number
end

function Custom.ValidateMacro(name, body)
    name = strtrim(name or "")
    if name == "" then
        return false, "the macro needs a name"
    end
    if #name > MAX_NAME_LENGTH then
        return false, format("the macro name can have %d letters at most", MAX_NAME_LENGTH)
    end
    if #(body or "") > MAX_BODY_LENGTH then
        return false, format("the macro text can have %d letters at most", MAX_BODY_LENGTH)
    end
    return true
end

function Custom.ValidateSection(section)
    if type(section) ~= "table" or type(section.title) ~= "string" or type(section.macros) ~= "table" then
        return false, "a set is missing its name or macros"
    end
    if section.tab ~= ns.CHARACTER and section.tab ~= ns.GENERAL then
        return false, "set " .. section.title .. " has no valid tab"
    end
    for _, macro in ipairs(section.macros) do
        if type(macro) ~= "table" or type(macro[1]) ~= "string" or type(macro[2]) ~= "string" then
            return false, "set " .. section.title .. " has a broken macro"
        end
        local ok, problem = Custom.ValidateMacro(macro[1], macro[2])
        if not ok then
            return false, macro[1] .. ": " .. problem
        end
    end
    return true
end

function Custom.CleanSection(section)
    local clean = {
        title = section.title,
        tab = section.tab,
        icon = tonumber(section.icon),
        iconSpell = tonumber(section.iconSpell),
        macros = {},
    }
    for _, macro in ipairs(section.macros) do
        tinsert(clean.macros, { strtrim(macro[1]), macro[2] })
    end
    return clean
end

local MAX_GEAR_SLOTS = 6
local MAX_PLACEHOLDER_LENGTH = 12

Custom.EQUIPMENT_SLOTS = {
    { id = 16, label = "Main hand" },
    { id = 17, label = "Off hand" },
    { id = 18, label = "Ranged" },
    { id = 13, label = "Trinket 1" },
    { id = 14, label = "Trinket 2" },
}

function Custom.EquipmentSlotLabel(inventorySlot)
    for _, equipmentSlot in ipairs(Custom.EQUIPMENT_SLOTS) do
        if equipmentSlot.id == inventorySlot then
            return equipmentSlot.label
        end
    end
    return "Slot " .. tostring(inventorySlot)
end

function Custom.GetEditableGearSlots(classFile)
    local sets = Custom.GetEditable(classFile)
    if not sets.gearSlots then
        local builtIn = ns.ClassSets[classFile]
        sets.gearSlots = DeepCopy(builtIn and builtIn.gearSlots or {})
    end
    return sets.gearSlots
end

function Custom.PlaceholderKey(word)
    return "<" .. strupper(strtrim(word or "")) .. ">"
end

function Custom.ValidateGearSlot(gearSlots, label, word, ignoreIndex)
    label = strtrim(label or "")
    word = strtrim(word or "")
    if label == "" then
        return false, "the gear slot needs a name"
    end
    if not word:match("^%w+$") then
        return false, "the placeholder can have only letters and numbers"
    end
    if #word > MAX_PLACEHOLDER_LENGTH then
        return false, format("the placeholder can have %d letters at most", MAX_PLACEHOLDER_LENGTH)
    end
    local key = Custom.PlaceholderKey(word)
    for index, gearSlot in ipairs(gearSlots) do
        if index ~= ignoreIndex and gearSlot.key == key then
            return false, "another gear slot already uses " .. key
        end
    end
    if not ignoreIndex and #gearSlots >= MAX_GEAR_SLOTS then
        return false, format("a class can have %d gear slots at most", MAX_GEAR_SLOTS)
    end
    return true
end

function Custom.RenamePlaceholder(classFile, oldKey, newKey)
    local sets = Custom.GetEditable(classFile)
    local changed = 0
    for _, section in pairs(sets.sections) do
        for _, macro in ipairs(section.macros) do
            local start = macro[2]:find(oldKey, 1, true)
            if start then
                local parts = {}
                local position = 1
                while start do
                    tinsert(parts, macro[2]:sub(position, start - 1))
                    tinsert(parts, newKey)
                    position = start + #oldKey
                    start = macro[2]:find(oldKey, position, true)
                end
                tinsert(parts, macro[2]:sub(position))
                macro[2] = table.concat(parts)
                changed = changed + 1
            end
        end
    end
    return changed
end

function Custom.ValidateGearSlots(gearSlots)
    if type(gearSlots) ~= "table" then
        return false, "the gear slots are broken"
    end
    local checked = {}
    for _, gearSlot in ipairs(gearSlots) do
        if type(gearSlot) ~= "table" or type(gearSlot.key) ~= "string" or type(gearSlot.label) ~= "string" then
            return false, "a gear slot is broken"
        end
        local word = gearSlot.key:match("^<(%w+)>$")
        local ok, problem = Custom.ValidateGearSlot(checked, gearSlot.label, word)
        if not ok then
            return false, problem
        end
        tinsert(checked, { key = gearSlot.key, label = gearSlot.label })
    end
    return true
end

function Custom.CleanGearSlots(gearSlots)
    local clean = {}
    for _, gearSlot in ipairs(gearSlots) do
        tinsert(clean, {
            key = gearSlot.key,
            label = strtrim(gearSlot.label),
            inventorySlot = tonumber(gearSlot.inventorySlot) or 16,
            default = "MY_" .. gearSlot.key:match("^<(%w+)>$"),
        })
    end
    return clean
end

Custom.MAX_NAME_LENGTH = MAX_NAME_LENGTH
Custom.MAX_BODY_LENGTH = MAX_BODY_LENGTH
