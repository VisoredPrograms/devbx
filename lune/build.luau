local module = {}

-- API References
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

-- References
local helper = require("./modules/helper")
local remodel = require("./modules/remodel")
-- dotenv.init()
local env = serde.decode("toml", fs.readFile("./.env"))

-- Downloads a Roblox place by ID, extracts key services, and writes them to disk.
-- `module.dump` or `module.export`
function module.dump(placeId: number | string): ()
	-- Download the asset content
	local content = remodel.download(placeId)
	local game: any = roblox.deserializePlace(content)

	-- Ensure necessary directories exist
	if not fs.isDir("./assets") then
		fs.writeDir("./assets")
	end

	-- Services
	local workspace = game:GetService("Workspace")

	-- Main execution
	for _, object in workspace:GetChildren() do
		local file = roblox.serializeModel({ object })
		fs.writeFile("./assets/" .. object.Name, file)
	end
end

-- Downloads the raw place file and saves it to disk.
function module.download(placeId: number | string, output: string)
	local content = remodel.download(placeId)
	fs.writeFile(`./{output}.rbxl`, content)
end

-- Downloads and saves the place, assets, and game file.
function module.init(output: string)
	local placeId = env.PLACE_ID
	assert(placeId, "Set up aborted — missing required place id.")

	module.download(placeId, output)
	-- module.dump(placeId)

	helper.spawn(
		"rojo",
		{ "sourcemap", "--output", "./sourcemap.json", "--include-non-scripts", "./default.project.json" },
		{ stdio = "forward" }
	)
	-- helper.spawn("asphalt", { "sync", "--target", "studio" }, { stdio = "forward" })
	helper.spawn("rojo", { "build", "--output", `./{output}.rbxl`, "./default.project.json" }, { stdio = "forward" })
end

-- Main execution
module.init(env.OUTPUT_NAME)

return module
