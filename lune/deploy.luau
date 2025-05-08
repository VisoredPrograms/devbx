-- API References
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

-- Modules
local helper = require("./lib/helper")

-- Variables
local isFile = fs.isFile("./game.rbxl")
assert(isFile, "Attempted action failed — missing required game file.")

-- Main execution
local command = roblox.studioApplicationPath() -- (process.os == "windows") and "explorer" or "open"
helper.spawn(command, { "game.rbxl" })
