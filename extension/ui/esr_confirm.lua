-- Easier Station Rebuilder: hands the engine's list of removed modules to the MD scripts.
-- The station build menu asks the engine which modules a plan change removes (menu.removedModules,
-- filled from GetRemovedConstructionPlanModules2). When the player confirms, this sends
-- { station, build method, removed module 1, removed module 2, ... } as a UI event; ESR_Main (MD)
-- listens for screen "StationConfigurationMenu", control "esr_confirm" and uses the list as the
-- doomed modules. The build method (e.g. "default", "terran") decides which recipe a refund uses.

local ffi = require("ffi")
local C = ffi.C

local menu

-- the build storage's own setting, else the player's global one (as the build menu shows them)
local function buildMethod()
	local ok, method = pcall(function ()
		local own = ffi.string(C.GetContainerBuildMethod(menu.buildstorage))
		if own ~= "" then
			return own
		end
		return ffi.string(C.GetPlayerBuildMethod())
	end)
	return ok and method or ""
end

local function sendRemoved()
	local list = { ConvertStringToLuaID(tostring(menu.container)), buildMethod() }
	for _, entry in ipairs(menu.removedModules or {}) do
		table.insert(list, ConvertStringToLuaID(tostring(entry.component)))
	end
	AddUITriggeredEvent(menu.name, "esr_confirm", list)
end

local function init()
	for _, m in ipairs(Menus or {}) do
		if m.name == "StationConfigurationMenu" then
			menu = m
			break
		end
	end
	if not menu then
		DebugError("[ESR] station build menu not found; removed modules are not sent to MD")
		return
	end

	local buttonConfirm = menu.buttonConfirm
	menu.buttonConfirm = function (...)
		local ok, err = pcall(sendRemoved)
		if not ok then
			DebugError("[ESR] sending removed modules failed: " .. tostring(err))
		end
		return buttonConfirm(...)
	end
end

init()
