local QBCore = exports['qb-core']:GetCoreObject()
local housePlants = {}
local insideHouse = false
local currentHouse = nil
local plantSpawned = false

DrawText3Ds = function(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)

    local factor = (string.len(text)) / 370

    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

RegisterNetEvent('qb-weed:client:getHousePlants', function(house)
    QBCore.Functions.TriggerCallback('qb-weed:server:getBuildingPlants', function(plants)
        currentHouse = house
        housePlants[currentHouse] = plants
        insideHouse = true

        spawnHousePlants()
    end, house)
end)

function spawnHousePlants()
    CreateThread(function()
        if not plantSpawned then
            for k, _ in pairs(housePlants[currentHouse]) do
                local plantData = {
                    plantCoords = {
                        x = json.decode(housePlants[currentHouse][k].coords).x,
                        y = json.decode(housePlants[currentHouse][k].coords).y,
                        z = json.decode(housePlants[currentHouse][k].coords).z
                    },
                    plantProp = joaat(QBWeed.Plants[housePlants[currentHouse][k].sort]["stages"][housePlants[currentHouse][k].stage])
                }

                local plantProp = CreateObject(plantData["plantProp"], plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"], false, false, false)

                while not plantProp do
                    Wait(0)
                end

                PlaceObjectOnGroundProperly(plantProp)

                Wait(10)

                FreezeEntityPosition(plantProp, true)
                SetEntityAsMissionEntity(plantProp, false, false)
            end

            plantSpawned = true
        end
    end)
end

function despawnHousePlants()
    CreateThread(function()
        if plantSpawned then
            for k, _ in pairs(housePlants[currentHouse]) do
                local plantData = {
                    ["plantCoords"] = {
                        ["x"] = json.decode(housePlants[currentHouse][k].coords).x,
                        ["y"] = json.decode(housePlants[currentHouse][k].coords).y,
                        ["z"] = json.decode(housePlants[currentHouse][k].coords).z
                    }
                }

                for _, stage in pairs(QBWeed.Plants[housePlants[currentHouse][k].sort]["stages"]) do
                    local closestPlant = GetClosestObjectOfType(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"], 3.5, joaat(stage), false, false, false)
                    
                    if closestPlant ~= 0 then
                        DeleteObject(closestPlant)
                    end
                end
            end

            plantSpawned = false
        end
    end)
end

local ClosestTarget = 0

CreateThread(function()
    while true do
        Wait(0)

        if insideHouse then
            if plantSpawned then
                for k, _ in pairs(housePlants[currentHouse]) do
                    local gender = "M"

                    if housePlants[currentHouse][k].gender == "woman" then
                        gender = "F"
                    end

                    local plantData = {
                        ["plantCoords"] = {
                            ["x"] = json.decode(housePlants[currentHouse][k].coords).x,
                            ["y"] = json.decode(housePlants[currentHouse][k].coords).y,
                            ["z"] = json.decode(housePlants[currentHouse][k].coords).z
                        },
                        ["plantStage"] = housePlants[currentHouse][k].stage,
                        ["plantProp"] = joaat(QBWeed.Plants[housePlants[currentHouse][k].sort]["stages"][housePlants[currentHouse][k].stage]),
                        ["plantSort"] = {
                            ["name"] = housePlants[currentHouse][k].sort,
                            ["label"] = QBWeed.Plants[housePlants[currentHouse][k].sort]["label"],
                        },
                        ["plantStats"] = {
                            ["food"] = housePlants[currentHouse][k].food,
                            ["health"] = housePlants[currentHouse][k].health,
                            ["progress"] = housePlants[currentHouse][k].progress,
                            ["stage"] = housePlants[currentHouse][k].stage,
                            ["highestStage"] = QBWeed.Plants[housePlants[currentHouse][k].sort]["highestStage"],
                            ["gender"] = gender,
                            ["plantId"] = housePlants[currentHouse][k].plantid
                        }
                    }

                    local plyDistance = #(GetEntityCoords(cache.ped) - vec3(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"]))

                    if plyDistance < 0.8 then
                        ClosestTarget = k

                        if plantData["plantStats"]["health"] > 0 then
                            if plantData["plantStage"] ~= plantData["plantStats"]["highestStage"] then
                                DrawText3Ds(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"], Lang:t('text.sort') .. plantData["plantSort"]["label"] .. '~w~ [' .. plantData["plantStats"]["gender"] .. '] | ' .. Lang:t('text.nutrition') .. ' ~b~' .. plantData["plantStats"]["food"] .. '% ~w~ | ' .. Lang:t('text.health') .. ' ~b~' .. plantData["plantStats"]["health"] .. '%')
                            else
                                DrawText3Ds(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"] + 0.2, Lang:t('text.harvest_plant'))
                                DrawText3Ds(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"],plantData["plantCoords"]["z"], Lang:t('text.sort') .. ' ~g~' .. plantData["plantSort"]["label"] .. '~w~ [' .. plantData["plantStats"]["gender"] .. '] | ' .. Lang:t('text.nutrition') .. ' ~b~' .. plantData["plantStats"]["food"] .. '% ~w~ | ' .. Lang:t('text.health') .. ' ~b~' .. plantData["plantStats"]["health"] .. '%')

                                if IsControlJustPressed(0, 38) then
                                    if lib.progressCircle({
                                        duration = 8000,
                                        position = 'bottom',
                                        label = Lang:t('text.harvesting_plant'),
                                        useWhileDead = false,
                                        canCancel = true,
                                        disable = {
                                            move = true,
                                            car = true,
                                            mouse = false,
                                            combat = true
                                        },
                                        anim = {
                                            dict = "amb@world_human_gardener_plant@male@base",
                                            clip = "base"
                                        }
                                    }) then
                                        ClearPedTasks(cache.ped)

                                        local amount = math.random(1, 6)

                                        if plantData["plantStats"]["gender"] == "M" then
                                            amount = math.random(1, 2)
                                        end

                                        TriggerServerEvent('qb-weed:server:harvestPlant', currentHouse, amount, plantData["plantSort"]["name"], plantData["plantStats"]["plantId"])
                                    else
                                        ClearPedTasks(cache.ped)

                                        lib.notify({ description = Lang:t("error.process_canceled"), type = 'error' })
                                    end
                                end
                            end
                        elseif plantData["plantStats"]["health"] == 0 then
                            DrawText3Ds(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"], Lang:t('error.plant_has_died'))

                            if IsControlJustPressed(0, 38) then
                                if lib.progressCircle({
                                    duration = 8000,
                                    position = 'bottom',
                                    label = Lang:t('text.removing_the_plant'),
                                    useWhileDead = false,
                                    canCancel = true,
                                    disable = {
                                        move = true,
                                        car = true,
                                        mouse = false,
                                        combat = true
                                    },
                                    anim = {
                                        dict = "amb@world_human_gardener_plant@male@base",
                                        clip = "base"
                                    }
                                }) then
                                    ClearPedTasks(cache.ped)

                                    TriggerServerEvent('qb-weed:server:removeDeathPlant', currentHouse, plantData["plantStats"]["plantId"])
                                else
                                    ClearPedTasks(cache.ped)

                                    lib.notify({ description = Lang:t("error.process_canceled"), type = 'error' })
                                end
                            end
                        end
                    end
                end
            end
        end

        if not insideHouse then
            Wait(5000)
        end
    end
end)

RegisterNetEvent('qb-weed:client:leaveHouse', function()
    despawnHousePlants()

    SetTimeout(1000, function()
        if currentHouse ~= nil then
            insideHouse = false
            housePlants[currentHouse] = nil
            currentHouse = nil
        end
    end)
end)

RegisterNetEvent('qb-weed:client:refreshHousePlants', function(house)
    if currentHouse ~= nil and currentHouse == house then
        despawnHousePlants()

        SetTimeout(100, function()
            QBCore.Functions.TriggerCallback('qb-weed:server:getBuildingPlants', function(plants)
                currentHouse = house
                housePlants[currentHouse] = plants

                spawnHousePlants()
            end, house)
        end)
    end
end)

RegisterNetEvent('qb-weed:client:refreshPlantStats', function()
    if insideHouse then
        despawnHousePlants()

        SetTimeout(100, function()
            QBCore.Functions.TriggerCallback('qb-weed:server:getBuildingPlants', function(plants)
                housePlants[currentHouse] = plants

                spawnHousePlants()
            end, currentHouse)
        end)
    end
end)

RegisterNetEvent('qb-weed:client:placePlant', function(type, item)
    local plyCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0, 0.75, 0)
    local plantData = {
        ["plantCoords"] = {
            ["x"] = plyCoords.x,
            ["y"] = plyCoords.y,
            ["z"] = plyCoords.z
        },
        ["plantModel"] = QBWeed.Plants[type]["stages"]["stage-a"],
        ["plantLabel"] = QBWeed.Plants[type]["label"]
    }
    local ClosestPlant = 0

    for _, v in pairs(QBWeed.Props) do
        if ClosestPlant == 0 then
            ClosestPlant = GetClosestObjectOfType(plyCoords.x, plyCoords.y, plyCoords.z, 0.8, joaat(v), false, false, false)
        end
    end

    if currentHouse ~= nil then
        if ClosestPlant == 0 then
            LocalPlayer.state:set("inv_busy", true, true)

            if lib.progressCircle({
                duration = 8000,
                position = 'bottom',
                label = Lang:t('text.planting'),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    mouse = false,
                    combat = true
                },
                anim = {
                    dict = "amb@world_human_gardener_plant@male@base",
                    clip = "base"
                }
            }) then
                ClearPedTasks(cache.ped)

                TriggerServerEvent('qb-weed:server:placePlant', json.encode(plantData["plantCoords"]), type, currentHouse)
                TriggerServerEvent('qb-weed:server:removeSeed', item.slot, type)
            else
                ClearPedTasks(cache.ped)

                lib.notify({ description = Lang:t("error.process_canceled"), type = 'error' })

                LocalPlayer.state:set("inv_busy", false, true)
            end
        else
            lib.notify({ description = Lang:t("error.cant_place_here"), type = 'error' })
        end
    else
        lib.notify({ description = Lang:t("error.not_safe_here"), type = 'error' })
    end
end)

RegisterNetEvent('qb-weed:client:foodPlant', function()
    if currentHouse ~= nil then
        if ClosestTarget ~= 0 then
            local gender = "M"

            if housePlants[currentHouse][ClosestTarget].gender == "woman" then
                gender = "F"
            end

            local plantData = {
                ["plantCoords"] = {
                    ["x"] = json.decode(housePlants[currentHouse][ClosestTarget].coords).x,
                    ["y"] = json.decode(housePlants[currentHouse][ClosestTarget].coords).y,
                    ["z"] = json.decode(housePlants[currentHouse][ClosestTarget].coords).z
                },
                ["plantStage"] = housePlants[currentHouse][ClosestTarget].stage,
                ["plantProp"] = joaat(QBWeed.Plants[housePlants[currentHouse][ClosestTarget].sort]["stages"][housePlants[currentHouse][ClosestTarget].stage]),
                ["plantSort"] = {
                    ["name"] = housePlants[currentHouse][ClosestTarget].sort,
                    ["label"] = QBWeed.Plants[housePlants[currentHouse][ClosestTarget].sort]["label"]
                },
                ["plantStats"] = {
                    ["food"] = housePlants[currentHouse][ClosestTarget].food,
                    ["health"] = housePlants[currentHouse][ClosestTarget].health,
                    ["progress"] = housePlants[currentHouse][ClosestTarget].progress,
                    ["stage"] = housePlants[currentHouse][ClosestTarget].stage,
                    ["highestStage"] = QBWeed.Plants[housePlants[currentHouse][ClosestTarget].sort]["highestStage"],
                    ["gender"] = gender,
                    ["plantId"] = housePlants[currentHouse][ClosestTarget].plantid
                }
            }
            local plyDistance = #(GetEntityCoords(cache.ped) - vec3(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"]))

            if plyDistance < 1.0 then
                if plantData["plantStats"]["food"] == 100 then
                    QBCore.Functions.Notify(Lang:t('error.not_need_nutrition'), 'error', 3500)
                else
                    LocalPlayer.state:set("inv_busy", true, true)

                    if lib.progressCircle({
                        duration = math.random(4000, 8000),
                        position = 'bottom',
                        label = Lang:t('text.feeding_plant'),
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            move = true,
                            car = true,
                            mouse = false,
                            combat = true
                        },
                        anim = {
                            dict = "timetable@gardener@filling_can",
                            clip = "gar_ig_5_filling_can"
                        }
                    }) then
                        ClearPedTasks(cache.ped)

                        local newFood = math.random(40, 60)

                        TriggerServerEvent('qb-weed:server:foodPlant', currentHouse, newFood, plantData["plantSort"]["name"], plantData["plantStats"]["plantId"])
                    else
                        ClearPedTasks(cache.ped)

                        LocalPlayer.state:set("inv_busy", false, true)

                        lib.notify({ description = Lang:t("error.process_canceled"), type = 'error' })
                    end
                end
            else
                lib.notify({ description = Lang:t("error.cant_place_here"), type = 'error' })
            end
        else
            lib.notify({ description = Lang:t("error.not_safe_here"), type = 'error' })
        end
    end
end)