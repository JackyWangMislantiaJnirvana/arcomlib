-- EventPump
--[[
-- Provide event-driven mechanism
-- Register handlers to listen events
-- Other arcomlib modules can also generate
-- its own handler to listen to events.
-- Arcomlib rev3
--]]

__DEBUG = false

local EventPump = {}
EventPump.__index = EventPump

-- Constants
EventPump.ARCOM_EVENT_NAME = "arcom_event"
EventPump.HANDLER_NOT_FOUND_HANDLER_TAG = "handlerNotFoundHandler"

function EventPump.new()
    local object = {}
    setmetatable(object, EventPump)

    -- Attributes
        -- Map between the name of event
        -- and its handler(s)
    object.handlerMap = {}

    return object
end

-- Notes about duplication-avoid mechanism:
--[[
-- Lua store functions declared in the same defination scope in the same address.
-- Every function defination are allocated a unique address.
-- so we compare reference of callbacks registed to avoid duplicated handlers.
-- Do that works? To be tested in the future.
--]]
function EventPump:listen(eventTag, callback)
    if type(eventTag) ~= "string" or type(callback) ~= "function" then
        error("EventPump: listen(): bad argument: name(string) and callback(function) requiered.", 2)
    end

    -- If this eventTag isn't registered before, create it.
    self.handlerMap[eventTag] = self.handlerMap[eventTag] or {}

    -- Duplication check.
    local ok = true
    for _, v in pairs(self.handlerMap[eventTag]) do
        if v.callback == callback then
            -- DEBUG
            print("[DEBUG] EventPump:listen(): Duplicated callback.")
            ok = false
        end
    end

    local handler = {
        eventName = eventTag,
        callback = callback,
    }
    if ok then
        table.insert(self.handlerMap[eventTag], handler)
        return true
    else
        return false
    end
end

-- ignore() seems unnecessary
--[[
function EventPump:ignore(eventName, callback)
    if type(eventName) ~= "string" or type(callback) ~= "function" then
        error("EventPump: ignore(): bad argument: name(string) and callback(function) requiered")
    end
end
-- ]]

-- Arcom event defination:
--[[    arcom_event, string: eventTag, argTable
-- 1. The name "arcom_event" is defined in ARCOM_EVENT_NAME and may change somehow.
-- 2. "eventTag" locate the target handlers. (Equals to "targetISR")
-- 3. "argTable" will be unpacked and sent to callback function as args.
--]]
function EventPump:pushEvent(eventTag, ...)
    if type(eventTag) ~= "string" then
        error("EventPump:pushEvent(): bad argument. eventTag(string) required.")
    end
    os.queueEvent(self.ARCOM_EVENT_NAME, eventTag, table.pack(...))
end

-- local non-interface function
-- Deliver events to handlers
-- Note about how to handle non-exist eventTag request.
--[[
-- Non-exist eventTag means there's no handler registed under the tag.
-- The M2M module provide a handler called
-- handlerNotFoundHandler(string: eventTag)
-- (Hmmmmm, what a strange name!)
-- to handle such situation.
-- More specifically, this handler will take the
-- tag provided and fire a feedback to the client
-- through feedback channel provided in M2M.
-- When being fed by non-exist targetTag,
-- this function will call this handler, **if it exists**.
 ]]
function EventPump:handleEvent(targetTag, ...)
    local argTable = table.pack(...)
    local handlerNotFound = true
    if self.handlerMap[targetTag] ~= nil then
        for _, v in pairs(self.handlerMap[targetTag]) do
            v.callback(table.unpack(argTable))
            handlerNotFound = false
        end
    end

    -- Call handlerNotFoundHandler(what a strange name!)
    -- when provided targetTag doesn't exist.
    if handlerNotFound then
        print("[ERR] EventPump: handler not found")
        -- Call handlerNotFoundHandler if possible
        local handlerNotFoundHandler = self.HANDLER_NOT_FOUND_HANDLER_TAG
        if handlerNotFoundHandler ~= nil then
            self.handlerMap[self.HANDLER_NOT_FOUND_HANDLER_TAG]
                [1].callback(targetTag)
        else
            print("[WARNING] EventPump: Missing handler not found handler")
            print("[WARNING] EventPump: Please get it calling m2m:getHandlerNotFoundHander()")
        end
    end
end


-- Real "pump" or so called "Event loop" is located here.
function EventPump:getRunable()
    local function runable()
        while true do
            local name, targetTag, argTable
            name, targetTag, argTable = os.pullEvent(self.ARCOM_EVENT_NAME)
            self:handleEvent(targetTag, table.unpack(argTable))
        end
    end
    return runable
end

return EventPump