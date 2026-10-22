local _, ns = ...

local ROW_HEIGHT = 46
local FIRST_ROW_Y = -64
local BUTTON_WIDTH = 72
local GEAR_LINE_HEIGHT = 24
local GEAR_AREA_BOTTOM = 116
local EMPTY_GEAR_ICON = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"

local CHECK_COLUMNS = 3
local CHECK_LINE_HEIGHT = 22
local MAX_LIST_HEIGHT = 420

local frame
local rows = {}
local expanded = {}
local selection = {}

local function TabLabel(tab)
    if tab == ns.CHARACTER then
        return "|cff66ccffCharacter tab|r"
    end
    return "|cffffcc00General tab|r"
end

local function SetStatus(text)
    frame.status:SetText(text)
end

local function CanChangeMacros()
    if InCombatLockdown() then
        SetStatus("|cffff4444You cannot change macros or bars in combat.|r")
        return false
    end
    return true
end

local function PlayerClassFile()
    local _, classFile = UnitClass("player")
    return classFile
end

local function DescribeSelectedProfile()
    local classFile = PlayerClassFile()
    local name = ns.Bars.GetSelectedProfile(classFile)
    local profile = ns.Bars.GetProfile(classFile, name)
    if not profile then
        return "No saved bar profiles yet"
    end
    return format("Saved by %s, %s", profile.savedBy or "?", date("%d %b %Y %H:%M", profile.savedAt or 0))
end

local function Refresh()
    if not (frame and frame:IsShown()) then
        return
    end
    local set = ns.Macros.GetPlayerSet()
    if not set then
        return
    end
    for _, row in ipairs(rows) do
        if row:IsShown() and set.sections[row.key] then
            local existing, total = ns.Macros.CountExisting(set, row.key)
            local color = existing == total and "|cff44ff44" or "|cffffffff"
            row.count:SetText(format("%s%d/%d|r", color, existing, total))
            if expanded[row.key] then
                local section = set.sections[row.key]
                for _, check in ipairs(row.checks) do
                    if check:IsShown() then
                        local made = ns.Macros.ExistsInGame(check.macroName, section.tab)
                        check.label:SetText((made and "|cff44ff44" or "|cffffffff") .. check.macroName .. "|r")
                        check:SetChecked(selection[row.key] and selection[row.key][check.macroName] or false)
                    end
                end
            end
        end
    end
    if frame.gearTitle:IsShown() then
        frame.gearTitle:SetText("Gear for this character (used by " .. table.concat(ns.Macros.NamesUsingGear(set), ", ") .. ")")
    end
    frame.layoutInfo:SetText(DescribeSelectedProfile())
    for _, gearLine in ipairs(frame.gearLines) do
        if gearLine:IsShown() then
            gearLine.itemName:SetText(ns.Macros.GetGearName(gearLine.gearSlot.key))
            gearLine.itemButton.icon:SetTexture(ns.Macros.GetGearIcon(gearLine.gearSlot.key) or EMPTY_GEAR_ICON)
        end
    end
    frame.profileDropdown:GenerateMenu()
end

local function MakeSets(sectionKeys, label)
    if not CanChangeMacros() then
        return
    end
    local counts = ns.Macros.MakeSections(ns.Macros.GetPlayerSet(), sectionKeys)
    SetStatus(format("%s: %d created, %d updated, %d failed", label, counts.created, counts.updated, counts.failed))
    Refresh()
end

local function MakeSelectedMacros()
    if not CanChangeMacros() then
        return
    end
    local set = ns.Macros.GetPlayerSet()
    local keys = {}
    for _, key in ipairs(set.order) do
        if selection[key] and next(selection[key]) then
            tinsert(keys, key)
        end
    end
    if #keys == 0 then
        SetStatus("Tick some macros first. Click + on a set to see its macros.")
        return
    end
    local counts = ns.Macros.MakeSelected(set, keys, selection)
    SetStatus(format("Selected macros: %d created, %d updated, %d failed", counts.created, counts.updated, counts.failed))
    Refresh()
end

