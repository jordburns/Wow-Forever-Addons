local _, ns = ...

local Editor = {}
ns.Editor = Editor

local SET_BUTTON_HEIGHT = 22
local MAX_SET_BUTTONS = 14
local MACRO_BUTTON_COLUMNS = 3
local MAX_MACRO_BUTTONS = 18

local MAX_GEAR_BUTTONS = 6
local SETS_MODE = "sets"
local GEAR_MODE = "gear"

local frame
local mode = SETS_MODE
local selectedKey
local selectedMacro
local selectedGearSlot
local gearButtons = {}
local setButtons = {}
local macroButtons = {}

local function SetStatus(text)
    frame.status:SetText(text)
end

local function ClassFile()
    return ns.UI.PlayerClassFile()
end

local function ViewSets()
    return ns.Macros.GetPlayerSet()
end

local function EditableSets()
    return ns.Custom.GetEditable(ClassFile())
end

local function SelectedSection()
    return selectedKey and ViewSets().sections[selectedKey]
end

local function EditableSection()
    return selectedKey and EditableSets().sections[selectedKey]
end

local function AfterChange(text)
    SetStatus(text)
    ns.UI.Refresh()
    Editor.Refresh()
end

local function CreateEditBox(parent, width)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width, 22)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", box.ClearFocus)
    box:SetScript("OnEnterPressed", box.ClearFocus)
    return box
end

local function NameTakenInTab(name, tab, ignoreSection, ignoreIndex)
    local sets = ViewSets()
    for _, key in ipairs(sets.order) do
        local section = sets.sections[key]
        if section.tab == tab then
            for index, macro in ipairs(section.macros) do
                if macro[1] == name and not (section == ignoreSection and index == ignoreIndex) then
                    return true
                end
            end
        end
    end
    return false
end

local function UpdateBodyCounter()
    local length = #frame.macroBody:GetText()
    local color = length > ns.Custom.MAX_BODY_LENGTH and "|cffff4444" or "|cffffffff"
    frame.bodyCounter:SetText(format("%s%d/%d|r", color, length, ns.Custom.MAX_BODY_LENGTH))
end

local function ShowMacro(macro)
    frame.macroName:SetText(macro and macro[1] or "")
    frame.macroBody:SetText(macro and macro[2] or "#showtooltip\n/cast ")
    frame.macroTitle:SetText(macro and "Change macro" or "New macro")
    UpdateBodyCounter()
end

local function SelectMacro(index)
    selectedMacro = index
    local section = SelectedSection()
    ShowMacro(section and index and section.macros[index])
    Editor.Refresh()
end

local function SelectSet(key)
    mode = SETS_MODE
    selectedKey = key
    selectedMacro = nil
    local section = SelectedSection()
    frame.setName:SetText(section and section.title or "")
    frame.setTab = section and section.tab or ns.CHARACTER
    ShowMacro(nil)
    Editor.Refresh()
end

local function NewSet()
    local sets = EditableSets()
    local key = ns.Custom.NewSectionKey(sets)
    sets.sections[key] = { title = "New set", tab = ns.CHARACTER, icon = 134400, macros = {} }
    tinsert(sets.order, key)
    SelectSet(key)
    AfterChange("Added a new set. Give it a name, then add macros.")
end

local function DeleteSet()
    local sets = EditableSets()
    local section = sets.sections[selectedKey]
    for index, key in ipairs(sets.order) do
        if key == selectedKey then
            tremove(sets.order, index)
        end
    end
    sets.sections[selectedKey] = nil
    SelectSet(sets.order[1])
    AfterChange("Deleted the set " .. section.title .. ". Its macros stay in /macro until you delete them there.")
end

local function MoveSet(step)
    local order = EditableSets().order
    for index, key in ipairs(order) do
        if key == selectedKey then
            local target = index + step
            if target >= 1 and target <= #order then
                order[index], order[target] = order[target], order[index]
                AfterChange("Moved the set.")
            end
            return
        end
    end
end

