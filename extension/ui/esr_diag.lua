-- Easier Station Rebuilder: diagnostic logger (Lua side).
-- Wraps the station build menu's Confirm button and writes what the game is about
-- to do to debuglog.txt, before the engine applies the plan change. Changes nothing.
-- Every line starts with "[ESR]" so the log can be filtered.

local ffi = require("ffi")
local C = ffi.C

local menu

local function log(text)
	DebugError("[ESR] " .. text)
end

local function wares(list)
	local parts = {}
	for _, entry in ipairs(list or {}) do
		table.insert(parts, tostring(entry.ware) .. "=" .. tostring(entry.amount))
	end
	return "{" .. table.concat(parts, ", ") .. "}"
end

-- same form as MD prints components (0x88f4e), so Lua and MD lines can be matched
local function hexid(id)
	local ok, text = pcall(function () return string.format("0x%x", tonumber(id)) end)
	return ok and text or tostring(id)
end

local function stationName()
	local ok, name = pcall(function () return ffi.string(C.GetComponentName(menu.container)) end)
	return ok and name or "?"
end

local function logConfirm()
	log(string.format("CONFIRM station=%s id=%s plan=%d new-index=%s", stationName(), hexid(menu.container), #(menu.constructionplan or {}), tostring(menu.newModulesIndex)))
	log("CONFIRM build storage=" .. wares(menu.buildstorageresources))

	local unchanged, changed, changedexisting = 0, 0, 0
	for i, entry in ipairs(menu.constructionplan or {}) do
		if menu.changedModulesIndices and menu.changedModulesIndices[i] then
			changed = changed + 1
			-- an existing component on a changed entry means the module stays but changes (e.g. equipment)
			local existing = entry.component ~= nil and entry.component ~= 0
			if existing then
				changedexisting = changedexisting + 1
			end
			log(string.format("CONFIRM changed #%d %s component=%s existing=%s needs=%s", i, tostring(entry.macro), hexid(entry.component), tostring(existing), wares(entry.resources)))
		else
			unchanged = unchanged + 1
		end
	end

	local removed = menu.removedModules or {}
	log(string.format("CONFIRM summary unchanged=%d changed=%d (existing %d) removed=%d", unchanged, changed, changedexisting, #removed))
	for i, entry in ipairs(removed) do
		-- the menu stores recycled resources as negative amounts (they reduce what is needed)
		local recycled = {}
		for _, resource in ipairs(entry.resources or {}) do
			table.insert(recycled, { ware = resource.ware, amount = -resource.amount })
		end
		log(string.format("CONFIRM removed #%d %s component=%s recycled=%s", i, tostring(entry.macro), hexid(entry.component), wares(recycled)))
	end
end

local function init()
	for _, m in ipairs(Menus or {}) do
		if m.name == "StationConfigurationMenu" then
			menu = m
			break
		end
	end
	if not menu then
		log("station build menu not found; Confirm is not logged")
		return
	end

	local buttonConfirm = menu.buttonConfirm
	menu.buttonConfirm = function (...)
		local ok, err = pcall(logConfirm)
		if not ok then
			log("logging Confirm failed: " .. tostring(err))
		end
		return buttonConfirm(...)
	end
	log("Lua logger loaded")
end

init()
