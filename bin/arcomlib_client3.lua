local WAIT_FOR_FEEDBACK = 0.0001
local FEEDBACK_FLUSH_PERIOD = 1
local MODEM_SIDE = "back"

local M2M = dofile("/lib/M2M.lua")

local m2m = M2M.new("Client", MODEM_SIDE)

print("ARC Communication System Client")

local feedBackQueue = {}	-- If a lock is nessensarry?

function spiltString(cmdString)
    local spiltedMsg = {}
	-- Spilt cmd string into seprate words
	-- Using Lua regExpressions,
	-- in which "[%w%p]" means "any letter, number or marks"
	for cur in string.gmatch( cmdString, "[%w%p]+" ) do
		table.insert( spiltedMsg, cur )
	end

    return spiltedMsg
end

-- flush everything in the FB Queue
-- it is called periodly or right after the Client firing a cmd
function flushFeedback ()
    if #feedBackQueue > 0 then
        -- override current prompt "arcom>"
        term.setCursorPos(1, select(2, term.getCursorPos()))
        while #feedBackQueue > 0 do
            print( feedBackQueue[1] )
            table.remove( feedBackQueue, 1 )
        end
        -- override current prompt "arcom>"
        term.setCursorPos(1, select(2, term.getCursorPos()))
        io.write("arcom>")
    end
end


function interfaceThread()
    while true do
        -- avoid several prompts running into each other
        term.setCursorPos(1, select(2, term.getCursorPos()))
        io.write( "arcom>" )
        local cmdString = read()
        if string.len(cmdString) ~= 0 then
            local spStr = spiltString(cmdString)
            m2m:sendMsg(table.unpack(spStr))
        end
        sleep(WAIT_FOR_FEEDBACK) -- wait for the handler to pick up feedback
        flushFeedback()
    end
end


-- Flush the feedBack Queue every few secs
function feedBackFlusherThread()
    while true do
        flushFeedback()
        sleep(FEEDBACK_FLUSH_PERIOD)
    end
end


function feedbackReceiverThread()
    while true do
        local senderID, status, description = m2m:pullFeedBack()
        table.insert( feedBackQueue, string.format("[%s] %s: %s", status, senderID, description) )
    end
end

parallel.waitForAny(interfaceThread, feedbackReceiverThread, feedBackFlusherThread)

