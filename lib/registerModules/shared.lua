IsServer  = IsDuplicityVersion()

local nyo_lib_modules = {} -- Modules Registred
local nyo_lib_modules_cfg = {} -- Modules Config Registred
local nyo_lib_functions = {} -- Modules Functions Registred

nyo_lib_configs = {} -- Modules Configs Started
nyo_lib_coords = {} -- Modules Coords Started
nyo_lib_commands = {} -- Modules Commands Started
nyo_lib_modules_lang = {} -- Modules Lang Started
local current_language = 'pt-BR'

local active_modules = {}
local module_ready = false
local pending_module_on_ready_functions = {}
local module_events_ids = {}
local on_stop_events = {}
local nyo_lib_last_caller



--- @param code: function -- module code
lib.registerModule = function(dependencies, waitModuleLoad, code)
    print('iniciando registro')
    local _code_type = type(code)

    if _code_type ~= 'function' and _code_type ~= 'table' then
        error 'Second param should be a function'
    end

    local code_info = _code_type ~= 'table' and debug.getinfo(code)
    local module = code_info and code_info.source:gsub('%@@nyo_lib/scripts/', ''):gsub('%/'..(IsServer and 'server' or 'client')..'.lua','') or nfw_last_caller
    
    print('registerModule', module)
    -- if module:find('nyo_') then
    --     error('Unknown error while loading module '..module)
    -- end

    console.debug('Registering module '..module)

    if nyo_lib_modules[module] then
        error(string.format('Module "%s" is already registered',module))
    end
    
    print('register', module)
    nyo_lib_modules[module] = { code = code, extendedCodes = {}, dependencies = dependencies or {}, waitModuleLoad = waitModuleLoad }
end

lib.extendModule = function(loadPriority, code)
    local module = lib.getModuleByTraceback()

    if not code then
        code = loadPriority
        loadPriority = nil
    end

    if not nyo_lib_modules[module] then return end

    table.insert(nyo_lib_modules[module].extendedCodes, { code = code, loadPriority = loadPriority or 0 })
end

--- @param cfg: { config = {}, locs = {}, functions = {} }
lib.registerConfig = function(cfg)
    print('registerConfig')
    if type(cfg) ~= 'table' then
        error 'First parameter should be table'
    end

    local module = lib.getModuleByTraceback()

    if nyo_lib_modules_cfg[module] then
        error 'Module config is already registered'
    end

    console.debug('Registering module config '..module)

    nyo_lib_modules_cfg[module] = cfg
end

lib.registerFunctions = function(framework, object)
    local module = Nfw.getModuleByTraceback()
    local _framework = type(framework)
    local _object = type(object)

    if ( not object and _framework ~= 'function' ) or ( not object and not framework ) or ( object and _framework ~= 'string' and _object ~= 'table' and _object ~= 'function') then
        error 'Invalid parameters'
    end

    if module:find('@nyo_lib') then
        local traceback = debug.traceback()
        object = framework
        framework = traceback:gsub('(.*)functions/',''):gsub('/'..(IsServer and 'server' or 'client')..'.lua(.*)', '')
        if framework == lib_config.framework then
            console.debug('Registering global functions')
            local result = object()
            nyo_lib_functions = result
        end
    else
        if framework == lib_config.framework then
            console.debug('Registering module "'..module..'" functions')
            if _object == 'function' then
                local result = object()
                nyo_lib_functions[module] = result
            else
                nyo_lib_functions[module] = object                
            end
        end
    end
end

lib.getModuleFunctions = function()
    local module = Nfw.getModuleByTraceback()
    return nyo_lib_functions[module]
end

