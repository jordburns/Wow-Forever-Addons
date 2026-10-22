local _, ns = ...

local CHARACTER, GENERAL = ns.CHARACTER, ns.GENERAL
local T = ns.MacroText

ns.ClassSets.HUNTER = {
    gearSlots = {},
    order = { "shots", "melee", "pet", "aspects", "traps" },
    sections = {
        shots = {
            title = "Shots and stings",
            iconSpell = 3044,
            tab = CHARACTER,
            macros = {
                { "Auto", "#showtooltip Auto Shot\n/cast [@mouseover,harm,nodead][] !Auto Shot" },
                { "AutoPet", "#showtooltip Auto Shot\n/targetenemy [noexists][dead][help]\n/cast !Auto Shot\n/petattack" },
                { "Arcane", T.OnEnemy("Arcane Shot") },
                { "Multi", T.OnEnemy("Multi-Shot") },
                { "Aimed", T.OnEnemy("Aimed Shot") },
                { "Sniper", T.OnEnemy("Sniper Shot") },
                { "Concuss", T.OnEnemy("Concussive Shot") },
                { "Distract", T.OnEnemy("Distracting Shot") },
                { "Tranq", T.OnEnemy("Tranquilizing Shot") },
                { "Serpent", T.OnEnemy("Serpent Sting") },
                { "Scorpid", T.OnEnemy("Scorpid Sting") },
                { "Viper", T.OnEnemy("Viper Sting") },
                { "Mark", T.OnEnemy("Hunter's Mark") },
                { "Volley", T.Plain("Volley") },
                { "Rapid", T.Plain("Rapid Fire") },
            },
        },
        melee = {
            title = "Melee and escape",
            iconSpell = 2973,
            tab = CHARACTER,
            macros = {
                { "Raptor", T.Melee("Raptor Strike") },
                { "Mongoose", T.Melee("Mongoose Bite") },
                { "Lacerate", T.Melee("Lacerate") },
                { "WingClip", T.Melee("Wing Clip") },
                { "Counter", T.Melee("Counterattack") },
                { "Disengage", T.Plain("Disengage") },
                { "Feign", T.Plain("Feign Death") },
            },
        },
        pet = {
            title = "Pet",
            iconSpell = 883,
            tab = CHARACTER,
            macros = {
                { "PetAttack", "#showtooltip\n/petattack [@mouseover,harm,nodead][]" },
                { "Pet", "#showtooltip\n/cast [nopet] Call Pet; [@pet,dead] Revive Pet; Mend Pet" },
                { "Feed", T.Plain("Feed Pet") },
                { "Dismiss", T.Plain("Dismiss Pet") },
            },
        },
        aspects = {
            title = "Aspects and auras",
            iconSpell = 13165,
            tab = GENERAL,
            macros = {
                { "H Hawk", T.Form("Aspect of the Hawk") },
                { "H Falcon", T.Form("Aspect of the Falcon") },
                { "H Monkey", T.Form("Aspect of the Monkey") },
                { "H Viper", T.Form("Aspect of the Viper") },
                { "H Cheetah", T.Form("Aspect of the Cheetah") },
                { "H Pack", T.Form("Aspect of the Pack") },
                { "H Wild", T.Form("Aspect of the Wild") },
                { "H Beast", T.Form("Aspect of the Beast") },
                { "H Trueshot", T.Plain("Trueshot Aura") },
                { "H Lion", T.Plain("Heart of the Lion") },
                { "H SumHawk", T.Plain("Summon Hawk") },
            },
        },
        traps = {
            title = "Traps and utility",
            iconSpell = 1499,
            tab = GENERAL,
            macros = {
                { "H Freeze", T.Plain("Freezing Trap") },
                { "H FrostTrap", T.Plain("Frost Trap") },
                { "H Immolate", T.Plain("Immolation Trap") },
                { "H Explosive", T.Plain("Explosive Trap") },
                { "H Flare", T.Plain("Flare") },
                { "H EFlare", T.Plain("Enchanted Flare") },
                { "H EagleEye", T.Plain("Eagle Eye") },
                { "H Scare", T.OnEnemy("Scare Beast") },
                { "H Tame", T.OnEnemy("Tame Beast") },
            },
        },
    },
}
