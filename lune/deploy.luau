-- API References
local process = require("@lune/process")

-- Modules
local build = require("./build")
build.init()

-- Main execution
local command = (process.os == "windows") and "explorer" or "open"
local result = process.exec(command, { "game.rbxl" })

assert(result.stderr, `Attempted action failed — Error: {result.stderr}`)
print(`Ready! Output: {result.stdout or "None"}`)
