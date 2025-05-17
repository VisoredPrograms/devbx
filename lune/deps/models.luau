local module = {}

-- API References
local net = require("@lune/net")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

-- Helpers

-- Returns the auth cookie from Roblox, environment, or CLI args.
function module.getCookie(): string
	local cookie = roblox.getAuthCookie()
	if cookie then
		return cookie
	end

	cookie = process.env.REMODEL_AUTH
	if cookie and #cookie > 0 then
		return `.ROBLOSECURITY={cookie}`
	end

	for index, arg in process.args do
		if arg == "--auth" then
			cookie = process.args[index + 1]
			if cookie and #cookie > 0 then
				return `.ROBLOSECURITY={cookie}`
			end
			break
		end
	end

	error("(!!) Could not find 'auth-cookie' in workspace (expected type: string)")
end

-- Main Functions

-- Downloads an asset by ID and returns its contents.
function module.copy(assetId: number | string): string
	-- Try to find the auth cookie for the current user
	local cookie = module.getCookie()

	-- Send a request to the asset delivery API,
	-- which will respond with cdn download link(s)
	local api_response = net.request({
		url = `https://assetdelivery.roblox.com/v2/assetId/{assetId}`,
		headers = {
			Accept = "application/json",
			Cookie = cookie,
		},
	})

	assert(
		api_response.ok,
		`(!!) Could not complete 'api-request': {api_response.statusCode} — {api_response.statusMessage}: {api_response.body}`
	)

	-- Make sure we got a valid response body
	local content = serde.decode("json", api_response.body)
	if type(content) ~= "table" or type(content.locations) ~= "table" then
		error("(!!) Could not fetch a valid 'response-body' (expected type: table).")
	end

	-- Grab the first asset download location - we only
	-- requested one in our query, so this will be correct
	local path = content.locations[1]
	if type(path) ~= "table" or type(path.location) ~= "string" then
		error("(!!) Could not find any suitable paths (expected type: table)")
	end

	-- Fetch the place contents from the CDN
	local cdn_response = net.request({
		url = path.location,
		headers = {
			Cookie = cookie,
		},
	})

	assert(
		cdn_response.ok,
		`(!!) Could not complete 'cdn-request': {cdn_response.statusCode} — {cdn_response.statusMessage}: {cdn_response.body}`
	)

	-- The response body should now be the contents of the asset file
	return cdn_response.body
end

-- Uploads asset contents to Roblox by asset ID.
function module.sync(assetId: number | string, contents: string): ()
	-- Try to find the auth cookie for the current user
	local cookie = module.getCookie()

	-- Use a different endpoint to fetch a valid CSRF token
	local csrf_headers = {
		["User-Agent"] = "Roblox/WinInet",
		Accept = "application/json",
		Cookie = cookie,
	}

	local csrf_response = net.request({
		url = `https://auth.roblox.com/`,
		body = contents,
		method = "POST",
		headers = csrf_headers,
	})

	local csrf_token = csrf_response.headers["x-csrf-token"]
	assert(csrf_token, "(!!) Could not fetch 'x-csrf-token'.")

	-- Upload the asset to Roblox
	local upload_headers = {
		["User-Agent"] = "Roblox/WinInet",
		["Content-Type"] = "application/octet-stream",
		["X-CSRF-Token"] = csrf_token,
		Accept = "application/json",
		Cookie = cookie,
	}

	local upload_response = net.request({
		url = `https://data.roblox.com/Data/Upload.ashx?assetid={assetId}`,
		body = contents,
		method = "POST",
		headers = upload_headers,
	})

	-- Make sure it uploaded properly
	assert(
		upload_response.ok,
		`(!!) Could not complete 'upload-request': {upload_response.statusCode} — {upload_response.statusMessage}: {upload_response.body}`
	)
end

return module
