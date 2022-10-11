dofile("flattened.lua")

local TAG = "test.*"
local TS = "2022-10-06T01:12:11.099408022-07:00"

local test_cases = {
    case1 = {
        [{log = {message = {foo = {bar = {baz1 = "This is example"}}}}}] = 
        {log = {message = "\"foo.bar.baz1\": \"This is example\""}}
    },
    case2 = {
        [{log = {message = {}}}] = {log = {message = ""}}
    },
    case3 = {
        [{log = {message = "This is example"}}] = {log = {message = "This is example"}}
    },
    case4 = {
        [{log = {app = "Example application"}}] =  {log = {app = "Example application"}}
    },
    case5 = {
        [{date = "2022-10-06T01:12:11.099408022-07:00"}] = {date = "2022-10-06T01:12:11.099408022-07:00"}
    },
}

local function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0
    local iter = function ()
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

local function deepcompare(t1,t2,ignore_mt)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1,v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not deepcompare(v1,v2) then return false end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not deepcompare(v1,v2) then return false end
    end
    return true
end

local function test_flattened()
    local tc = 0
    for _ in pairs(test_cases) do tc = tc + 1 end
    for name, test_data in pairsByKeys(test_cases) do
        for record, expect in pairs(test_data) do
            local msg = "test_flattened: " .. name .. " of " .. tc
            local _, _, record_out = flattened(TAG, TS, record)
            assert(deepcompare(expect, record_out), msg .. " => FAILED!")
            print(msg .. " => PASSED!")
        end
    end
end

test_flattened()
