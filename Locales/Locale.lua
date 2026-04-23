local addonName, addon = ...

addon.Locale = addon.Locale or {}
local Locale = addon.Locale

local AceLocale = LibStub("AceLocale-3.0")
local registeredLocales = Locale.registeredLocales or {}
local subscribers = Locale.subscribers or {}
local currentLocale = Locale.currentLocale
local pendingLocaleOverride = Locale.pendingLocaleOverride

Locale.registeredLocales = registeredLocales
Locale.subscribers = subscribers
Locale.defaultLocale = Locale.defaultLocale or "enUS"

local localeAliases = {
	enGB = "enUS",
}

local localeDisplayNames = {
	deDE = "German",
	enUS = "English",
	esES = "Spanish",
	esMX = "Latin American Spanish",
	frFR = "French",
	itIT = "Italian",
	koKR = "Korean",
	ptBR = "Brazilian Portuguese",
	ruRU = "Russian",
	zhCN = "Simplified Chinese",
	zhTW = "Traditional Chinese",
}

local specializationLocaleKeys = {
	[62] = "Spec: Arcane",
	[63] = "Spec: Fire",
	[64] = "Spec: Frost",
	[65] = "Spec: Holy",
	[66] = "Spec: Protection",
	[70] = "Spec: Retribution",
	[71] = "Spec: Arms",
	[72] = "Spec: Fury",
	[73] = "Spec: Protection",
	[102] = "Spec: Balance",
	[103] = "Spec: Feral",
	[104] = "Spec: Guardian",
	[105] = "Spec: Restoration",
	[250] = "Spec: Blood",
	[251] = "Spec: Frost",
	[252] = "Spec: Unholy",
	[253] = "Spec: Beast Mastery",
	[254] = "Spec: Marksmanship",
	[255] = "Spec: Survival",
	[256] = "Spec: Discipline",
	[257] = "Spec: Holy",
	[258] = "Spec: Shadow",
	[259] = "Spec: Assassination",
	[260] = "Spec: Outlaw",
	[261] = "Spec: Subtlety",
	[262] = "Spec: Elemental",
	[263] = "Spec: Enhancement",
	[264] = "Spec: Restoration",
	[265] = "Spec: Affliction",
	[266] = "Spec: Demonology",
	[267] = "Spec: Destruction",
	[268] = "Spec: Brewmaster",
	[269] = "Spec: Windwalker",
	[270] = "Spec: Mistweaver",
	[577] = "Spec: Havoc",
	[581] = "Spec: Vengeance",
	[1467] = "Spec: Devastation",
	[1468] = "Spec: Preservation",
	[1473] = "Spec: Augmentation",
}

local auraLocaleKeys = {
	[17] = "Aura: Power Word: Shield",
	[139] = "Aura: Renew",
	[774] = "Aura: Rejuvenation",
	[974] = "Aura: Earth Shield Ally",
	[8936] = "Aura: Regrowth",
	[33763] = "Aura: Lifebloom",
	[41635] = "Aura: Prayer of Mending",
	[48438] = "Aura: Wild Growth",
	[53563] = "Aura: Beacon of Light",
	[61295] = "Aura: Riptide",
	[77489] = "Aura: Echo of Light",
	[115175] = "Aura: Soothing Mist",
	[119611] = "Aura: Renewing Mist",
	[124682] = "Aura: Enveloping Mist",
	[155777] = "Aura: Germination",
	[156322] = "Aura: Eternal Flame",
	[156910] = "Aura: Beacon of Faith",
	[194384] = "Aura: Atonement",
	[207400] = "Aura: Ancestral Vigor",
	[355941] = "Aura: Dream Breath",
	[360827] = "Aura: Blistering Scales",
	[363502] = "Aura: Dream Flight",
	[364343] = "Aura: Echo",
	[366155] = "Aura: Reversion",
	[367364] = "Aura: Echo Reversion",
	[373267] = "Aura: Lifebind",
	[376788] = "Aura: Echo Dream Breath",
	[382024] = "Aura: Earthliving Weapon",
	[383648] = "Aura: Earth Shield Self",
	[395152] = "Aura: Ebon Might",
	[410089] = "Aura: Prescience",
	[410263] = "Aura: Inferno's Blessing",
	[410686] = "Aura: Symbiotic Bloom",
	[413984] = "Aura: Shifting Sands",
	[450769] = "Aura: Aspect of Harmony",
	[1244893] = "Aura: Beacon of the Savior",
	[1253593] = "Aura: Void Shield",
}

local clientLocale = localeAliases[GetLocale()] or GetLocale() or "enUS"

local function NormalizeLocale(locale)
	if type(locale) ~= "string" or locale == "" then
		return nil
	end

	return localeAliases[locale] or locale
end

local function HasRegisteredTranslations(locale)
	local translations = locale and registeredLocales[locale] or nil
	return translations ~= nil and next(translations) ~= nil
end

