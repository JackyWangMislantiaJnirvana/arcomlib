-- Table pickler
-- Programmed in standard Lua oo style(: syntax and metatable)
-- Part of arcomlib

local pickler = {}
pickler.__index = pickler

function pickler:dump (t)
  local resultString = ""
  local file_w = fs.open(self.targetFile, "w")
  for k,v in pairs(t) do
    resultString = resultString..k.."="..v.."\n"
  end
  file_w.write(resultString)
  file_w.close()
end

function pickler:get ()
  local resultTable = {}
  local rawString = self.file_r.readAll()
  for k, v in string.gmatch(rawString, "(%w+)=(%w+)") do
    resultTable[k] = v
  end
  return resultTable
end

function pickler.new (targetFile)
  if type(targetFile) ~= "string" then
    error("Pickler: new: bad target file.")
  end

  -- COMPAT: fs API are called filesystem in OC
  local object = {}
  setmetatable(object, pickler)
  object.targetFile = targetFile

  if fs.exists(targetFile) ~= true then
    fs.open(targetFile, "w").close()
  end
  object.file_r = fs.open(targetFile, "r")

  return object
end


return pickler
