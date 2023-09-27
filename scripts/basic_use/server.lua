lib.registerModule({}, false, function()

    print('server code started')

    -- Trigger Client Event
    RegisterCommand("basic_use", function(source, args)
        SafeEvents.triggerClient('SafeEventBasicTeste', source, args[1])
    end)

    -- RPC Register
    RPC.addHandler('RPC-Callback', function(source)
        return source
    end)
end)