local PickleJar = dofile("/lib/PickleJar.lua")
local generalStatus = PickleJar.new("/Testers/wow.conf")

--[[]]
print("accessing pre-readed value b.")
print("generalStatus[\"b\"]= "..generalStatus["b"])
print("Set a = 123")
generalStatus["a"] = 123
print("Reading a")
print("read: generalStatus[\"a\"] = "..generalStatus["a"])
--]]
