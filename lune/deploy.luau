-- API References
local fs = require("@lune/fs")
local process = require("@lune/process")

-- Modules
local isFile = fs.isFile("./game.rbxl")
assert(isFile, "Attempted action failed — missing required game file.")

-- Main execution
local command = (process.os == "windows") and "explorer" or "open"
local result = process.exec(command, { "game.rbxl" })

assert(result.stderr, `Attempted action failed — Error: {result.stderr}`)
print(`Ready! Output: {result.stdout ~= "" and result.stdout or "None"}`)
