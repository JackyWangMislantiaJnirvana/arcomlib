local arcomStd = {}
arcomStd.__index = arcomStd

function arcomStd.new (h_net, h_pickler)
  if type(h_net) ~= "table" or type(h_pickler) ~= "table" then
    error("ArcomStd: new: bad args. arcomnet handle and table pickler handle required.")
  end

  local object = {}
  setmetatable(object, arcomStd)

  -- Attributes of class ArcomStd
  object.netHandle = h_net
  object.picklerHandle = h_pickler
  object.status = ""
  object.pickledVars = {}
  object.ISRTable = {}

  return object
end

-- Registering methods
function arcomStd:regMainLoop (ml)
  print("Todo!")
end

function arcomStd:regInitFunction (initF)
  print("Todo!")
end

function arcomStd:regSafetyProtocol (sp)
  print("Todo!")
end

function arcomStd:regInterrupt (ISR, name)
  print("Todo!")
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
