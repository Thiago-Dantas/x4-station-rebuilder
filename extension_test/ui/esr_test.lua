-- Easy Station Rebuild test harness (Lua side). Development only; tools/run-game.ps1 links it in.
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

-- x,y separate modules that share a macro, and show the B1(c) move (defence disc, y +1000).
local function planOrder(menu)
	local parts = {}
	for _, entry in ipairs(menu.constructionplan or {}) do
		local x, y = "?", "?"
		pcall(function ()
			x = string.format("%.0f", entry.offset.x)
			y = string.format("%.0f", entry.offset.y)
		end)
		table.insert(parts, tostring(entry.macro) .. "@" .. x .. "," .. y)
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

-- B1(a): save the live plan and load it back.
-- B1(b): load player_1792159001 (sequence order of the two energy cells swapped). That plan
-- was removed from the profile library after run 21.
-- B1(c): load player_1792161001. Same layout, defence disc offset.y set to 1000. The build
-- menu has no FFI call that moves a module; the gizmo is engine-side. The "reloaded" line
-- is the engine's removed-module list.
local B1_PLANS = {
	b1b = "player_1792159001",
	b1c = "player_1792161001",
}

local function matchStation(mode, station)
	log("b1: station param " .. tostring(station) .. " mode=" .. tostring(mode))
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
		if B1_PLANS[mode] then
			confirmPlan(menu, B1_PLANS[mode])
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

-- The build menu's "remove module" button. sequence=false removes that module only;
-- the retry uses true (remove the module and whatever is attached to it) when the first call
-- left the engine's removed list empty. Pass allowSequence=false to keep that retry off
-- (b6dock: the dock area is the plan root, and sequence=true would take the whole station).
-- B4 removes the S container. b6menu removes the pier. b6dock removes the dock area.
local function removePlanModule(tag, macro, doneControl, station, allowSequence)
	log(tag .. ": station param " .. tostring(station))
	local id = ConvertStringTo64Bit(tostring(station))
	OpenMenu("StationConfigurationMenu", Helper.convertComponentIDs({ 0, 0, id }), nil)
	log(tag .. ": build menu opened for " .. ffi.string(C.GetComponentName(id)))
	later(8, function ()
		local menu = findMenu("StationConfigurationMenu")
		if not menu or not menu.shown or not menu.holomap or menu.holomap == 0 then
			log(tag .. ": menu not ready, shown=" .. tostring(menu and menu.shown) .. " holomap=" .. tostring(menu and menu.holomap))
			AddUITriggeredEvent("ESR_Test", doneControl, "fail")
			return
		end
		menu.refreshPlan()
		local entries, withcomp, removed, changed = planCounts(menu)
		log(string.format("%s open: entries=%d with-component=%d removed=%d changed=%d", tag, entries, withcomp, removed, changed))
		log(tag .. " open-order: " .. planOrder(menu))
		local entry = nil
		for _, candidate in ipairs(menu.constructionplan or {}) do
			if candidate.macro == macro then
				entry = candidate
				break
			end
		end
		if not entry then
			log(tag .. ": " .. macro .. " is not in the plan")
			AddUITriggeredEvent("ESR_Test", doneControl, "fail")
			return
		end
		local function applyRemove(sequence)
			log(string.format("%s: RemoveItemFromConstructionMap2 idx=%s sequence=%s", tag, tostring(entry.idx), tostring(sequence)))
			C.RemoveItemFromConstructionMap2(menu.holomap, entry.idx, sequence)
			menu.refreshPlan()
			entries, withcomp, removed, changed = planCounts(menu)
			log(string.format("%s removed: entries=%d with-component=%d removed=%d changed=%d", tag, entries, withcomp, removed, changed))
			log(tag .. " order: " .. planOrder(menu))
		end
		local ok, err = pcall(applyRemove, false)
		if not ok then
			log(tag .. ": remove failed: " .. tostring(err))
			AddUITriggeredEvent("ESR_Test", doneControl, "fail")
			return
		end
		if removed == 0 and allowSequence == false then
			log(tag .. ": sequence=false removed nothing; not removing the attached modules")
		elseif removed == 0 then
			log(tag .. ": sequence=false removed nothing; retrying with the attached modules")
			ok, err = pcall(applyRemove, true)
			if not ok then
				log(tag .. ": sequence remove failed: " .. tostring(err))
				AddUITriggeredEvent("ESR_Test", doneControl, "fail")
				return
			end
		end
		if removed == 0 then
			log(tag .. ": module still not on the removed list")
			AddUITriggeredEvent("ESR_Test", doneControl, "fail")
			return
		end
		menu.buttonConfirm()
		log(tag .. ": confirmed")
		later(3, function ()
			menu.closeMenu("close")
			log(tag .. ": build menu closed")
			AddUITriggeredEvent("ESR_Test", doneControl, "")
		end)
	end)
