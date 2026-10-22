local _, ns = ...

local CHARACTER, GENERAL = ns.CHARACTER, ns.GENERAL
local T = ns.MacroText

ns.ClassSets.WARLOCK = {
    gearSlots = {},
    order = { "destruction", "affliction", "control", "pet", "curses", "demonology" },
    sections = {
        destruction = {
            title = "Destruction",
            iconSpell = 686,
            tab = CHARACTER,
            macros = {
                { "SBolt", T.OnEnemy("Shadow Bolt") },
                { "Immolate", T.OnEnemy("Immolate") },
                { "Incinerate", T.OnEnemy("Incinerate") },
                { "SPain", T.OnEnemy("Searing Pain") },
                { "SBurn", T.OnEnemy("Shadowburn") },
                { "Conflag", T.OnEnemy("Conflagrate") },
                { "SoulFire", T.OnEnemy("Soul Fire") },
                { "RoF", T.Plain("Rain of Fire") },
                { "Hellfire", T.Plain("Hellfire") },
            },
        },
        affliction = {
            title = "Affliction",
            iconSpell = 172,
            tab = CHARACTER,
            macros = {
                { "Corruption", T.OnEnemy("Corruption") },
                { "Agony", T.OnEnemy("Bane of Agony") },
                { "Doom", T.OnEnemy("Bane of Doom") },
                { "Siphon", T.OnEnemy("Siphon Life") },
                { "DLife", T.OnEnemy("Drain Life") },
                { "DSoul", T.OnEnemy("Drain Soul") },
                { "DMana", T.OnEnemy("Drain Mana") },
                { "LifeTap", T.Plain("Life Tap") },
            },
        },
        control = {
            title = "Control",
            iconSpell = 5782,
            tab = CHARACTER,
            macros = {
                { "Fear", T.OnEnemy("Fear") },
                { "Howl", T.Plain("Howl of Terror") },
                { "DCoil", T.OnEnemy("Death Coil") },
                { "Banish", T.OnEnemy("Banish") },
                { "Subjugate", T.OnEnemy("Subjugate Demon") },
            },
        },
        pet = {
            title = "Pet",
            iconSpell = 688,
            tab = CHARACTER,
            macros = {
                { "PetAttack", "#showtooltip\n/petattack [@mouseover,harm,nodead][]" },
                { "Funnel", T.Plain("Health Funnel") },
            },
        },
        curses = {
            title = "Curses",
            iconSpell = 702,
            tab = GENERAL,
            macros = {
                { "Wl CoW", T.OnEnemy("Curse of Weakness") },
                { "Wl CoR", T.OnEnemy("Curse of Recklessness") },
                { "Wl CoE", T.OnEnemy("Curse of the Elements") },
                { "Wl CoT", T.OnEnemy("Curse of Tongues") },
            },
        },
        demonology = {
            title = "Demons, armor and stones",
            iconSpell = 687,
            tab = GENERAL,
            macros = {
                { "Wl Imp", T.Plain("Summon Imp") },
                { "Wl Void", T.Plain("Summon Voidwalker") },
                { "Wl Succubus", T.Plain("Summon Succubus") },
                { "Wl Incubus", T.Plain("Summon Incubus") },
                { "Wl Felhunter", T.Plain("Summon Felhunter") },
                { "Wl Inferno", T.Plain("Inferno") },
                { "Wl DSkin", T.Plain("Demon Skin") },
                { "Wl DArmor", T.Plain("Demon Armor") },
                { "Wl SWard", T.Plain("Shadow Ward") },
                { "Wl HStone", T.Plain("Create Healthstone") },
                { "Wl SStone", T.Plain("Create Soulstone") },
                { "Wl FStone", T.Plain("Create Firestone") },
                { "Wl SpStone", T.Plain("Create Spellstone") },
                { "Wl Breath", T.OnFriend("Unending Breath") },
                { "Wl DInvis", T.OnFriend("Detect Invisibility") },
                { "Wl Eye", T.Plain("Eye of Kilrogg") },
                { "Wl Summon", T.Plain("Ritual of Summoning") },
            },
        },
    },
}
