if not _VERSION:find('5.4') then
    error('^1Lua 5.4 must be enabled in the resource manifest!^0', 2)
end

local resourceName = GetCurrentResourceName()
local lib_name = 'nyo_lib'
lib_config = {}
lib_config.debug=true
IsServer  = IsDuplicityVersion()

---if resourceName == nyo_lib then return end

if resourceName ~= lib_name then
    if GetResourceState(lib_name) ~= 'started' then
        error('^1nyo_lib must be started before this resource.^0', 0)
    end
end

msgpack.setoption('ignore_invalid', true)


console = {}
local Console = {}
-----------------------------------------------------------------------------------------------
-- Console
-----------------------------------------------------------------------------------------------

--- @param message: string
Console.debug = function(message)
    if lib_config.debug then
        print('^3[ DEBUG ] ^7'..message)
    end
end

--- @param table: table
--- @param tabpos?: number
Console.table = function(table, tabpos)
    tabpos = tabpos or 0
    local tab = ''
    local spaceamount = 0
    for i = 1, tabpos do
        tab = tab..'\t'
    end
    for k,v in pairs(table) do
        local _k = #tostring(k)
        if _k > spaceamount then
            spaceamount = _k
        end
    end
    for k,v in pairs(table) do
        local _k = #tostring(k)
        local space = ''
        for i = 1, spaceamount - _k do
            space = space..' '
        end
        if type(v) == 'table' then
            Console.table(v, tabpos + 1)
        end
    end
    print()
end

setmetatable(console, {
    __index = function(t,k)
        return Console[k]
    end,

    __newindex = function()
        return false
    end,
    __metatable = 'Noops'
})

-----------------------------------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------------------------------
local LoadResourceFile = LoadResourceFile
local context = IsDuplicityVersion() and 'server' or 'client'

function noop() end

local function loadModule(self, module)
    local dir = ('modules/%s'):format(module)
    local chunk = LoadResourceFile(lib_name, ('%s/%s.lua'):format(dir, context))
    local shared = LoadResourceFile(lib_name, ('%s/shared.lua'):format(dir))

    if shared then
        chunk = (chunk and ('%s\n%s'):format(shared, chunk)) or shared
    end

    if chunk then
        local fn, err = load(chunk, ('@@nyo_lib/modules/%s/%s.lua'):format(module, context))

        if not fn or err then
            return error(('\n^1Error importing module (%s): %s^0'):format(dir, err), 3)
        end

        local result = fn()
        self[module] = result or noop
        return self[module]
    end
end

-----------------------------------------------------------------------------------------------
-- API
-----------------------------------------------------------------------------------------------

local function call(self, index, ...)
    local module = rawget(self, index)

    --print(module)

    if not module then
        self[index] = noop
        module = loadModule(self, index)

        if not module then
            local function method(...)
                return export[index](nil, ...)
            end

            if not ... then
                self[index] = method
            end

            return method
        end
    end

    return module
end

lib = setmetatable({
    name = lib_name,
    context = context
}, {
    __index = call,
    __call = call,
})

-- Override standard Lua require with our own.
require = lib.require


function cache(key, func, timeout) end

cache = setmetatable({ game = GetGameName(), resource = resourceName }, {
    __index = context == 'client' and function(self, key)
        AddEventHandler(('nyo_lib:cache:%s'):format(key), function(value)
            self[key] = value
        end)

        return rawset(self, key, export.cache(nil, key) or false)[key]
    end or nil,

    __call = function(self, key, func, timeout)
        local value = rawget(self, key)

        if not value then
            value = func()

            rawset(self, key, value)

            if timeout then SetTimeout(timeout, function() self[key] = nil end) end
        end

        return value
    end,
})

if resourceName == lib_name then 
    require 'modules.events.shared'
end