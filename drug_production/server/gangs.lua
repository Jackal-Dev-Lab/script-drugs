GangService = {}

local function fetchGang(source)
    local playerGang = exports['t1ger_gangs']:GetPlayerGang(source)
    if not playerGang then return nil end

    return {
        id = playerGang.id or playerGang.gang_id,
        name = playerGang.name,
        label = playerGang.label or playerGang.name
    }
end

function GangService.getPlayerGang(source)
    return fetchGang(source)
end

function GangService.removeGangCash(gangId, amount)
    if amount <= 0 then return true end
    return exports['t1ger_gangs']:RemoveGangCash(gangId, amount)
end

function GangService.hasGangCash(gangId, amount)
    local cash = exports['t1ger_gangs']:GetGangCash(gangId)
    return cash and cash >= amount
end

function GangService.notifyGang(gangId, eventName, payload)
    local members = exports['t1ger_gangs']:GetOnlineGangMembers(gangId) or {}
    for _, src in ipairs(members) do
        TriggerClientEvent(eventName, src, payload)
    end
end