local function GetStoredLocaleOverride()
	if addon.Database and addon.Database.GetLocaleOverride then
		return NormalizeLocale(addon.Database:GetLocaleOverride())
	end

	return pendingLocaleOverride
end

local function ResolveLocale(locale)
	local normalizedLocale = NormalizeLocale(locale) or GetStoredLocaleOverride() or clientLocale

	if HasRegisteredTranslations(normalizedLocale) then
		return normalizedLocale
	end

	if HasRegisteredTranslations(clientLocale) then
		return clientLocale
	end

	if HasRegisteredTranslations(Locale.defaultLocale) then
		return Locale.defaultLocale
	end

	for registeredLocale, translations in pairs(registeredLocales) do
		if next(translations) ~= nil then
			return registeredLocale
		end
	end

	return Locale.defaultLocale
end

local function SetResolvedLocale(locale)
	currentLocale = ResolveLocale(locale)
	Locale.currentLocale = currentLocale
	return currentLocale
end

local function CreateWriteProxy(target, aceProxy)
	return setmetatable({}, {
		__index = function(_, key)
			return target[key]
		end,
		__newindex = function(_, key, value)
			local storedValue = value == true and key or value
			target[key] = storedValue

			if aceProxy then
				aceProxy[key] = storedValue
			end
		end,
	})
end

function Locale:NewLocale(application, locale, isDefault, silent)
	if application ~= addonName then
		error(("Locale:NewLocale received unexpected application %q"):format(tostring(application)), 2)
	end

	local normalizedLocale = NormalizeLocale(locale) or locale
	if isDefault then
		self.defaultLocale = normalizedLocale
	end

	registeredLocales[normalizedLocale] = registeredLocales[normalizedLocale] or {}

	local aceProxy = AceLocale:NewLocale(application, normalizedLocale, isDefault, silent)
	return CreateWriteProxy(registeredLocales[normalizedLocale], aceProxy)
end

function Locale:Initialize()
	SetResolvedLocale(GetStoredLocaleOverride())
end

function Locale:GetCurrentLocale()
	if not currentLocale then
		SetResolvedLocale(GetStoredLocaleOverride())
	end

	return currentLocale
end

function Locale:GetGameLocale()
	return clientLocale
end

function Locale:GetLocaleOverride()
	return GetStoredLocaleOverride()
end

function Locale:GetLocaleDisplayName(locale)
	local normalizedLocale = NormalizeLocale(locale) or locale
	return localeDisplayNames[normalizedLocale] or normalizedLocale or self.defaultLocale
end

function Locale:GetSpecializationDisplayName(specID, fallbackName)
	local key = specializationLocaleKeys[specID]
	if not key then
		return fallbackName
	end

	local localizedName = self:GetString(key)
	if localizedName == key then
		return fallbackName or key
	end

	return localizedName
end

function Locale:GetAuraDisplayName(spellID, fallbackName)
	local numericSpellID = tonumber(spellID)
	local key = numericSpellID and auraLocaleKeys[numericSpellID] or nil
	if not key then
		return fallbackName
	end

	local localizedName = self:GetString(key)
	if localizedName == key then
		return fallbackName or key
	end

	return localizedName
end

function Locale:GetAvailableLocales()
	local locales = {}

	for locale, translations in pairs(registeredLocales) do
		if next(translations) ~= nil then
			table.insert(locales, locale)
		end
	end

	table.sort(locales, function(left, right)
		if left == self.defaultLocale then
			return true
		end

		if right == self.defaultLocale then
			return false
		end

		return left < right
	end)

	return locales
end

function Locale:GetString(key)
	if type(key) ~= "string" then
		return key
	end

	local activeTranslations = registeredLocales[self:GetCurrentLocale()]
	if activeTranslations and activeTranslations[key] ~= nil then
		return activeTranslations[key]
	end

	local fallbackTranslations = registeredLocales[self.defaultLocale]
	if fallbackTranslations and fallbackTranslations[key] ~= nil then
		return fallbackTranslations[key]
	end

	return key
end

function Locale:RegisterForUpdates(key, callback)
	subscribers[key] = callback
end

function Locale:UnregisterForUpdates(key)
	subscribers[key] = nil
end

function Locale:NotifyUpdated()
	local resolvedLocale = self:GetCurrentLocale()

	for _, callback in pairs(subscribers) do
		callback(resolvedLocale)
	end
end

function Locale:SetLocaleOverride(locale)
	local normalizedLocale = NormalizeLocale(locale)
	pendingLocaleOverride = normalizedLocale
	Locale.pendingLocaleOverride = pendingLocaleOverride

	if addon.Database and addon.Database.SetLocaleOverride then
		addon.Database:SetLocaleOverride(normalizedLocale)
	end

	SetResolvedLocale(normalizedLocale)
	self:NotifyUpdated()
end

addon.L = addon.L or setmetatable({}, {
	__index = function(_, key)
		return Locale:GetString(key)
	end,
	__newindex = function()
		error("addon.L is read-only", 2)
	end,
})
