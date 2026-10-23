local _, ns = ...

local CHARACTER, GENERAL = ns.CHARACTER, ns.GENERAL

local EQUIP_SHIELD_IF_MISSING = "/equipslot [noequipped:Shields] 16 <1H>\n/equipslot [noequipped:Shields] 17 <SHIELD>\n"

ns.ClassSets.WARRIOR = {
    gearSlots = ns.WEAPON_AND_SHIELD_SLOTS,
    order = { "openers", "battle", "defensive", "berserker", "gear", "anystance", "talents" },
    retired = {
        { "Charge", CHARACTER },
        { "BS", CHARACTER },
        { "W CShout", GENERAL },
        { "W 2H", GENERAL },
        { "W Shield", GENERAL },
    },
    sections = {
        openers = {
            title = "Openers and utility",
            icon = 132337,
            tab = CHARACTER,
            macros = {
                { "HS Attack", "#showtooltip Heroic Strike\n/startattack\n/cast Heroic Strike" },
                { "Kick", "#showtooltip [stance:3] Pummel; Shield Bash\n/equipslot [nostance:3,noequipped:Shields] 16 <1H>\n/equipslot [nostance:3,noequipped:Shields] 17 <SHIELD>\n/cast [stance:3] Pummel; Shield Bash" },
                { "Pull", "#showtooltip\n/cast [equipped:Thrown] Throw; [equipped:Guns] Shoot Gun; [equipped:Crossbows] Shoot Crossbow; Shoot Bow" },
                { "Shout", "#showtooltip\n/cast Battle Shout" },
            },
        },
        battle = {
            title = "Battle Stance",
            icon = 132349,
            tab = CHARACTER,
            macros = {
                { "TClap", "#showtooltip Thunder Clap\n/cast [stance:3,equipped:Shields] Defensive Stance; [stance:3] Battle Stance; Thunder Clap" },
                { "OP", "#showtooltip Overpower\n/startattack\n/cast [stance:1] Overpower; Battle Stance" },
                { "Mock", "#showtooltip Mocking Blow\n/cast [stance:1] Mocking Blow; Battle Stance" },
                { "Retal", "#showtooltip Retaliation\n/cast [stance:1] Retaliation; Battle Stance" },
                { "Execute", "#showtooltip Execute\n/startattack\n/cast [stance:2] Battle Stance; Execute" },
                { "Ham", "#showtooltip Hamstring\n/cast [stance:2] Battle Stance; Hamstring" },
                { "Rend", "#showtooltip Rend\n/startattack\n/cast [stance:3] Battle Stance; Rend" },
                { "Sweep", "#showtooltip Sweeping Strikes\n/cast [stance:1] Sweeping Strikes; Battle Stance" },
            },
        },
        defensive = {
            title = "Defensive Stance and shield",
            icon = 132341,
            tab = CHARACTER,
            macros = {
                { "Revenge", "#showtooltip Revenge\n/startattack\n/cast [stance:2] Revenge; Defensive Stance" },
                { "SBlock", "#showtooltip Shield Block\n" .. EQUIP_SHIELD_IF_MISSING .. "/cast [stance:2] Shield Block; Defensive Stance" },
                { "SWall", "#showtooltip Shield Wall\n" .. EQUIP_SHIELD_IF_MISSING .. "/cast [stance:2] Shield Wall; Defensive Stance" },
                { "SSlam", "#showtooltip Shield Slam\n" .. EQUIP_SHIELD_IF_MISSING .. "/startattack\n/cast Shield Slam" },
                { "Taunt", "#showtooltip Taunt\n/cast [stance:2] Taunt; Defensive Stance" },
                { "Disarm", "#showtooltip Disarm\n/cast [stance:2] Disarm; Defensive Stance" },
                { "CShout", "#showtooltip Challenging Shout\n" .. EQUIP_SHIELD_IF_MISSING .. "/cast [stance:2] Challenging Shout; Defensive Stance" },
            },
        },
        berserker = {
            title = "Berserker Stance",
            icon = 132275,
            tab = CHARACTER,
            macros = {
                { "Reck", "#showtooltip Recklessness\n/cast [stance:3] Recklessness; Berserker Stance" },
                { "BRage", "#showtooltip Berserker Rage\n/cast [stance:3] Berserker Rage; Berserker Stance" },
                { "WW", "#showtooltip Whirlwind\n/cast [stance:3] Whirlwind; Berserker Stance" },
                { "Intercept", "#showtooltip Intercept\n/cast [stance:3] Intercept; Berserker Stance" },
            },
        },
        gear = {
            title = "Weapon swaps",
            icon = 132362,
            tab = CHARACTER,
            replaces = {
                { "W 2H", GENERAL },
                { "W Shield", GENERAL },
            },
            macros = {
                { "W 2H", "#showtooltip\n/equipslot 16 <2H>" },
                { "W Shield", "#showtooltip <SHIELD>\n/equipslot 16 <1H>\n/equipslot 17 <SHIELD>" },
            },
        },
        anystance = {
            title = "Any stance",
            icon = 132366,
            tab = GENERAL,
            macros = {
                { "W Blood", "#showtooltip\n/cast Bloodrage" },
                { "W VRush", "#showtooltip\n/startattack\n/cast Victory Rush" },
                { "W Demo", "#showtooltip\n/cast Demoralizing Shout" },
                { "W IShout", "#showtooltip\n/cast Intimidating Shout" },
                { "W Sunder", "#showtooltip\n/startattack\n/cast Sunder Armor" },
                { "W Cleave", "#showtooltip\n/startattack\n/cast Cleave" },
                { "W Slam", "#showtooltip\n/startattack\n/cast Slam" },
            },
        },
        talents = {
            title = "Talents",
            icon = 132355,
            tab = GENERAL,
            macros = {
                { "W MS", "#showtooltip\n/startattack\n/cast Mortal Strike" },
                { "W BT", "#showtooltip\n/startattack\n/cast Bloodthirst" },
                { "W DWish", "#showtooltip\n/cast Death Wish" },
                { "W LStand", "#showtooltip\n/cast Last Stand" },
                { "W CBlow", "#showtooltip\n/startattack\n/cast Concussion Blow" },
                { "W Howl", "#showtooltip\n/cast Piercing Howl" },
                { "W Spear", "#showtooltip Spearing Strike\n/startattack\n/cast [stance:1] Spearing Strike; Battle Stance" },
            },
        },
    },
}
