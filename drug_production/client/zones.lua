local function hasLabState()
    return LocalPlayer.state.drug_lab ~= nil
end

CreateThread(function()
    for labId, lab in pairs(Config.Labs) do
        exports.ox_target:addSphereZone({
            coords = lab.entry,
            radius = 1.8,
            options = {
                {
                    name = ('drug_lab_enter_%s'):format(labId),
                    icon = 'fa-solid fa-door-open',
                    label = ('Entrer dans %s'):format(lab.label),
                    distance = 2.0,
                    onSelect = function()
                        TriggerServerEvent('drug_production:server:requestLabAccess', labId)
                    end
                },
                {
                    name = ('drug_lab_buy_%s'):format(labId),
                    icon = 'fa-solid fa-money-bill',
                    label = ('Acheter contrôle (%s$)'):format(Config.LabPurchasePrice),
                    distance = 2.0,
                    onSelect = function()
                        TriggerServerEvent('drug_production:server:purchaseLab', labId)
                    end
                }
            }
        })

        exports.ox_target:addSphereZone({
            coords = lab.intrusionZone,
            radius = 2.2,
            options = {
                {
                    name = ('drug_lab_intrude_%s'):format(labId),
                    icon = 'fa-solid fa-user-ninja',
                    label = ('Forcer l\'entrée %s'):format(lab.label),
                    distance = 2.0,
                    onSelect = function()
                        local passed = lib.skillCheck(Config.SkillChecks.intrusion, { 'w', 'a', 's', 'd' })
                        TriggerServerEvent('drug_production:server:tryIntrusion', labId, passed)
                    end
                }
            }
        })

        exports.ox_target:addSphereZone({
            coords = lab.exit,
            radius = 1.8,
            options = {
                {
                    name = ('drug_lab_exit_%s'):format(labId),
                    icon = 'fa-solid fa-door-closed',
                    label = 'Sortir du labo',
                    canInteract = hasLabState,
                    onSelect = function()
                        TriggerServerEvent('drug_production:server:leaveLab', labId)
                    end
                }
            }
        })
    end
end)
