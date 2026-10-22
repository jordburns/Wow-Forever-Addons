local _, ns = ...

local CHARACTER, GENERAL = ns.CHARACTER, ns.GENERAL
local T = ns.MacroText

ns.ClassSets.MAGE = {
    gearSlots = {},
    order = { "frost", "fire", "arcane", "defense", "buffs" },
    sections = {
        frost = {
            title = "Frost",
            iconSpell = 116,
            tab = CHARACTER,
            macros = {
                { "Frostbolt", T.OnEnemy("Frostbolt") },
                { "IceLance", T.OnEnemy("Ice Lance") },
                { "FrostBlast", T.OnEnemy("Frost Blast") },
                { "FNova", T.Plain("Frost Nova") },
                { "CoC", T.Plain("Cone of Cold") },
                { "Blizzard", T.Plain("Blizzard") },
            },
        },
        fire = {
            title = "Fire",
            iconSpell = 133,
            tab = CHARACTER,
            macros = {
                { "Fireball", T.OnEnemy("Fireball") },
                { "FFBolt", T.OnEnemy("Frostfire Bolt") },
                { "FireBlast", T.OnEnemy("Fire Blast") },
                { "Scorch", T.OnEnemy("Scorch") },
                { "Pyro", T.OnEnemy("Pyroblast") },
                { "BWave", T.Plain("Blast Wave") },
                { "Flamestrike", T.Plain("Flamestrike") },
            },
        },
        arcane = {
            title = "Arcane",
            iconSpell = 5143,
            tab = CHARACTER,
            macros = {
                { "AMissiles", T.OnEnemy("Arcane Missiles") },
                { "ABlast", T.OnEnemy("Arcane Blast") },
                { "AWrath", T.OnEnemy("Arcane Wrath") },
                { "AExplode", T.Plain("Arcane Explosion") },
                { "CSpell", T.OnEnemy("Counterspell") },
                { "Poly", T.OnEnemy("Polymorph") },
            },
        },
        defense = {
            title = "Defense and mana",
            iconSpell = 1953,
            tab = CHARACTER,
            macros = {
                { "Blink", T.Plain("Blink") },
                { "IBarrier", T.Plain("Ice Barrier") },
                { "MShield", T.Plain("Mana Shield") },
                { "FWard", T.Plain("Frost Ward") },
                { "FireWard", T.Plain("Fire Ward") },
                { "Evocation", T.Plain("Evocation") },
                { "RCurse", T.OnFriend("Remove Lesser Curse") },
            },
        },
        buffs = {
            title = "Armor, buffs and conjures",
            iconSpell = 1459,
            tab = GENERAL,
            macros = {
                { "M FArmor", T.Plain("Frost Armor") },
                { "M IArmor", T.Plain("Ice Armor") },
                { "M MArmor", T.Plain("Mage Armor") },
                { "M AI", T.OnFriend("Arcane Intellect") },
                { "M ABrill", T.OnFriend("Arcane Brilliance") },
                { "M Amplify", T.OnFriend("Amplify Magic") },
                { "M Dampen", T.OnFriend("Dampen Magic") },
                { "M SlowFall", T.OnFriend("Slow Fall") },
                { "M Water", T.Plain("Conjure Water") },
                { "M Food", T.Plain("Conjure Food") },
            },
        },
    },
}