local function TextureFromCursor()
    local cursorType, first, _, spellId = GetCursorInfo()
    if cursorType == "spell" then
        local getTexture = (C_Spell and C_Spell.GetSpellTexture) or GetSpellTexture
        return getTexture(spellId or first)
    elseif cursorType == "item" then
        return (C_Item and C_Item.GetItemIconByID or GetItemIcon)(first)
    elseif cursorType == "macro" then
        return select(2, GetMacroInfo(first))
    end
end

local function DropIconFromCursor()
    local texture = TextureFromCursor()
    if not texture then
        return
    end
    ClearCursor()
    local section = EditableSection()
    section.icon = texture
    section.iconSpell = nil
    AfterChange("Changed the icon of " .. section.title .. ".")
end

local ICON_COLUMNS = 10
local ICON_ROWS = 7
local ICON_SIZE = 36
local ICONS_PER_PAGE = ICON_COLUMNS * ICON_ROWS

local iconPicker
local allIcons

local function IconTexture(icon)
    if type(icon) == "string" and not icon:find("\\", 1, true) then
        return "Interface\\Icons\\" .. icon
    end
    return icon
end

local function LoadAllIcons()
    allIcons = {}
    for _, collect in ipairs({ GetLooseMacroIcons, GetLooseMacroItemIcons, GetMacroIcons, GetMacroItemIcons }) do
        local result = collect and collect(allIcons)
        if type(result) == "table" and result ~= allIcons then
            for _, icon in ipairs(result) do
                tinsert(allIcons, icon)
            end
        end
    end
end

local function AddNamedIcon(results, seen, search, name, icon)
    if icon and name and not seen[icon] and strlower(name):find(search, 1, true) then
        seen[icon] = true
        tinsert(results, icon)
    end
end

local function SearchSpellbook(results, seen, search)
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
        for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(line)
            for index = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                local itemInfo = C_SpellBook.GetSpellBookItemInfo(index, bank)
                if itemInfo then
                    AddNamedIcon(results, seen, search, itemInfo.name, itemInfo.iconID)
                end
            end
        end
    elseif GetNumSpellTabs then
        for tab = 1, GetNumSpellTabs() do
            local _, _, offset, count = GetSpellTabInfo(tab)
            for index = offset + 1, offset + count do
                AddNamedIcon(results, seen, search, GetSpellBookItemName(index, "spell"), GetSpellBookItemTexture(index, "spell"))
            end
        end
    end
end

local function SearchItems(results, seen, search)
    local getItemName = (C_Item and C_Item.GetItemNameByID) or GetItemInfo
    local getItemIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    for slot = 1, 19 do
        local itemId = GetInventoryItemID("player", slot)
        if itemId then
            AddNamedIcon(results, seen, search, getItemName(itemId), getItemIcon(itemId))
        end
    end
    if C_Container then
        for bag = 0, NUM_BAG_SLOTS or 4 do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local itemId = C_Container.GetContainerItemID(bag, slot)
                if itemId then
                    AddNamedIcon(results, seen, search, getItemName(itemId), getItemIcon(itemId))
                end
            end
        end
    end
end

local function SearchMacros(results, seen, search)
    local generalCount, characterCount = GetNumMacros()
    local accountSlots = ns.Macros.AccountSlots()
    for index = 1, accountSlots + characterCount do
        if index <= generalCount or index > accountSlots then
            local name, icon = GetMacroInfo(index)
            AddNamedIcon(results, seen, search, name, icon)
        end
    end
end

local function SearchIcons(text)
    local search = strlower(strtrim(text or ""))
    if search == "" then
        return allIcons
    end
    if tonumber(search) then
        return { tonumber(search) }
    end
    local results, seen = {}, {}
    for _, source in ipairs({ SearchSpellbook, SearchItems, SearchMacros }) do
        pcall(source, results, seen, search)
    end
    return results
end

