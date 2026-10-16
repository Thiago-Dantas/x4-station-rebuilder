-- Easy Station Rebuild: hands the engine's list of removed modules to the MD scripts.
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

-- each removed module's equipment as the menu read it before Confirm (GetCurrentLoadout): station equipment can't be
-- found by MD searches (automated runs 10-12), so it is sent along. Flat list for the UI event:
-- { station, module, macro, count, macro, count, module, ... }; only modules with equipment.
local function equipmentCounts(plan)
	local counts, found = {}, false
	for _, kind in ipairs({ "turretgroup", "shieldgroup" }) do
		for _, group in pairs(plan[kind] or {}) do
			if type(group) == "table" and (group.macro or "") ~= "" and (group.count or 0) > 0 then
				counts[group.macro] = (counts[group.macro] or 0) + group.count
				found = true
			end
		end
	end
	if not found then
		-- no groups: single slots (macro names, or tables with a macro)
		for _, kind in ipairs({ "turret", "shield" }) do
			for _, slot in pairs(plan[kind] or {}) do
				local macro = (type(slot) == "table") and slot.macro or slot
				if (type(macro) == "string") and (macro ~= "") then
					counts[macro] = (counts[macro] or 0) + 1
				end
			end
		end
	end
	return counts
end

local function sendEquipment()
	local list = { ConvertStringToLuaID(tostring(menu.container)) }
	for _, entry in ipairs(menu.removedModules or {}) do
		local counts = equipmentCounts(entry.upgradeplan or {})
		if next(counts) then
			table.insert(list, ConvertStringToLuaID(tostring(entry.component)))
			for macro, count in pairs(counts) do
				table.insert(list, macro)
				table.insert(list, count)
			end
		end
	end
	AddUITriggeredEvent(menu.name, "esr_equipment", list)
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
		-- equipment first: MD stores it before the removed-module list starts the sweep
		local ok, err = pcall(sendEquipment)
		if not ok then
			DebugError("[ESR] sending equipment of removed modules failed: " .. tostring(err))
		end
		ok, err = pcall(sendRemoved)
		if not ok then
			DebugError("[ESR] sending removed modules failed: " .. tostring(err))
		end
		return buttonConfirm(...)
	end
end

init()
