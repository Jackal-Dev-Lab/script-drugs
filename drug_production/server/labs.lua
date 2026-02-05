local intrusionLocks = {}
local activeIntruders = {}

local function ensureTables()
    MySQL.query([[CREATE TABLE IF NOT EXISTS drug_labs (
        id INT PRIMARY KEY,
        gang_id INT NULL,
        gang_name VARCHAR(100) NULL,
        expires_at INT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )]])

    for labId in pairs(Config.Labs) do
        MySQL.insert('INSERT IGNORE INTO drug_labs (id) VALUES (?)', { labId })
    end
end

local function getLabState(labId)
    local row = MySQL.single.await('SELECT * FROM drug_labs WHERE id = ?', { labId })
    if not row then return nil end

    if row.expires_at and row.expires_at <= os.time() then
        MySQL.update.await('UPDATE drug_labs SET gang_id = NULL, gang_name = NULL, expires_at = NULL WHERE id = ?', { labId })
        row.gang_id, row.gang_name, row.expires_at = nil, nil, nil
    end

    return row
end

local function setLabOwner(labId, gang)
    local expiresAt = os.time() + (Config.LabDurationHours * 3600)
    MySQL.update.await('UPDATE drug_labs SET gang_id = ?, gang_name = ?, expires_at = ? WHERE id = ?', {
        gang.id, gang.name, expiresAt, labId
    })

    return expiresAt
end

local function canUseLab(source, labId)
    local gang = GangService.getPlayerGang(source)
    local state = getLabState(labId)
    if not state then return false, 'Lab introuvable', nil end
    if not gang then return false, 'Vous devez être dans un gang', state end

    if state.gang_id and state.gang_id == gang.id then
        return true, 'owner', state
    end

    local intruder = activeIntruders[source]
    if intruder and intruder.labId == labId and intruder.expiresAt > os.time() then
        return true, 'intruder', state
    end

    return false, 'Accès refusé', state
end

RegisterNetEvent('drug_production:server:purchaseLab', function(labId)
    local src = source
    local lab = Config.Labs[labId]
    if not lab then return end
    if not Security.validatePosition(src, lab.entry, 5.0) then return end

    local gang = GangService.getPlayerGang(src)
    if not gang then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Tu dois avoir un gang.' })
        return
    end

    local cd = ('buy_%s'):format(labId)
    local onCd, remaining = Security.isOnCooldown(src, cd, Config.Cooldowns.purchase)
    if onCd then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Cooldown: %ss'):format(remaining) })
        return
    end

    local state = getLabState(labId)
    if state and state.gang_id and state.expires_at and state.expires_at > os.time() then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Lab déjà contrôlé.' })
        return
    end

    if not GangService.hasGangCash(gang.id, Config.LabPurchasePrice) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Caisse gang insuffisante.' })
        return
    end

    if not GangService.removeGangCash(gang.id, Config.LabPurchasePrice) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Paiement gang refusé.' })
        return
    end

    local expiresAt = setLabOwner(labId, gang)
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = ('Lab acheté. Expire dans %sh'):format(Config.LabDurationHours)
    })

    Security.log(src, 'lab_purchase', ('lab=%s gang=%s expires=%s'):format(labId, gang.name, expiresAt))
end)

RegisterNetEvent('drug_production:server:tryIntrusion', function(labId, passed)
    local src = source
    local lab = Config.Labs[labId]
    if not lab then return end
    if not Security.validatePosition(src, lab.intrusionZone, 5.0) then return end

    local gang = GangService.getPlayerGang(src)
    if not gang then return end

    local state = getLabState(labId)
    if not state or not state.gang_id then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Lab sans propriétaire.' })
        return
    end

    if state.gang_id == gang.id then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Vous contrôlez déjà ce lab.' })
        return
    end

    if intrusionLocks[labId] then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Intrusion déjà en cours.' })
        return
    end

    local cd = ('intrusion_%s'):format(labId)
    local onCd = Security.isOnCooldown(src, cd, Config.Cooldowns.intrusion)
    if onCd then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Intrusion en cooldown.' })
        return
    end

    intrusionLocks[labId] = src

    if passed then
        activeIntruders[src] = {
            labId = labId,
            expiresAt = os.time() + (Config.IntrusionAccessMinutes * 60),
            gangId = gang.id
        }

        TriggerClientEvent('drug_production:client:enterLab', src, labId)
        GangService.notifyGang(state.gang_id, 'drug_production:client:intrusionAlert', labId)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Intrusion réussie.' })
        Security.log(src, 'intrusion_success', ('lab=%s owner_gang=%s'):format(labId, state.gang_name or 'unknown'))
    else
        if math.random(100) <= Config.IntrusionFailureAlertChance then
            GangService.notifyGang(state.gang_id, 'drug_production:client:intrusionAlert', labId)
        end

        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Intrusion échouée.' })
        Security.log(src, 'intrusion_failed', ('lab=%s'):format(labId))
    end

    SetTimeout(5000, function()
        if intrusionLocks[labId] == src then
            intrusionLocks[labId] = nil
        end
    end)
end)

RegisterNetEvent('drug_production:server:requestLabAccess', function(labId)
    local src = source
    local lab = Config.Labs[labId]
    if not lab then return end
    if not Security.validatePosition(src, lab.entry, 5.0) then return end

    local allowed, reason = canUseLab(src, labId)
    if not allowed then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = reason })
        return
    end

    TriggerClientEvent('drug_production:client:enterLab', src, labId)
end)

RegisterNetEvent('drug_production:server:leaveLab', function(labId)
    local src = source
    local lab = Config.Labs[labId]
    if not lab then return end
    if not Security.validatePosition(src, lab.exit, 8.0) then return end

    TriggerClientEvent('drug_production:client:exitLab', src)
end)

RegisterNetEvent('drug_production:server:forceExitLab', function(labId)
    local src = source
    local lab = Config.Labs[labId]
    if not lab then return end

    TriggerClientEvent('drug_production:client:exitLab', src)
end)

RegisterNetEvent('drug_production:server:validateSpawnLab', function()
    local src = source
    local state = Player(src).state.drug_lab
    if not state then return end

    TriggerClientEvent('drug_production:client:exitLab', src)
    Security.log(src, 'forced_exit_on_spawn', ('lab=%s'):format(state))
end)

AddEventHandler('playerDropped', function()
    activeIntruders[source] = nil
end)

CreateThread(function()
    ensureTables()
end)

LabService = {
    canUseLab = canUseLab,
    getLabState = getLabState
}
