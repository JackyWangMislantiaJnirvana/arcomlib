-- PickleJar.lua
-- Provide non-violate storage of a non-nested table.
-- Arcomlib rev3
_DEBUG = false

local PickleJar = {}

-- Support handy usage: (if a PickleJar object is called "pk")
-- pk[Name] = valueWantedToBePickled
function PickleJar.__index (obj, key)
  if _DEBUG then print("[DEBUG]Calling PickleJar.__index, key = "..key) end

  return getmetatable(obj)[key] or obj.valueTable[key]
end

function PickleJar.__newindex (obj, key, val)
  if _DEBUG then
      print("[DEBUG]Calling PickleJar.__newindex, key = "..key)
      print("[DEBUG]val = "..val)
  end

  obj.valueTable[key] = val
  obj:flush()
end

-- Constructor
function PickleJar.new (targetFile)
  if type(targetFile) ~= "string" then
    error("PickleJar: new: bad target file.")
  end

  -- COMPAT: fs API are called filesystem in OC
  local object = {}

  -- If file doesn't exist, make a new one.
  if fs.exists(targetFile) == false then
    fs.open(targetFile, "w").close()
  end

  setmetatable(object, PickleJar)

  -- Init attributes
  -- Using rawset to avoid any metamethods magic
  -- (Because __index is overloaded for index access
  -- for pickled values.)
  rawset(object, "targetFile", targetFile)
  rawset(object, "valueTable", {})

  -- Initialy load content from file
  object:load()

  return object
end

function PickleJar:flush ()
  local resultString = ""
  local file_w = fs.open(self.targetFile, "w")
  for k,v in pairs(self.valueTable) do
    resultString = resultString..k.."="..v.."\n"
  end

  if _DEBUG then print("[DEBUG]in flush "..resultString) end

  file_w.write(resultString)
  file_w.close()
end

function PickleJar:load ()
  local file_r = fs.open(self.targetFile, "r")
  local rawString = file_r.readAll()

  if _DEBUG then print("[DEBUG]loaded string: "..rawString) end

  for k, v in string.gmatch(rawString, "(%w+) *= *(%w+)") do

    if _DEBUG then print("[DEBUG]loaded: k = "..k.." v = "..v) end

    self.valueTable[k] = v
  end
  file_r.close()
end

function PickleJar:getAll ()
  return self.valueTable
end

function PickleJar:setAll (t)
  if type(t) ~= "table" then
    error("PickleJar.setAll: feed me with a table to override all pickled value!")
  end
  self.valueTable = t
  self:flush()
end

--[[
function PickleJar_mt.__index(tab, key)
  --debug
  print("__index called, key = "..key)
  print(type(key))
  return tab.valueTable[key]
end

function PickleJar_mt.__newindex(tab, key, value)
  --debug
  print("__newindex called")
  tab.valueTable[key] = value
  tab:flush()
end
--]]
return PickleJar
