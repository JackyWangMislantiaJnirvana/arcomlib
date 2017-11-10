local ESTOP_TEMP = 2400
local CAST_TEMP = 1400
local DROP_TEMP = 2000
local LOOP_DELAY = 0.5
local CAST_DELAY = 5

local arcom = dofile("/lib/arcomlib.lua")
local smeltery = dofile("/lib/smeltery.lua")

print("Arcom Production Server for SMC")
arcom.initServer("SMC", "bottom")

local function initialize ()
	smeltery.caster.stop()
	smeltery.drop()
	print "SMC is online."
	arcom.sendFeedback("OK", "SMC is online.")
	print "Please light the burning box to start."
end

local function mainLoop ()
	while true do
		local temp = smeltery.getTemp()
		if temp >= DROP_TEMP and temp < ESTOP_TEMP and smeltery.caster.getStatus() == false then
	  	sleep(CAST_DELAY)
			smeltery.drop()
			print "Added a smelting unit to the smeltery."
		end
		if temp >= CAST_TEMP and temp < DROP_TEMP and smeltery.caster.getStatus() == false then
			smeltery.caster.start()
			print "Started casting."
		end
		if (temp <= CAST_TEMP or temp >= DROP_TEMP) and smeltery.caster.getStatus() == true then
			smeltery.caster.stop()
			print "Stopped casting."
		end
		sleep(LOOP_DELAY)
	end
end

local function safetyProtocal ()
	local temp = smeltery.getTemp()
	if temp >= ESTOP_TEMP then
		arcom.innerInterrupt("estop")
		arcom.sendFeedback("SAFETY", "A E-Stop is triggered in smeltery due to overheating.")
		print "The smeltery had an E-Stop. Relight the burning box to continue."
	end
end

local function estop ()
	smeltery.e_stop()
	arcom.sendFeedback("OK", "An E-Stop is applied to smeltery.")
	arcom.innerInterrupt("disable")
end

local function drop ()
	smeltery.drop()
end

local function cast (opt)
	if opt == nil then
		arcom.sendFeedback("ERR", "Missing opt for caster, expected start, stop or stat.")
		return
	end
	if opt == "start" then
		smeltery.caster.start()
		arcom.sendFeedback("OK", "Caster started.")
	elseif opt == "stop" then
		smeltery.caster.stop()
		arcom.sendFeedback("OK", "Caster stoped.")
	elseif opt == "stat" then
		arcom.sendFeedback("INFO", "Caster status is "..tostring(smeltery.caster.getStatus()))
	else
		arcom.sendFeedback("ERR", "Wrong opt, expected start, stop or stat.")
	end
end

local function getTemp ()
	arcom.sendFeedback("INFO", "Current Temperature is "..smeltery.getTemp())
end

arcom.regInitFunction(initialize)
arcom.regMainLoop(mainLoop)

arcom.regInterrupt(estop, "estop")
arcom.regInterrupt(drop, "drop")
arcom.regInterrupt(cast, "cast")
arcom.regInterrupt(getTemp, "getTemp")

arcom.startServer()
arcom.clearup()
