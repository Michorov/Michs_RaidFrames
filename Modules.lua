local _, addon = ...

local Modules = {}
addon.Modules = Modules

local registeredModules = {}
local registeredModulesByRef = {}
local initialized = false

function Modules:Register(definition)
	if type(definition) ~= "table" then
		error("Modules:Register requires a definition table", 2)
	end

	if type(definition.module) ~= "table" then
		error("Modules:Register requires definition.module", 2)
	end

	if registeredModulesByRef[definition.module] then
		return
	end

	table.insert(registeredModules, definition)
	registeredModulesByRef[definition.module] = true
end

function Modules:Initialize()
	if initialized then
		return
	end

	local modulesToInit = {
		addon.Frames.Base.Background,
		addon.Frames.Base.Health,
		addon.Frames.Base.Power,
		addon.Frames.Base.Border,
		addon.Frames.Widgets.Indicators.ReadyCheck,
		addon.Frames.Widgets.Indicators.PendingSummon,
		addon.Frames.Widgets.Indicators.Ping,
		addon.Frames.Widgets.Indicators.RaidMarker,
		addon.Frames.Widgets.Indicators.RoleIcon,
		addon.Frames.Widgets.Indicators.GroupStatus,
		addon.Frames.Widgets.Indicators.Threat,
		addon.Frames.Widgets.Bars.Absorbs,
		addon.Frames.Widgets.Bars.HealAbsorbs,
		addon.Frames.Widgets.Texts.Name,
		addon.Frames.Widgets.Texts.Health,
		addon.Frames.Widgets.Texts.Power,
		addon.Frames.Widgets.Texts.StatusText,
		addon.Frames.Widgets.Texts.Away,
		addon.Frames.Widgets.Texts.HealAbsorbs,
		addon.Frames.ManagedContainers.Buffs,
		addon.Frames.ManagedContainers.CustomBuffs,
		addon.Frames.ManagedContainers.Debuffs,
		addon.Frames.ManagedContainers.Dispels,
		addon.Frames.ManagedContainers.Defensives,
		addon.Frames.ManagedContainers.BuffOverlay,
		addon.Frames.ManagedContainers.RaidBuffReminder,
		addon.Frames.Widgets.Icons.Buffs,
		addon.Frames.Widgets.Icons.CustomBuffs,
		addon.Frames.Widgets.Icons.Debuffs,
		addon.Frames.Widgets.Icons.BigDefensive,
		addon.Frames.Widgets.Icons.Dispels,
		addon.Frames.Widgets.Icons.RaidBuffReminder,
		addon.Frames.Widgets.Bars.BuffOverlay,
	}

	for _, module in ipairs(modulesToInit) do
		if module and type(module.Init) == "function" then
			module:Init()
		end
	end

	initialized = true
end

function Modules:EnsureFrame(frame, settings)
	if not frame then
		return
	end

	for _, definition in ipairs(registeredModules) do
		local module = definition.module
		if type(module.Ensure) == "function" then
			module:Ensure(frame, settings)
		end
	end
end

function Modules:UpdateSettingsFrame(frame, settings)
	if not frame then
		return
	end

	for _, definition in ipairs(registeredModules) do
		local module = definition.module
		if type(module.UpdateSettings) == "function" then
			module:UpdateSettings(frame, settings)
		end
	end
end

function Modules:RequestUpdateSettings()
	local notifiedReasons = {}

	for _, definition in ipairs(registeredModules) do
		local reason = definition.settingsReason
		if reason and not notifiedReasons[reason] then
			notifiedReasons[reason] = true
			addon.UpdateScheduler:Notify(reason)
		end
	end
end

function Modules:RequestUpdateState(unit)
	local notifiedReasons = {}

	for _, definition in ipairs(registeredModules) do
		local reason = definition.stateReason
		if reason and not notifiedReasons[reason] then
			notifiedReasons[reason] = true
			addon.UpdateScheduler:Notify(reason, unit)
		end
	end
end

function Modules:RequestUpdateAll()
	addon.UpdateScheduler:Notify("layoutChanged")
	self:RequestUpdateSettings()
	self:RequestUpdateState()
end
