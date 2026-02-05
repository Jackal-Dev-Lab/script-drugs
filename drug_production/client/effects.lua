local function applyDrugVisual(effectName, duration)
    StartScreenEffect(effectName, 0, true)
    ShakeGameplayCam('DRUNK_SHAKE', 0.4)
    SetTimecycleModifier('spectator5')

    SetTimeout(duration, function()
        StopScreenEffect(effectName)
        ShakeGameplayCam('DRUNK_SHAKE', 0.0)
        ClearTimecycleModifier()
    end)
end

RegisterNetEvent('drug_production:client:useGasBalloon', function()
    if not lib.progressBar({
        duration = 4500,
        label = 'Inhalation du ballon',
        canCancel = true,
        disable = { move = true, combat = true },
        anim = { scenario = 'WORLD_HUMAN_SMOKING' }
    }) then
        return
    end

    applyDrugVisual('DrugsTrevorClownsFight', 20000)

    TriggerServerEvent('drug_production:server:applyBalloonStress')
end)

RegisterNetEvent('drug_production:client:processingIncident', function(kind)
    if kind == 'explosion' then
        AddExplosion(GetEntityCoords(cache.ped), 2, 0.5, true, false, 0.3)
    elseif kind == 'injury' then
        SetEntityHealth(cache.ped, math.max(110, GetEntityHealth(cache.ped) - 25))
    elseif kind == 'intoxication' then
        applyDrugVisual('DrugsMichaelAliensFight', 9000)
    end
end)
