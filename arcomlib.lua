local arcomlib = {}

local CLIENT_MODEM_SIDE = "back"
local ARCOM_PROTOCAL = "arcom"

-- API layer
-------------------------------------------
function arcomlib.initClient()
	arcomlib.instanceType = "Client"
	rednet.open(CLIENT_MODEM_SIDE)
	print( "Arcom Client: Initialized." )
end


function arcomlib.initServer( serverName, modemside )
	arcomlib.instanceName = serverName
	arcomlib.instanceModemSide = modemside
	arcomlib.instanceType = "Server"
	rednet.open(modemside)
	rednet.host(ARCOM_PROTOCAL, serverName)

	-- Init interrupt vector table
	if arcomlib.interruptVectorTable == nil then
		arcomlib.interruptVectorTable = {}
	end
	-- Defultly create ISR "enable" and "disable"
	-- to start and stop the main loop
	__enabled = false
	arcomlib.interruptVectorTable["enable"] = function()
		__enabled = true
	end
	arcomlib.interruptVectorTable["disable"] = function()
		__enabled = false
	end

	print( "Arcom Server: "..serverName.." Initialized, initially disabled.")
end


function arcomlib.regMainLoop( mainLoop )
	arcomlib.mainLoopFunction = function()
		while true do
			if __enabled == true then
				mainLoop()
				sleep(0.1)
			else
				sleep(1)
			end
		end
	end
end


function arcomlib.regInterrupt( ISR, boundedCmd )
	arcomlib.interruptVectorTable[boundedCmd] = ISR
end


function arcomlib.startServer()
	local ISRHost = 
	function()
		while true do
			local cmd = {}
			local senderID = -1
			senderID, cmd, _ = rednet.receive(ARCOM_PROTOCAL)
			print( "Arcom Server: recieved an request to ISR "..cmd.targetISR.." from "..senderID..".")
			arcomlib.interruptVectorTable[cmd.targetISR](table.unpack(cmd.args))
		end
	end
	-- Use parallel API to start the ISR host 
	-- and the main loop at the same time.
	parallel.waitForAny(arcomlib.mainLoopFunction, ISRHost)
end


-- TODO: make this capable with feedbacks
function arcomlib.fireCmd( msg )
	local spiltedMsg = {}
	-- Spilt cmd string into seprate words
	-- Using Lua regExpressions, 
	-- in which "[%w%p]" means "any letter, number or marks"
	for cur in string.gmatch( msg, "[%w%p]+" ) do
		table.insert( spiltedMsg, cur )
	end
	local cmd = {}
	-- Lua's index starts from 1!!!
	-- Keep it in your mind!
	cmd.dest = spiltedMsg[1]
	cmd.targetISR = spiltedMsg[2]
	cmd.args = table.pack( table.unpack( spiltedMsg, 3, #spiltedMsg ) )
	-- Lookup server ID
	destID = rednet.lookup(ARCOM_PROTOCAL, cmd.dest)
	-- Send cmd
	rednet.send(destID, cmd, ARCOM_PROTOCAL)
end


function arcomlib.sendFeedback( stat, msg )
	-- TODO
end


function arcomlib.clearup()
	-- TODO
end

------------------------------------
return arcomlib