end

-- B2: three modules, one Confirm. sequence stays false. The S container's
-- successors are the pier and the habitat, and sequence=true would take those
-- too. Nothing is added: AddMacroToConstructionMap starts a drag and does not
-- place a module. The first energy-cell entry is the only one of that macro removed.
local function removePlanModules(tag, macros, doneControl, station)
	log(tag .. ": station param " .. tostring(station))
	local id = ConvertStringTo64Bit(tostring(station))
	OpenMenu("StationConfigurationMenu", Helper.convertComponentIDs({ 0, 0, id }), nil)
	log(tag .. ": build menu opened for " .. ffi.string(C.GetComponentName(id)))
	later(8, function ()
		local menu = findMenu("StationConfigurationMenu")
		if not menu or not menu.shown or not menu.holomap or menu.holomap == 0 then
			log(tag .. ": menu not ready, shown=" .. tostring(menu and menu.shown) .. " holomap=" .. tostring(menu and menu.holomap))
			AddUITriggeredEvent("ESR_Test", doneControl, "fail")
			return
		end
		menu.refreshPlan()
		local entries, withcomp, removed, changed = planCounts(menu)
		log(string.format("%s open: entries=%d with-component=%d removed=%d changed=%d", tag, entries, withcomp, removed, changed))
		log(tag .. " open-order: " .. planOrder(menu))
		local function findEntry(macro)
			for _, candidate in ipairs(menu.constructionplan or {}) do
				if candidate.macro == macro then
					return candidate
				end
			end
		end
		for _, macro in ipairs(macros) do
			local entry = findEntry(macro)
			if not entry then
				log(tag .. ": " .. macro .. " is not in the plan")
				AddUITriggeredEvent("ESR_Test", doneControl, "fail")
				return
			end
			local before = removed
			log(string.format("%s: RemoveItemFromConstructionMap2 idx=%s macro=%s sequence=false", tag, tostring(entry.idx), macro))
			local ok, err = pcall(function ()
				C.RemoveItemFromConstructionMap2(menu.holomap, entry.idx, false)
			end)
			if not ok then
				log(tag .. ": remove failed: " .. tostring(err))
				AddUITriggeredEvent("ESR_Test", doneControl, "fail")
				return
			end
			menu.refreshPlan()
			entries, withcomp, removed, changed = planCounts(menu)
			log(string.format("%s removed: entries=%d with-component=%d removed=%d changed=%d", tag, entries, withcomp, removed, changed))
			log(tag .. " order: " .. planOrder(menu))
			if removed <= before then
				log(tag .. ": sequence=false did not remove " .. macro)
				AddUITriggeredEvent("ESR_Test", doneControl, "fail")
				return
			end
		end
		menu.buttonConfirm()
		log(tag .. ": confirmed")
		later(3, function ()
			menu.closeMenu("close")
			log(tag .. ": build menu closed")
			AddUITriggeredEvent("ESR_Test", doneControl, "")
		end)
	end)
end

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

-- B3: import extension_test/plans/esr_b3.xml (copied into the profile's constructionplan
-- folder before the run) and load it onto the station. The file is library plan
-- tutorial_quantumtube under id player_1792192001.
local B3_PLAN_ID = "player_1792192001"

