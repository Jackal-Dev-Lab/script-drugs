local currentLab
local insideLab = false

local function fadeTeleport(coords)
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do Wait(50) end

    FreezeEntityPosition(cache.ped, true)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    if coords.w then
        SetEntityHeading(cache.ped, coords.w)
    end

    Wait(250)
    FreezeEntityPosition(cache.ped, false)
    DoScreenFadeIn(800)
end

RegisterNetEvent('drug_production:client:enterLab', function(labId)
    local lab = Config.Labs[labId]
    if not lab then return end

    currentLab = labId
    insideLab = true
    fadeTeleport(lab.interior)
    LocalPlayer.state:set('drug_lab', labId, true)
end)

RegisterNetEvent('drug_production:client:exitLab', function()
    if not currentLab then return end
    local lab = Config.Labs[currentLab]

    fadeTeleport(vec4(lab.entry.x, lab.entry.y, lab.entry.z, 0.0))
    insideLab = false
    LocalPlayer.state:set('drug_lab', nil, true)
    currentLab = nil
end)

RegisterNetEvent('drug_production:client:intrusionAlert', function(labId)
    local lab = Config.Labs[labId]
    if not lab then return end

    lib.notify({ type = 'error', title = 'Alerte labo', description = ('Intrusion en cours: %s'):format(lab.label) })

    local blip = AddBlipForCoord(lab.entry.x, lab.entry.y, lab.entry.z)
    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 1.2)
    SetBlipColour(blip, 1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(('ALERTE %s'):format(lab.label))
    EndTextCommandSetBlipName(blip)

    SetTimeout(30000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

CreateThread(function()
    while true do
        Wait(1500)
        if insideLab and currentLab then
            local lab = Config.Labs[currentLab]
            if #(GetEntityCoords(cache.ped) - lab.interior.xyz) > 80.0 then
                TriggerServerEvent('drug_production:server:forceExitLab', currentLab)
            end
        end
    end
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('drug_production:server:validateSpawnLab')
end)
