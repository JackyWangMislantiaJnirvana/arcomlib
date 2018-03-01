-- M2M
-- Machine to Machine communications
-- Arcomlib rev3

__DEBUG = false

local ARCOM_MSG_PROTOCAL = "Arcom_MSG"
local ARCOM_FB_PROTOCAL = "Arcom_FB"

local EventPump = dofile("/lib/EventPump.lua")
local M2M = {}
M2M.__index = M2M

function M2M.new(hostName, modemSide)
    local object = {}
    setmetatable(object, M2M)
    object.hostName = hostName
    object.eventPump = EventPump.new()

    rednet.open(modemSide)
    rednet.host(ARCOM_MSG_PROTOCAL, hostName)

    return object
end

-- Communication Protocal:
--[[
--Msg:
-- Feed everyting you want to send to sendMsg()
-- these things will be automatically packed into a table
-- and send through rednet
--Feedback:
-- Feed status and description to sendFeedBack()
-- these two will be packed into one table
-- and broadcast through rednet
--]]
function M2M:sendMsg(receiverHostname, ...)
    if type(receiverHostname) ~= "string" then
        error("M2M:sendMsg():receiver hostname(string) required.")
    end
    local receiverID = rednet.lookup(ARCOM_MSG_PROTOCAL, receiverHostname)
    if receiverID == nil then
        print("[ERR] M2M: Receiver not found.")
    else
        rednet.send(receiverID, table.pack(...), ARCOM_MSG_PROTOCAL)
    end
    -- TODO Mega network support: cell fallback
end

-- Feedback pack is consist of
-- sender hostname, status(string) and description(string)
function M2M:sendFeedBack(status, description)
    if type(status) ~= "string" or type(description) ~= "string" then
        error("M2M:sendFeedBack():status(string) and description(stirng) required.", 2)
    end
    rednet.broadcast(table.pack(self.hostName, status, description), ARCOM_FB_PROTOCAL)
end

function M2M:pullFeedBack()
    local senderID, fbTab
    senderID, fbTab = rednet.receive(ARCOM_FB_PROTOCAL)
    return table.unpack(fbTab)
end

function M2M:getRunable()
    local function runable()
        while true do
            local senderID, msgTab = rednet.receive(ARCOM_MSG_PROTOCAL)
            -- Grab eventTag out from the table
            local eventTag = msgTab[1]
            table.remove(msgTab, 1)
            self.eventPump:pushEvent(eventTag, table.unpack(msgTab))
        end
    end
    return runable
end

function M2M:getHandlerNotFoundHandler()
    local function handlerNotFoundHandler(targetTag)
        if __DEBUG then
            print("[DEBUG] ", targetTag)
            print("[DEBUG] ", type(targetTag.." dosen't exist."))
        end
        self:sendFeedBack("ERR", targetTag .. " doesn't exist.")
    end
    return handlerNotFoundHandler
end

return M2M
