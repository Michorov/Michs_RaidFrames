local _, addon = ...

local Database = {}
addon.Database = Database

local AceDB = LibStub("AceDB-3.0")

local initialized = false

local DEFAULTS = {
	profile = {
		core = {
			showSoloPartyFrame = true,
			hideBlizzardRaidFrames = true,
			outOfRangeAlpha = 0.5,
			uiScale = 1.0,
		},
		party = {
			size = { width = 128, height = 64 },
			position = { x = 0, y = 0 },
			spacing = { x = -1, y = -1 },
			direction = "VERTICAL",
			background = {
				color = {
					r = 0.12,
					g = 0.12,
					b = 0.12,
					a = 1.0,
				},
			},
			health = {
				texture = "Interface\\Buttons\\WHITE8x8",
				classColor = true,
				color = {
					r = 0.12,
					g = 0.12,
					b = 0.12,
					a = 1.0,
				},
			},
			power = {
				enabled = true,
				healerOnly = false,
				texture = "Interface\\Buttons\\WHITE8x8",
				height = 8,
				borderEnabled = true,
				borderThicknessPx = 1,
				backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
			},
			border = {
				thicknessPx = 1,
				color = { r = 0, g = 0, b = 0, a = 1 },
			},
			widgets = {
				texts = {
					name = {
						anchor = "TOPLEFT",
						position = {
							x = 2,
							y = -2,
						},
						classColor = false,
						color = {
							r = 0,
							g = 0,
							b = 0,
							a = 1,
						},
						font = "Fonts\\ARIALN.TTF",
						size = 12,
						outline = "NONE",
					},
				},
				icons = {
					buffs = {
						anchor = "BOTTOMRIGHT",
						relativeAnchor = "BOTTOMRIGHT",
						offsetX = -2,
						offsetY = 2,

						maxIcons = 6,
						iconsPerRow = 3,
						iconSize = 16,
						spacing = -1,

						showStacks = true,
						stacksFontSize = 10,

						showCooldown = false,
						cooldownFontSize = 10,

						borderSizePx = 1,
					},
					debuffs = {
						anchor = "BOTTOMLEFT",
						relativeAnchor = "BOTTOMLEFT",
						offsetX = 2,
						offsetY = 2,

						maxIcons = 6,
						iconsPerRow = 3,
						iconSize = 16,
						spacing = -1,

						showStacks = true,
						stacksFontSize = 10,

						showCooldown = false,
						cooldownFontSize = 10,

						borderSizePx = 1,
					},
					privateAuras = {
						anchor = "LEFT",
						relativeAnchor = "LEFT",
						offsetX = 2,
						offsetY = 2,

						maxIcons = 3,
						iconSize = 20,
						spacing = 1,
					},
					bigDefensive = {
						anchor = "CENTER",
						relativeAnchor = "CENTER",
						offsetX = 0,
						offsetY = 0,

						maxIcons = 1,
						iconSize = 32,

						showStacks = true,
						stacksFontSize = 10,

						showCooldown = false,
						cooldownFontSize = 16,

						borderSizePx = 1,
					},
				},
				bars = {
					absorbs = {
						color = {
							r = 0.2,
							g = 0.8,
							b = 1.0,
							a = 0.5,
						},
					},
					healAbsorbs = {
						color = {
							r = 1,
							g = 0,
							b = 0,
							a = 0.5,
						},
					},
				},
				indicators = {
					readyCheck = {},
					dispels = {
						anchor = "TOPRIGHT",
						relativeAnchor = "TOPRIGHT",
						offsetX = -2,
						offsetY = -2,

						iconSize = 16,
						spacing = 2,
						alpha = 1.0,
					},
				},
			},
		},
		raid = {
			size = { width = 110, height = 56 },
			position = { x = 0, y = 0 },
			spacing = { x = -1, y = -1 },
			groups = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false,
			},
			direction = "HORIZONTAL",
			reverse = false,
			background = {
				color = {
					r = 0.12,
					g = 0.12,
					b = 0.12,
					a = 1.0,
				},
			},
			health = {
				texture = "Interface\\Buttons\\WHITE8x8",
				classColor = true,
				color = {
					r = 0.12,
					g = 0.12,
					b = 0.12,
					a = 1.0,
				},
			},
			power = {
				enabled = true,
				healerOnly = false,
				texture = "Interface\\Buttons\\WHITE8x8",
				height = 6,
				borderEnabled = true,
				borderThicknessPx = 1,
				backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
			},
			border = {
				thicknessPx = 1,
				color = { r = 0, g = 0, b = 0, a = 1 },
			},
			widgets = {
				texts = {
					name = {
						anchor = "TOPLEFT",
						position = {
							x = 2,
							y = -2,
						},
						classColor = false,
						color = {
							r = 0,
							g = 0,
							b = 0,
							a = 1,
						},
						font = "Fonts\\ARIALN.TTF",
						size = 10,
						outline = "NONE",
					},
				},
				icons = {
					buffs = {
						anchor = "BOTTOMRIGHT",
						relativeAnchor = "BOTTOMRIGHT",
						offsetX = -2,
						offsetY = 2,

						maxIcons = 6,
						iconsPerRow = 3,
						iconSize = 16,
						spacing = -1,

						showStacks = true,
						stacksFontSize = 10,

						showCooldown = false,
						cooldownFontSize = 10,

						borderSizePx = 1,
					},
					debuffs = {
						anchor = "BOTTOMLEFT",
						relativeAnchor = "BOTTOMLEFT",
						offsetX = 2,
						offsetY = 2,

						maxIcons = 6,
						iconsPerRow = 3,
						iconSize = 16,
						spacing = -1,

						showStacks = true,
						stacksFontSize = 10,

						showCooldown = false,
						cooldownFontSize = 10,

						borderSizePx = 1,
					},
					privateAuras = {
						anchor = "LEFT",
						relativeAnchor = "LEFT",
						offsetX = 2,
						offsetY = 2,

						maxIcons = 3,
						iconSize = 16,
						spacing = 1,
					},
					bigDefensive = {
						anchor = "CENTER",
						relativeAnchor = "CENTER",
						offsetX = 0,
						offsetY = 0,

						maxIcons = 1,
						iconSize = 28,

						showStacks = true,
						stacksFontSize = 16,

						showCooldown = false,
						cooldownFontSize = 16,

						borderSizePx = 1,
					},
				},
				bars = {
					absorbs = {
						color = {
							r = 0.2,
							g = 0.8,
							b = 1.0,
							a = 0.5,
						},
					},
					healAbsorbs = {
						color = {
							r = 1,
							g = 0,
							b = 0,
							a = 0.5,
						},
					},
				},
				indicators = {
					readyCheck = {},
					dispels = {
						anchor = "TOPRIGHT",
						relativeAnchor = "TOPRIGHT",
						offsetX = -2,
						offsetY = -2,

						iconSize = 12,
						spacing = 2,
						alpha = 1.0,
					},
				},
			},
		},
	},
	global = {},
	char = {},
}

