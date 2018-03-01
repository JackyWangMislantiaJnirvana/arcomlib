__DEBUG = true

local device = dofile("/bin/SMC3/device.lua")

local EventPump = dofile("/lib/Eventpump.lua")
local Controller = dofile("/lib/Controller.lua")
local Safety = dofile("/lib/Safety.lua")
local M2M = dofile("/lib/M2M.lua")

local eventPump = EventPump.new()
local controller = Controller.new("SMC0")
local safety = Safety.new()
local m2m = M2M.new("SMC0", "top")

local MAX_TEMP_CERAMIC = 2400
local DROP_TEMP_CERAMIC = 2350

function enable()
    eventPump:pushEvent("ignite")
    controller:enable()

    m2m:sendFeedBack("OK", "Enabled")
    print("SMC0: enabled")
end

function disable()
    controller:disable()

    m2m:sendFeedBack("OK", "Disabled")
    print("SMC0: disabled")
end

function estop()
    device.setEStopper(true)
    controller:estop()

    m2m:sendFeedBack("INFO", "Emergency stop")
    print("SMC0: estopped")

    -- Block until crucible is under safe temp
    repeat
        sleep(STOPPER_DELAY)
    until(device.tempSens.getval() <= MAX_TEMP_CERAMIC)
    device.setEStopper(false)

end

function drop()
    device.drop()

    m2m:sendFeedBack("OK", "A smelting unit is added")
    print("SMC0: dropped")
end

function cast(status)
    if status == "start" then
        device.caster.start()
        print("SMC0: cast started")
        m2m:sendFeedBack("OK", "Casting started")
    elseif status == "stop" then
        device.caster.stop()
        print("SMC0: cast stopped")
        m2m:sendFeedBack("OK", "Casting stopped")
    else
        m2m:sendFeedBack("INFO", "Cast: usage: cast start/stop")
    end
end

function ignite()
    print("SMC0: ignited")
    device.ignite()
    m2m:sendFeedBack("OK", "Burning box started")
end

function smelteryLoop_Steel()
    if device.caster.getStatus() ~= true then
        eventPump:pushEvent("cast", "start")
    end

    local temp = device.getTemp()
    if temp >= DROP_TEMP_CERAMIC then
        eventPump:pushEvent("drop")
    end
end

function watchdog_ceramic()
    if device.getTemp() >= MAX_TEMP_CERAMIC then
        eventPump:pushEvent("estop")
    end
end

eventPump:listen(eventPump.HANDLER_NOT_FOUND_HANDLER_TAG, m2m:getHandlerNotFoundHandler())

eventPump:listen("drop", drop)
eventPump:listen("cast", cast)
eventPump:listen("estop", estop)
eventPump:listen("enable", enable)
eventPump:listen("disable", disable)
eventPump:listen("ignite", ignite)
controller:setLoop(smelteryLoop_Steel)
safety:setWatchdog(watchdog_ceramic)

parallel.waitForAll(
    eventPump:getRunable(),
    controller:getRunable(),
    m2m:getRunable(),
    safety:getRunable()
)
