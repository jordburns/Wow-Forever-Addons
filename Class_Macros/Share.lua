local _, ns = ...

local Share = {}
ns.Share = Share

local PAYLOAD_VERSION = 1
local PAYLOAD_ADDON = "ClassMacros"
local ACCEPTED_PAYLOAD_ADDONS = { ClassMacros = true, ClassMacrosV2 = true }
local VALID_SLOT_TYPES = { macro = true, spell = true, item = true }

local frame

local function SetStatus(text)
    frame.status:SetText(text)
end

local function ShowText(text)
    frame.editBox:SetText(text)
    frame.editBox:HighlightText()
    frame.editBox:SetFocus()
end

local function NewPayload(kind, classFile)
    return { addon = PAYLOAD_ADDON, version = PAYLOAD_VERSION, kind = kind, class = classFile }
end

local function ExportAllSets()
    local classFile = ns.UI.PlayerClassFile()
    local set = ns.Macros.GetPlayerSet()
    local payload = NewPayload("sets", classFile)
    payload.order = ns.Custom.DeepCopy(set.order)
    payload.gearSlots = ns.Custom.CleanGearSlots(set.gearSlots or {})
    payload.sections = {}
    for _, key in ipairs(set.order) do
        payload.sections[key] = ns.Custom.CleanSection(set.sections[key])
    end
    ShowText(ns.Serializer.Export(payload))
    SetStatus(format("All %d sets exported. Press Ctrl+C to copy the text.", #set.order))
end

local function ExportBarProfile()
    local classFile = ns.UI.PlayerClassFile()
    local name = ns.Bars.GetSelectedProfile(classFile)
    local profile = ns.Bars.GetProfile(classFile, name)
    if not profile then
        SetStatus("There is no bar profile to export. Save bars first.")
        return
    end
    local payload = NewPayload("bars", classFile)
    payload.name = name
    payload.profile = ns.Custom.DeepCopy(profile)
    ShowText(ns.Serializer.Export(payload))
    SetStatus("Bar profile " .. name .. " exported. Press Ctrl+C to copy the text.")
end

function Share.ExportSet(sectionKey, fromWindow)
    Share.Open(fromWindow)
    local classFile = ns.UI.PlayerClassFile()
    local section = ns.Macros.GetPlayerSet().sections[sectionKey]
    local payload = NewPayload("set", classFile)
    payload.section = ns.Custom.CleanSection(section)
    ShowText(ns.Serializer.Export(payload))
    SetStatus("Set " .. section.title .. " exported. Press Ctrl+C to copy the text.")
end

local function ClassName(classFile)
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile]) or classFile
end

local function ImportSet(payload)
    local ok, problem = ns.Custom.ValidateSection(payload.section)
    if not ok then
        return nil, problem
    end
    local section = ns.Custom.CleanSection(payload.section)
    local sets = ns.Custom.GetEditable(payload.class)
    for _, key in ipairs(sets.order) do
        if sets.sections[key].title == section.title then
            sets.sections[key] = section
            return format("Replaced the %s set %s.", ClassName(payload.class), section.title)
        end
    end
    local key = ns.Custom.NewSectionKey(sets)
    sets.sections[key] = section
    tinsert(sets.order, key)
    return format("Added the %s set %s.", ClassName(payload.class), section.title)
end

