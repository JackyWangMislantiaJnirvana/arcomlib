local EventPump = dofile("/lib/Eventpump.lua")
local Controller = dofile("/lib/Controller.lua")
local Safety = dofile("/lib/Safety.lua")
local M2M = dofile("/lib/M2M.lua")

local eventPump = EventPump.new()
local controller = Controller.new("DemoServer")
local safety = Safety.new()
local m2m = M2M.new("Demo", "left")

function blink()
    redstone.setOutput("top", true)
    sleep(1)
    redstone.setOutput("top", false)
    sleep(1)
end

function lightSwitch(stat)
    print("[DEBUG]")
    if stat == "on" then
        redstone.setOutput("right", true)
        m2m:sendFeedBack("OK", "Light turned ON.")
    end
    if stat == "off" then
        redstone.setOutput("right", false)
        m2m:sendFeedBack("OK", "Light turned OFF.")
    end
end

function enable()
    controller:enable()
end

function disable()
    controller:disable()
end

eventPump:listen("light", lightSwitch)
eventPump:listen("enable", enable)
eventPump:listen("disable", disable)
controller:setLoop(blink)

parallel.waitForAll(eventPump:getRunable(), controller:getRunable(), m2m:getRunable())