local function ShowIconPage()
    local icons = iconPicker.icons or allIcons
    local pageCount = math.max(1, math.ceil(#icons / ICONS_PER_PAGE))
    iconPicker.page = math.min(math.max(iconPicker.page, 1), pageCount)
    local first = (iconPicker.page - 1) * ICONS_PER_PAGE
    for index, button in ipairs(iconPicker.buttons) do
        local icon = icons[first + index]
        button.iconValue = icon and IconTexture(icon)
        button.icon:SetTexture(button.iconValue)
        button:SetShown(icon ~= nil)
    end
    iconPicker.pageText:SetText(format("Page %d of %d (%d icons)", iconPicker.page, pageCount, #icons))
end

local function ChooseIcon(texture)
    iconPicker:Hide()
    local section = EditableSection()
    section.icon = texture
    section.iconSpell = nil
    AfterChange("Changed the icon of " .. section.title .. ".")
end

local function CreateIconPicker()
    iconPicker = CreateFrame("Frame", "ClassMacrosIconPicker", frame, "BasicFrameTemplateWithInset")
    iconPicker:SetSize(ICON_COLUMNS * (ICON_SIZE + 2) + 36, ICON_ROWS * (ICON_SIZE + 2) + 144)
    iconPicker:SetPoint("TOPLEFT", frame, "TOPRIGHT", 4, 0)
    iconPicker:SetFrameStrata("FULLSCREEN_DIALOG")
    iconPicker:SetClampedToScreen(true)
    iconPicker:EnableMouse(true)
    tinsert(UISpecialFrames, "ClassMacrosIconPicker")

    local title = iconPicker:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -6)
    title:SetText("Choose an icon")

    local searchLabel = iconPicker:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    searchLabel:SetPoint("TOPLEFT", 20, -32)
    searchLabel:SetText("Search")
    iconPicker.search = CreateEditBox(iconPicker, 200)
    iconPicker.search:SetPoint("LEFT", searchLabel, "RIGHT", 12, 0)
    iconPicker.search:SetScript("OnTextChanged", function(self)
        iconPicker.icons = SearchIcons(self:GetText())
        iconPicker.page = 1
        ShowIconPage()
    end)
    local searchHelp = iconPicker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    searchHelp:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -8)
    searchHelp:SetPoint("RIGHT", iconPicker, "RIGHT", -16, 0)
    searchHelp:SetJustifyH("LEFT")
    searchHelp:SetText("Finds your spells, items and macros by name, or an icon by its number.")

    iconPicker.buttons = {}
    for index = 1, ICONS_PER_PAGE do
        local column = (index - 1) % ICON_COLUMNS
        local line = math.floor((index - 1) / ICON_COLUMNS)
        local button = CreateFrame("Button", nil, iconPicker)
        button:SetSize(ICON_SIZE, ICON_SIZE)
        button:SetPoint("TOPLEFT", 18 + column * (ICON_SIZE + 2), -80 - line * (ICON_SIZE + 2))
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints()
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        button:SetScript("OnClick", function(self) ChooseIcon(self.iconValue) end)
        iconPicker.buttons[index] = button
    end

    local previous = ns.UI.CreateButton(iconPicker, "< Previous", 100, function()
        iconPicker.page = iconPicker.page - 1
        ShowIconPage()
    end)
    previous:SetPoint("BOTTOMLEFT", 16, 16)

    local nextPage = ns.UI.CreateButton(iconPicker, "Next >", 100, function()
        iconPicker.page = iconPicker.page + 1
        ShowIconPage()
    end)
    nextPage:SetPoint("BOTTOMRIGHT", -16, 16)

    iconPicker.pageText = iconPicker:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    iconPicker.pageText:SetPoint("BOTTOM", 0, 20)

    iconPicker:EnableMouseWheel(true)
    iconPicker:SetScript("OnMouseWheel", function(_, delta)
        iconPicker.page = iconPicker.page - delta
        ShowIconPage()
    end)
end

local function OpenIconPicker()
    if not allIcons then
        LoadAllIcons()
    end
    if not iconPicker then
        CreateIconPicker()
        iconPicker.page = 1
    end
    iconPicker:Show()
    ShowIconPage()
end

local function SaveSet()
    local title = strtrim(frame.setName:GetText())
    if title == "" then
        SetStatus("|cffff4444The set needs a name.|r")
        return
    end
    local section = EditableSection()
    if section.tab ~= frame.setTab then
        local replaces = {}
        for _, macro in ipairs(section.macros) do
            tinsert(replaces, { macro[1], section.tab })
        end
        section.replaces = replaces
    end
    section.title = title
    section.tab = frame.setTab
    AfterChange("Saved the set " .. title .. ". If you changed its tab, click Make for it in the main window.")
end

local function SaveMacro()
    if not ns.UI.CanChangeMacros() then
        SetStatus("|cffff4444You cannot change macros in combat.|r")
        return
    end
    local name = strtrim(frame.macroName:GetText())
    local body = frame.macroBody:GetText()
    local ok, problem = ns.Custom.ValidateMacro(name, body)
    if not ok then
        SetStatus("|cffff4444Not saved: " .. problem .. ".|r")
        return
    end
    local section = EditableSection()
    if NameTakenInTab(name, section.tab, SelectedSection(), selectedMacro) then
        SetStatus("|cffff4444Not saved: another set already has a macro called " .. name .. " in the same tab.|r")
        return
    end
    if selectedMacro then
        local oldName = section.macros[selectedMacro][1]
        section.macros[selectedMacro] = { name, body }
        local updated = ns.Macros.UpdateInGame(oldName, section.tab, name, body)
        AfterChange(updated and ("Saved " .. name .. " and updated it in /macro.")
            or ("Saved " .. name .. ". Click Make for this set in the main window to create it."))
    else
        tinsert(section.macros, { name, body })
        selectedMacro = #section.macros
        AfterChange("Added " .. name .. ". Click Make for this set in the main window to create it.")
    end
end

local function DeleteMacro()
    local section = EditableSection()
    local macro = section.macros[selectedMacro]
    tremove(section.macros, selectedMacro)
    local deleted = ns.UI.CanChangeMacros() and ns.Macros.DeleteInGame(macro[1], section.tab)
    selectedMacro = nil
    ShowMacro(nil)
    AfterChange("Removed " .. macro[1] .. " from the set" .. (deleted and " and deleted it from /macro." or "."))
end

local function ResetClass()
    ns.Custom.ResetClass(ClassFile())
    SelectSet(ViewSets().order[1])
    AfterChange("All sets are back to the built-in sets. Click Make all in the main window to update /macro.")
end

local function GearSlots()
    return ViewSets().gearSlots or {}
end

local function ShowGearSlot(gearSlot)
    frame.gearLabel:SetText(gearSlot and gearSlot.label or "")
    frame.gearWord:SetText(gearSlot and gearSlot.key:match("^<(%w+)>$") or "")
    frame.gearInventorySlot = gearSlot and gearSlot.inventorySlot or 16
    frame.gearTitle:SetText(gearSlot and "Change gear slot" or "New gear slot")
end

local function SelectGearSlot(index)
    mode = GEAR_MODE
    selectedGearSlot = index
    ShowGearSlot(index and GearSlots()[index])
    Editor.Refresh()
end

local function CycleEquipmentSlot()
    local slots = ns.Custom.EQUIPMENT_SLOTS
    local position = 1
    for index, equipmentSlot in ipairs(slots) do
        if equipmentSlot.id == frame.gearInventorySlot then
            position = index
        end
    end
    frame.gearInventorySlot = slots[position % #slots + 1].id
    Editor.Refresh()
end

local function SaveGearSlot()
    local gearSlots = ns.Custom.GetEditableGearSlots(ClassFile())
    local label = strtrim(frame.gearLabel:GetText())
    local word = strtrim(frame.gearWord:GetText())
    local ok, problem = ns.Custom.ValidateGearSlot(gearSlots, label, word, selectedGearSlot)
    if not ok then
        SetStatus("|cffff4444Not saved: " .. problem .. ".|r")
        return
    end
    local key = ns.Custom.PlaceholderKey(word)
    local gearSlot = { key = key, label = label, inventorySlot = frame.gearInventorySlot, default = "MY_" .. strupper(word) }
    local message = format("Saved the gear slot %s. Use %s in a macro text.", label, key)
    if selectedGearSlot then
        local oldKey = gearSlots[selectedGearSlot].key
        if oldKey ~= key then
            local changed = ns.Custom.RenamePlaceholder(ClassFile(), oldKey, key)
            ns.Macros.MoveGearSettings(oldKey, key)
            message = message .. format(" %d macros now use %s instead of %s. Click Make all to update /macro.", changed, key, oldKey)
        end
        gearSlots[selectedGearSlot] = gearSlot
    else
        tinsert(gearSlots, gearSlot)
        selectedGearSlot = #gearSlots
    end
    AfterChange(message)
end

local function DeleteGearSlot()
    local gearSlots = ns.Custom.GetEditableGearSlots(ClassFile())
    local gearSlot = tremove(gearSlots, selectedGearSlot)
    selectedGearSlot = nil
    ShowGearSlot(nil)
    AfterChange(format("Deleted the gear slot %s. Macros that use %s keep it as plain text.", gearSlot.label, gearSlot.key))
end

local function Confirm(text, action)
    StaticPopupDialogs["CLASS_MACROS_EDITOR_CONFIRM"].text = text
    StaticPopup_Show("CLASS_MACROS_EDITOR_CONFIRM", nil, nil, action)
end

StaticPopupDialogs["CLASS_MACROS_EDITOR_CONFIRM"] = {
    text = "",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function(self, action)
        self:Hide()
        C_Timer.After(0, action)
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
}

function Editor.Refresh()
    if not (frame and frame:IsShown()) then
        return
    end
    local sets = ViewSets()
    if selectedKey and not sets.sections[selectedKey] then
        selectedKey = nil
    end
    for index, button in ipairs(setButtons) do
        local key = sets.order[index]
        local section = key and sets.sections[key]
        if section then
            local marker = (mode == SETS_MODE and key == selectedKey) and "|cff44ff44> |r" or ""
            button:SetText(marker .. section.title)
            button.key = key
            button:Show()
        else
            button:Hide()
        end
    end
    frame.gearModeButton:SetText(mode == GEAR_MODE and "|cff44ff44> |rGear slots" or "Gear slots")
    frame.gearArea:SetShown(mode == GEAR_MODE)
    if mode == GEAR_MODE then
        frame.setArea:Hide()
        local gearSlots = GearSlots()
        for index, button in ipairs(gearButtons) do
            local gearSlot = gearSlots[index]
            if gearSlot then
                local marker = index == selectedGearSlot and "|cff44ff44> |r" or ""
                button:SetText(format("%s%s  %s", marker, gearSlot.label, gearSlot.key))
                button:Show()
            else
                button:Hide()
            end
        end
        frame.equipmentSlotButton:SetText(ns.Custom.EquipmentSlotLabel(frame.gearInventorySlot))
        frame.deleteGearSlot:SetEnabled(selectedGearSlot ~= nil)
        return
    end
    local section = SelectedSection()
    frame.setArea:SetShown(section ~= nil)
    if not section then
        return
    end
    frame.tabButton:SetText(frame.setTab == ns.CHARACTER and "Character tab" or "General tab")
    frame.iconButton.icon:SetTexture(ns.UI.SectionIcon(section))
    for index, button in ipairs(macroButtons) do
        local macro = section.macros[index]
        if macro then
            local marker = index == selectedMacro and "|cff44ff44> |r" or ""
            button:SetText(marker .. macro[1])
            button:Show()
        else
            button:Hide()
        end
    end
    frame.macroCount:SetText(format("%d macros", #section.macros))
    frame.deleteMacro:SetEnabled(selectedMacro ~= nil)
    frame.resetClass:SetEnabled(ns.Custom.HasBuiltIn(ClassFile()) and ns.Custom.IsCustomized(ClassFile()))
end

local function CreateEditorFrame()
    frame = CreateFrame("Frame", "ClassMacrosEditorFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(760, 540)
    frame:SetPoint("CENTER", 20, -20)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    tinsert(UISpecialFrames, "ClassMacrosEditorFrame")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -6)
    title:SetText("Class Macros - Edit sets")

    local setsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    setsLabel:SetPoint("TOPLEFT", 18, -34)
    setsLabel:SetText("Sets")

    for index = 1, MAX_SET_BUTTONS do
        local button = ns.UI.CreateButton(frame, "", 190, function(self) SelectSet(self.key) end)
        button:SetPoint("TOPLEFT", 16, -52 - (index - 1) * SET_BUTTON_HEIGHT)
        setButtons[index] = button
    end

    local newSet = ns.UI.CreateButton(frame, "New set", 92, NewSet)
    newSet:SetPoint("TOPLEFT", 16, -52 - MAX_SET_BUTTONS * SET_BUTTON_HEIGHT - 8)

    frame.resetClass = ns.UI.CreateButton(frame, "Reset to built-in", 190, function()
        Confirm("Reset all sets of this class to the built-in sets?\n\nYour own sets and changes are lost.", ResetClass)
    end)
    frame.resetClass:SetPoint("TOPLEFT", newSet, "BOTTOMLEFT", 0, -4)

    frame.gearModeButton = ns.UI.CreateButton(frame, "Gear slots", 190, function() SelectGearSlot(nil) end)
    frame.gearModeButton:SetPoint("TOPLEFT", frame.resetClass, "BOTTOMLEFT", 0, -12)

    frame.copyFrom = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    frame.copyFrom:SetWidth(190)
    frame.copyFrom:SetPoint("TOPLEFT", frame.gearModeButton, "BOTTOMLEFT", 0, -12)
    frame.copyFrom:SetDefaultText("Copy sets from...")
    frame.copyFrom:SetupMenu(function(_, rootDescription)
        local sources = ns.Custom.ListCopySources(ClassFile())
        if #sources == 0 then
            rootDescription:CreateTitle("No other characters of this class yet")
        end
        for _, source in ipairs(sources) do
            rootDescription:CreateButton(source.label, function()
                Confirm("Replace the sets of this character with the sets from " .. source.label .. "?\n\nMacros in /macro change when you click Make.", function()
                    ns.Custom.CopyFrom(ClassFile(), source.sets)
                    SelectSet(ViewSets().order[1])
                    AfterChange("Copied the sets from " .. source.label .. ". Click Make all in the main window to update /macro.")
                end)
            end)
        end
    end)

    frame.gearArea = CreateFrame("Frame", nil, frame)
    frame.gearArea:SetPoint("TOPLEFT", 222, -30)
    frame.gearArea:SetPoint("BOTTOMRIGHT", -16, 40)
    frame.gearArea:Hide()
    local gearArea = frame.gearArea

    local gearHeading = gearArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gearHeading:SetPoint("TOPLEFT", 0, -4)
    gearHeading:SetText("Gear slots for this class")

    local gearHelp = gearArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    gearHelp:SetPoint("TOPLEFT", gearHeading, "BOTTOMLEFT", 0, -6)
    gearHelp:SetPoint("RIGHT", gearArea, "RIGHT", 0, 0)
    gearHelp:SetJustifyH("LEFT")
    gearHelp:SetText("Each gear slot gets a line in the Gear area of the main window, with a drag slot and Use equipped. Write its placeholder in a macro text, for example /equipslot 16 <MH>. The addon puts in this character's item name.")

    for index = 1, MAX_GEAR_BUTTONS do
        local button = ns.UI.CreateButton(gearArea, "", 260, function() SelectGearSlot(index) end)
        button:SetPoint("TOPLEFT", 0, -60 - (index - 1) * SET_BUTTON_HEIGHT)
        gearButtons[index] = button
    end

    local newGearSlot = ns.UI.CreateButton(gearArea, "New gear slot", 120, function() SelectGearSlot(nil) end)
    newGearSlot:SetPoint("TOPLEFT", 0, -60 - MAX_GEAR_BUTTONS * SET_BUTTON_HEIGHT - 6)

    frame.gearTitle = gearArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.gearTitle:SetPoint("TOPLEFT", newGearSlot, "BOTTOMLEFT", 0, -14)

    local gearLabelText = gearArea:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    gearLabelText:SetPoint("TOPLEFT", frame.gearTitle, "BOTTOMLEFT", 0, -12)
    gearLabelText:SetText("Name")
    frame.gearLabel = CreateEditBox(gearArea, 180)
    frame.gearLabel:SetPoint("LEFT", gearLabelText, "RIGHT", 52, 0)

    local gearWordText = gearArea:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    gearWordText:SetPoint("TOPLEFT", gearLabelText, "BOTTOMLEFT", 0, -16)
    gearWordText:SetText("Placeholder  <")
    frame.gearWord = CreateEditBox(gearArea, 110)
    frame.gearWord:SetPoint("LEFT", gearWordText, "RIGHT", 8, 0)
    local gearWordEnd = gearArea:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    gearWordEnd:SetPoint("LEFT", frame.gearWord, "RIGHT", 4, 0)
    gearWordEnd:SetText(">")

    local equipmentText = gearArea:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    equipmentText:SetPoint("TOPLEFT", gearWordText, "BOTTOMLEFT", 0, -16)
    equipmentText:SetText("Use equipped takes the item from")
    frame.equipmentSlotButton = ns.UI.CreateButton(gearArea, "", 120, CycleEquipmentSlot)
    frame.equipmentSlotButton:SetPoint("LEFT", equipmentText, "RIGHT", 8, 0)

    local saveGearSlot = ns.UI.CreateButton(gearArea, "Save gear slot", 120, SaveGearSlot)
    saveGearSlot:SetPoint("TOPLEFT", equipmentText, "BOTTOMLEFT", 0, -16)

    frame.deleteGearSlot = ns.UI.CreateButton(gearArea, "Delete gear slot", 130, function()
        Confirm("Delete this gear slot?\n\nMacros that use its placeholder keep it as plain text.", DeleteGearSlot)
    end)
    frame.deleteGearSlot:SetPoint("LEFT", saveGearSlot, "RIGHT", 6, 0)

    frame.setArea = CreateFrame("Frame", nil, frame)
    frame.setArea:SetPoint("TOPLEFT", 222, -30)
    frame.setArea:SetPoint("BOTTOMRIGHT", -16, 40)
    local area = frame.setArea

    frame.iconButton = CreateFrame("Button", nil, area)
    frame.iconButton:SetSize(26, 26)
    frame.iconButton:SetPoint("TOPLEFT", 0, 2)
    frame.iconButton.icon = frame.iconButton:CreateTexture(nil, "ARTWORK")
    frame.iconButton.icon:SetAllPoints()
    frame.iconButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    frame.iconButton:RegisterForClicks("LeftButtonUp")
    frame.iconButton:SetScript("OnReceiveDrag", DropIconFromCursor)
    frame.iconButton:SetScript("OnClick", function()
        if GetCursorInfo() then
            DropIconFromCursor()
        else
            OpenIconPicker()
        end
    end)
    frame.iconButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Set icon")
        GameTooltip:AddLine("Click to choose from all macro icons. Or drag a spell from your spellbook, an item from your bags or a macro from /macro here.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.iconButton:SetScript("OnLeave", GameTooltip_Hide)

    local nameLabel = area:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", frame.iconButton, "RIGHT", 8, 0)
    nameLabel:SetText("Set name")
    frame.setName = CreateEditBox(area, 190)
    frame.setName:SetPoint("LEFT", nameLabel, "RIGHT", 12, 0)

    frame.tabButton = ns.UI.CreateButton(area, "", 110, function()
        frame.setTab = frame.setTab == ns.CHARACTER and ns.GENERAL or ns.CHARACTER
        Editor.Refresh()
    end)
    frame.tabButton:SetPoint("LEFT", frame.setName, "RIGHT", 8, 0)

    local saveSet = ns.UI.CreateButton(area, "Save set", 80, SaveSet)
    saveSet:SetPoint("LEFT", frame.tabButton, "RIGHT", 6, 0)

    local moveUp = ns.UI.CreateButton(area, "Move up", 80, function() MoveSet(-1) end)
    moveUp:SetPoint("TOPLEFT", 0, -32)
    local moveDown = ns.UI.CreateButton(area, "Move down", 90, function() MoveSet(1) end)
    moveDown:SetPoint("LEFT", moveUp, "RIGHT", 4, 0)
    local exportSet = ns.UI.CreateButton(area, "Export set", 90, function() ns.Share.ExportSet(selectedKey, frame) end)
    exportSet:SetPoint("LEFT", moveDown, "RIGHT", 4, 0)
    local deleteSet = ns.UI.CreateButton(area, "Delete set", 90, function()
        Confirm("Delete this set from the list?\n\nIts macros stay in /macro until you delete them there.", DeleteSet)
    end)
    deleteSet:SetPoint("LEFT", exportSet, "RIGHT", 4, 0)

    local macrosLabel = area:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    macrosLabel:SetPoint("TOPLEFT", 0, -66)
    macrosLabel:SetText("Macros in this set")
    frame.macroCount = area:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.macroCount:SetPoint("LEFT", macrosLabel, "RIGHT", 8, 0)

    for index = 1, MAX_MACRO_BUTTONS do
        local column = (index - 1) % MACRO_BUTTON_COLUMNS
        local line = math.floor((index - 1) / MACRO_BUTTON_COLUMNS)
        local button = ns.UI.CreateButton(area, "", 165, function() SelectMacro(index) end)
        button:SetPoint("TOPLEFT", column * 170, -84 - line * SET_BUTTON_HEIGHT)
        macroButtons[index] = button
    end

    local newMacro = ns.UI.CreateButton(area, "New macro", 100, function() SelectMacro(nil) end)
    newMacro:SetPoint("TOPLEFT", 0, -84 - (MAX_MACRO_BUTTONS / MACRO_BUTTON_COLUMNS) * SET_BUTTON_HEIGHT - 6)

    frame.macroTitle = area:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.macroTitle:SetPoint("TOPLEFT", newMacro, "BOTTOMLEFT", 0, -12)

    local macroNameLabel = area:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    macroNameLabel:SetPoint("TOPLEFT", frame.macroTitle, "BOTTOMLEFT", 0, -10)
    macroNameLabel:SetText("Name")
    frame.macroName = CreateEditBox(area, 160)
    frame.macroName:SetMaxLetters(ns.Custom.MAX_NAME_LENGTH)
    frame.macroName:SetPoint("LEFT", macroNameLabel, "RIGHT", 12, 0)

    local bodyLabel = area:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bodyLabel:SetPoint("TOPLEFT", macroNameLabel, "BOTTOMLEFT", 0, -14)
    bodyLabel:SetText("Macro text")
    frame.bodyCounter = area:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.bodyCounter:SetPoint("LEFT", bodyLabel, "RIGHT", 8, 0)

    local bodyBackground = CreateFrame("Frame", nil, area)
    bodyBackground:SetPoint("TOPLEFT", bodyLabel, "BOTTOMLEFT", 0, -4)
    bodyBackground:SetSize(500, 96)
    local backgroundTexture = bodyBackground:CreateTexture(nil, "BACKGROUND")
    backgroundTexture:SetAllPoints()
    backgroundTexture:SetColorTexture(0, 0, 0, 0.5)

    frame.macroBody = CreateFrame("EditBox", nil, bodyBackground)
    frame.macroBody:SetPoint("TOPLEFT", 6, -4)
    frame.macroBody:SetPoint("BOTTOMRIGHT", -6, 4)
    frame.macroBody:SetMultiLine(true)
    frame.macroBody:SetAutoFocus(false)
    frame.macroBody:SetFontObject(ChatFontNormal)
    frame.macroBody:SetScript("OnEscapePressed", frame.macroBody.ClearFocus)
    frame.macroBody:SetScript("OnTextChanged", UpdateBodyCounter)
    bodyBackground:EnableMouse(true)
    bodyBackground:SetScript("OnMouseDown", function() frame.macroBody:SetFocus() end)

    local saveMacro = ns.UI.CreateButton(area, "Save macro", 100, SaveMacro)
    saveMacro:SetPoint("TOPLEFT", bodyBackground, "BOTTOMLEFT", 0, -6)

    frame.deleteMacro = ns.UI.CreateButton(area, "Delete macro", 110, function()
        Confirm("Remove this macro from the set and delete it from /macro?", DeleteMacro)
    end)
    frame.deleteMacro:SetPoint("LEFT", saveMacro, "RIGHT", 6, 0)

    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.status:SetPoint("BOTTOMLEFT", 18, 16)
    frame.status:SetPoint("BOTTOMRIGHT", -18, 16)
    frame.status:SetJustifyH("LEFT")

    frame:SetScript("OnShow", Editor.Refresh)
    frame:SetScript("OnHide", ns.UI.ReturnToPreviousWindow)
    ns.UI.AddBackAndCloseButtons(frame)
end

function Editor.Open()
    if not frame then
        CreateEditorFrame()
    end
    ns.UI.ReplaceWindow(frame)
    if not selectedKey then
        SelectSet(ViewSets().order[1])
    end
    Editor.Refresh()
end
