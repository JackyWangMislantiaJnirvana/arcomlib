local WAIT_FOR_FEEDBACK = 0.0001
local FEEDBACK_FLUSH_PERIOD = 1

print("ARC Communication Systems Client")
local arcom = dofile( "/lib/arcomlib.lua" )
arcom.initClient()

local feedBackQueue = {}	-- If a lock is nessensarry?


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
			arcom.fireCmd(cmdString)
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
		local feedBack = {}
		feedBack = arcom.receiveFeedback()
		table.insert( feedBackQueue, string.format("[%s] %s: %s", feedBack.stat, feedBack.sender, feedBack.msg) )
	end
end

-- wow parallel such cool wow!
parallel.waitForAny(interfaceThread, feedbackReceiverThread, feedBackFlusherThread)
