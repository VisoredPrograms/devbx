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

-- Helpers

-- Ensures the required directory structure exists under ./src.
function module.mkdirs(directories: { string }): ()
	for _, dir in directories do
		if fs.isDir(dir) then
			-- print(`Directory structure validated — dir, \"{dir}\", already exists.`)
			continue
		end

		fs.writeDir(dir)
	end
end

local function exportScripts(container: Instance, path: string): ()
	for _, object in ipairs(container:GetDescendants()) do
		-- Skip non-script objects
		if not (object:IsA("Script") or object:IsA("ModuleScript") or object:IsA("LocalScript")) then
			continue
		end

		-- Check if this script has any child scripts
		local Pregnant = false
		for _, child in ipairs(object:GetChildren()) do
			if child:IsA("Script") or child:IsA("ModuleScript") or child:IsA("LocalScript") then
				Pregnant = true
				break
			end
		end

		local dir = `./src/{path}`
		local filePath: string

		if Pregnant then
			-- If it has script children, create a folder with `init.luau`
			filePath = `{dir}/{object.Name}/init.luau`
			fs.writeDir(`{dir}/{object.Name}`)
		else
			-- If no script children, save directly as `ScriptName.luau`
			filePath = `{dir}/{object.Name}.luau`
		end

		fs.writeFile(filePath, object.Source)

		-- Recursively export child scripts (if any)
		if Pregnant then
			exportScripts(object, `{path}/{object.Name}`)
		end
	end
end

-- Functions

-- Downloads a Roblox place by ID, extracts key services, and writes them to disk.
-- `module.dump` or `module.export`
function module.dump(placeId: number | string): ()
	-- Download the asset content
	local content = remodel.download(placeId)
	local game: any = roblox.deserializePlace(content)

	-- Services
	local StarterPlayer = game:GetService("StarterPlayer")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local ServerStorage = game:GetService("ServerStorage")

	-- Main execution
	exportScripts(StarterPlayer, "client")
	exportScripts(ReplicatedStorage, "shared")
	exportScripts(ServerScriptService, "server")
	exportScripts(ServerStorage, "server")
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

	local directories = {
		"./src",
		"./src/client",
		"./src/shared",
		"./src/server",
	}
	module.mkdirs(directories)

	-- module.download(placeId, output)
	module.dump(placeId)

	helper.spawn(
		"rojo",
		{ "sourcemap", "--output", "./sourcemap.json", "--include-non-scripts", "default.project.json" },
		{ stdio = "forward" }
	)
	-- helper.spawn("asphalt", { "sync", "--target", "studio" }, { stdio = "forward" })
	helper.spawn("rojo", { "build", "--output", `./{output}.rbxl`, "default.project.json" }, { stdio = "forward" })
end

-- Main execution
module.init(env.OUTPUT_NAME)

return module
