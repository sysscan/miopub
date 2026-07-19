local REPO = "sysscan/miopub"
local BRANCH = "main"

local GAMES = {
	{ slug = "warfare", placeIds = { 81748781442029, 83902709332473 } },
	{ slug = "apocalypse-rising-2", placeIds = { 863266079 }, universeIds = { 358276974 } },
	{
		slug = "clean-the-library",
		placeIds = { 109881277752094, 78079451644610, 89238670762026, 93995531664434, 115091863501564, 101950101356168 },
		universeIds = { 10226701629 },
	},
	{ slug = "murder-mystery-2", placeIds = { 142823291 }, universeIds = { 66654135 } },
	{ slug = "overkill", placeIds = { 124842176624983 }, universeIds = { 8420998291 } },
	{ slug = "killstreak", placeIds = { 90184287580174 } },
	{ slug = "catch-and-tame", placeIds = { 96645548064314 }, universeIds = { 9091133975 } },
	{ slug = "drain-the-lake", placeIds = { 138381251771774, 124786371598438 }, universeIds = { 10267363348 } },
}

local ALIASES = {
	ar2 = "apocalypse-rising-2",
	mm2 = "murder-mystery-2",
}

local function contains(values, target): boolean
	for _, value in ipairs(values or {}) do
		if value == target then
			return true
		end
	end
	return false
end

local function selectGame(): string?
	local forced = shared.__HubForceGame
	if typeof(forced) == "string" and forced ~= "" then
		forced = forced:lower():gsub("^games/", ""):gsub("/init%.lua$", "")
		return ALIASES[forced] or forced
	end
	for _, entry in ipairs(GAMES) do
		if contains(entry.placeIds, game.PlaceId) or contains(entry.universeIds, game.GameId) then
			return entry.slug
		end
	end
	return nil
end

-- Resolve an executor global by name. On some executors (e.g. Potassium) these
-- are chunk globals not mirrored into getgenv(), so probe every environment.
local function execGlobal(name: string): any
	local direct = rawget(getfenv and getfenv() or {}, name)
	if direct ~= nil then
		return direct
	end
	if typeof(getgenv) == "function" then
		local ok, env = pcall(getgenv)
		if ok and type(env) == "table" and env[name] ~= nil then
			return env[name]
		end
	end
	if type(_G) == "table" and _G[name] ~= nil then
		return _G[name]
	end
	return nil
end

-- A body is only a real bundle if it is non-empty and not an HTTP error page.
-- GitHub returns "404: Not Found" (and HttpGet returns "" on non-200), so both
-- must be rejected or the loader will try to compile the error text as Lua.
local function looksLikeBundle(body: any): boolean
	if typeof(body) ~= "string" or #body == 0 then
		return false
	end
	local head = body:sub(1, 32)
	if head:find("^404: Not Found") or head:find("^400:") or head:find("^Not Found") then
		return false
	end
	return true
end

-- request-style HTTP: request / http_request / syn.request. Returns (body, statusCode).
local function requestBody(url: string): (string?, number?)
	local candidates = { execGlobal("request"), execGlobal("http_request") }
	local synTbl = execGlobal("syn")
	if type(synTbl) == "table" then
		table.insert(candidates, synTbl.request)
	end
	for _, reqFn in ipairs(candidates) do
		if typeof(reqFn) == "function" then
			local ok, res = pcall(reqFn, { Url = url, Method = "GET" })
			if ok and type(res) == "table" then
				local status = tonumber(res.StatusCode or res.status_code or res.Status)
				local body = res.Body or res.body
				if (status == nil or status == 200) and looksLikeBundle(body) then
					return body, status
				end
				return nil, status
			end
		end
	end
	return nil, nil
end

-- Tries every HTTP path an executor might expose; returns (body, diagnostic).
-- diagnostic is a short human string describing why it failed (for error output).
local function fetch(url: string): (string?, string?)
	if typeof(game) == "Instance" then
		local ok, body = pcall(function()
			return game:HttpGet(url, true)
		end)
		if ok and looksLikeBundle(body) then
			return body, nil
		end
	end
	local httpGet = execGlobal("HttpGet")
	if typeof(httpGet) == "function" then
		local ok, body = pcall(httpGet, url)
		if ok and looksLikeBundle(body) then
			return body, nil
		end
	end
	local body, status = requestBody(url)
	if looksLikeBundle(body) then
		return body, nil
	end
	return nil, status and ("HTTP " .. tostring(status)) or "empty/unreachable"
end

if typeof(loadstring) ~= "function" then
	error("[MioHub] loadstring unavailable", 0)
end

local slug = selectGame()
if not slug then
	error("[MioHub] this game is not supported (PlaceId " .. tostring(game.PlaceId) .. ", GameId " .. tostring(game.GameId) .. ")", 0)
end

local now = typeof(tick) == "function" and tick() or os.time()
local stamp = tostring(math.floor(now))

-- Mio releases are generated locally with the maximum/hardened profile. Do not
-- fall back to Atlas or a readable bundle: a missing Mio artifact is a release
-- error, not permission to launch a differently branded or unprotected build.
local FILENAMES = {
	"bundle-obfuscated.lua",
}

local attempts = {}
for _, filename in ipairs(FILENAMES) do
	local path = "games/" .. slug .. "/" .. filename
	table.insert(attempts, {
		path = path,
		url = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/" .. path .. "?t=" .. stamp,
	})
	table.insert(attempts, {
		path = path,
		url = "https://cdn.jsdelivr.net/gh/" .. REPO .. "@" .. BRANCH .. "/" .. path .. "?t=" .. stamp,
	})
end

local lastError = nil
for _, attempt in ipairs(attempts) do
	local ok, source, diag = pcall(fetch, attempt.url)
	if ok and looksLikeBundle(source) then
		local fn, compileError = loadstring(source, "@miohub/" .. attempt.path)
		if fn then
			return fn()
		end
		lastError = "compile error: " .. tostring(compileError)
	elseif ok then
		lastError = tostring(diag) .. " @ " .. attempt.url
	else
		lastError = tostring(source)
	end
end

error(
	"[MioHub] could not download the bundle for "
		.. slug
		.. " ("
		.. tostring(lastError)
		.. "). Checked "
		.. REPO
		.. " for games/"
		.. slug
		.. "/{"
		.. table.concat(FILENAMES, ", ")
		.. "} — none were reachable. Publish the obfuscated bundle for this game, or load from a local workspace.",
	0
)
