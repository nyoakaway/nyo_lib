local nvec = vec3(0.0,0.0,0.0)
local CloseCoordinates = {}
plyPed = PlayerPedId()
plyCoords = GetEntityCoords(PlayerPedId())

lib.onReady(function()
    function checkPlayerPermission(perm)            
        return true          
    end

    function checkUpgrade(upgrade)
        return true
    end

    if #nyo_lib_coords > 0 then 
        CreateThread(function ()

            local function CheckMarkerPermission(playerPermissions, perm)
                if not playerPermissions then return true end
                if not perm or perm == '' or config.showMakerWithoutPermission then
                    return true
                end
                if type(perm) == 'table' then
                    for k,v in pairs(perm) do
                        if playerPermissions[v] then
                            return true
                        end
                    end
                elseif playerPermissions[perm] then
                    return true
                end
                return false
            end

            while true do
                CloseCoordinates = {}
                local textures = {}
                local usedTextures = {}
                plyCoords = GetEntityCoords(PlayerPedId())
                
                for k,v in pairs(nyo_lib_coords) do
                    local distance = #(plyCoords - v.coord)
                    local maxDistance = v.markerDistance or 10.0
                    local config = nyo_lib_configs[v.config]
                    if config.marker and config.marker.custom and config.marker.custom.active then
                        textures[#textures + 1] = config.marker.custom
                    end
                    if distance <= maxDistance then
                        if lib_config.markerDebug then
                            console.debug('^3[ MARKER ]^7 Adding close coordinates '..v.coord..' | '..v.config)
                        end
                        if ((not config.perm or config.perm == '') or checkPlayerPermission(config.perm)) and ((not v.requestUpgrade or v.requestUpgrade == '') or checkUpgrade(v.requestUpgrade)) then
                            if config.marker and config.marker.custom and config.marker.custom.active then
                                usedTextures[config.marker.custom.dict..config.marker.custom.name] = config.marker.custom
                            end
                            v.k_index = k
                            CloseCoordinates[#CloseCoordinates + 1] = v
                        end
                    end
                end

                print(json.encode(CloseCoordinates))
                for k,v in pairs(textures) do
                    if not usedTextures[v.dict..v.name] then
                        if HasStreamedTextureDictLoaded(v.dict) then
                            SetStreamedTextureDictAsNoLongerNeeded(v.dict)
                            if lib_config.markerDebug then
                                console.debug('^3[ MARKER ]^7 Removing dict '..v.dict)
                            end
                        end
                    end
                end
                for k,v in pairs(usedTextures) do
                    if not HasStreamedTextureDictLoaded(v.dict) then
                        if lib_config.markerDebug then
                            console.debug('^3[ MARKER ]^7 Loading dict '..v.dict)
                        end
                        RequestStreamedTextureDict(v.dict)
                    end
                end
                Wait(lib_config.updateCloseCoordinatesTime)
            end

        end)

        CreateThread(function()
            while true do
                local msec = lib_config.sleepMarkerTime
                for k,v in pairs(CloseCoordinates) do
                    msec = 4
                    local mconfig = nyo_lib_configs[v.config]
                    if mconfig then
                        local mtype = type(mconfig.marker)
                        if not disabled_marker_types[registered_marker_types[mconfig.type] or 1] then
                            if registered_marker_functions[mconfig.type] then
                                registered_marker_functions[mconfig.type](v, v.k_index)
                            else
                                if mtype == 'function' then
                                    mconfig.marker(v.coord, v.text)
                                elseif mtype == 'table' then
                                    local type = mconfig.marker.id
                                    local pos = v.coord
                                    local dir = mconfig.marker.direction or nvec
                                    local rot =  mconfig.marker.rotacao or nvec
                                    local scale = mconfig.marker.scale or nvec
                                    local rgba = mconfig.marker.color
                                    local bobUpAndDown = mconfig.marker.bobUpAndDown or false
                                    local faceCamera = mconfig.marker.faceCamera or false
                                    local rotate = mconfig.marker.rotation or false
                                    local drawOnEnts = mconfig.marker.drawOnEnts or false
                                    local dict = mconfig.marker.custom and mconfig.marker.custom.active and HasStreamedTextureDictLoaded(mconfig.marker.custom.dict) and mconfig.marker.custom.dict 
                                    local name = mconfig.marker.custom and mconfig.marker.custom.active and mconfig.marker.custom.name
                                    --print(type, rgba[1], rgba[2], rgba[3], rgba[4], bobUpAndDown, faceCamera, 1, rotate, dict, name, drawOnEnts)
                                    DrawMarker(2, pos, 0.0, 0.0, 0.0, rot, scale, 255, 128, 0, 50, false, true, 2, nil, nil, false)
                                    DrawMarker(type, pos, dir, rot, scale, rgba[1], rgba[2], rgba[3], rgba[4], bobUpAndDown, faceCamera, 1, rotate, dict, name, drawOnEnts)
                                elseif mconfig.text3d then
                                    DrawText3Ds(v.coord.x, v.coord.y, v.coord.z, v.text or '')
                                elseif mconfig.text2d then
                                    drawTxt2D(v.text or '', 4, 0.9, 0.5, 0.5, 255,255,255, 150)
                                end
                            end
                            if #(plyCoords - v.coord) <= (v.distance or 1.1) and IsControlJustPressed(0,mconfig.actionKey) /*and Nfw.checkPermission(mconfig.perm)*/ and not LocalPlayer.state.handCuffed and not LocalPlayer.state.blockAnim then
                                if registered_click_functions[mconfig.type] then
                                    registered_click_functions[mconfig.type](v, v.k_index)
                                    Wait(500)
                                end
                            end
                        end
                    end
                end
                Wait(msec)
            end
        end)
    end

end)