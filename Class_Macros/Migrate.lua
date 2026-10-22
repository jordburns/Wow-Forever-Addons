local addonName = ...

local function CopyMissing(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            target[key] = value
        end
    end
end

local function MergeAccountData()
    local old = ClassMacrosV2DB
    if type(old) ~= "table" then
        return
    end
    ClassMacrosDB = ClassMacrosDB or {}
    for classFile, profiles in pairs(old.profiles or {}) do
        ClassMacrosDB.profiles = ClassMacrosDB.profiles or {}
        ClassMacrosDB.profiles[classFile] = ClassMacrosDB.profiles[classFile] or {}
        for name, profile in pairs(profiles) do
            ClassMacrosDB.profiles[classFile][name] = profile
        end
    end
    for _, field in ipairs({ "characterSets", "importedSets", "customSets", "selected" }) do
        if type(old[field]) == "table" then
            ClassMacrosDB[field] = ClassMacrosDB[field] or {}
            for key, value in pairs(old[field]) do
                ClassMacrosDB[field][key] = value
            end
        end
    end
    CopyMissing(ClassMacrosDB, old)
    ClassMacrosV2DB = nil
end

local function MergeCharacterData()
    local old = ClassMacrosV2CharacterDB
    if type(old) ~= "table" then
        return
    end
    ClassMacrosCharacterDB = ClassMacrosCharacterDB or {}
    for field, values in pairs(old) do
        if type(values) == "table" then
            ClassMacrosCharacterDB[field] = ClassMacrosCharacterDB[field] or {}
            for key, value in pairs(values) do
                ClassMacrosCharacterDB[field][key] = value
            end
        elseif ClassMacrosCharacterDB[field] == nil then
            ClassMacrosCharacterDB[field] = values
        end
    end
    ClassMacrosV2CharacterDB = nil
end

local migrationFrame = CreateFrame("Frame")
migrationFrame:RegisterEvent("ADDON_LOADED")
migrationFrame:SetScript("OnEvent", function(self, _, loadedName)
    if loadedName ~= addonName then
        return
    end
    MergeAccountData()
    MergeCharacterData()
    self:UnregisterEvent("ADDON_LOADED")
end)
