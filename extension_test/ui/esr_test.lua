-- Easier Station Rebuild test harness (Lua side). Development only; tools/run-game.ps1 links it in.
-- Start menu: loads ESR_TEST.save (ui/esr_test_config.lua). In game: tells the MD side which scenario to
-- run (UI event screen "ESR_Test", control "scenario"), drives the station build menu for scenarios that
-- need it (Lua event "esr_test_replace"), and quits when MD raises "esr_test_quit".
-- Uses the FFI functions the game's own menus declare (IsStartmenu, IsSaveValid, the construction plan
-- functions); it does not declare them itself, because a second declaration could break those menus.

local ffi = require("ffi")
local C = ffi.C

local config = ESR_TEST or { save = "save_010", scenario = "b6" }

-- the plan the user loaded in their own replacement test (2026-10-15)
local REPLACE_PLAN_ID = "player_1792092162"

local function log(text)
	DebugError("[ESR-TEST] " .. text)
end

local function later(seconds, fn)
	Helper.addDelayedOneTimeCallbackOnUpdate(function ()
		local ok, err = pcall(fn)
		if not ok then
			log("step failed: " .. tostring(err))
		end
	end, true, getElapsedTime() + seconds)
end

local function loadTestSave()
	if not C.IsSaveValid(config.save) then
		log("test save " .. config.save .. " is not valid; nothing loaded")
		return
	end
	log("start menu: loading " .. config.save)
	LoadGame(config.save)
end

local function findMenu(name)
	for _, m in ipairs(Menus or {}) do
		if m.name == name then
			return m
		end
	end
end

-- import the plan file if the library doesn't have the plan yet (as the player does in the build menu)
local function importPlan(id)
	local n = C.GetNumConstructionPlans()
	local buf = ffi.new("UIConstructionPlan[?]", n)
	n = C.GetConstructionPlans(buf, n)
	for i = 0, n - 1 do
		if ffi.string(buf[i].id) == id then
			log("plan " .. id .. " already in the library")
			return true
		end
	end
	n = C.GetNumImportableConstructionPlans()
	local files = ffi.new("UIConstructionPlanInfo[?]", n)
	n = C.GetImportableConstructionPlans(files, n)
	for i = 0, n - 1 do
		if ffi.string(files[i].id) == id then
			local filename = ffi.string(files[i].filename)
			C.ImportMapConstructionPlan(filename, id)
			log("imported plan " .. id .. " from '" .. filename .. "'")
			return true
		end
	end
	log("plan " .. id .. " not found in the library or the import folder")
	return false
end

local function planCounts(menu)
	local entries = menu.constructionplan or {}
	local withcomp = 0
	for _, entry in ipairs(entries) do
		if entry.component ~= nil and entry.component ~= 0 then
			withcomp = withcomp + 1
		end
	end
	local changed = 0
	for _ in pairs(menu.changedModulesIndices or {}) do
		changed = changed + 1
	end
	return #entries, withcomp, #(menu.removedModules or {}), changed
end

local function findPlanByName(name)
	local n = C.GetNumConstructionPlans()
	local buf = ffi.new("UIConstructionPlan[?]", n)
	n = C.GetConstructionPlans(buf, n)
	local found, best = nil, -1
	for i = 0, n - 1 do
		if ffi.string(buf[i].name) == name then
			local id = ffi.string(buf[i].id)
			local num = tonumber(string.match(id, "player_(%d+)")) or 0
			if num >= best then
				best = num
				found = id
			end
		end
	end
	return found
end

-- Positions separate the two energy-cell modules, which share a macro.
local function planOrder(menu)
	local parts = {}
	for _, entry in ipairs(menu.constructionplan or {}) do
		local x = "?"
		pcall(function () x = string.format("%.0f", entry.offset.x) end)
		table.insert(parts, tostring(entry.macro) .. "@" .. x)
	end
	return table.concat(parts, ", ")
end

local function confirmPlan(menu, planid)
	log("b1: loading plan " .. planid)
	menu.dropdownLoad(nil, planid)
	local entries, withcomp, removed, changed = planCounts(menu)
	log(string.format("b1 reloaded: entries=%d with-component=%d removed=%d changed=%d", entries, withcomp, removed, changed))
	later(2, function ()
		menu.refreshPlan()
		entries, withcomp, removed, changed = planCounts(menu)
		log(string.format("b1 reloaded-settled: entries=%d with-component=%d removed=%d changed=%d", entries, withcomp, removed, changed))
		log("b1 order: " .. planOrder(menu))
		menu.buttonConfirm()
		log("b1: confirmed")
		later(3, function ()
			menu.closeMenu("close")
			log("b1: build menu closed")
			AddUITriggeredEvent("ESR_Test", "b1done", "")
		end)
	end)
