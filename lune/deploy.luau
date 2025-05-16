-- API References
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

-- References
local helper = require("./modules/helper")
local env = serde.decode("toml", fs.readFile("./.env"))
local placeName = env.OUTPUT_NAME or "game"

-- Variables
local isFile = fs.isFile(`./{placeName}.rbxl`)
assert(isFile, "(!!) Could not find 'game' (expected type: place)")

-- Main execution
print("(!) Processing 'game'. Stay patient.")

local command = roblox.studioApplicationPath() -- (process.os == "windows") and "explorer" or "open"
helper.spawn(command, { `./{placeName}.rbxl` })
helper.spawn("rojo", { "serve" }, { stdio = "forward" })
