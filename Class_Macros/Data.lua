local _, ns = ...

ns.CHARACTER = "character"
ns.GENERAL = "general"

ns.WEAPON_AND_SHIELD_SLOTS = {
    { key = "<1H>", label = "One-hand", inventorySlot = 16, default = "MY_1H" },
    { key = "<SHIELD>", label = "Shield", inventorySlot = 17, default = "MY_SHIELD" },
    { key = "<2H>", label = "Two-hand", inventorySlot = 16, default = "MY_2H" },
}

ns.ClassSets = {}

local FRIEND = "[@mouseover,help,nodead][help,nodead][@player]"
local ENEMY = "[@mouseover,harm,nodead][]"
local ANYONE = "[@mouseover,exists,nodead][]"
local DEAD_FRIEND = "[@mouseover,help,dead][]"

ns.MacroText = {
    Plain = function(spell)
        return "#showtooltip\n/cast " .. spell
    end,
    Melee = function(spell)
        return "#showtooltip " .. spell .. "\n/startattack\n/cast " .. ENEMY .. " " .. spell
    end,
    OnEnemy = function(spell)
        return "#showtooltip " .. spell .. "\n/cast " .. ENEMY .. " " .. spell
    end,
    OnFriend = function(spell)
        return "#showtooltip " .. spell .. "\n/cast " .. FRIEND .. " " .. spell
    end,
    OnAnyone = function(spell)
        return "#showtooltip " .. spell .. "\n/cast " .. ANYONE .. " " .. spell
    end,
    OnDeadFriend = function(spell)
        return "#showtooltip " .. spell .. "\n/cast " .. DEAD_FRIEND .. " " .. spell
    end,
    Form = function(spell)
        return "#showtooltip " .. spell .. "\n/cast !" .. spell
    end,
}
