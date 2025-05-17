local module = {}

-- API References
local process = require("@lune/process")

-- Constants
local spawn_options: process.ExecOptions? = { stdio = "forward" } -- { shell = "powershell", stdio = "forward" }

function module.spawn(program: string, params: { string }, options: process.ExecOptions?): { [string]: any }
	options = options or spawn_options
	local response = process.exec(program, params, options)

	if response.stderr and response.stderr ~= "" then
		warn(`(!!) Could not execute '{program}' (expected type: 'process'): {response.stderr}`)
	end

	if response.stdout and response.stdout ~= "" then
		print(`(!) Could not execute '{program}' (expected type: 'process'): {response.stdout}`)
	end

	return response
end

return module
