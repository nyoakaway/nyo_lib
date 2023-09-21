lib.events = {}

--- ================================================================================================ ---
--- [ Tunnel Events ] ============================================================================== ---
--- ================================================================================================ ---

SafeEvents = {}
RPC        = {}

local RegisterEvent = RegisterNetEvent
local rpc = {}
local safe_events   = {}
local safe_handlers = {}
local rpc_handlers  = {}
local rpc_requests  = {}
local registered_stop_events = {}
local registered_stop_rpc = {}

if IsServer then

    RegisterNetEvent('nyo_lib:safe_events', function(info, ...)
        -- console.table({info, params})
        local params = {...}
        local source = source
        --local player = Player(source).state
        local name = info.name
        -- local _token = source..GetPlayerName(source)..NetworkGetNetworkIdFromEntity(GetPlayerPed(source))
        -- local safe_token = Token.stringEncrypt(_token, 'nfw')
        console.debug('^3[ SAFE EVENTS ] ^7 Received event '..name.. ' from '..source)
        if lib_config.debugSpecial then
            console.table({info, params}, 1)
        end
        --if safe_token == token  then
            if safe_handlers[name] then
                for k,v in pairs(safe_handlers[name]) do
                    CreateThread(function()
                        if v then
                            v(source, table.unpack(params))
                        end
                    end)
                end
            end
        --else
        --    console.debug('^3[ SAFE EVENTS ] ^7 Invalid token. Event: '..name.. ' | Source: '..source)
        --end
    end)

    safe_events.triggerClient = function(name, src, ...)
        console.debug('^3[ SAFE EVENTS ] ^7 Triggering client event '..name..' | '..src)
        if src == -1 then
            for k,v in pairs(GetPlayers()) do
                TriggerClientEvent('nyo_lib:safe_events', v, { name = name }, {...} )
            end
        else
            TriggerClientEvent('nyo_lib:safe_events', src, { name = name }, {...} )
        end
    end

else
    
    RegisterNetEvent('nyo_lib:safe_events', function(info, params)
        local name = info.name
        console.debug('^3[ SAFE EVENTS ] ^7 Received event '..name)
        if lib_config.debugSpecial then
            console.table({info, params}, 1)
        end
        --if token == LocalPlayer.state['ريزيتس حار حقًا ونيو به وحدة رائعة passa nem wifi aqui viu !'] then
            if safe_handlers[name] then
                for k,v in pairs(safe_handlers[name]) do
                    CreateThread(function()
                        if v then
                            v(table.unpack(params))
                        end
                    end)
                end
            end
        --else        
        --    console.debug('^3[ SAFE EVENTS ] ^7 Invalid token. Event: '..name)
        --end
    end)

    safe_events.triggerServer = function(name, ...)
        local params = {...}
        CreateThread(function()
            -- while PlayerPedId() == 0 do
            --     Wait(100)
            -- end
            print(name)
            print(params)
            print(json.encode(params))
            console.debug('^3[ SAFE EVENTS ] ^7 Triggering server event '..name)
            TriggerServerEvent('nyo_lib:safe_events', { name = name }, table.unpack(params))
        end)
    end

end

