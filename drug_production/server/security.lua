local cooldowns = {}

Security = {}

function Security.isOnCooldown(source, key, seconds)
    cooldowns[source] = cooldowns[source] or {}
    local expiry = cooldowns[source][key]
    local now = os.time()

    if expiry and expiry > now then
        return true, expiry - now
    end

    cooldowns[source][key] = now + seconds
    return false, 0
end

function Security.getPlayerCoords(source)
    local ped = GetPlayerPed(source)
    if ped <= 0 then return nil end
    return GetEntityCoords(ped)
end

function Security.validatePosition(source, targetCoords, maxDistance)
    local coords = Security.getPlayerCoords(source)
    if not coords then return false end
    return #(coords - targetCoords) <= (maxDistance or Config.PositionValidationDistance)
end

function Security.log(source, action, context)
    local name = GetPlayerName(source) or ('src:%s'):format(source)
    print(('[drug_production] %s (%s) => %s | %s'):format(name, source, action, context or 'none'))
end

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