local function loadStoredPlan(tag, planid, doneControl, station)
	log(tag .. ": station param " .. tostring(station))
	if not importPlan(planid) then
		AddUITriggeredEvent("ESR_Test", doneControl, "fail")
		return
	end
	local id = ConvertStringTo64Bit(tostring(station))
	OpenMenu("StationConfigurationMenu", Helper.convertComponentIDs({ 0, 0, id }), nil)
	log(tag .. ": build menu opened for " .. ffi.string(C.GetComponentName(id)))
	later(8, function ()
		local menu = findMenu("StationConfigurationMenu")
		if not menu or not menu.shown or not menu.holomap or menu.holomap == 0 then
			log(tag .. ": menu not ready, shown=" .. tostring(menu and menu.shown) .. " holomap=" .. tostring(menu and menu.holomap))
			AddUITriggeredEvent("ESR_Test", doneControl, "fail")
			return
		end
		menu.refreshPlan()
		local entries, withcomp, removed, changed = planCounts(menu)
		log(string.format("%s open: entries=%d with-component=%d removed=%d changed=%d", tag, entries, withcomp, removed, changed))
		log(tag .. " open-order: " .. planOrder(menu))
		log(tag .. ": loading plan " .. planid)
		local ok, err = pcall(function () menu.dropdownLoad(nil, planid) end)
		if not ok then
			log(tag .. ": load failed: " .. tostring(err))
			AddUITriggeredEvent("ESR_Test", doneControl, "fail")
			return
		end
		entries, withcomp, removed, changed = planCounts(menu)
		log(string.format("%s loaded: entries=%d with-component=%d removed=%d changed=%d", tag, entries, withcomp, removed, changed))
		later(2, function ()
			menu.refreshPlan()
			entries, withcomp, removed, changed = planCounts(menu)
			log(string.format("%s loaded-settled: entries=%d with-component=%d removed=%d changed=%d", tag, entries, withcomp, removed, changed))
			log(tag .. " order: " .. planOrder(menu))
			if removed == 0 then
				log(tag .. ": loaded plan removed nothing")
				AddUITriggeredEvent("ESR_Test", doneControl, "fail")
				return
			end
			menu.buttonConfirm()
			log(tag .. ": confirmed")
			later(3, function ()
				menu.closeMenu("close")
				log(tag .. ": build menu closed")
				AddUITriggeredEvent("ESR_Test", doneControl, "")
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
	RegisterEvent("esr_test_b1", function (_, station) matchStation("b1", station) end)
	RegisterEvent("esr_test_b1b", function (_, station) matchStation("b1b", station) end)
	RegisterEvent("esr_test_b1c", function (_, station) matchStation("b1c", station) end)
	RegisterEvent("esr_test_b4", function (_, station) removePlanModule("b4", "storage_arg_s_container_01_macro", "b4done", station) end)
	RegisterEvent("esr_test_b2", function (_, station)
		removePlanModules("b2", {
			"storage_arg_s_container_01_macro",
			"prod_gen_energycells_macro",
			"defence_arg_claim_01_macro",
		}, "b2done", station)
	end)
	RegisterEvent("esr_test_b3", function (_, station) loadStoredPlan("b3", B3_PLAN_ID, "b3done", station) end)
	RegisterEvent("esr_test_b6menu", function (_, station) removePlanModule("b6menu", "pier_arg_harbor_02_macro", "b6done", station) end)
	RegisterEvent("esr_test_b6dock", function (_, station) removePlanModule("b6dock", "dockarea_arg_m_station_01_macro", "b6dockdone", station, false) end)
	-- the "workshop" game start's Force build button (menu.buttonForceBuild) uses the same function
	RegisterEvent("esr_test_forcebuild", function (_, station)
		local id = ConvertStringTo64Bit(tostring(station))
		C.ForceBuildCompletion(id)
		log("ForceBuildCompletion called for " .. ffi.string(C.GetComponentName(id)))
	end)
	-- savewrite: write this slot only. The name "#010" is the in-file label, same shape as "#002".
	RegisterEvent("esr_test_save", function ()
		log("SaveGame " .. config.save)
		local ok, err = pcall(function ()
			SaveGame(config.save, "#010")
		end)
		if not ok then
			log("SaveGame failed: " .. tostring(err))
			AddUITriggeredEvent("ESR_Test", "savedone", "fail")
		else
			log("SaveGame returned")
		end
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