function Database:GetCurrentProfileName()
	return self.db:GetCurrentProfile()
end

function Database:GetProfileNames()
	local t = {}
	for _, name in ipairs({ self.db:GetProfiles() }) do
		t[name] = name
	end
	return t
end

function Database:HasProfile(name)
	for _, n in ipairs(self.db:GetProfiles() or {}) do
		if n == name then
			return true
		end
	end
	return false
end

function Database:SetProfile(name)
	self.db:SetProfile(name)
end

function Database:CopyProfile(sourceName)
	self.db:CopyProfile(sourceName)
end

function Database:DeleteProfile(name)
	self.db:DeleteProfile(name, true)
end

function Database:GetProfile()
	if not initialized then
		error("Database is not initialized", 2)
	end
	return self.db.profile
end

function Database:GetGlobal()
	if not initialized then
		error("Database is not initialized", 2)
	end
	return self.db.global
end

function Database:GetChar()
	if not initialized then
		error("Database is not initialized", 2)
	end
	return self.db.char
end

function Database:Initialize()
	if initialized then
		error("Database already initialized", 2)
	end

	self.db = AceDB:New("Michs_RaidFramesDB", DEFAULTS, true)

	local function OnProfileChanged()
		addon.UpdateScheduler:Notify("layoutChanged")
		addon.UpdateScheduler:Notify("backgroundSettingsChanged")
		addon.UpdateScheduler:Notify("healthSettingsChanged")
		addon.UpdateScheduler:Notify("powerSettingsChanged")
		addon.UpdateScheduler:Notify("powerStateChanged")
		addon.UpdateScheduler:Notify("borderSettingsChanged")
		addon.UpdateScheduler:Notify("nameSettingsChanged")
		addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
		addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
		addon.UpdateScheduler:Notify("dispelsSettingsChanged")
	end

	self.db:RegisterCallback("OnProfileChanged", OnProfileChanged)
	self.db:RegisterCallback("OnProfileCopied", OnProfileChanged)
	self.db:RegisterCallback("OnProfileReset", OnProfileChanged)

	initialized = true
end
