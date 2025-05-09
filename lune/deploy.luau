-- API References
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

-- References
local helper = require("./modules/helper")
local env = serde.decode("toml", fs.readFile("./.env"))

-- Variables
local isFile = fs.isFile(`./{env.OUTPUT_NAME}.rbxl`)
assert(isFile, "Attempted action failed — missing required game file.")

-- Main execution
print("Attempted action successful — starting game.")

local command = roblox.studioApplicationPath() -- (process.os == "windows") and "explorer" or "open"
helper.spawn(command, { `./{env.OUTPUT_NAME}.rbxl` })
helper.spawn("rojo", { "serve" }, { stdio = "forward" })
