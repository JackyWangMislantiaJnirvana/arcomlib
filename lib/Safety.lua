-- Safety.lua
-- Safety features
--  1. safety watchdog
--  2. emergency stop function

Safety = {}
Safety.__index = Safety

function Safety.new()
    local object = {}
    setmetatable(object, Safety)

    return object
end

function Safety:setWatchdog(watchdog)
    if type(watchdog) ~= "function" then
        error("Safety:setWatchdog: function expected.")
    end

    local function wrappedWatchdog()
        while true do
            watchdog()
        end
    end
    self.wrappedWatchdog = wrappedWatchdog
end

-- Function passed to setEStoper will be returned
-- as a event handler and can be registered into
-- EventPump module and handle every e-stop event,
-- from both inner(safety watchdog),
-- and outter side(estop command from the network).
-- Note: users need to turn off the controller
-- by themselves(Controller.estop())
function Safety:setEStoper(estoper)
    if type(estoper) ~= "function" then
        error("Safety:setEStoper: function expected.")
    end

    self.wrappedEStoper = estoper
end

function Safety:getRunable()
    return self.wrappedWatchdog
end
function Safety:getHandler()
    return self.wrappedEStoper
end

return Safety