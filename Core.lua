local addonName, addon = ...

local function InitializeAddon()
	addon.Database:Initialize()
	addon.Locale:Initialize()

	addon.Utilities:RefreshPixelGrid()

	local flushCallback = addon.Updater:CreateFlushCallback()
	addon.UpdateScheduler:SetFlushCallback(flushCallback)

	addon.Options:Initialize()

	addon.Modules:Initialize()
	addon.EventHandler:Initialize()
end

local core = CreateFrame("Frame")
core:RegisterEvent("ADDON_LOADED")
core:SetScript("OnEvent", function(_, event, loadedAddonName)
	if event ~= "ADDON_LOADED" then
		return
	end

	if loadedAddonName ~= addonName then
		return
	end

	core:UnregisterEvent("ADDON_LOADED")
	InitializeAddon()
end)
