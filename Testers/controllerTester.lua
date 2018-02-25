_DEBUG = true
local Controller = dofile("/lib/Controller.lua")
local controller = Controller.new("test")

controller:setLoop(function()
    print("Here is Loop function!")
    sleep(1)
end)

function statusChanger()
    --
    print("[TEST] enabling controller")
    controller:enable()
    sleep(5)
    print("[TEST] disabling controller")
    controller:disable()
    controller:getStatus()
    --]]
end

parallel.waitForAll(controller:getRunable(), statusChanger)