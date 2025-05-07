local module = {}

-- API References
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

-- Modules
local remodel = require("./lib/remodel")
local dotenv = require("./lib/dotenv")
dotenv.init()

-- Downloads a Roblox place by ID, extracts key services, and writes them to disk.
-- `module.dump` or `module.export`
function module.dump(placeId: number | string): ()
	-- Download the asset content
	local content = remodel.download(placeId)
	local game: any = roblox.deserializePlace(content)

	-- Ensure necessary directories exist
	if not fs.isDir("./map") then
		fs.writeDir("./map")
	end

	if not fs.isDir("./assets") then
		fs.writeDir("./assets")
	end

	-- Save the models to files
	fs.writeFile("./map/Workspace.rbxm", roblox.serializeModel({ game.Workspace }))
	fs.writeFile("./map/Lighting.rbxm", roblox.serializeModel({ game.Lighting }))
	fs.writeFile(`./assets/Models.rbxm`, roblox.serializeModel({ game.ReplicatedStorage }))
end

-- Downloads the raw place file and saves it to disk.
function module.download(placeId: number | string)
	local content = remodel.download(process.env.PLACE_ID)
	fs.writeFile("./game.rbxl", content)
end

-- Downloads and saves the place, assets, and game file.
function module.init()
	local placeId = process.env.PLACE_ID
	assert(placeId, "Attempted action aborted — missing required place id.")

	module.download(placeId)
	module.dump(placeId)

	process.exec("rojo", { "build -o game.rbxl" })
	process.exec("asphalt", { "sync" })
end

-- Main execution
module.init()

return module
