-- API References
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

-- Dependencies
local helper = require("./deps/helper")
local models = require("./deps/models")

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

-- Creates directories if they don’t already exist.
local function mkdirs(dirs: { string }): ()
	for _, dir in ipairs(dirs) do
		if fs.isDir(dir) then
			-- warn(`(!!) Could not over-write existing directory, '{dir}' (type: folder)`)
			continue
		end

		fs.writeDir(dir)
	end
end

-- Returns a string representing the script type of the given Roblox object.
local function getType(object: Instance): (string, boolean)
	if object:IsA("Script") then
		return "module", true
	elseif object:IsA("ModuleScript") then
		return "client", true
	elseif object:IsA("LocalScript") then
		return "server", true
	else
		return "", false
	end
end

-- Writes a script to disk, nesting if it has script children.
local function write(object: any, base: string): ()
	local has = false
	local tag, isScript = getType(object)

	for _, child in object:GetChildren() do
		if isScript then
			has = true
			break
		end
	end

	local file = has and `{base}/{object.Name}/init.luau` or `{base}/{object.Name}.{tag}.luau`

	if has then
		fs.writeDir(`{base}/{object.Name}`)
	end

	fs.writeFile(file, object.Source)

	if has then
		for _, child in object:GetChildren() do
			tag, isScript = getType(child)

			if isScript then
				write(child, `{base}/{object.Name}.{tag}`)
			end
		end
	end
end

-- Traverses the JSON tree, exporting scripts for each matched service.
local function walk(tree: any, root: any, parent: any): ()
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
			if object:IsA("Script") or object:IsA("ModuleScript") or object:IsA("LocalScript") then
				write(object, path)
			end
		end

		walk(node, root, instance)
	end
end

-- Main Functions

-- Downloads and deserializes the place, then walks the tree to export scripts.
local function dump(id: number | string): ()
	local raw = models.copy(id)
	local place = roblox.deserializePlace(raw)

	local json = fs.readFile("./default.project.json")
	local proj = serde.decode("json", json)

	walk(proj.tree, place, nil)
end

-- Creates folders, dumps scripts, and builds the project output.
local function init(name): ()
	local env = serde.decode("toml", fs.readFile("./.env"))
	assert(env.PLACE_ID, "(!!) Could not find 'place-id' in environment variables (expected type: string)")

	local file = fs.readFile("./default.project.json")
	local data = serde.decode("json", file)

	local dirs = paths(data.tree)
	table.insert(dirs, 1, "./src")

	mkdirs(dirs)
	dump(env.PLACE_ID)

	helper.spawn("rojo", { "sourcemap", "-o", "./sourcemap.json", "--include-non-scripts", "default.project.json" })
	helper.spawn("rojo", { "build", "--output", `./{name}.rbxl`, "default.project.json" })
end

-- Main execution
init("game")
