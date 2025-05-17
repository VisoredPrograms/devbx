-- API References
local fs = require("@lune/fs")
local serde = require("@lune/serde")

-- Dependencies
local helper = require("./modules/helper")

-- References
local toml = fs.readFile("./.env")
local env = serde.decode("toml", toml)
local name = env.OUTPUT_NAME or "game"

-- Main execution
print("(!) devbx: attempting to record local changes for rbx place file")

helper.spawn("rojo", { "sourcemap", "-o", "./sourcemap.json", "--include-non-scripts", "default.project.json" })
helper.spawn("rojo", { "build", "-o", "./" .. name .. ".rbxl", "default.project.json" })

print("(!) devbx: local changes recorded — assets and scripts synced to place file history")
