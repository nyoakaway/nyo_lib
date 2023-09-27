lib.registerModule({}, false, function()

    print('client code started')

    -- Register Client Event
    SafeEvents.register('SafeEventBasicTeste', function(param)
        print(param)
    end)

    -- Trigger RPC CallBack
    RegisterCommand("basic_use_rpc", function()
        result = RPC.trigger('RPC-Callback')  
        print(result)
    end)

    -- Get Config
    local cfg = nyo_lib_configs['BasicConfig']
    print(json.encode(cfg))
end)