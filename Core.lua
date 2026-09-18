local addonName, addon = ...

local _, _, _, interfaceVersion = GetBuildInfo()
interfaceVersion = tonumber(interfaceVersion) or 0
addon.IsRestrictedAuraAPI = interfaceVersion >= 120100
	or (interfaceVersion > 16000 and interfaceVersion < 20000)

local function InitializeAddon()
	addon.Utilities:RefreshPixelGrid()
	addon.Utilities.PixelPerfect:RefreshScaling()

	addon.Database:Initialize()
	addon.Utilities.PixelPerfect:SetGlobalScale(addon.Database:GetProfile().core.uiScale)
	addon.Locale:Initialize()

	local flushCallback = addon.Updater:CreateFlushCallback()
	addon.UpdateScheduler:SetFlushCallback(flushCallback)

	addon.Styles.Textures:RegisterCallbacks()
	addon.Styles.Fonts:RegisterCallbacks()

	addon.Modules:Initialize()

	addon.EventHandler:Initialize()

	addon.Options:Initialize()
	addon.Options.Minimap:Initialize()
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
