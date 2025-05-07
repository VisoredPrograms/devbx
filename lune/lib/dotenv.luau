local module = {}

-- Constants
local ENV_PATH = "./.env"

-- API References
local fs = require("@lune/fs")
local process = require("@lune/process")

-- Reads the .env file and loads key-value pairs into the store table.
function module.init(): ()
	local isFile = fs.isFile(ENV_PATH)
	assert(isFile, "Attempted action aborted — could not find file.")

	local content = fs.readFile(ENV_PATH)
	assert(content, "Attempted action aborted — could not fetch data.")

	-- Read each line in the file
	for line in content:gmatch("[^\r\n]+") do
		if line == "" or line:match("^%s*#") then
			continue
		end

		local key, value = line:match("^%s*(%S+)%s*=%s*(.+)%s*$")
		if not key or not value then
			warn("Attempted action skipped — could not fetch valid key/value.")
			continue
		end

		value = value:gsub('^%s*"?(.-)"?%s*$', "%1")
		process.env[key] = value
	end
end

return module
