ModUtil.RegisterMod("EnemyRandomizer")

local config = {
    RandomizeMiniBosses = false, -- WIP DO NOT USE
    RandomizeBosses = false, -- WIP DO NOT USE
    Tartarus = {
        TartarusEnemies = true,
        AsphodelEnemies = true,
        ElysiumEnemies = true,
        StyxEnemies = true,
        MiniBosses = false,
        Bosses = false,
    },
    Asphodel = {
        TartarusEnemies = true,
        AsphodelEnemies = true,
        ElysiumEnemies = true,
        StyxEnemies = true,
        MiniBosses = false,
        Bosses = false,
    },
    Elysium = {
        TartarusEnemies = true,
        AsphodelEnemies = true,
        ElysiumEnemies = true,
        StyxEnemies = true,
        MiniBosses = false,
        Bosses = false,
    },
    Styx = {
        TartarusEnemies = true,
        AsphodelEnemies = true,
        ElysiumEnemies = true,
        StyxEnemies = true,
        MiniBosses = false,
        Bosses = false,
    },
}
EnemyRandomizer.Config = config

EnemyRandomizer.DefaultEnemySetSuffixes = {
    '',
    'Devotion',
    'Challenge', -- troves?
    'Survival', --not in 2/3/4, hardly matters
    'Hard', --not in 4
    'Thanatos', --not in 4
    'ShrineChallenge', --takes biome name not number
    'MiniBossFodder', --4 only
    'Mini', --4 only
    'MiniHard', --4 only
    'Traversal', --4 only
}
EnemyRandomizer.BiomeIndex = {
    Tartarus = 1,
    Asphodel = 2,
    Elysium = 3,
    Styx = 4,
}
EnemyRandomizer.EnemySets = {
    Bosses ={
        "HydraHeadDartmaker",
        "HydraHeadLavamaker", 
        "HydraHeadSummoner", 
        "HydraHeadSlammer", 
        "HydraHeadWavemaker",
        "Harpy",
        "Harpy2",
        "Harpy3",
        "Theseus",
        "Minotaur",
        "Hades",
    }
}

ModUtil.LoadOnce( function()

            local function GetEnemySetName( biome, enemySetSuffix )
                if enemySetSuffix == 'ShrineChallenge' then
                    return enemySetSuffix .. biome
                else
                    return 'EnemiesBiome' .. EnemyRandomizer.BiomeIndex[biome] .. enemySetSuffix
                end
            end
            -- overwriting enemy sets

            -- default enemy sets
            for biome, biomeIndex in pairs(EnemyRandomizer.BiomeIndex) do
                local biomeConfig = EnemyRandomizer.Config[biome]

                for i, enemySetSuffix in pairs(EnemyRandomizer.DefaultEnemySetSuffixes) do
                    local enemySetName = GetEnemySetName(biome, enemySetSuffix)
                    local biomeEnemySet = {}
                    if EnemySets[enemySetName] then
                        if biomeConfig.TartarusEnemies then
                            biomeEnemySet = ConcatTableValues(biomeEnemySet, EnemySets[GetEnemySetName("Tartarus", enemySetSuffix)] or EnemySets["EnemiesBiome1"])
                        end
                        if biomeConfig.AsphodelEnemies then
                            biomeEnemySet = ConcatTableValues(biomeEnemySet, EnemySets[GetEnemySetName("Asphodel", enemySetSuffix)] or EnemySets["EnemiesBiome2"])
                        end
                        if biomeConfig.ElysiumEnemies then
                            biomeEnemySet = ConcatTableValues(biomeEnemySet, EnemySets[GetEnemySetName("Elysium", enemySetSuffix)] or EnemySets["EnemiesBiome3"])
                        end
                        if biomeConfig.StyxEnemies then
                            biomeEnemySet = ConcatTableValues(biomeEnemySet, EnemySets[GetEnemySetName("Styx", enemySetSuffix)] or EnemySets["EnemiesBiome4"])
                        end
                        if biomeConfig.MiniBosses then
                            biomeEnemySet = ConcatTableValues(biomeEnemySet, EnemySets["Minibosses"])
                        end
                        if biomeConfig.Bosses then
                            biomeEnemySet = ConcatTableValues(biomeEnemySet, EnemyRandomizer.EnemySets.Bosses)
                        end
                        EnemyRandomizer.EnemySets[enemySetName] = biomeEnemySet
                    end
                end
            end
            --styx single enemy rooms
            local count = 0
            local styxSingleEnemySet = {}
            if EnemyRandomizer.Config['Styx'].MiniBosses then
                styxSingleEnemySet = ConcatTableValues(styxSingleEnemySet, EnemySets["Minibosses"])
                count = count + 5
            end
            if EnemyRandomizer.Config['Styx'].Bosses then
                styxSingleEnemySet = ConcatTableValues(styxSingleEnemySet, EnemyRandomizer.EnemySets.Bosses)
                count = count + 5
            end
            if EnemyRandomizer.Config['Styx'].StyxEnemies then
                for i=1,count do 
                    styxSingleEnemySet = ConcatTableValues(styxSingleEnemySet, EnemySets['EnemiesBiome4MiniSingle'])
                end
            end
            EnemyRandomizer.EnemySets['EnemiesBiome4MiniSingle'] = styxSingleEnemySet

            -- overwriting encounter data
            ModUtil.MapSetTable(EncounterData, {
                GeneratedTartarus = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome1,
                    HardEncounterOverrideValues = {
                        EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome1Hard,
                    }
                },
                GeneratedAsphodel = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome2,
                    HardEncounterOverrideValues = {
                        EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome2Hard,
                    }
                },
                GeneratedElysium = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome3,
                    HardEncounterOverrideValues = {
                        EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome3Hard,
                    }
                },
                GeneratedStyx = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome4,
                },
                BaseStyxMiniboss = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome4MiniBossFodder,
                },
                GeneratedStyxMini = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome4Mini,
                    HardEncounterOverrideValues = {
                        EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome4MiniHard
                    },
                },
                GeneratedStyxMiniSingle = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome4MiniSingle,
                    HardEncounterOverrideValues = {
                        EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome4MiniSingle
                    },
                },
                TimeChallengeTartarus = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome1,
                },
                TimeChallengeAsphodel = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome2Challenge,
                },
                TimeChallengeElysium = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome3,
                },
                TimeChallengStyx = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome4,
                },
                DevotionTestTartarus = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome1Devotion,
                },
                DevotionTestAsphodel = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome2Devotion,
                },
                DevotionTestElysium = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome3Devotion,
                },
                ThanatosTartarus = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome1Thanatos,
                },
                ThanatosAsphodel = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome2Thanatos,
                },
                ThanatosElysium = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome3Thanatos,
                },
                ShrineChallengeTartarus = {
                    EnemySet = EnemyRandomizer.EnemySets.ShrineChallengeTartarus,
                },
                ShrineChallengeAsphodel = {
                    EnemySet = EnemyRandomizer.EnemySets.ShrineChallengeAsphodel,
                },
                ShrineChallengeElysium = {
                    EnemySet = EnemyRandomizer.EnemySets.ShrineChallengeElysium,
                },
                SurvivalTartarus = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome1Survival,
                },
                SurvivalAsphodel = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome2Survival,
                },
                SurvivalElysium = {
                    EnemySet = EnemyRandomizer.EnemySets.EnemiesBiome3Survival,
                },

            })
        end)