-- Controller.lua
-- Provide a auto controller structure
-- Arcomlib rev3

-- If PickleJar isn't automatically loaded into ENV
-- (CC's style API handling)
-- then load it by dofile.(How premitive...
PickleJar = _G.PickleJar or dofile("/lib/PickleJar.lua")

Controller = {}
Controller.__index = Controller
Controller.enumStatus = {
    enabed = 1,     -- running normally
    disabled = 2,   -- paused
    halt = 3,       -- shutdown
    failed = 4      -- something goes wrong
}

function Controller.new(name)
    local object = {}
    setmetatable(object, Controller)

    object.name = name
    object.status = PickleJar.new("Con_" .. object.name .. ".status")
    object.status.runLevel = object.status.runLevel or Controller.enumStatus.halt
    return object
end

function Controller:setLoop(loop)
    if type(loop) ~= "function" then
        error("Controller.setLoop: function required.")
    end
    self.loopFunc = function()
        while self.status.runLevel == Controller.enumStatus.enabled do
            loop()
        end
    end
end

-- safety feature is moved to Safety.lua
--[[
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
--]]

-- Status setter
function Controller:enable()    self.status.runLevel = Controller.enumStatus.enabled    end
function Controller:disable()   self.status.runLevel = Controller.enumStatus.disabled   end
function Controller:halt()      self.status.runLevel = Controller.enumStatus.halt       end
function Controller:estop()     self.status.runLevel = Controller.enumStatus.failed     end
-- Status getter
function Controller:getStatus() return self.status.runLevel end

-- Get runable controller
function Controller:getRunable()
    return Controller.loopFunc
end