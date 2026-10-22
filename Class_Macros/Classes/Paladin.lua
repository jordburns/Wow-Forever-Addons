local _, ns = ...

local CHARACTER, GENERAL = ns.CHARACTER, ns.GENERAL

local FRIEND = "[@mouseover,help,nodead][help,nodead][@player]"
local ENEMY = "[@mouseover,harm,nodead][]"
local ANYONE = "[@mouseover,exists,nodead][]"
local DEAD_FRIEND = "[@mouseover,help,dead][]"
local EQUIP_SHIELD_IF_MISSING = "/equipslot [noequipped:Shields] 16 <1H>\n/equipslot [noequipped:Shields] 17 <SHIELD>\n"

local function OnFriend(spell)
    return "#showtooltip " .. spell .. "\n/cast " .. FRIEND .. " " .. spell
end

local function OnEnemy(spell)
    return "#showtooltip " .. spell .. "\n/startattack\n/cast " .. ENEMY .. " " .. spell
end

local function Plain(spell)
    return "#showtooltip\n/cast " .. spell
end

ns.ClassSets.PALADIN = {
    gearSlots = ns.WEAPON_AND_SHIELD_SLOTS,
    order = { "combat", "healing", "blessings", "defense", "gear", "seals", "auras", "greater", "utility" },
    sections = {
        combat = {
            title = "Combat",
            iconSpell = 20271,
            tab = CHARACTER,
            macros = {
                { "Judge", OnEnemy("Judgement") },
                { "HStrike", OnEnemy("Holy Strike") },
                { "HotR", OnEnemy("Hammer of the Righteous") },
                { "HoJ", OnEnemy("Hammer of Justice") },
                { "HoW", OnEnemy("Hammer of Wrath") },
                { "Exo", OnEnemy("Exorcism") },
                { "Repent", OnEnemy("Repentance") },
            },
        },
        healing = {
            title = "Healing",
            iconSpell = 635,
            tab = CHARACTER,
            macros = {
                { "HL", OnFriend("Holy Light") },
                { "FoL", OnFriend("Flash of Light") },
                { "HShock", "#showtooltip Holy Shock\n/cast " .. ANYONE .. " Holy Shock" },
                { "LVigil", "#showtooltip Light's Vigil\n/cast " .. ANYONE .. " Light's Vigil" },
                { "LoH", OnFriend("Lay on Hands") },
                { "Cleanse", OnFriend("Cleanse") },
                { "Purify", OnFriend("Purify") },
                { "Redeem", "#showtooltip Redemption\n/cast " .. DEAD_FRIEND .. " Redemption" },
            },
        },
        blessings = {
            title = "Blessings",
            iconSpell = 19740,
            tab = CHARACTER,
            macros = {
                { "BoM", OnFriend("Blessing of Might") },
                { "BoW", OnFriend("Blessing of Wisdom") },
                { "BoL", OnFriend("Blessing of Light") },
                { "Salv", OnFriend("Salvation") },
                { "BoF", OnFriend("Blessing of Freedom") },
                { "BoP", OnFriend("Blessing of Protection") },
                { "BoS", OnFriend("Blessing of Sacrifice") },
            },
        },
        defense = {
            title = "Defense and shield",
            iconSpell = 20925,
            tab = CHARACTER,
            macros = {
                { "HShield", "#showtooltip Holy Shield\n" .. EQUIP_SHIELD_IF_MISSING .. "/cast Holy Shield" },
                { "DI", OnFriend("Divine Intervention") },
            },
        },
        gear = {
            title = "Weapon swaps",
            icon = 132362,
            tab = CHARACTER,
            macros = {
                { "2H", "#showtooltip\n/equipslot 16 <2H>" },
                { "Shield", "#showtooltip <SHIELD>\n/equipslot 16 <1H>\n/equipslot 17 <SHIELD>" },
            },
        },
        seals = {
            title = "Seals",
            iconSpell = 21084,
            tab = GENERAL,
            macros = {
                { "P SoR", Plain("Seal of Righteousness") },
                { "P SotC", Plain("Seal of the Crusader") },
                { "P SoC", Plain("Seal of Command") },
                { "P SoF", Plain("Seal of Fury") },
                { "P SoJ", Plain("Seal of Justice") },
                { "P SoL", Plain("Seal of Light") },
                { "P SoW", Plain("Seal of Wisdom") },
            },
        },
        auras = {
            title = "Auras and Righteous Fury",
            iconSpell = 465,
            tab = GENERAL,
            macros = {
                { "P Devo", Plain("Devotion Aura") },
                { "P Ret", Plain("Retribution Aura") },
                { "P Conc", Plain("Concentration Aura") },
                { "P ShadowR", Plain("Shadow Resistance Aura") },
                { "P FrostR", Plain("Frost Resistance Aura") },
                { "P FireR", Plain("Fire Resistance Aura") },
                { "P RFury", Plain("Righteous Fury") },
            },
        },
        greater = {
            title = "Greater blessings",
            iconSpell = 25782,
            tab = GENERAL,
            macros = {
                { "P GBoM", OnFriend("Greater Blessing of Might") },
                { "P GBoW", OnFriend("Greater Blessing of Wisdom") },
                { "P GBoL", OnFriend("Greater Blessing of Light") },
                { "P GBoK", OnFriend("Greater Blessing of Kings") },
                { "P MSalv", OnFriend("Mass Salvation") },
            },
        },
        utility = {
            title = "Cooldowns and utility",
            iconSpell = 642,
            tab = GENERAL,
            macros = {
                { "P DProt", Plain("Divine Protection") },
                { "P Bubble", Plain("Divine Shield") },
                { "P Bulwark", Plain("Templar's Bulwark") },
                { "P Voice", Plain("Voice of Truth") },
                { "P Conse", Plain("Consecration") },
                { "P HWrath", Plain("Holy Wrath") },
                { "P Turn", "#showtooltip Turn Undead\n/cast " .. ENEMY .. " Turn Undead" },
                { "P Revoke", Plain("Revoke") },
            },
        },
    },
}
