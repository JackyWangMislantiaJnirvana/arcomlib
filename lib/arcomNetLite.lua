local ArcomNetLite = {}
ArcomNetLite.__index = ArcomNetLite

function ArcomNetLite.new (hostName, netModem)
  if type(hostName) ~= "string" or type(netModem) ~= "table" then
    error("ArcomNetLite: new(): bad args. host name and a wrap table of modem required.")
  end

  local object = {}
  setmetatable(object, ArcomNetLite)

  -- Attributes of class ArcomNetLite
  object.hostName = hostName
  object.netModem = netModem

  return object
end

function sendMsg (dest, targetISR, args)
  if type(dest) ~= "string"
      or type(targetISR) ~= "string"
      or type(args) ~= "table" then
    error( "ArcomNetLite: sendMsg(): bad args. Destination Node's name, ISR's name and table of arguments required.")
    -- Todo
  end
end

function sendFeedback (stat, msg)
  if type(stat) ~= "string" or type(msg) ~= "string" then
    error("ArcomNetLite: sendFeedback(): bad args. Status string(OK, etc) and message required.")
  end
  -- Todo
end

function pullMsg (timeout)
  if type(timeout) ~= "number" then
    error("ArcomNetLite: pullMsg(): bad args. Timeout required.")
  end
  -- Todo
end

function pullFeedback (timeout)
  if type(timeout) ~= "number" then
    error("ArcomNetLite: pullFeedback(): bad args. Timeout required.")
  end
  -- Todo
end
