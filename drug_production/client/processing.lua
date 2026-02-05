local stageZones = {}

local function playScenario(name, duration)
    TaskStartScenarioInPlace(cache.ped, name, 0, true)
    Wait(duration)
    ClearPedTasks(cache.ped)
end

RegisterNetEvent('drug_production:client:startStage', function(payload)
    local zoneName = ('process_%s_%s'):format(payload.drug, payload.stage)
    local check = Config.SkillChecks[payload.drug]

    local passed = true
    if check and #check > 0 then
        passed = lib.skillCheck(check, { 'w', 'a', 's', 'd' })
    end

    if not passed then
        TriggerServerEvent('drug_production:server:processResult', payload, false)
        return
    end

    if lib.progressBar({
        duration = payload.duration,
        label = payload.label,
        canCancel = true,
        disable = { move = true, combat = true },
        anim = { scenario = 'WORLD_HUMAN_STAND_MOBILE' }
    }) then
        playScenario('PROP_HUMAN_BUM_BIN', 1200)
        TriggerServerEvent('drug_production:server:processResult', payload, true)
    else
        TriggerServerEvent('drug_production:server:processResult', payload, false)
    end

    if stageZones[zoneName] then
        stageZones[zoneName] = nil
    end
end)

RegisterNetEvent('drug_production:client:registerProcessZones', function(data)
    for _, zone in ipairs(data) do
        local zoneName = ('process_%s_%s'):format(zone.drug, zone.stage)
        if stageZones[zoneName] then goto continue end

        stageZones[zoneName] = exports.ox_target:addSphereZone({
            coords = zone.coords,
            radius = 1.6,
            options = {
                {
                    name = zoneName,
                    icon = 'fa-solid fa-flask',
                    label = zone.label,
                    onSelect = function()
                        local amount = lib.inputDialog('Production batch', {
                            { type = 'number', label = 'Quantité batch', min = 1, max = Config.DefaultBatchLimit, default = 1 }
                        })

                        if not amount then return end

                        TriggerServerEvent('drug_production:server:startStage', {
                            labId = zone.labId,
                            drug = zone.drug,
                            stage = zone.stage,
                            batch = amount[1]
                        })
                    end
                }
            }
        })
        ::continue::
    end
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    TriggerServerEvent('drug_production:server:requestProcessZones')
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('drug_production:server:requestProcessZones')
end)
