-- API References
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

-- Dependencies
local helper = require("./deps/helper")

-- Helpers

-- Returns all "$path" strings found recursively in the given tree.
local function paths(tree: any): { string }
	local list = {}

	for _, node in pairs(tree) do
		if type(node) ~= "table" then
			continue
		end

		if node["$path"] then
			table.insert(list, node["$path"])
		end

		for _, sub in paths(node) do
			table.insert(list, sub)
		end
	end

	return list
end

-- Returns a string representing the script type of the given Roblox object.
local function getType(object: Instance): (string, boolean)
	if object:IsA("Script") then
		return "", true
	elseif object:IsA("ModuleScript") then
		return ".client", true
	elseif object:IsA("LocalScript") then
		return ".server", true
	else
		return ".unknown", false
	end
end

-- Reads a script from disk and updates it in the Roblox instance
local function update(object: any, base: string): boolean
	local hasChildren = false
	local tag, isScript = getType(object)

	-- Check if this is a script container (has script children)
	for _, child in object:GetChildren() do
		tag, isScript = getType(child)
		if isScript then
			hasChildren = true
			break
		end
	end

	local filePath = hasChildren and `{base}/{object.Name}/init.luau` or `{base}/{object.Name}{tag}.luau`

	if not fs.isFile(filePath) then
		return false
	end

	-- Update the script source
	object.Source = fs.readFile(filePath)

	-- Recursively update child scripts if this is a container
	if hasChildren then
		for _, child in object:GetChildren() do
			tag, isScript = getType(child)
			if isScript then
				update(child, `{base}/{object.Name}`)
			end
		end
	end

	return true
end

-- Traverses the JSON tree, updating scripts for each matched service.
local function walkAndUpdate(tree: any, root: any, parent: any): ()
	for _, node in pairs(tree) do
		if type(node) ~= "table" or not node["$className"] then
			continue
		end

		local class = node["$className"]
		local path = node["$path"]
		local instance = parent and parent:FindFirstChildOfClass(class) or root:FindFirstChildOfClass(class)

		if not instance or not path then
			continue
		end

		for _, object in instance:GetDescendants() do
			local _, isScript = getType(object)
			if isScript then
				update(object, path)
			end
		end

		walkAndUpdate(node, root, instance)
	end
end

-- Main Functions

-- Updates an existing place file with modified scripts
local function updatePlace(inputFile: string, outputFile: string)
	-- Read the existing place file
	local placeData = fs.readFile(inputFile)
	local place = roblox.deserializePlace(placeData)

	-- Read project configuration
	local json = fs.readFile("./default.project.json")
	local project = serde.decode("json", json)

	-- Update scripts from source files
	walkAndUpdate(project.tree, place, nil)

	-- Serialize and write the updated place file
	local updatedData = roblox.serializePlace(place)
	fs.writeFile(outputFile, updatedData)
end

-- Updates scripts and rebuilds the project
local function upload(name: string)
	local env = serde.decode("toml", fs.readFile("./.env"))
	assert(env.PLACE_ID, "(!!) Could not find 'PLACE_ID' in environment variables")

	-- Generate sourcemap first to ensure proper script locations
	helper.spawn("rojo", { "sourcemap", "-o", "./sourcemap.json", "--include-non-scripts", "default.project.json" })

	-- Update the place file with modified scripts
	updatePlace(`./{name}.rbxl`, `./{name}_updated.rbxl`)

	-- Replace the original file with the updated one
	-- fs.remove(`./{name}.rbxl`)
	-- fs.rename(`./{name}_updated.rbxl`, `./{name}.rbxl`)

	print(`Successfully updated {name}.rbxl with local script changes`)
end

-- Main execution
upload("game")
