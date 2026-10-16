-- Easier Station Rebuilder test harness (Lua side). Development only; tools/run-game.ps1 links it in.
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
