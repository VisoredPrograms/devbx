local module = {}

-- Constants

-- API References
local process = require("@lune/process")

function module.spawn(program: string, params: { string }, options: process.ExecOptions?): { [string]: any }
	local response = process.exec(program, params, options)

	if response.stderr and response.stderr ~= "" then
		warn(response.stderr)
	end

	if response.stdout and response.stdout ~= "" then
		print(response.stdout)
	end

	return response
end

return module
