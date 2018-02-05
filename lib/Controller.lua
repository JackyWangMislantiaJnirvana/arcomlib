-- Controller.lua
-- Provide a auto controller structure
-- Arcomlib rev3

-- If PickleJar isn't automatically loaded into ENV
-- (CC's style API handling)
-- then load it by dofile.(How premitive...
PickleJar = _G.PickleJar or dofile("/lib/PickleJar.lua")

Controller = {}
Controller.__index = Controller
Controller.stats = {
    enabed = 1,     -- running normally
    disabled = 2,   -- paused
    halt = 3,       -- shutdown
    failed = 4      -- something goes wrong
}

function Controller.new(name)
    local object = {}
    setmetatable(object, Controller)

    object.name = name
    object.controllerStatus = PickleJar.new("Con_" .. object.name .. ".status")
    object.controllerStatus.status = object.controllerStatus.status or Controller.stats.halt
    return object
end

function Controller:setLoop(loop)
    if type(loop) ~= "function" then
        error("Controller.setLoop: function required.")
    end
    self.loopFunc = function()
        while self.controllerStatus["status"] == Controller.stats.enabled do
            loop()
        end
    end
end

function Controller:setSafety(safety)
    if type(safety) ~= "function" then
        error("Controller.setSafety: function required.")
    end
    self.safetyFunc = function()
        while true do
            safety()
        end
    end
end

function Controller:getRunable()
    return function()
        waitForAll(Controller.safetyFunc, Controller.loopFunc)
    end
end