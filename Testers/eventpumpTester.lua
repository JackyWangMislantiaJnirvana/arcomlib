local EventPump = dofile("/lib/EventPump.lua")
local eventPump = EventPump.new()

function eventProducer()
    while true do
        eventPump:pushEvent("test", "test")
        sleep(1)
    end
end

function test(msg)
    print(msg)
end

eventPump:listen("test", test)
eventPump:listen("test", test)
parallel.waitForAll(eventPump:getRunable(), eventProducer)
