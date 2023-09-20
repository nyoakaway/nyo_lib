lib.nuiReady = false

registered_click_functions = {}
registered_marker_functions = {}
registered_marker_types = {}
disabled_marker_types = {false, false}
local registered_nui_callbacks   = {}
local pending_nui_messages       = {}

SafeEvents.register('مترجم كامبريدج | الإنجليزية البرتغالية', function()
    lib.loadModules()
end)


lib.registerKeyPress = function(func)
    local module = lib.getModuleByTraceback()
    registered_click_functions[module] = func
end

lib.registerMarkerFunction = function(func)
    local module = lib.getModuleByTraceback()
    registered_marker_functions[module] = func
end

lib.setMarkerType = function(type)
    local module = lib.getModuleByTraceback()
    registered_marker_types[module] = type
end

lib.disableMarkerType = function(type)
    disabled_marker_types[type] = true
end

lib.enableMarkerType = function(type)
    disabled_marker_types[type] = false
end

lib.registerInterface = function(nuiType)
    local module = lib.getModuleByTraceback()
    if lib.nuiReady then
        SendNUIMessage({
            action = 'RegisterInterface',
            moduleName = module,
            nuiType = nuiType
        })
    else
        pending_nui_messages[#pending_nui_messages + 1] = {
            action = 'RegisterInterface',
            moduleName = module,
            nuiType = nuiType
        }
    end
end

lib.openUI = function(data, keyboardFocus, cursorFocus)
    local module = lib.getModuleByTraceback()
    local info = {
        action = 'OpenUI',
        moduleName = module,
        data = data
    }
    if (keyboardFocus or keyboardFocus == nil) or (cursorFocus or cursorFocus == nil) then
        SetNuiFocus(keyboardFocus or keyboardFocus == nil, cursorFocus or cursorFocus == nil)
    end
    if lib.nuiReady then
        SendNUIMessage(info)
    else
        pending_nui_messages[#pending_nui_messages + 1] = info
    end
end

lib.closeUI = function(data)
    local module = lib.getModuleByTraceback()
    local info = {
        action = 'CloseUI',
        moduleName = module,
        data = data
    }
    if lib.nuiReady then
        SendNUIMessage(info)
    else
        pending_nui_messages[#pending_nui_messages + 1] = info
    end
end

lib.registerNUICallback = function(name,cb)
    local module = lib.getModuleByTraceback()
    RegisterNUICallback(module..'/'..name, cb)
end

lib.sendNUIMessage = function(action, data)
    local module = lib.getModuleByTraceback()
    data.action = module..'-sendMessage'
    data._action = action
    SendNUIMessage(data)
end

-- NUI Ready
RegisterNUICallback('nui-ready', function(data, cb)
    SafeEvents.triggerServer('مترجم كامبريدج | الإنجليزية البرتغالية')
    lib.nuiReady = true
    for index = 1, #pending_nui_messages do
        SendNUIMessage(pending_nui_messages[index])
    end
    pending_nui_messages = nil
    cb({})
end)

local hidingPlayers = false
local hidingVehicles = false

lib.enableHidingPlayers = function()
    local plyPed = PlayerPedId()
    if not hidingPlayers then
        hidingPlayers = true
        CreateThread(function()
            while hidingPlayers do
                for k,v in pairs(GetGamePool('CPed')) do
                    if GetEntityAlpha(v) > 0 and v ~= plyPed then
                        SetEntityAlpha(v, 0, false)
                    end
                end
                Wait(100)
            end
            for k,v in pairs(GetGamePool('CPed')) do
                ResetEntityAlpha(v)
            end
        end)
    end
end

lib.enableHidingVehicles = function()
    local plyPed = PlayerPedId()
    if not hidingVehicles then
        hidingVehicles = true
        CreateThread(function()
            local hidedEntities = {}
            while hidingVehicles do
                for k,v in pairs(GetGamePool('CVehicle')) do
                    if not hidedEntities[v] and v ~= GetVehiclePedIsIn(plyPed) then
                        SetEntityAlpha(v, 0, false)
                        hidedEntities[v] = true
                    end
                end
                Wait(100)
            end
            for k,v in pairs(GetGamePool('CVehicle')) do
                ResetEntityAlpha(v)
            end
        end)
    end
end

lib.disableHidingPlayers = function()
    hidingPlayers = false
end

lib.disableHidingVehicles = function()
    hidingVehicles = false
end

RegisterCommand("nyo_lib:setlang",function(s,args,rawC)
    if args[1] then
        lib.setCurrentLanguage(args[1])
    end
end)