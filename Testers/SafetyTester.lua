local Safety = dofile("/lib/Safety.lua")
local EventPump = dofile("/lib/EventPump.lua")
local safety = Safety.new()
local eventPump = EventPump.new()

function estopEventSource()
    print("Press enter to raise a estop event.")
    io.input():read()
    eventPump:pushEvent("estop")
end

safety:setEStoper(function()
    print("E-Stopper is here!")
end)

safety:setWatchdog(function()
    print("Watchdog is here.")
    sleep(15)
end)

eventPump:listen("estop" ,safety:getHandler())
parallel.waitForAll(safety:getRunable(), eventPump:getRunable(), estopEventSource)