lib.onModuleStop = function(module, func)
    if not on_stop_events[module] then on_stop_events[module] = {} end
    on_stop_events[module][#on_stop_events[module] + 1] = func
end

RegisterCommand("teste", function(source, args)
    lib.loadModules()
end)

lib.loadModules = function()
    local modulesForLoad = {}
    for module, module_info in pairs(nyo_lib_modules) do    
        if lib_config.scripts[module] then
            console.debug('Starting module '..module)
            active_modules[module] = {}
            if nyo_lib_modules_cfg[module] then
                local cfg = nyo_lib_modules_cfg[module]
                if cfg.config then
                    for k,v in pairs(cfg.config) do
                        nyo_lib_configs[k] = v
                        nyo_lib_configs[k].type = module
                        nyo_lib_configs[k].input = module
                    end
                end
                if cfg.commands and not IsServer then
                    nyo_lib_commands[module] = {}
                    for k,v in pairs(cfg.commands) do
                        nyo_lib_commands[module][#nyo_lib_commands[module] + 1] = v
                    end
                end
                if cfg.locs then
                    for k,v in pairs(cfg.locs) do
                        if lib_config.markerDebug then
                            console.debug('^3[ MARKER ]^7 Loading coords '..v.coord..' | '..v.config)
                        end
                        nyo_lib_coords[#nyo_lib_coords + 1] = v
                    end
                end
            end
            module_events_ids[module] = {}
            local _RegisterNetEvent = RegisterNetEvent
            local _AddEventHandler = AddEventHandler
            local RegisterNetEvent = function(event, func)
                if func then
                    local eventData = RegisterNetEvent(event, func)
                    module_events_ids[module][#module_events_ids[module] + 1] = eventData
                    return eventData
                end
            end
            local AddEventHandler = function(event, func)
                local eventData = RegisterNetEvent(event, func)
                module_events_ids[module][#module_events_ids[module] + 1] = eventData
                return eventData
            end
            table.insert(modulesForLoad, {module, module_info})
        end
    end
    
    
    local loadOrder = {}
    local loadedDependencies = {}
    local inLoadOrder = {}
    local function loadDependencies(module, module_info, n)
        for l,w in pairs(module_info.dependencies) do
            for n2, module2 in pairs(modulesForLoad) do
                if module2[1] == w then
                    if not loadedDependencies[w] then
                        loadedDependencies[w] = true
                        loadDependencies(module2[1], module2[2], n2)
                    end
                    if not inLoadOrder[w] then
                        table.insert(loadOrder, n2)
                    end
                end
            end
        end
        if not inLoadOrder[module] then
            table.insert(loadOrder, n)
            inLoadOrder[module] = true
        end
    end
    for k,v in pairs(modulesForLoad) do
        loadDependencies(v[1],v[2], k)
    end
    for k,v in pairs(loadOrder) do
        local module_name = modulesForLoad[v][1]
        local module_info = modulesForLoad[v][2]
        if IsServer then
            local db_installed = GetResourceKvpInt('nyo_lib'..module_name..'_db_installed')
            if db_installed ~= 1 then
                local db = LoadResourceFile('nyo_lib', 'scripts/'..module_name..'/database.sql')
                if db then
                    local queries = db:split(';')
                    for k,v in pairs(queries) do
                        NyoFw.querySync(v, {})
                    end
                    SetResourceKvpInt('nyo_lib'..module_name..'_db_installed', 1)
                end
            end
        end
        local f = function ()
            module_info.code()
            table.sort(module_info.extendedCodes, function(a,b)
                return a.loadPriority > b.loadPriority
            end)
            for k,v in pairs(module_info.extendedCodes) do
                v.code()
            end
        end
        if not module_info.waitModuleLoad then CreateThread(f)
        else f() end
    end
    nyo_lib_modules     = {}    
    nyo_lib_modules_cfg = {}
    module_ready = true

    for k, v in pairs(pending_module_on_ready_functions) do
        v()
    end
    pending_module_on_ready_functions = {}
end

lib.registerCommand = function(func)
    local module = lib.getModuleByTraceback()
    local commands = nyo_lib_commands[module]
    if not commands then return end
    for k,v in pairs(commands) do
        RegisterCommand(v.command, function(source, args, rawC)
            local ped = IsServer and GetPlayerPed(source) or plyPed
            local cds = GetEntityCoords(ped)
            local allowed
            if v.coords then
                for l,w in pairs(v.coords) do
                    if #(cds - w[1]) < w[2] then
                        allowed = true
                        break
                    end
                end
            elseif v.coord then
                if #(cds - v.coord) < v.distance then
                    allowed = true
                end
            elseif not IsServer and v.interiors then
                for l,w in pairs(v.interiors) do
                    if GetInteriorAtCoords(plyCoords) == w then
                        allowed = true
                        break
                    end
                end
            elseif not IsServer and v.interior then     
                if GetInteriorAtCoords(plyCoords) == v.interior then
                    allowed = true
                end
            else 
                allowed = true
            end
            if IsServer then 
                func(source, v)
            else 
                func(v)
            end
            -- if allowed then
            --     local config = nyo_lib_commands[v.config]
            --     if IsServer then
            --         local user_id = NyoFw.getCharId(source)
            --         if Nfw.checkPermission(user_id, config.perm) then            
            --             func(source, v)
            --         end
            --     else
            --         if Nfw.checkPermission(config.perm) then
            --             func(v)
            --         end
            --     end
            -- end
        end)
    end
    nyo_lib_commands[module] = {}
end


lib.getModuleByTraceback = function()
    local traceback = debug.traceback()
    local module = traceback:gsub('(.*)@nyo_lib/scripts/',''):gsub('/(.*)','')
    if module:find('@nyo_lib') and traceback:find('citizen:/scripting/lua/scheduler.lua:507: in function <citizen:/scripting/lua/scheduler.lua:506>') then
        module = nyo_lib_last_caller
        nyo_lib_last_caller = nil
    end
    return module
end

lib.isReady = function()
    return module_ready
end

lib.onReady = function(func)
    if lib.isReady() then
        CreateThread(func)
    else
        pending_module_on_ready_functions[#pending_module_on_ready_functions + 1] = func
    end
end

lib.isModuleActive = function(module)
    return active_modules[module]
end

lib.getActiveModules = function()
    local res = {}
    for k,v in pairs(active_modules) do
        if v then
            res[k] = v
        end
    end
    return res
end

if not IsServer then

    local modules_languages = {}
    local current_language

    local function onLanguageUpdate(oldLanguage, newLanguage)
        modules_languages = {}
        for module,_ in pairs(lib.getActiveModules()) do
            modules_languages[module] = json.decode(LoadResourceFile('nyo_lib', 'scripts/'..module..'/lang/'..newLanguage..'.json')) or {}
        end
    end

    CreateThread(function()
        lib.onReady(function()
            lib.setCurrentLanguage(GetResourceKvpString('nyo_lib_lang') or lib_config.defaultLanguage or 'pt-BR')
            nyo_lib_modules_lang = {}
            for module,_ in pairs(lib.getActiveModules()) do
                nyo_lib_modules_lang[module] = json.decode(LoadResourceFile('nyo_lib', 'scripts/'..module..'/lang/'..current_language..'.json')) or {}
            end
        end)
    end)

    lib.setCurrentLanguage = function(language)
        SetResourceKvp('nyo_lib_lang', language)
        onLanguageUpdate(current_language, language)
        current_language = language
        SendNUIMessage({
            action = "setLanguage",
            language = current_language
        })
    end
    
    lib.getModuleLanguage = function(_module)
        local module = _module or lib.getModuleByTraceback()
        return setmetatable({}, {
            __index = function(t,k)
                return nyo_lib_modules_lang[module][k] or ''
            end,           
            __newindex = function(t,k,v)
                return false
            end
        })
    end
    
end

if IsServer then 
    CreateThread(function()
        lib.loadModules()
    end)

end