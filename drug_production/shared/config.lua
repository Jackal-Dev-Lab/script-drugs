Config = {}

Config.Debug = false
Config.LabDurationHours = 72
Config.LabPurchasePrice = 500000
Config.IntrusionCooldownSeconds = 900
Config.IntrusionFailureAlertChance = 35
Config.IntrusionAccessMinutes = 20
Config.DefaultBatchLimit = 10
Config.PositionValidationDistance = 4.0

Config.Quality = {
    min = 0,
    max = 100,
    stolenLabPenalty = 12,
    gangOwnedBonus = 6,
    skillSuccessBonus = 8,
    skillFailPenalty = 14,
}

Config.Risks = {
    meth = { explosion = 18, injury = 20, policeAlert = 25, materialLoss = 30 },
    cocaine = { intoxication = 15, explosion = 7, policeAlert = 20, materialLoss = 18 },
    weed = { materialLoss = 10, policeAlert = 5 },
    gas = { injury = 8 }
}

Config.Cooldowns = {
    purchase = 30,
    intrusion = Config.IntrusionCooldownSeconds,
    process = 2,
}

Config.Labs = {
    [1] = {
        label = 'Lab Industriel Elysian',
        allowedDrugs = { 'weed', 'weed_processed', 'cocaine', 'meth', 'gas' },
        entry = vec3(1197.98, -3253.71, 7.1),
        interior = vec4(1088.61, -3187.52, -38.99, 178.0),
        exit = vec3(1088.81, -3188.5, -38.99),
        intrusionZone = vec3(1193.2, -3247.6, 6.1),
        blip = { sprite = 499, color = 1, scale = 0.85 }
    },
    [2] = {
        label = 'Lab Clandestin Grapeseed',
        allowedDrugs = { 'weed', 'cocaine', 'meth' },
        entry = vec3(2444.3, 4968.0, 46.8),
        interior = vec4(997.23, -3200.7, -36.39, 270.0),
        exit = vec3(996.9, -3200.7, -36.39),
        intrusionZone = vec3(2435.8, 4965.6, 45.2),
        blip = { sprite = 499, color = 3, scale = 0.85 }
    }
}

Config.SkillChecks = {
    intrusion = { 'medium', 'hard', 'hard' },
    weed = { 'easy', 'medium' },
    weed_processed = { 'medium', 'hard' },
    cocaine = { 'medium', 'hard', 'hard' },
    meth = { 'hard', 'hard', 'hard' },
    gas = { 'easy' }
}

Config.Recipes = {
    weed = {
        stages = {
            { key = 'dry', label = 'Séchage', time = 9000, inputs = { weed_brute = 2 }, outputs = { weed_sechee = 2 } },
            { key = 'cut', label = 'Coupe', time = 7000, inputs = { weed_sechee = 2 }, outputs = { weed_traitee = 2 } },
            { key = 'bag', label = 'Mise en pochon', time = 6000, inputs = { weed_traitee = 1 }, outputs = { weed_pochon = 1 } }
        }
    },
    weed_processed = {
        stages = {
            { key = 'solvent', label = 'Traitement chimique', time = 12000, inputs = { weed_traitee = 2, solvants = 1 }, outputs = { weed_concentre_pochon = 2 } }
        }
    },
    cocaine = {
        stages = {
            { key = 'paste', label = 'Préparer pâte', time = 10000, inputs = { cocaine_feuille = 3, produits_chimiques = 1 }, outputs = { cocaine_pate = 2 } },
            { key = 'raw', label = 'Coke brute', time = 11000, inputs = { cocaine_pate = 2 }, outputs = { cocaine_brute = 2 } },
            { key = 'pure', label = 'Purification', time = 12000, inputs = { cocaine_brute = 2, solvants = 1 }, outputs = { cocaine_pochon = 2 } }
        }
    },
    meth = {
        stages = {
            { key = 'liquid', label = 'Cuisson liquide', time = 12000, inputs = { meth_matiere = 3, produits_chimiques = 2 }, outputs = { meth_liquide = 2 } },
            { key = 'crystal', label = 'Cristallisation', time = 14000, inputs = { meth_liquide = 2 }, outputs = { meth_brute = 2 } },
            { key = 'bag', label = 'Conditionnement', time = 10000, inputs = { meth_brute = 2 }, outputs = { meth_pochon = 2 } }
        }
    },
    gas = {
        stages = {
            { key = 'fill', label = 'Remplir les ballons', time = 8000, inputs = { bonbonne_gaz = 1, ballon_vide = 2 }, outputs = { ballon_plein = 2 } }
        }
    }
}

Config.Items = {
    weed_brute = { label = 'Weed brute', weight = 120 },
    cocaine_feuille = { label = 'Feuilles de coca', weight = 100 },
    meth_matiere = { label = 'Matière meth', weight = 125 },
    weed_sechee = { label = 'Weed séchée', weight = 90 },
    weed_traitee = { label = 'Weed traitée', weight = 85 },
    cocaine_pate = { label = 'Pâte de cocaïne', weight = 110 },
    cocaine_brute = { label = 'Cocaïne brute', weight = 95 },
    meth_liquide = { label = 'Meth liquide', weight = 115 },
    meth_brute = { label = 'Meth cristallisée brute', weight = 105 },
    weed_pochon = { label = 'Pochon de weed', weight = 35 },
    weed_concentre_pochon = { label = 'Pochon de weed concentrée', weight = 30 },
    cocaine_pochon = { label = 'Pochon de cocaïne', weight = 30 },
    meth_pochon = { label = 'Pochon de meth', weight = 30 },
    bonbonne_gaz = { label = 'Bonbonne de gaz', weight = 9000 },
    ballon_vide = { label = 'Ballon vide', weight = 5 },
    ballon_plein = { label = 'Ballon plein', weight = 10 },
    solvants = { label = 'Solvants', weight = 50 },
    produits_chimiques = { label = 'Produits chimiques', weight = 60 },
}

Config.PoliceAlert = function(source, reason)
    TriggerEvent('drug_production:server:policeAlert', source, reason)
end
