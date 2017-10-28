local arcomlib = {}

local CLIENT_MODEM_SIDE = "back"
local ARCOM_CMD_PROTOCAL = "arcom_cmd"
local ARCOM_FEEDBACK_PROTOCAL = "arcom_feedback"
local ARCOM_CLIENT_NAME = "ArcomClient"

-- API layer
-------------------------------------------
function arcomlib.initClient()
	arcomlib.instanceType = "Client"
	arcomlib.instanceName = ARCOM_CLIENT_NAME
	rednet.open(CLIENT_MODEM_SIDE)
	rednet.host(ARCOM_FEEDBACK_PROTOCAL, ARCOM_CLIENT_NAME)
	print( "Arcom Client: Initialized." )
end


function arcomlib.initServer( serverName, modemside )
	arcomlib.instanceName = serverName
	arcomlib.instanceModemSide = modemside
	arcomlib.instanceType = "Server"
	rednet.open(modemside)
	rednet.host(ARCOM_CMD_PROTOCAL, serverName)

	-- Init interrupt vector table
	if arcomlib.interruptVectorTable == nil then
		arcomlib.interruptVectorTable = {}
	end
	-- Defultly create ISR "enable" and "disable"
	-- to start and stop the main loop
	__enabled = false
	arcomlib.interruptVectorTable["enable"] = function()
		__enabled = true
		arcomlib.sendFeedback("OK", "Enabled.")
	end
	arcomlib.interruptVectorTable["disable"] = function()
		arcomlib.sendFeedback("OK", "Disabled.")
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
	local ISRHost = function()
		while true do
			local cmd = {}
			local senderID = -1
			senderID, cmd, _ = rednet.receive(ARCOM_CMD_PROTOCAL)
			local isNameValid = false
			for isrName, isrFunc in pairs( arcomlib.interruptVectorTable ) do
				if cmd.targetISR == isrName then
					isNameValid = true
					print( "Arcom Server: recieved an request to ISR "..cmd.targetISR..".")
					arcomlib.interruptVectorTable[cmd.targetISR](table.unpack(cmd.args))
				end
			end
			if isNameValid == false then
				arcomlib.sendFeedback("ERROR", "No such ISR!")
			end
		end
	end
	-- Use parallel API to start the ISR host 
	-- and the main loop at the same time.
	parallel.waitForAny(arcomlib.mainLoopFunction, ISRHost)
end


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
	destID = rednet.lookup(ARCOM_CMD_PROTOCAL, cmd.dest)
	if destID == nil then
		print( "[ERROR] Arcom DNS: no such server!" )
		return
	end
	-- Send cmd
	rednet.send(destID, cmd, ARCOM_CMD_PROTOCAL)
end


function arcomlib.sendFeedback( stat, msg )
	local feedBack = {}
	feedBack.stat = stat
	feedBack.msg = msg
	feedBack.sender = arcomlib.instanceName
	clientID = rednet.lookup(ARCOM_FEEDBACK_PROTOCAL, ARCOM_CLIENT_NAME)
	rednet.send(clientID, feedBack, ARCOM_FEEDBACK_PROTOCAL)
end


function arcomlib.receiveFeedback()
	local feedBack = {}
	_, feedBack, _ = rednet.receive(ARCOM_FEEDBACK_PROTOCAL)
	return feedBack
end


function arcomlib.clearup()
	if arcomlib.instanceType == nil then
		return
	end

	print( "Arcom: clearing up." )
	arcomlib.instanceType = nil
	arcomlib.instanceName = nil
	arcomlib.instanceModemSide = nil
	rednet.unhost(arcomlib.instanceName)
end

------------------------------------
return arcomlib