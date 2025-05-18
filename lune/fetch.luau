-- API References
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

-- Dependencies
local models = require("./modules/models")

-- Helpers

-- Replaces only invalid filesystem characters in names, not path separators.
local function sanitize(name: string): string
	local str = tostring(name)
	str = str:gsub("%s+", "_") -- Replace all whitespace characters with underscore
	str = str:gsub('[:<>"\\|%?%*]', "") -- Remove invalid symbols completely
	return str
end

-- Returns all "$path" strings found recursively in the given tree.
local function paths(tree: any): { string }
	local list = {}

	for idx, node in pairs(tree) do
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
	for idx, dir in ipairs(dirs) do
		if fs.isDir(dir) then
			-- warn("(!!) devbx: could not over-write existing directory, '" .. dir .. "' (type: folder)")
			continue
		end

		fs.writeDir(dir)
	end
end

-- Returns the full path of a Roblox instance from the root to the object.
local function getPath(object: Instance): string
	local path = {}

	while object.Parent and object ~= game do
		table.insert(path, 1, object.Name)
		object = object.Parent
	end

	return "./src/" .. table.concat(path, "/")
end

-- Returns a string representing the script type of the given Roblox object.
local function getType(object: Instance): (string, boolean)
	if object:IsA("Script") then
		return "server", true
	elseif object:IsA("ModuleScript") then
		return "", true
	elseif object:IsA("LocalScript") then
		return "client", true
	else
		return "unknown", false
	end
end

-- Writes a script to disk, nesting if it has script children.
local function write(object: any): ()
	local tag, isScript = getType(object)

	if not isScript then
		return
	end

	local path = getPath(object)
	path = sanitize(path)

	local products = {} -- Check if this script has any descendant scripts

	for idx, instance in object:GetChildren() do
		local _, instanceScript = getType(instance)
		if instanceScript then
			table.insert(products, instance)
			break
		end
	end

	if #products < 0 then
		if not fs.isDir(path) then
			fs.writeDir(path)
		end

		path = sanitize(`{path}/init.luau`) -- If it has script children, create a folder with `init.luau`
	else
		local dir = path:match("^(.*)/") or "."
		if not fs.isDir(dir) then
			fs.writeDir(dir)
		end

		path = sanitize(`{path}.{tag}.luau`) -- If no script children, save directly as `ScriptName.tag.luau`
	end

	fs.writeFile(path, object.Source)

	for _, product in products do
		write(product) -- Recursively export child scripts (if any)
	end
end

-- Traverses the JSON tree, exporting scripts for each matched service.
local function walk(tree: any, root: any): ()
	for idx, node in pairs(tree) do
		if type(node) ~= "table" or not node["$className"] then
			continue
		end

		local class = node["$className"]
		local path = node["$path"]
		local instance = root:FindFirstChildOfClass(class)

		if instance and path then
			for _, object in instance:GetDescendants() do
				write(object)
			end
		end
	end
end

-- Main Functions

-- Downloads and deserializes the place, then walks the tree to export scripts.
local function dump(id: number | string): ()
	local raw = models.copy(id)
	local place = roblox.deserializePlace(raw)

	local json = fs.readFile("./default.project.json")
	local project = serde.decode("json", json)

	walk(project.tree, place)
end

-- Creates folders, dumps scripts, and builds the project output.
local function init(name): ()
	-- Read environment variables
	local toml = fs.readFile("./.env")
	local env = serde.decode("toml", toml)
	assert(env.PLACE_ID, "(!!) devbx: could not find 'place-id' in environment variables (expected type: string)")

	-- Read project configuration
	local file = fs.readFile("./default.project.json")
	local project = serde.decode("json", file)
	local tree = project.tree
	assert(tree, "(!!) devbx: could not find 'tree' in json (expected type: table)")

	local dirs = paths(tree)
	table.insert(dirs, 1, "./src")

	mkdirs(dirs)
	dump(env.PLACE_ID)
end

-- Main execution
print("(!) devbx: checking Roblox place file for remote updates")
init("game")
print("(!) devbx: update check complete — latest place file metadata retrieved")
