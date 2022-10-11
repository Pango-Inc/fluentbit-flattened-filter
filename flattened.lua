local fpaths = os.getenv("LUA_FLATTENED_PATH")
local sep = os.getenv("LUA_FLATTENED_SEPARATOR") or '.'

if fpaths == nil then
  error("LUA_FLATTENED_PATH envvar not found!", 1)
end

-- convert a nested table to a flat table
local function flatten(t)
    local res = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            v = flatten(v)
            for k2, v2 in pairs(v) do
                res[k .. sep .. k2] = v2
            end
        else
            res[k] = v
        end
    end
    return res
end

-- convert a table to a string
local function to_string(k,v)
    local s = {}
    s[#s+1]="\""
    s[#s+1]=k
    s[#s+1]="\""
    s[#s+1]=": "
    s[#s+1]="\""
    s[#s+1]=v
    s[#s+1]="\""
    return table.concat(s)
end

-- split string by @sep
local function split(text)
    local res = {}
    local t = {}
    local count = string.len(text) + 1
    for i = 1, count do
        local char = string.sub(text, i, i)
        if char == sep or i == count then
            table.insert(res, table.concat(t))
            t = {}
        else
            table.insert(t, char)
        end
    end
    return res
end

local paths = split(fpaths)

-- retrieve nested table
local function get_nested(t)
    local nested_record = t
    for _, val in pairs(paths) do
        if type(nested_record) == 'table' then
            nested_record = nested_record[val]
        end
    end
    return nested_record
end

-- put nested table back after modification
local function put_nested(tp, tch)
    local parent = tp
    local child = tch
    local t = {}
    for i=#paths, 2, -1 do
        t[paths[i]] = child
        child = t
    end
    parent[paths[1]] = child
    return parent
end

-- main function, should be executed by fluent-bit
function flattened(tag, timestamp, record)
    local _ = tag
    local nt = get_nested(record)
    if type(nt) == 'table' then
        local fnt = flatten(nt)
        local fnst = {}
        for k,v in pairs(fnt) do
            fnst[#fnst+1] = to_string(k,v)
        end
        local fns = table.concat(fnst,", ")
        record = put_nested(record, fns)
        return 2, timestamp, record
    else
        return 0, timestamp, record
    end
end
