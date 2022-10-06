dofile("flattened.lua")

local TAG = "test.*"
local TS = "2022-10-06T01:12:11.099408022-07:00"

local test_case = {
    [{log = {message = {foo = {bar = {baz1 = "This is example", baz2 = "This is example too"}}}}}] = 
    {log = {message = "\"foo.bar.baz1\": \"This is example\", \"foo.bar.baz2\": \"This is example too\""}}
}

local function test_flattened()
    for record, expect in pairs(test_case) do
        local _, _, record_out = flattened(TAG, TS, record)        
        assert(table.concat(expect) == table.concat(record_out), "test_flattened FAILED!")
    end
end

test_flattened()
