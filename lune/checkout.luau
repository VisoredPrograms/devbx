-- API References
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

-- Dependencies
local helper = require("./modules/helper")

-- References
local toml = fs.readFile("./.env")
local env = serde.decode("toml", toml)
local name = env.OUTPUT_NAME or "game"

-- Variables
local isFile = fs.isFile("./" .. name .. ".rbxl")
local studioCmd = roblox.studioApplicationPath() -- (process.os == "windows") and "explorer" or "open"

-- Assertations
assert(isFile, "(!!) devbx: could not find '" .. name .. "' (expected type: place)")

-- Main execution
print("(!) devbx: attempting to execute rbx place file")
helper.spawn(studioCmd, { "./" .. name .. ".rbxl" })
print("(!) devbx: place file initiated successfully")
helper.spawn("rojo", { "serve" }, { stdio = "forward" })
