lib.getClosestVehiclesInfo = function(radius)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsUsing(ped)
    if not IsPedInAnyVehicle(ped) then
        veh = lib.getClosestEntity('vehicle', nil, radius, 'all')
    end
    if IsEntityAVehicle(veh) then
        local lock = GetVehicleDoorLockStatus(veh)
        local trunk = GetVehicleDoorAngleRatio(v,5)
        local x,y,z = table.unpack(GetEntityCoords(ped))
        local tuning = { GetNumVehicleMods(veh,13),GetNumVehicleMods(veh,12),GetNumVehicleMods(veh,15),GetNumVehicleMods(veh,11),GetNumVehicleMods(veh,16) }
        local vehModel = GetEntityModel(veh)
        return veh,VehToNet(veh),GetVehicleNumberPlateText(veh),vehModel,GetDisplayNameFromVehicleModel(vehModel),GetStreetNameFromHashKey(GetStreetNameAtCoord(x,y,z))
    end
end

return lib.getClosestVehiclesInfo