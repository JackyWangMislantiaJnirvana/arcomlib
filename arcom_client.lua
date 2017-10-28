local WAIT_FOR_FEEDBACK = 0.0001

print("ARC Communication Systems Client")
local arcom = dofile( "arcomlib.lua" )
arcom.initClient()

local feedBackQueue = {}	-- If a lock is nessensarry?

function interfaceLoop()
	while true do
		io.write( "arcom>" )
		local cmdString = read()
		if string.len(cmdString) ~= 0 then
			arcom.fireCmd(cmdString)
		end
		sleep(WAIT_FOR_FEEDBACK) -- wait for the handler to pick up feedback
		while #feedBackQueue > 0 do
			print( feedBackQueue[1] )
			table.remove( feedBackQueue, 1 )
		end
	end
end

function feedbackHandler()
	while true do
		local feedBack = {}
		feedBack = arcom.receiveFeedback()
		table.insert( feedBackQueue, string.format("[%s] %s: %s", feedBack.stat, feedBack.sender, feedBack.msg) )
	end
end

parallel.waitForAny(interfaceLoop, feedbackHandler)
