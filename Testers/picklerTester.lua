local Pickler = dofile("/lib/pickler.lua")
local p = Pickler.new("/examples/wow.conf")
local t = {a="b", b="c", c="d"}
print("p:dump()")
p:dump(t)
print("p:read()")
local tb = p:get()
for k, v in pairs(tb) do
  print(k.."="..v)
end
