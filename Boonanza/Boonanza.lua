--[[
    BOONANAZA
    Authors:
      cgull (Discord: cgull#4469)

    This mod makes every boon regardless of god contain
    boons from all 8 Olympians, with options for total chaos. Oops!
]]
ModUtil.RegisterMod("Boonanza")

local config = {
    Enabled = true,
    HermesIncluded = true,
    HammersIncluded = true,
    ChaosIncluded = true,
    FullRandom = true, -- ignores boon priority + prerequisites
}
Boonanza.Config = config
Boonanza.OlympianList = {
    "ZeusUpgrade",
    "AresUpgrade",
    "ArtemisUpgrade",
    "AphroditeUpgrade",
    "DionysusUpgrade",
    "AthenaUpgrade",
    "PoseidonUpgrade",
    "DemeterUpgrade",
}
Boonanza.GodLootList = {}
if Boonanza.Config.Enabled then
    Boonanza.GodLootList = DeepCopyTable(Boonanza.OlympianList)
end
if Boonanza.Config.Enabled and Boonanza.Config.HermesIncluded then
    table.insert(Boonanza.GodLootList, "HermesUpgrade")
end
if Boonanza.Config.Enabled and Boonanza.Config.HammersIncluded then
    table.insert(Boonanza.GodLootList, "WeaponUpgrade")
end

local function ConcatLootTable(lootList, tableName)
    output = {}
    for i, lootName in ipairs(lootList) do
        tableToInsert = LootData[lootName][tableName]
        if tableToInsert then
            for i, thingToInsert in ipairs(tableToInsert) do
                table.insert(output, thingToInsert)
            end
        end
    end
    return output
end

local function ConcatLootTableKVP(lootList, tableName)
    output = {}
    for i, lootName in ipairs(lootList) do
        tableToInsert = LootData[lootName][tableName]
        if tableToInsert then
            for key, value in pairs(tableToInsert) do
                output[key] = value
            end
        end
    end
    return output
end

Boonanza.ConcatTraits = ConcatLootTable(Boonanza.GodLootList, "Traits")
Boonanza.ConcatConsumables = ConcatLootTable(Boonanza.GodLootList, "Consumables")
Boonanza.ConcatWeaponUpgrades = ConcatLootTable(Boonanza.GodLootList, "WeaponUpgrades")
Boonanza.ConcatLinkedUpgrades = ConcatLootTableKVP(Boonanza.GodLootList, "LinkedUpgrades")

local function GeneratePriorityUpgrades()
    local output = {}
    if Boonanza.Config.FullRandom then
        return output
    end
    for i = 1, 4 do
        selectedGodLoot = GetRandomValue(Boonanza.OlympianList)
        if i <= 3 then
            table.insert(output, LootData[selectedGodLoot]['PriorityUpgrades'][i])
        else
            -- beowulf check
            if HeroHasTrait("ShieldLoadAmmoTrait") and god ~= "Poseidon" and god ~= "Dionysus" then
                table.insert(output, LootData[selectedGodLoot]['PriorityUpgrades'][5])
            else
                table.insert(output, LootData[selectedGodLoot]['PriorityUpgrades'][i])
            end
        end
    end
    return output
end

local function IsRandomizedLoot( lootData )
    return (Boonanza.Config.Enabled and Contains(Boonanza.GodLootList, lootData.Name)) or
            (Boonanza.Config.ChaosIncluded and lootData.Name == "TrialUpgrade")
end

ModUtil.WrapBaseFunction("CreateLoot", function( baseFunc, args) 
    local originalName = nil
    local originalRarityForce = nil
    if Boonanza.Config.Enabled and 
       ((Boonanza.Config.HermesIncluded and args.Name == "HermesUpgrade") 
         or (Boonanza.Config.HammersIncluded and args.Name == "WeaponUpgrade")) then
        originalName = args.Name
        originalRarityForce = args.ForceCommon
        args.Name = "Boon"
        args.ForceCommon = false
        args.LootData = args.LootData or LootData[originalName]
        args.BoonRaritiesOverride = {
            RareChance = CurrentRun.Hero["BoonData"].RareChance,
            EpicChance = CurrentRun.Hero["BoonData"].EpicChance,
            HeroicChance = CurrentRun.Hero["BoonData"].HeroicChance,
            LegendaryChance = CurrentRun.Hero["BoonData"].LegendaryChance,
        }
    end
    local returnValue = baseFunc(args)
    DebugPrint({Text=returnValue.Rare})
    args.Name = originalName or args.Name
    args.ForceCommon = originalRarityForce or args.ForceCommon
    return returnValue
end, Boonanza)

ModUtil.WrapBaseFunction("GetPriorityDependentTraits", function( baseFunc, lootData )
    if Boonanza.FullRandom and Boonanza.Config.Enabled and (lootData.GodLoot or IsRandomizedLoot(lootData)) then
        return {}
    end
    if Boonanza.Config.Enabled and (lootData.GodLoot or IsRandomizedLoot(lootData)) then
        lootData.LinkedUpgrades = Boonanza.ConcatLinkedUpgrades
        allPriorityDependentTraits = baseFunc(lootData)
        if #allPriorityDependentTraits > 1 then
            return {
                GetRandomValue(allPriorityDependentTraits)
            }
        else
            return allPriorityDependentTraits
        end
    else
        return baseFunc(lootData)
    end

end, Boonanza)

ModUtil.WrapBaseFunction("SetTraitsOnLoot", function( baseFunc, loot, args )
    local chaosLoot = nil
    if Boonanza.Config.Enabled and (loot.GodLoot or IsRandomizedLoot(loot)) then
        loot.PriorityUpgrades = GeneratePriorityUpgrades()
        if Boonanza.Config.ChaosIncluded then
            chaosLoot = DeepCopyTable(LootData['TrialUpgrade'])
            chaosLoot.RarityChances = GetRarityChances(chaosLoot)
            chaosLootGenerated = true
            SetTransformingTraitsOnLoot(chaosLoot, DeepCopyTable(LootData['TrialUpgrade']))

            if loot.Name == "TrialUpgrade" then
                loot.Name = "ZeusUpgrade"
            end
        end
    end
    baseFunc(loot, args)
    if chaosLoot then
        local chaosChance = 1.0 / 15
        local chaosBoonsToAdd = {}
        local boonChoices = #loot.UpgradeOptions
        for i = 1, boonChoices do
            if RandomChance(chaosChance) then
                local nonChaosBoonRemoved = RemoveRandomValue(loot.UpgradeOptions)
                table.insert(chaosBoonsToAdd, RemoveRandomValue(chaosLoot.UpgradeOptions))
            end
        end
        for i, chaosBoon in pairs(chaosBoonsToAdd) do
            table.insert(loot.UpgradeOptions, chaosBoon)
        end
        loot.UpgradeOptions = CollapseTable(loot.UpgradeOptions)
    end
end, Boonanza)

ModUtil.WrapBaseFunction("GetEligibleUpgrades", function( baseFunc, upgradeOptions, lootData, upgradeChoiceData )
    if Boonanza.Config.Enabled and (lootData.GodLoot or IsRandomizedLoot(lootData)) then
        if Boonanza.Config.FullRandom then
            local linkedUpgradeKeys = {}
            for k,v in pairs(Boonanza.ConcatLinkedUpgrades) do
                table.insert(linkedUpgradeKeys, k)
            end
            upgradeChoiceData.Traits = ConcatTableValues(
                ConcatTableValues(
                    Boonanza.ConcatTraits),
                    linkedUpgradeKeys
            )
            upgradeChoiceData.Consumables = Boonanza.ConcatConsumables
            upgradeChoiceData.LinkedUpgrades = {}
            upgradeChoiceData.WeaponUpgrades = Boonanza.ConcatWeaponUpgrades
        else
            upgradeChoiceData.Traits = Boonanza.ConcatTraits
            upgradeChoiceData.WeaponUpgrades = Boonanza.ConcatWeaponUpgrades
            upgradeChoiceData.Consumables = Boonanza.ConcatConsumables
            upgradeChoiceData.LinkedUpgrades = Boonanza.ConcatLinkedUpgrades
        end
    end

    return baseFunc(upgradeOptions, lootData, upgradeChoiceData)
end, Boonanza)

ModUtil.WrapBaseFunction( "SetupMap", function(baseFunc)
    LoadPackages({Names = {
        "ZeusUpgrade",
        "PoseidonUpgrade",
        "AthenaUpgrade",
        "AphroditeUpgrade",
        "ArtemisUpgrade",
        "AresUpgrade",
        "DionysusUpgrade",
        "HermesUpgrade",
        "DemeterUpgrade",
        "Chaos"
    }})
    return baseFunc()
end, Boonanza)