local function ImportAllSets(payload)
    if type(payload.order) ~= "table" or type(payload.sections) ~= "table" then
        return nil, "the sets are missing"
    end
    local order, sections = {}, {}
    for _, key in ipairs(payload.order) do
        local section = payload.sections[key]
        local ok, problem = ns.Custom.ValidateSection(section)
        if not ok then
            return nil, problem
        end
        local cleanKey = "custom" .. (#order + 1)
        tinsert(order, cleanKey)
        sections[cleanKey] = ns.Custom.CleanSection(section)
    end
    local gearSlots
    if payload.gearSlots then
        local ok, problem = ns.Custom.ValidateGearSlots(payload.gearSlots)
        if not ok then
            return nil, problem
        end
        gearSlots = ns.Custom.CleanGearSlots(payload.gearSlots)
    end
    local sets = ns.Custom.GetEditable(payload.class)
    sets.order, sets.sections = order, sections
    sets.gearSlots = gearSlots or sets.gearSlots
    return format("Replaced all %s sets with %d imported sets.", ClassName(payload.class), #order)
end

local function ImportBarProfile(payload)
    local profile = payload.profile
    if type(profile) ~= "table" or type(profile.slots) ~= "table" or type(payload.name) ~= "string" then
        return nil, "the bar profile is missing"
    end
    local slots = {}
    for slot, action in pairs(profile.slots) do
        if type(slot) ~= "number" or type(action) ~= "table" or not VALID_SLOT_TYPES[action.type] then
            return nil, "the bar profile has a broken slot"
        end
        slots[slot] = { type = action.type, name = action.name, tab = action.tab, id = tonumber(action.id) }
    end
    local layout = { slots = slots, savedBy = tostring(profile.savedBy or "?"), savedAt = tonumber(profile.savedAt) or time() }
    local finalName = ns.Bars.ImportProfile(payload.class, payload.name, layout)
    return format("Imported the %s bar profile as %s.", ClassName(payload.class), finalName)
end

local function RunsCode(body)
    local lowerBody = strlower(body)
    return lowerBody:find("/run", 1, true) or lowerBody:find("/script", 1, true)
end

local function CountScriptMacros(payload)
    local sections = payload.kind == "set" and { payload.section } or payload.sections or {}
    local count = 0
    for _, section in pairs(sections) do
        for _, macro in ipairs(type(section) == "table" and section.macros or {}) do
            if type(macro[2]) == "string" and RunsCode(macro[2]) then
                count = count + 1
            end
        end
    end
    return count
end

local IMPORTERS = { set = ImportSet, sets = ImportAllSets, bars = ImportBarProfile }

local function Import(payload)
    local message, problem = IMPORTERS[payload.kind](payload)
    if not message then
        SetStatus("|cffff4444Import failed: " .. problem .. "|r")
        return
    end
    if payload.class ~= ns.UI.PlayerClassFile() then
        message = message .. " To use it, log in on a " .. ClassName(payload.class)
            .. ", open Edit sets and choose Copy sets from > Imported sets."
    end
    local scriptCount = CountScriptMacros(payload)
    if scriptCount > 0 then
        message = message .. format(" |cffffcc00Warning: %d imported macros run Lua code (/run or /script). Read them in the editor before you use them.|r", scriptCount)
    end
    SetStatus("|cff44ff44" .. message .. "|r")
    ns.UI.Refresh()
    ns.Editor.Refresh()
end

StaticPopupDialogs["CLASS_MACROS_IMPORT_ALL"] = {
    text = "Replace all your %s macro sets with the imported sets?\n\nYour own changes to those sets are lost. Macros already in /macro do not change until you click Make.",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function(self, payload)
        self:Hide()
        C_Timer.After(0, function() Import(payload) end)
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
}

local function StartImport()
    local payload, problem = ns.Serializer.Import(frame.editBox:GetText())
    if not payload then
        SetStatus("|cffff4444Import failed: " .. problem .. "|r")
        return
    end
    if type(payload) ~= "table" or not ACCEPTED_PAYLOAD_ADDONS[payload.addon] or not IMPORTERS[payload.kind]
        or type(payload.class) ~= "string" then
        SetStatus("|cffff4444Import failed: this string is not a set or bar profile from Class Macros|r")
        return
    end
    if payload.kind == "sets" then
        StaticPopup_Show("CLASS_MACROS_IMPORT_ALL", ClassName(payload.class), nil, payload)
        return
    end
    Import(payload)
end

local function CreateShareFrame()
    frame = CreateFrame("Frame", "ClassMacrosShareFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 420)
    frame:SetPoint("CENTER", 40, -40)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    tinsert(UISpecialFrames, "ClassMacrosShareFrame")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -6)
    title:SetText("Class Macros - Import / Export")

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 16, -32)
    hint:SetPoint("TOPRIGHT", -16, -32)
    hint:SetJustifyH("LEFT")
    hint:SetText("Export: choose what to export, then press Ctrl+C. Import: click in the box, paste a string with Ctrl+V, then click Import. Import accepts one set, all sets or a bar profile. Only import strings from people you trust.")

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 18, -64)
    scrollFrame:SetPoint("BOTTOMRIGHT", -36, 104)

    frame.editBox = CreateFrame("EditBox", nil, scrollFrame)
    frame.editBox:SetMultiLine(true)
    frame.editBox:SetAutoFocus(false)
    frame.editBox:SetMaxLetters(0)
    frame.editBox:SetFontObject(ChatFontNormal)
    frame.editBox:SetWidth(530)
    frame.editBox:SetHeight(220)
    frame.editBox:SetScript("OnEscapePressed", frame.editBox.ClearFocus)
    if ScrollingEdit_OnCursorChanged then
        frame.editBox:SetScript("OnCursorChanged", ScrollingEdit_OnCursorChanged)
        frame.editBox:SetScript("OnUpdate", function(self, elapsed) ScrollingEdit_OnUpdate(self, elapsed, scrollFrame) end)
    end
    scrollFrame:SetScrollChild(frame.editBox)
    scrollFrame:EnableMouse(true)
    scrollFrame:SetScript("OnMouseDown", function() frame.editBox:SetFocus() end)

    local setLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    setLabel:SetPoint("BOTTOMLEFT", 18, 72)
    setLabel:SetText("One set:")

    frame.setDropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    frame.setDropdown:SetWidth(220)
    frame.setDropdown:SetPoint("LEFT", setLabel, "RIGHT", 8, 0)
    frame.setDropdown:SetDefaultText("Choose a set")
    frame.setDropdown:SetupMenu(function(_, rootDescription)
        local set = ns.Macros.GetPlayerSet()
        for _, key in ipairs(set and set.order or {}) do
            rootDescription:CreateRadio(set.sections[key].title, function(value)
                return frame.exportKey == value
            end, function(value)
                frame.exportKey = value
            end, key)
        end
    end)

    local exportOne = ns.UI.CreateButton(frame, "Export set", 100, function()
        local set = ns.Macros.GetPlayerSet()
        if not (frame.exportKey and set.sections[frame.exportKey]) then
            SetStatus("Choose a set first.")
            return
        end
        Share.ExportSet(frame.exportKey)
    end)
    exportOne:SetPoint("LEFT", frame.setDropdown, "RIGHT", 8, 0)

    local exportSets = ns.UI.CreateButton(frame, "Export all sets", 130, ExportAllSets)
    exportSets:SetPoint("BOTTOMLEFT", 16, 40)

    local exportBars = ns.UI.CreateButton(frame, "Export bar profile", 140, ExportBarProfile)
    exportBars:SetPoint("LEFT", exportSets, "RIGHT", 6, 0)

    local import = ns.UI.CreateButton(frame, "Import", 100, StartImport)
    import:SetPoint("BOTTOMRIGHT", -16, 40)

    local clear = ns.UI.CreateButton(frame, "Clear", 80, function()
        frame.editBox:SetText("")
        frame.editBox:SetFocus()
        SetStatus("")
    end)
    clear:SetPoint("RIGHT", import, "LEFT", -6, 0)

    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.status:SetPoint("BOTTOMLEFT", 18, 18)
    frame.status:SetPoint("BOTTOMRIGHT", -18, 18)
    frame.status:SetJustifyH("LEFT")

    frame:SetScript("OnHide", ns.UI.ReturnToPreviousWindow)
    ns.UI.AddBackAndCloseButtons(frame)
end

function Share.Open(fromWindow)
    if not frame then
        CreateShareFrame()
    end
    ns.UI.ReplaceWindow(frame, fromWindow)
end
