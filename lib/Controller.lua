-- Controller.lua
-- Provide a auto controller structure
-- Arcomlib rev3
_DEBUG = false

-- If PickleJar isn't automatically loaded into ENV
-- (CC's style API handling)
-- then load it by dofile.(How premitive...

local PickleJar = _G.PickleJar or dofile("/lib/PickleJar.lua")

local Controller = {}
Controller.__index = Controller
Controller.enumStatus = {
    enabled  = "enabled",   -- running normally
    disabled = "disabled",  -- paused
    halt     = "halt",      -- shutdown
    failed   = "failed"     -- something goes wrong
}

-- Note:
-- this name is used to name the config files.
function Controller.new(name)
    if type(name) ~= "string" then error("Controller.new: name(string) required") end
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
        while true do

            if _DEBUG then
                print("[DEBUG]", type(self.status.runLevel))
                print("[DEBUG]", type(Controller.enumStatus.enabled))
            end

            if self.status.runLevel == Controller.enumStatus.enabled then
                if _DEBUG then
                    print("[DEBUG]", "calling loopfunc")
                end

                loop()
            end
            sleep(0.001)
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
    return self.loopFunc
end

return Controller