safe_events.register = function(name, handler)
    if not safe_handlers[name] then
        safe_handlers[name] = {}
    end
    local id = #safe_handlers[name] + 1
    safe_handlers[name][id] = handler
    local module = cache.resource--lib.getModuleByTraceback()
    if module ~= "@nfw" then
        if not registered_stop_events[module] then
            console.debug('^3[ SAFE EVENTS ] ^7 Registering event '..name)
            registered_stop_events[module] = {}
            registered_stop_events[module][#registered_stop_events[module] + 1] = {name = name, id = id}
            -- lib.onModuleStop(module, function()
            --     for k,v in pairs(registered_stop_events[module]) do
            --         SafeEvents.remove(v.name, v.id)
            --     end
            --     registered_stop_events[module] = nil
            -- end)
        else
            registered_stop_events[module][#registered_stop_events[module] + 1] = {name = name, id = id}
        end
    end
    return id
end

safe_events.remove = function(name, id)
    if name and safe_handlers[name] and id then
        console.debug('^3[ SAFE EVENTS ] ^7 Removing event '..name)
        safe_handlers[name][id] = nil
    end
end

setmetatable(SafeEvents, {
    __index = function(t,k)
        return safe_events[k]
    end,

    __newindex = function(t,k,v)
        return false
    end,

    __call = function(t, ...)

    end,
    __metatable = 'SAI DAQUI, TA DOIDAO?'

})

rpc.addHandler = function(name, func)
    if not rpc_handlers[name] then
        local module = cache.resource--lib.getModuleByTraceback()
        if module ~= "@nfw" then
            if not registered_stop_rpc[module] then
                registered_stop_rpc[module] = {}
                registered_stop_rpc[module][#registered_stop_rpc[module] + 1] = name
                -- lib.onModuleStop(module, function()
                --     for k,v in pairs(registered_stop_rpc[module]) do
                --         RPC.removeHandler(v)
                --     end
                --     registered_stop_rpc[module] = nil
                -- end)
            else
                registered_stop_rpc[module][#registered_stop_rpc[module] + 1] = name
            end
        end
        rpc_handlers[name] = func
    end
end

rpc.removeHandler = function(name)
    rpc_handlers[name] = nil
end

if IsServer then
    rpc.triggerCallback = function(name, cb, src, ...)
        console.debug('^3[ RPC ] ^7 Triggering callback '..name..' | '..src)
        local id = #rpc_requests + 1
        rpc_requests[id] = { callback = cb }
        SafeEvents.triggerClient('nyo_lib:rpc:request', src, { name = name, id = id }, ...)
    end

    rpc.trigger = function(name, src, ...)
        local id = #rpc_requests + 1
        local p = promise.new()
        rpc_requests[id] = { promise = p }
        SafeEvents.triggerClient('nyo_lib:rpc:request', src, { name = name, id = id }, ...)
        local res = Citizen.Await(p)
        if res.err then
            error(res.err)
        end
        return table.unpack(res)
    end

    SafeEvents.register('nyo_lib:rpc:request', function(src, info, ...)
        local name, id = info.name, info.id
        if rpc_handlers[name] then
            SafeEvents.triggerClient('nyo_lib:rpc:response', src, info, rpc_handlers[name](src, ...))
        else
            info.err = 'Invalid request name'
            SafeEvents.triggerClient('nyo_lib:rpc:response', src, info)
        end
    end)

    SafeEvents.register('nyo_lib:rpc:response', function(src, info, ...)
        local name, id, err = info.name, info.id, info.err
        if rpc_requests[id] then
            local callback, promise = rpc_requests[id].callback, rpc_requests[id].promise
            if err then
                if callback then
                    error(err)
                end
                if promise then
                    promise:resolve(info)
                end
            else
                if callback then
                    return callback(...)
                end
                if promise then
                    promise:resolve({...})
                end
            end
        else
            error('RPC request with id '..id..' not found')
        end
    end)

else
    rpc.triggerCallback = function(name, cb, ...)
        local id = #rpc_requests + 1
        rpc_requests[id] = { callback = cb }
        SafeEvents.triggerServer('nyo_lib:rpc:request', { name = name, id = id }, ...)
    end

    rpc.trigger = function(name, ...)
        local id = #rpc_requests + 1
        local p = promise.new()
        rpc_requests[id] = { promise = p }
        SafeEvents.triggerServer('nyo_lib:rpc:request', { name = name, id = id }, ...)
        local res = Citizen.Await(p)
        if res.err then
            error(res.err)
        end
        return table.unpack(res)
    end

    SafeEvents.register('nyo_lib:rpc:request', function(info, ...)
        local name, id = info.name, info.id
        if rpc_handlers[name] then
            SafeEvents.triggerServer('nyo_lib:rpc:response', info, rpc_handlers[name](...))
        else
            info.err = 'Invalid request name'
            SafeEvents.triggerServer('nyo_lib:rpc:response', info)
        end
    end)

    SafeEvents.register('nyo_lib:rpc:response', function(info, ...)
        local name, id, err = info.name, info.id, info.err
        if rpc_requests[id] then
            local callback, promise = rpc_requests[id].callback, rpc_requests[id].promise
            if err then
                if callback then
                    error(err)
                end
                if promise then
                    promise:resolve(info)
                end
            else
                if callback then
                    return callback(...)
                end
                if promise then
                    promise:resolve({...})
                end
            end
        else
            error('RPC request with id '..id..' not found')
        end
    end)
end

setmetatable(RPC, {
    __index = function(t,k)
        return rpc[k]
    end,

    __newindex = function(t,k,v)
        return false
    end,

    __call = function(t, ...)

    end,
    __metatable = 'SAI DAQUI, TA DOIDAO?'

})


-- if IsServer then 
--     SafeEvents.register('مترجم كامبريدج | الإنجليزية البرتغالية', function(source)
--         print('recebido')
--         console.debug(' Player connected on module '..source)
--         lib.onReady(function()
--             SafeEvents.triggerClient('مترجم كامبريدج | الإنجليزية البرتغالية', source)
--         end)
--     end)
-- end

return SafeEvents, RPC