end

-- B1(a): save the live plan and load it back. B1(b): load player_1792159001, the same
-- layout with the two energy-cell modules swapped in sequence order. The "reloaded" line
-- is the engine's removed-module list.
local B1B_PLAN = "player_1792159001"

local function matchStation(reorder, station)
	log("b1: station param " .. tostring(station) .. " reorder=" .. tostring(reorder))
	local id = ConvertStringTo64Bit(tostring(station))
	OpenMenu("StationConfigurationMenu", Helper.convertComponentIDs({ 0, 0, id }), nil)
	log("b1: build menu opened for " .. ffi.string(C.GetComponentName(id)))
	later(8, function ()
		local menu = findMenu("StationConfigurationMenu")
		if not menu or not menu.shown or not menu.holomap or menu.holomap == 0 then
			log("b1: menu not ready, shown=" .. tostring(menu and menu.shown) .. " holomap=" .. tostring(menu and menu.holomap))
			AddUITriggeredEvent("ESR_Test", "b1done", "")
			return
		end
		menu.refreshPlan()
		local entries, withcomp, removed, changed = planCounts(menu)
		log(string.format("b1 open: entries=%d with-component=%d removed=%d changed=%d", entries, withcomp, removed, changed))
		log("b1 open-order: " .. planOrder(menu))
		if reorder then
			confirmPlan(menu, B1B_PLAN)
			return
		end
		C.SaveMapConstructionPlan(menu.holomap, "local", "player", false, "esr b1", "")
		log("b1: saved the live plan as 'esr b1'")
		later(3, function ()
			local planid = findPlanByName("esr b1")
			if not planid then
				log("b1: saved plan not in the library")
				AddUITriggeredEvent("ESR_Test", "b1done", "")
				return
			end
			confirmPlan(menu, planid)
		end)
	end)
end

-- the player's steps: open the station's build menu, load the plan, confirm, close
local function replaceStation(_, station)
	log("replace: station param " .. tostring(station) .. " (" .. type(station) .. ")")
	local id = ConvertStringTo64Bit(tostring(station))
	if not importPlan(REPLACE_PLAN_ID) then
		return
	end
	OpenMenu("StationConfigurationMenu", Helper.convertComponentIDs({ 0, 0, id }), nil)
	log("replace: build menu opened for " .. ffi.string(C.GetComponentName(id)))
	later(8, function ()
		local menu = findMenu("StationConfigurationMenu")
		log("replace: menu shown " .. tostring(menu and menu.shown) .. ", holomap " .. tostring(menu and menu.holomap))
		menu.dropdownLoad(nil, REPLACE_PLAN_ID)
		log("replace: plan loaded onto the map")
		later(8, function ()
			log("replace: plan view has " .. #(menu.constructionplan or {}) .. " entries, " .. #(menu.removedModules or {}) .. " removed modules; confirming")
			menu.buttonConfirm()
			later(5, function ()
				menu.closeMenu("close")
				log("replace: build menu closed")
			end)
		end)
	end)
end

local function init()
	RegisterEvent("esr_test_quit", function ()
		-- a short delay: right after a load the game ignored QuitGame (run 2)
		log("quitting the game in 3 s")
		later(3, function () QuitGame() end)
	end)
	RegisterEvent("esr_test_replace", replaceStation)
	RegisterEvent("esr_test_b1", function (_, station) matchStation(false, station) end)
	RegisterEvent("esr_test_b1b", function (_, station) matchStation(true, station) end)
	-- the "workshop" game start's Force build button (menu.buttonForceBuild) uses the same function
	RegisterEvent("esr_test_forcebuild", function (_, station)
		local id = ConvertStringTo64Bit(tostring(station))
		C.ForceBuildCompletion(id)
		log("ForceBuildCompletion called for " .. ffi.string(C.GetComponentName(id)))
	end)
	-- the MD side raises this once the save has loaded (run 5: a timed request came during loading and was lost)
	RegisterEvent("esr_test_ready", function ()
		AddUITriggeredEvent("ESR_Test", "scenario", config.scenario)
		log("scenario " .. config.scenario .. " requested")
	end)

	local ok, isstart = pcall(function () return C.IsStartmenu() end)
	if not ok then
		log("IsStartmenu failed: " .. tostring(isstart))
		return
	end
	log("Lua harness loaded, start menu: " .. tostring(isstart) .. ", save " .. config.save .. ", scenario " .. config.scenario)
	if isstart then
		-- give the start menu a moment to finish setting up
		later(5, loadTestSave)
	end
end

init()
