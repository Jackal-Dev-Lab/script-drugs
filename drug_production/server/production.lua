local pendingProcesses = {}
local cachedProcessZones = {}

local function getStage(drug, stageKey)
    local definition = Config.Recipes[drug]
    if not definition then return nil end

    for _, stage in ipairs(definition.stages) do
        if stage.key == stageKey then
            return stage
        end
    end

    return nil
end

local function calculateQuality(base, success, isOwner)
    local quality = base + math.random(-8, 8)

    if success then
        quality += Config.Quality.skillSuccessBonus
    else
        quality -= Config.Quality.skillFailPenalty
    end

    if isOwner then
        quality += Config.Quality.gangOwnedBonus
    else
        quality -= Config.Quality.stolenLabPenalty
    end

    return math.min(Config.Quality.max, math.max(Config.Quality.min, quality))
end

local function getOutputMetadata(drug, quality)
    local metadata = {
        quality = quality,
        purity = math.min(100, quality + math.random(0, 10))
    }

    if drug == 'weed' or drug == 'weed_processed' then
        local strains = { 'OG Kush', 'Purple Haze', 'Skunk #1', 'Amnesia' }
        metadata.strain = strains[math.random(#strains)]
    end

    return metadata
end

local function consumeInputs(source, inputs, multiplier)
    for item, count in pairs(inputs) do
        local removed = exports.ox_inventory:RemoveItem(source, item, count * multiplier)
        if not removed then
            return false, item
        end
    end

    return true
end

local function giveOutputs(source, outputs, multiplier, metadata)
    for item, count in pairs(outputs) do
        exports.ox_inventory:AddItem(source, item, count * multiplier, metadata)
    end
end

local function rollIncident(source, drug)
    local risk = Config.Risks[drug]
    if not risk then return end

    for kind, chance in pairs(risk) do
        if math.random(100) <= chance then
            if kind == 'policeAlert' then
                Config.PoliceAlert(source, ('Incident %s'):format(drug))
            elseif kind == 'materialLoss' then
                -- handled via failed processing branch
            else
                TriggerClientEvent('drug_production:client:processingIncident', source, kind)
            end
        end
    end
end

local function registerUseables()
    exports.ox_inventory:RegisterUsableItem('ballon_plein', function(source, item)
        if not exports.ox_inventory:RemoveItem(source, item.name, 1, nil, item.slot) then return end
        TriggerClientEvent('drug_production:client:useGasBalloon', source)
    end)
end

local function registerCrafting()
    for drug, recipe in pairs(Config.Recipes) do
        for _, stage in ipairs(recipe.stages) do
            exports.ox_inventory:RegisterCraftingRecipe({
                name = ('drug_%s_%s'):format(drug, stage.key),
                ingredients = stage.inputs,
                duration = stage.time,
                count = 1,
                metadata = { source = 'drug_production' },
                result = next(stage.outputs)
            })
        end
    end
end

local function buildProcessZones()
    cachedProcessZones = {}

    for labId, lab in pairs(Config.Labs) do
        for _, drug in ipairs(lab.allowedDrugs) do
            local recipe = Config.Recipes[drug]
            if recipe then
                for i, stage in ipairs(recipe.stages) do
                    cachedProcessZones[#cachedProcessZones + 1] = {
                        labId = labId,
                        drug = drug,
                        stage = stage.key,
                        label = ('[%s] %s'):format(lab.label, stage.label),
                        coords = vec3(
                            lab.interior.x + (i * 0.85),
                            lab.interior.y + (i * 0.2),
                            lab.interior.z
                        )
                    }
                end
            end
        end
    end
end

RegisterNetEvent('drug_production:server:startStage', function(payload)
    local src = source

    if type(payload) ~= 'table' then return end
    local stage = getStage(payload.drug, payload.stage)
    local lab = Config.Labs[payload.labId]
    if not stage or not lab then return end

    local batch = math.max(1, math.min(Config.DefaultBatchLimit, tonumber(payload.batch) or 1))

    local allowed, mode = LabService.canUseLab(src, payload.labId)
    if not allowed then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Accès labo refusé.' })
        return
    end

    local onCd = Security.isOnCooldown(src, 'process', Config.Cooldowns.process)
    if onCd then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Action trop rapide.' })
        return
    end

    for item, count in pairs(stage.inputs) do
        local itemCount = exports.ox_inventory:GetItemCount(src, item)
        if itemCount < (count * batch) then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Ingrédient manquant: %s'):format(item) })
            return
        end
    end

    local processId = ('%s:%s:%s'):format(src, payload.drug, payload.stage)
    pendingProcesses[processId] = {
        source = src,
        labId = payload.labId,
        drug = payload.drug,
        stage = payload.stage,
        batch = batch,
        ownerMode = mode,
        stageData = stage
    }

    TriggerClientEvent('drug_production:client:startStage', src, {
        id = processId,
        drug = payload.drug,
        stage = payload.stage,
        duration = stage.time * batch,
        label = ('%s x%s'):format(stage.label, batch)
    })
end)

RegisterNetEvent('drug_production:server:processResult', function(payload, success)
    local src = source
    if type(payload) ~= 'table' or not payload.id then return end

    local process = pendingProcesses[payload.id]
    if not process or process.source ~= src then return end
    pendingProcesses[payload.id] = nil

    local stage = process.stageData
    if not consumeInputs(src, stage.inputs, process.batch) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Impossible de consommer les composants.' })
        return
    end

    local quality = calculateQuality(60, success, process.ownerMode == 'owner')

    if not success then
        rollIncident(src, process.drug)
        local drugRisk = Config.Risks[process.drug] or {}
        if math.random(100) <= (drugRisk.materialLoss or 20) then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Batch perdu suite à un incident.' })
            Security.log(src, 'process_fail_loss', process.drug)
            return
        end
    end

    local metadata = getOutputMetadata(process.drug, quality)

    if process.drug == 'gas' then
        local cylinders = exports.ox_inventory:Search(src, 'slots', 'bonbonne_gaz') or {}
        local cylinder = cylinders[1]
        if not cylinder then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Aucune bonbonne valide.' })
            return
        end

        local uses = (cylinder.metadata and cylinder.metadata.uses) or 100
        local consume = 10 * process.batch
        if uses < consume then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Bonbonne vide.' })
            return
        end

        local newUses = uses - consume
        exports.ox_inventory:SetMetadata(src, cylinder.slot, {
            quality = cylinder.metadata and cylinder.metadata.quality or 100,
            uses = newUses
        })

        metadata.uses = newUses
    end

    giveOutputs(src, stage.outputs, process.batch, metadata)
    rollIncident(src, process.drug)

    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = ('Production terminée (%s) qualité %s'):format(process.drug, quality)
    })

    Security.log(src, 'process_success', ('drug=%s stage=%s batch=%s quality=%s'):format(process.drug, process.stage, process.batch, quality))
end)

RegisterNetEvent('drug_production:server:requestProcessZones', function()
    local src = source
    TriggerClientEvent('drug_production:client:registerProcessZones', src, cachedProcessZones)
end)

RegisterNetEvent('drug_production:server:applyBalloonStress', function()
    local src = source
    TriggerEvent('esx_status:remove', src, 'stress', 100000)
    Security.log(src, 'balloon_use', 'stress_down')
end)

RegisterNetEvent('drug_production:server:policeAlert', function(sourcePlayer, reason)
    Security.log(sourcePlayer or source, 'police_alert', reason)
end)

CreateThread(function()
    registerUseables()
    registerCrafting()
    buildProcessZones()
end)
