-- API References
local fs = require("@lune/fs")
-- local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

-- Modules
local helper = require("./lib/helper")

-- Constants
local env = serde.decode("toml", fs.readFile("./.env"))

-- Variables
local isFile = fs.isFile(`./{env.OUTPUT_NAME}.rbxl`)
assert(isFile, "Attempted action failed — missing required game file.")

-- Main execution
print("Attempted action successful — starting game.")

local command = roblox.studioApplicationPath() -- (process.os == "windows") and "explorer" or "open"
helper.spawn(command, { `./{env.OUTPUT_NAME}.rbxl` })
helper.spawn("rojo", { "serve" }, { stdio = "forward" })
