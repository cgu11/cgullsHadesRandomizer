--[[
    EveryBoonInOne
    Authors:
      cgull (Discord: cgull#4469)

    This mod makes every boon (non hermes/chaos) regardless of god contain
    boons from all 8 Olympians. Oops!
]]
ModUtil.RegisterMod("EveryBoonInOne")

local config = {
    Enabled = true,
}
EveryBoonInOne.Config = config

EveryBoonInOne.GodLootList = {
    "ZeusUpgrade",
    "AresUpgrade",
    "ArtemisUpgrade",
    "AphroditeUpgrade",
    "DionysusUpgrade",
    "AthenaUpgrade",
    "PoseidonUpgrade",
    "DemeterUpgrade",
}

local function ConcatLootTable(lootList, tableName)
    output = {}
    for i, lootName in ipairs(lootList) do
        tableToInsert = LootData[lootName][tableName]
        for i, thingToInsert in ipairs(tableToInsert) do
            table.insert(output, thingToInsert)
        end
    end
    return output
end

EveryBoonInOne.ConcatTraits = ConcatLootTable(EveryBoonInOne.GodLootList, "Traits")
EveryBoonInOne.ConcatConsumables = ConcatLootTable(EveryBoonInOne.GodLootList, "Consumables")
EveryBoonInOne.ConcatWeaponUpgrades = ConcatLootTable(EveryBoonInOne.GodLootList, "WeaponUpgrades")
EveryBoonInOne.ConcatLinkedUpgrades = ConcatLootTable(EveryBoonInOne.GodLootList, "LinkedUpgrades")

local function GeneratePriorityUpgrades()
    output = {}
    for i = 1, 4 do
        selectedGodLoot = GetRandomValue(EveryBoonInOne.GodLootList)
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

ModUtil.WrapBaseFunction("GetPriorityDependentTraits", function( baseFunc, lootData )
    lootData.LinkedUpgrades = EveryBoonInOne.ConcatLinkedUpgrades
    allPriorityDependentTraits = baseFunc(lootData)
    if #allPriorityDependentTraits > 1 then
        return {
            GetRandomValue(allPriorityDependentTraits)
        }
    else
        return allPriorityDependentTraits
    end
end, EveryBoonInOne)

ModUtil.WrapBaseFunction("SetTraitsOnLoot", function( baseFunc, loot )
    if loot.GodLoot then
        loot.PriorityUpgrades = GeneratePriorityUpgrades()
    end
    baseFunc(loot)
end, EveryBoonInOne)

ModUtil.WrapBaseFunction("GetEligibleUpgrades", function( baseFunc, upgradeOptions, lootData, upgradeChoiceData )
    if lootData.GodLoot then
        upgradeChoiceData.Traits = EveryBoonInOne.ConcatTraits
        upgradeChoiceData.WeaponUpgrades = EveryBoonInOne.ConcatWeaponUpgrades
        upgradeChoiceData.Consumables = EveryBoonInOne.ConcatConsumables
        upgradeChoiceData.LinkedUpgrades = EveryBoonInOne.ConcatLinkedUpgrades
    end

    return baseFunc(upgradeOptions, lootData, upgradeChoiceData)
end, EveryBoonInOne)