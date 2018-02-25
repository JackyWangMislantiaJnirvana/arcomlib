local M2M = dofile("/lib/M2M.lua")
print(M2M)
local EventPump = dofile("/lib/EventPump.lua")

local m2m = M2M.new("receiver", "back")
local eventPump = EventPump.new()

function testHandler(msg)
    print(msg)
end

eventPump:listen("test", testHandler)

parallel.waitForAll(m2m:getRunable(), eventPump:getRunable())