local function DeleteSets(data)
    if not CanChangeMacros() then
        return
    end
    local deleted = ns.Macros.DeleteSections(ns.Macros.GetPlayerSet(), data.keys, data.includeRetired)
    SetStatus(format("%s: %d deleted", data.label, deleted))
    Refresh()
end

local function SaveBars(profileName)
    if not CanChangeMacros() then
        return
    end
    profileName = strtrim(profileName or "")
    if profileName == "" then
        SetStatus("Type a profile name to save your bars.")
        return
    end
    local classFile = PlayerClassFile()
    local saved = ns.Bars.Save(classFile, profileName)
    ns.Bars.SelectProfile(classFile, profileName)
    SetStatus(format("Saved profile %s: %d action slots", profileName, saved))
    Refresh()
end

local function LoadBars(profileName)
    if not CanChangeMacros() then
        return
    end
    local result = ns.Bars.Load(PlayerClassFile(), profileName)
    if not result then
        SetStatus("No saved bar profile. Click Save bars on a character with your layout first.")
        return
    end
    SetStatus(format("Loaded profile %s: %d placed, %d already right, %d waiting, %d missing",
        profileName, result.placed, result.unchanged, result.waiting, #result.problems))
    if result.waiting > 0 then
        print(format("Class Macros: %d spells or items wait in their slots until you learn or get them", result.waiting))
    end
    if #result.problems > 0 then
        print("Class Macros: not placed. For a macro that is not found, click Make all, then Load bars again:")
        for _, line in ipairs(result.problems) do
            print("  " .. line)
        end
    end
end

local function DeleteProfile(profileName)
    local classFile = PlayerClassFile()
    ns.Bars.DeleteProfile(classFile, profileName)
    ns.Bars.SelectProfile(classFile, nil)
    SetStatus("Deleted profile " .. profileName)
    Refresh()
end

local function ItemNameById(itemId)
    if C_Item and C_Item.GetItemNameByID then
        return C_Item.GetItemNameByID(itemId)
    end
    return (GetItemInfo(itemId))
end

local function ItemIconById(itemId)
    if C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(itemId)
    end
    return GetItemIcon(itemId)
end

local function SetGear(gearSlot, itemId)
    if not CanChangeMacros() then
        return
    end
    local itemName = ItemNameById(itemId)
    if not itemName then
        SetStatus("The game does not know that item yet. Try again in a moment.")
        return
    end
    ns.Macros.SetGearName(gearSlot.key, itemName)
    ns.Macros.SetGearIcon(gearSlot.key, ItemIconById(itemId))
    local updated = ns.Macros.UpdateMacrosUsingGear(ns.Macros.GetPlayerSet())
    SetStatus(format("%s set to %s. %d gear macros updated.", gearSlot.label, itemName, updated))
    Refresh()
end

local function UseEquippedGear(gearSlot)
    local itemId = GetInventoryItemID("player", gearSlot.inventorySlot)
    if not itemId then
        SetStatus(format("Equip your %s first, then click Use equipped again.", strlower(gearSlot.label)))
        return
    end
    SetGear(gearSlot, itemId)
end

local function DropGearFromCursor(gearSlot)
    local cursorType, itemId = GetCursorInfo()
    if cursorType ~= "item" then
        return
    end
    ClearCursor()
    SetGear(gearSlot, itemId)
end

local function CloseThenRun(popup, action, argument)
    popup:Hide()
    C_Timer.After(0, function() action(argument) end)
end

local function PopupEditBox(popup)
    return popup.editBox or popup.EditBox
end

StaticPopupDialogs["CLASS_MACROS_DELETE"] = {
    text = "Delete these macros?\n\n%s\n\nThey also go from your action bars.",
    button1 = DELETE,
    button2 = CANCEL,
    OnAccept = function(self, data) CloseThenRun(self, DeleteSets, data) end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
}

StaticPopupDialogs["CLASS_MACROS_SAVE_BARS"] = {
    text = "Save the action bars of this character as a profile.\n\nProfile name (a profile with the same name is replaced):",
    button1 = SAVE,
    button2 = CANCEL,
    hasEditBox = 1,
    OnShow = function(self, defaultName)
        local box = PopupEditBox(self)
        box:SetText(defaultName or "")
        box:HighlightText()
        box:SetFocus()
    end,
    OnAccept = function(self) CloseThenRun(self, SaveBars, PopupEditBox(self):GetText()) end,
    EditBoxOnEnterPressed = function(self) CloseThenRun(self:GetParent(), SaveBars, self:GetText()) end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["CLASS_MACROS_LOAD_BARS"] = {
    text = "Load the bar profile %s onto this character's action bars?\n\nSlots in the profile are replaced. Other slots stay as they are.",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function(self, profileName) CloseThenRun(self, LoadBars, profileName) end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
}

StaticPopupDialogs["CLASS_MACROS_DELETE_PROFILE"] = {
    text = "Delete the bar profile %s?\n\nYour action bars and macros do not change.",
    button1 = DELETE,
    button2 = CANCEL,
    OnAccept = function(self, profileName) CloseThenRun(self, DeleteProfile, profileName) end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

local function CreateButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function SectionIcon(section)
    if section.icon then
        return section.icon
    end
    local getTexture = (C_Spell and C_Spell.GetSpellTexture) or GetSpellTexture
    return (section.iconSpell and getTexture(section.iconSpell)) or 134400
end

local function MacroNames(section)
    local names = {}
    for _, macro in ipairs(section.macros) do
        tinsert(names, macro[1])
    end
    return table.concat(names, ", ")
end

local function CurrentSection(row)
    local set = ns.Macros.GetPlayerSet()
    return set and set.sections[row.key]
end

local LayoutRows

local function SetAllChecks(row, checked)
    local section = CurrentSection(row)
    selection[row.key] = {}
    if checked then
        for _, macro in ipairs(section.macros) do
            selection[row.key][macro[1]] = true
        end
    end
    Refresh()
end

local function CreateCheck(row)
    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetSize(22, 22)
    check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    check.label:SetPoint("LEFT", check, "RIGHT", 2, 0)
    check:SetScript("OnClick", function(self)
        selection[row.key] = selection[row.key] or {}
        selection[row.key][self.macroName] = self:GetChecked() or nil
    end)
    return check
end

local function CreateRow()
    local row = CreateFrame("Frame", nil, frame.listContent)
    row:SetSize(frame.listContent:GetWidth(), ROW_HEIGHT - 4)
    row.checks = {}

    row.expand = CreateButton(row, "+", 22, function()
        expanded[row.key] = not expanded[row.key] or nil
        LayoutRows()
    end)
    row.expand:SetPoint("TOPLEFT", 0, -8)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ROW_HEIGHT - 10, ROW_HEIGHT - 10)
    row.icon:SetPoint("TOPLEFT", row.expand, "TOPRIGHT", 4, 4)

    row.selectAll = CreateButton(row, "All", 50, function() SetAllChecks(row, true) end)
    row.selectNone = CreateButton(row, "None", 60, function() SetAllChecks(row, false) end)

    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 0)

    row.names = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.names:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
    row.names:SetWidth(row:GetWidth() - 2 * BUTTON_WIDTH - ROW_HEIGHT - 90)
    row.names:SetJustifyH("LEFT")

    row.delete = CreateButton(row, "Delete", BUTTON_WIDTH, function()
        local section = CurrentSection(row)
        if section then
            StaticPopup_Show("CLASS_MACROS_DELETE", section.title, nil,
                { keys = { row.key }, label = section.title })
        end
    end)
    row.delete:SetPoint("TOPRIGHT", 0, -8)

    row.make = CreateButton(row, "Make", BUTTON_WIDTH, function()
        local section = CurrentSection(row)
        if section then
            MakeSets({ row.key }, section.title)
        end
    end)
    row.make:SetPoint("RIGHT", row.delete, "LEFT", -4, 0)

    row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.count:SetPoint("RIGHT", row.make, "LEFT", -8, 0)

    return row
end

local function GearAreaHeight(set)
    if #(set.gearSlots or {}) == 0 then
        return 0
    end
    return 30 + #set.gearSlots * GEAR_LINE_HEIGHT
end

local function CreateGearLine()
    local line = CreateFrame("Frame", nil, frame)
    line:SetSize(frame:GetWidth() - 32, GEAR_LINE_HEIGHT)

    line.label = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    line.label:SetPoint("LEFT", 8, 0)

    line.itemButton = CreateFrame("Button", nil, line)
    line.itemButton:SetSize(GEAR_LINE_HEIGHT - 2, GEAR_LINE_HEIGHT - 2)
    line.itemButton:SetPoint("LEFT", 94, 0)
    line.itemButton.icon = line.itemButton:CreateTexture(nil, "ARTWORK")
    line.itemButton.icon:SetAllPoints()
    line.itemButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    line.itemButton:RegisterForClicks("LeftButtonUp")
    line.itemButton:SetScript("OnReceiveDrag", function() DropGearFromCursor(line.gearSlot) end)
    line.itemButton:SetScript("OnClick", function() DropGearFromCursor(line.gearSlot) end)
    line.itemButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Drag your " .. strlower(line.gearSlot.label) .. " here from your bags")
        GameTooltip:Show()
    end)
    line.itemButton:SetScript("OnLeave", GameTooltip_Hide)

    line.itemName = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line.itemName:SetPoint("LEFT", line.itemButton, "RIGHT", 8, 0)

    line.useEquipped = CreateButton(line, "Use equipped", 110, function() UseEquippedGear(line.gearSlot) end)
    line.useEquipped:SetPoint("RIGHT", 0, 0)

    return line
end

local function LayoutGear(set)
    local gearSlots = set.gearSlots or {}
    for index, gearSlot in ipairs(gearSlots) do
        local line = frame.gearLines[index] or CreateGearLine()
        frame.gearLines[index] = line
        line.gearSlot = gearSlot
        line:ClearAllPoints()
        line:SetPoint("BOTTOMLEFT", 16, GEAR_AREA_BOTTOM + (#gearSlots - index) * GEAR_LINE_HEIGHT)
        line.label:SetText(gearSlot.label .. ":")
        line:Show()
    end
    for index = #gearSlots + 1, #frame.gearLines do
        frame.gearLines[index]:Hide()
    end
    frame.gearTitle:ClearAllPoints()
    frame.gearTitle:SetPoint("BOTTOMLEFT", 16, GEAR_AREA_BOTTOM + #gearSlots * GEAR_LINE_HEIGHT + 6)
    frame.gearTitle:SetShown(#gearSlots > 0)
end

local function LayoutChecks(row, section)
    local checkWidth = (row:GetWidth() - 30) / CHECK_COLUMNS
    for index, macro in ipairs(section.macros) do
        local check = row.checks[index] or CreateCheck(row)
        row.checks[index] = check
        check.macroName = macro[1]
        local column = (index - 1) % CHECK_COLUMNS
        local line = math.floor((index - 1) / CHECK_COLUMNS)
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", 26 + column * checkWidth, -ROW_HEIGHT - line * CHECK_LINE_HEIGHT)
        check:Show()
    end
    for index = #section.macros + 1, #row.checks do
        row.checks[index]:Hide()
    end
    local lines = math.ceil(#section.macros / CHECK_COLUMNS)
    row.selectAll:ClearAllPoints()
    row.selectAll:SetPoint("TOPLEFT", 26, -ROW_HEIGHT - lines * CHECK_LINE_HEIGHT - 2)
    row.selectNone:ClearAllPoints()
    row.selectNone:SetPoint("LEFT", row.selectAll, "RIGHT", 4, 0)
    return ROW_HEIGHT + lines * CHECK_LINE_HEIGHT + 30
end

function LayoutRows()
    local set = ns.Macros.GetPlayerSet()
    local y = 0
    for index, key in ipairs(set.order) do
        local section = set.sections[key]
        local row = rows[index] or CreateRow()
        rows[index] = row
        row.key = key
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row.icon:SetTexture(SectionIcon(section))
        row.title:SetText(format("%d. %s  %s", index, section.title, TabLabel(section.tab)))
        row.names:SetText(MacroNames(section))
        row.expand:SetText(expanded[key] and "-" or "+")
        local height = ROW_HEIGHT
        if expanded[key] then
            height = LayoutChecks(row, section)
        else
            for _, check in ipairs(row.checks) do
                check:Hide()
            end
        end
        row.selectAll:SetShown(expanded[key] ~= nil)
        row.selectNone:SetShown(expanded[key] ~= nil)
        row:SetHeight(height - 4)
        row:Show()
        y = y + height
    end
    for index = #set.order + 1, #rows do
        rows[index]:Hide()
    end
    frame.listContent:SetHeight(math.max(y, 1))
    frame.emptyText:SetShown(#set.order == 0)
    LayoutGear(set)
    local listHeight = math.min(math.max(y, ROW_HEIGHT), MAX_LIST_HEIGHT)
    frame:SetHeight(-FIRST_ROW_Y + listHeight + 120 + GearAreaHeight(set))
    frame.listScroll:SetHeight(listHeight)
    Refresh()
end

local function CreateMainFrame(set, classDisplayName, classFile)
    frame = CreateFrame("Frame", "ClassMacrosFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 400)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    tinsert(UISpecialFrames, "ClassMacrosFrame")

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", 0, -6)
    frame.title:SetText("Class Macros - " .. classDisplayName)

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.hint:SetPoint("TOPLEFT", 16, -32)
    frame.hint:SetPoint("TOPRIGHT", -250, -32)
    frame.hint:SetJustifyH("LEFT")
    frame.hint:SetText("Macros show a question mark until you learn the spell. Set your gear below to fill in the weapon names.")

    local shareButton = CreateButton(frame, "Import / Export", 120, function() ns.Share.Open() end)
    shareButton:SetPoint("TOPRIGHT", -16, -30)

    local editButton = CreateButton(frame, "Edit sets", 100, function() ns.Editor.Open() end)
    editButton:SetPoint("RIGHT", shareButton, "LEFT", -6, 0)

    frame.listScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.listScroll:SetPoint("TOPLEFT", 16, FIRST_ROW_Y)
    frame.listScroll:SetPoint("RIGHT", frame, "RIGHT", -34, 0)
    frame.listContent = CreateFrame("Frame", nil, frame.listScroll)
    frame.listContent:SetSize(frame:GetWidth() - 50, 1)
    frame.listScroll:SetScrollChild(frame.listContent)

    frame.emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.emptyText:SetPoint("TOPLEFT", 24, FIRST_ROW_Y - 10)
    frame.emptyText:SetText("No macro sets yet. Click Edit sets to make one, or Import / Export to import one.")

    local makeAll = CreateButton(frame, "Make all", 100, function()
        MakeSets(ns.Macros.GetPlayerSet().order, "All sets")
    end)
    makeAll:SetPoint("BOTTOMLEFT", 16, 40)

    local deleteAll = CreateButton(frame, "Delete all", 100, function()
        StaticPopup_Show("CLASS_MACROS_DELETE", "All " .. classDisplayName .. " sets", nil,
            { keys = ns.Macros.GetPlayerSet().order, label = "All sets", includeRetired = true })
    end)
    deleteAll:SetPoint("LEFT", makeAll, "RIGHT", 6, 0)

    local makeSelected = CreateButton(frame, "Make selected", 120, MakeSelectedMacros)
    makeSelected:SetPoint("LEFT", deleteAll, "RIGHT", 6, 0)

    local loadBars = CreateButton(frame, "Load bars", 100, function()
        local name = ns.Bars.GetSelectedProfile(classFile)
        if not name then
            SetStatus("No saved bar profile. Click Save bars on a character with your layout first.")
            return
        end
        StaticPopup_Show("CLASS_MACROS_LOAD_BARS", name, nil, name)
    end)
    loadBars:SetPoint("BOTTOMRIGHT", -16, 40)

    local saveBars = CreateButton(frame, "Save bars", 100, function()
        local defaultName = ns.Bars.GetSelectedProfile(classFile) or UnitName("player")
        StaticPopup_Show("CLASS_MACROS_SAVE_BARS", nil, nil, defaultName)
    end)
    saveBars:SetPoint("RIGHT", loadBars, "LEFT", -6, 0)

    local deleteProfile = CreateButton(frame, "Delete profile", 110, function()
        local name = ns.Bars.GetSelectedProfile(classFile)
        if name then
            StaticPopup_Show("CLASS_MACROS_DELETE_PROFILE", name, nil, name)
        end
    end)
    deleteProfile:SetPoint("BOTTOMRIGHT", -16, 66)

    frame.profileDropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    frame.profileDropdown:SetWidth(180)
    frame.profileDropdown:SetPoint("RIGHT", deleteProfile, "LEFT", -10, 0)
    frame.profileDropdown:SetDefaultText("No profiles yet")
    frame.profileDropdown:SetupMenu(function(_, rootDescription)
        for _, name in ipairs(ns.Bars.ListProfiles(classFile)) do
            rootDescription:CreateRadio(name, function(value)
                return ns.Bars.GetSelectedProfile(classFile) == value
            end, function(value)
                ns.Bars.SelectProfile(classFile, value)
                Refresh()
            end, name)
        end
    end)

    local profileLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileLabel:SetPoint("RIGHT", frame.profileDropdown, "LEFT", -6, 0)
    profileLabel:SetText("Bar profile:")

    frame.layoutInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.layoutInfo:SetPoint("BOTTOMRIGHT", -18, 92)

    frame.gearTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.gearLines = {}

    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.status:SetPoint("BOTTOMLEFT", 18, 18)
    frame.status:SetPoint("BOTTOMRIGHT", -18, 18)
    frame.status:SetJustifyH("LEFT")

    frame:SetScript("OnShow", LayoutRows)
    frame:RegisterEvent("UPDATE_MACROS")
    frame:SetScript("OnEvent", Refresh)
end

local function ToggleMainFrame()
    local classDisplayName, classFile = UnitClass("player")
    if not ns.Macros.GetPlayerSet() then
        ns.Custom.GetEditable(classFile)
    end
    local set = ns.Macros.GetPlayerSet()
    if not frame then
        CreateMainFrame(set, classDisplayName, classFile)
    end
    frame:SetShown(not frame:IsShown())
end

ns.UI = {
    Refresh = function()
        if frame and frame:IsShown() then
            LayoutRows()
        end
    end,
    SetStatus = function(text)
        if frame then
            SetStatus(text)
        end
    end,
    CreateButton = CreateButton,
    ReplaceWindow = function(newWindow, oldWindow)
        oldWindow = oldWindow or frame
        if oldWindow and oldWindow:IsShown() and oldWindow ~= newWindow then
            local left, top = oldWindow:GetLeft(), oldWindow:GetTop()
            oldWindow.isBeingReplaced = true
            oldWindow:Hide()
            oldWindow.isBeingReplaced = nil
            newWindow.returnTo = oldWindow
            if left and top then
                newWindow:ClearAllPoints()
                newWindow:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
            end
        end
        newWindow:Show()
    end,
    AddBackAndCloseButtons = function(window)
        local back = CreateButton(window, "< Back", 70, function() window:Hide() end)
        back:SetHeight(18)
        back:SetPoint("TOPLEFT", 6, -2)
        window.backButton = back
        if window.CloseButton then
            window.CloseButton:SetScript("OnClick", function()
                window.returnTo = nil
                window:Hide()
            end)
        end
        window:HookScript("OnShow", function() back:SetShown(window.returnTo ~= nil) end)
    end,
    ReturnToPreviousWindow = function(window)
        if window.isBeingReplaced then
            return
        end
        local previous = window.returnTo
        window.returnTo = nil
        if previous then
            previous:Show()
        end
    end,
    CanChangeMacros = function()
        return not InCombatLockdown()
    end,
    PlayerClassFile = PlayerClassFile,
    SectionIcon = SectionIcon,
    TabLabel = TabLabel,
}

SLASH_CLASSMACROS1 = "/classmacros"
SlashCmdList.CLASSMACROS = function(argument)
    if strtrim(argument or "") == "slots" then
        ns.Bars.PrintSlots()
        return
    end
    ToggleMainFrame()
end

local welcomeFrame = CreateFrame("Frame")
welcomeFrame:RegisterEvent("PLAYER_LOGIN")
welcomeFrame:SetScript("OnEvent", function()
    print("|cff66ccffClass Macros|r by Crypto. Type |cffffcc00/classmacros|r to open it.")
end)
