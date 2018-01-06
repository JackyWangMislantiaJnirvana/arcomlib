-- Constant Values
local STAT_UNINIT = "uninited"
local STAT_HALT = "halt"
local STAT_RUNNING = "enabled"
local STAT_PAUSED = "disabled"
local STAT_MALFUNC = "failed"
local PICKLE_FILENAME = "/usr/arcomPickle"

local arcomStd = {}
arcomStd.__index = arcomStd

function arcomStd.new (h_net, h_pickler)
  if type(h_net) ~= "table" or type(h_pickler) ~= "table" then
    error("ArcomStd: new(): bad args. arcomnet handle and table pickler handle required.")
  end

  local object = {}
  setmetatable(object, arcomStd)

  -- Attributes of class ArcomStd
  object.picklerHandle = h_pickler.new(PICKLE_FILENAME)
  object.netHandle = h_net
    -- Make sure Node's status is restored properly
    -- right after a HARD exiting
  object.pickledVars = object.picklerHandle:get()
  object.status = object.pickledVars.status or STAT_UNINIT
  object.ISRTable = {}

  return object
end

-- Registering methods
function arcomStd:regLoop(loopFunc)
  if type(loopFunc) ~= "function" then
    error("ArcomStd: regLoop(): bad args. Loop function required.")
  end

  --[[ wrap original loopFunc.
  loopFunc is called periodically
  when the node is enabled.
  --]]
  self.loopFunctionWrap = function ()
    while self.status == "enabled" do
      loopFunc()
    end
  end
end

function arcomStd:regInit(initFunc)
  if type(initFunc) ~= "function" then
    error("ArcomStd: regInit(): bad args. Init function required.")
  end

  --[[ Wrap original initFunc
  initFunc is called once when startup
  if the Node ISN'T running.
  (This mechanism aims to avoid duplicated
  initialization when re-enter the world)
  (Because CC's computer shutdown on exiting the world)
  --]]
  self.initFunction = function ()
    if self.status ==  STAT_UNINIT then
      initFunc()
    end
  end
end

function arcomStd:regSafety(safeProtc)
  if type(safeProtc) ~= "function" then
    error("ArcomStd: regSafety(): bad args. Safety Protocol function required.")
  end
  -- Wrap safety thread
  self.safetyProtocol = function ()
    safeProtc()
  end
end

function arcomStd:regEmergency (eFunc)
  if type(eFunc) ~= "function" then
    error("ArcomStd: regEmergency(): bad args. Emergency function required.")
  end
  self.eFunction = eFunc
end

function arcomStd:regISR (ISR, name)
  if type(ISR) ~= "function" or type(name) ~= "string" then
    error("ArcomStd: regInt(): bad args. ISR function and its name required.")
  end
  self.ISRTable[name] = ISR
end

-- ISR interface methods
function arcomStd:changeStat (stat)
  print("Todo!")
end

function arcomStd:innerInterrupt (targetISR, args)
  print("Todo!")
end

function arcomStd:getPickleVal (name)
  print("Todo!")
end

function arcomStd:writePickleVal (name, val)
  print("Todo!")
end

-- Private methods
function arcomStd:callISR (ISRName, args)
  print("Todo!")
end

-- Node Operations
  -- Main Entrance of StdNode program
  -- Protected using pcall()
function arcomStd:startNode ()
  print("Todo!")
end
