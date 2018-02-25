local M2M = dofile("/lib/M2M.lua")
local m2m = M2M.new("sender", "top")

m2m:sendMsg("receiver", "test", "Hello, Arcomlib!")

-- Test wrong hostname
m2m:sendMsg("greg", "test", "Hello, Greg!")