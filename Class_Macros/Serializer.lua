local _, ns = ...

local Serializer = {}
ns.Serializer = Serializer

local PREFIX = "CM2!"
local BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Encode(value, out)
    local valueType = type(value)
    if valueType == "string" then
        tinsert(out, "s" .. #value .. ":" .. value)
    elseif valueType == "number" then
        tinsert(out, "n" .. tostring(value) .. ";")
    elseif valueType == "boolean" then
        tinsert(out, value and "T" or "F")
    elseif valueType == "table" then
        tinsert(out, "t")
        for key, item in pairs(value) do
            Encode(key, out)
            Encode(item, out)
        end
        tinsert(out, "e")
    end
end

local function Decode(text, position, depth)
    if depth > 20 then
        error("data is nested too deeply")
    end
    local tag = text:sub(position, position)
    if tag == "s" then
        local colon = text:find(":", position, true)
        local length = colon and tonumber(text:sub(position + 1, colon - 1))
        if not length then
            error("broken text value")
        end
        return text:sub(colon + 1, colon + length), colon + length + 1
    elseif tag == "n" then
        local semicolon = text:find(";", position, true)
        local number = semicolon and tonumber(text:sub(position + 1, semicolon - 1))
        if not number then
            error("broken number value")
        end
        return number, semicolon + 1
    elseif tag == "T" or tag == "F" then
        return tag == "T", position + 1
    elseif tag == "t" then
        local result = {}
        position = position + 1
        while text:sub(position, position) ~= "e" do
            if position > #text then
                error("data ends too early")
            end
            local key, item
            key, position = Decode(text, position, depth + 1)
            item, position = Decode(text, position, depth + 1)
            result[key] = item
        end
        return result, position + 1
    end
    error("unknown data")
end

local function ToBase64(data)
    return ((data:gsub(".", function(character)
        local byte, bits = character:byte(), ""
        for bit = 8, 1, -1 do
            bits = bits .. (byte % 2 ^ bit - byte % 2 ^ (bit - 1) > 0 and "1" or "0")
        end
        return bits
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(bits)
        if #bits < 6 then
            return ""
        end
        local index = 0
        for bit = 1, 6 do
            index = index + (bits:sub(bit, bit) == "1" and 2 ^ (6 - bit) or 0)
        end
        return BASE64:sub(index + 1, index + 1)
    end) .. ({ "", "==", "=" })[#data % 3 + 1])
end

local function FromBase64(data)
    data = data:gsub("[^" .. BASE64 .. "=]", "")
    return (data:gsub(".", function(character)
        if character == "=" then
            return ""
        end
        local index, bits = BASE64:find(character, 1, true) - 1, ""
        for bit = 6, 1, -1 do
            bits = bits .. (index % 2 ^ bit - index % 2 ^ (bit - 1) > 0 and "1" or "0")
        end
        return bits
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(bits)
        if #bits ~= 8 then
            return ""
        end
        local byte = 0
        for bit = 1, 8 do
            byte = byte + (bits:sub(bit, bit) == "1" and 2 ^ (8 - bit) or 0)
        end
        return string.char(byte)
    end))
end

function Serializer.Export(value)
    local out = {}
    Encode(value, out)
    return PREFIX .. ToBase64(table.concat(out))
end

function Serializer.Import(text)
    text = strtrim(text or "")
    if text:sub(1, #PREFIX) ~= PREFIX then
        return nil, "this is not a Class Macros string"
    end
    local ok, value = pcall(function()
        local data = FromBase64(text:sub(#PREFIX + 1))
        local result, position = Decode(data, 1, 0)
        if position <= #data then
            error("extra data at the end")
        end
        return result
    end)
    if not ok then
        return nil, "the string is broken or not complete (" .. tostring(value):gsub("^.-:%d+: ", "") .. ")"
    end
    return value
end
