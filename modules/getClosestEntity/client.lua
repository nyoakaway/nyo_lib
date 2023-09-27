lib.getClosestEntity = function(type, coords, range, targets)
    local playerPed = PlayerPedId()
    local closestEntity = nil 
    local closestDistance = nil
    local targets = targets or 'all'
    local netId = nil
    if type then 
        local entities = {}
        if type == "ped" or type == 1 then 
            entities = GetGamePool("CPed")
        elseif type == "vehicle" or type == 2 then 
            entities = GetGamePool("CVehicle")
        elseif type == "object" or type == 3 then 
            entities = GetGamePool("CObject")
        end

        if coords then 
            coords = type(coords) ~= "vector3" and vector3(coords.x, coords.y, coords.z) or coords
        else 
            coords = GetEntityCoords(playerPed)
        end

        if not range then 
            range = 2.0
        end

        for _, entity in ipairs(entities) do 
            local aliveCheck = true
           
            if type == 'ped' and (entity == playerPed or (targets == 'players' and not IsPedAPlayer(entity))) then 
                aliveCheck = false
            end
            local d = #(coords - GetEntityCoords(entity))
            if aliveCheck and (not closestEntity or d < closestDistance) and d < range then 
                closestEntity = entity
                closestDistance = d
                if IsPedAPlayer(entity) then 
                    netId = nil
                    for _,player in ipairs(GetActivePlayers()) do 
                        if GetPlayerPed(player) == entity then 
                            netId = GetPlayerServerId(player)
                        end                            
                    end
                end

                if IsEntityAVehicle(entity) then 
                    netId = VehToNet(entity)
                end
            end
        end
    end
    return closestEntity, closestDistance, netId
end

return lib.getClosestEntity