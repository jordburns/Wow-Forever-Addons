local _, ns = ...

local CHARACTER, GENERAL = ns.CHARACTER, ns.GENERAL
local T = ns.MacroText

ns.ClassSets.ROGUE = {
    gearSlots = {},
    order = { "builders", "finishers", "stealth", "defense", "utility" },
    sections = {
        builders = {
            title = "Builders",
            iconSpell = 1752,
            tab = CHARACTER,
            macros = {
                { "SStrike", T.Melee("Sinister Strike") },
                { "Backstab", T.Melee("Backstab") },
                { "Mutilate", T.Melee("Mutilate") },
                { "Hemo", T.Melee("Hemorrhage") },
                { "Gouge", T.Melee("Gouge") },
            },
        },
        finishers = {
            title = "Finishers",
            iconSpell = 2098,
            tab = CHARACTER,
            macros = {
                { "Evisc", T.Melee("Eviscerate") },
                { "SnD", T.Plain("Slice and Dice") },
                { "Rupture", T.Melee("Rupture") },
                { "Kidney", T.Melee("Kidney Shot") },
                { "Expose", T.Melee("Expose Armor") },
            },
        },
        stealth = {
            title = "Stealth",
            iconSpell = 1784,
            tab = CHARACTER,
            macros = {
                { "Stealth", "#showtooltip Stealth\n/cast [nostealth] Stealth" },
                { "Opener", "#showtooltip\n/cast [stealth] Cheap Shot; Sinister Strike" },
                { "Ambush", T.Melee("Ambush") },
                { "Garrote", T.Melee("Garrote") },
                { "CheapShot", T.Melee("Cheap Shot") },
                { "Sap", T.OnEnemy("Sap") },
                { "PickPocket", T.OnEnemy("Pick Pocket") },
                { "Distract", T.Plain("Distract") },
                { "Vanish", T.Plain("Vanish") },
            },
        },
        defense = {
            title = "Interrupts and defense",
            iconSpell = 1766,
            tab = CHARACTER,
            macros = {
                { "Kick", T.OnEnemy("Kick") },
                { "Blind", T.OnEnemy("Blind") },
                { "Evasion", T.Plain("Evasion") },
                { "Sprint", T.Plain("Sprint") },
                { "Feint", T.Plain("Feint") },
                { "Redirect", T.OnAnyone("Redirect") },
            },
        },
        utility = {
            title = "Traps and locks",
            iconSpell = 2836,
            tab = GENERAL,
            macros = {
                { "R Detect", T.Plain("Detect Traps") },
                { "R Disarm", T.Plain("Disarm Trap") },
                { "R PickLock", T.Plain("Pick Lock") },
                { "R Poisons", T.Plain("Poisons") },
            },
        },
    },
}
