-- API References
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

-- Dependencies
local helper = require("./deps/helper")

-- References
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
