local _, addon = ...

local Database = {}
addon.Database = Database

local AceDB = LibStub("AceDB-3.0")

local initialized = false

local CUSTOM_AURA_DEFAULTS = {
	EVOKER = {
		[1468] = {
			[355941] = { enabled = true, name = "Dream Breath" },
			[363502] = { enabled = true, name = "Dream Flight" },
			[364343] = { enabled = true, name = "Echo" },
			[366155] = { enabled = true, name = "Reversion" },
			[367364] = { enabled = true, name = "Echo Reversion" },
			[373267] = { enabled = true, name = "Lifebind" },
			[376788] = { enabled = true, name = "Echo Dream Breath" },
		},
		[1473] = {
			[360827] = { enabled = true, name = "Blistering Scales" },
			[395152] = { enabled = true, name = "Ebon Might" },
			[410089] = { enabled = true, name = "Prescience" },
			[410263] = { enabled = true, name = "Inferno's Blessing" },
			[410686] = { enabled = true, name = "Symbiotic Bloom" },
			[413984] = { enabled = true, name = "Shifting Sands" },
		},
		[-1] = {
			[360827] = { enabled = true, name = "Blistering Scales" },
			[395152] = { enabled = true, name = "Ebon Might" },
			[410089] = { enabled = true, name = "Prescience" },
			[410263] = { enabled = true, name = "Inferno's Blessing" },
			[410686] = { enabled = true, name = "Symbiotic Bloom" },
			[413984] = { enabled = true, name = "Shifting Sands" },
			[355941] = { enabled = true, name = "Dream Breath" },
			[363502] = { enabled = true, name = "Dream Flight" },
			[364343] = { enabled = true, name = "Echo" },
			[366155] = { enabled = true, name = "Reversion" },
			[367364] = { enabled = true, name = "Echo Reversion" },
			[373267] = { enabled = true, name = "Lifebind" },
			[376788] = { enabled = true, name = "Echo Dream Breath" },
		},
	},

	DRUID = {
		[105] = {
			[774] = { enabled = true, name = "Rejuvenation" },
			[8936] = { enabled = true, name = "Regrowth" },
			[33763] = { enabled = true, name = "Lifebloom" },
			[48438] = { enabled = true, name = "Wild Growth" },
			[155777] = { enabled = true, name = "Germination" },
		},
		[-1] = {
			[774] = { enabled = true, name = "Rejuvenation" },
			[8936] = { enabled = true, name = "Regrowth" },
			[33763] = { enabled = true, name = "Lifebloom" },
			[48438] = { enabled = true, name = "Wild Growth" },
			[155777] = { enabled = true, name = "Germination" },
		},
	},

	PRIEST = {
		[256] = {
			[17] = { enabled = true, name = "Power Word: Shield" },
			[194384] = { enabled = true, name = "Atonement" },
			[1253593] = { enabled = true, name = "Void Shield" },
			[41635] = { enabled = true, name = "Prayer of Mending" },
		},
		[257] = {
			[139] = { enabled = true, name = "Renew" },
			[41635] = { enabled = true, name = "Prayer of Mending" },
			[77489] = { enabled = true, name = "Echo of Light" },
		},
		[-1] = {
			[139] = { enabled = true, name = "Renew" },
			[41635] = { enabled = true, name = "Prayer of Mending" },
			[77489] = { enabled = true, name = "Echo of Light" },
			[17] = { enabled = true, name = "Power Word: Shield" },
			[194384] = { enabled = true, name = "Atonement" },
			[1253593] = { enabled = true, name = "Void Shield" },
		},
	},

	MONK = {
		[270] = {
			[115175] = { enabled = true, name = "Soothing Mist" },
			[119611] = { enabled = true, name = "Renewing Mist" },
			[124682] = { enabled = true, name = "Enveloping Mist" },
			[450769] = { enabled = true, name = "Aspect of Harmony" },
		},
		[-1] = {
			[115175] = { enabled = true, name = "Soothing Mist" },
			[119611] = { enabled = true, name = "Renewing Mist" },
			[124682] = { enabled = true, name = "Enveloping Mist" },
			[450769] = { enabled = true, name = "Aspect of Harmony" },
		},
	},

	SHAMAN = {
		[264] = {
			[974] = { enabled = true, name = 'Earth Shield "Ally"' },
			[383648] = { enabled = true, name = 'Earth Shield "Self"' },
			[61295] = { enabled = true, name = "Riptide" },
			[207400] = { enabled = true, name = "Ancestral Vigor" },
			[382024] = { enabled = true, name = "Earthliving Weapon" },
			-- [444490] = { enabled = true, name = "Hydrobubble", allowMissingSource = true },
			-- Some issues with filtering Hydrobubble because source is not player but ancestors so can't be filtered by HELPFUL|PLAYER
		},
		[-1] = {
			[974] = { enabled = true, name = 'Earth Shield "Ally"' },
			[383648] = { enabled = true, name = 'Earth Shield "Self"' },
			[61295] = { enabled = true, name = "Riptide" },
			[207400] = { enabled = true, name = "Ancestral Vigor" },
			[382024] = { enabled = true, name = "Earthliving Weapon" },
			-- [444490] = { enabled = true, name = "Hydrobubble", allowMissingSource = true },
			-- Some issues with filtering Hydrobubble because source is not player but ancestors so can't be filtered by HELPFUL|PLAYER
		},
	},

	PALADIN = {
		[65] = {
			[53563] = { enabled = true, name = "Beacon of Light" },
			[156322] = { enabled = true, name = "Eternal Flame" },
			[156910] = { enabled = true, name = "Beacon of Faith" },
			[1244893] = { enabled = true, name = "Beacon of the Savior" },
		},
		[-1] = {
			[53563] = { enabled = true, name = "Beacon of Light" },
			[156322] = { enabled = true, name = "Eternal Flame" },
			[156910] = { enabled = true, name = "Beacon of Faith" },
			[1244893] = { enabled = true, name = "Beacon of the Savior" },
		},
	},
}

local function SyncCustomAuraValues(currentValues, defaultValues)
	currentValues = currentValues or {}
	defaultValues = defaultValues or {}

	for className in pairs(currentValues) do
		if defaultValues[className] == nil then
			currentValues[className] = nil
		end
	end

	for className, classDefaults in pairs(defaultValues) do
		local classValues = currentValues[className]
		if type(classValues) ~= "table" then
			classValues = {}
			currentValues[className] = classValues
		end

		for specID in pairs(classValues) do
			if classDefaults[specID] == nil then
				classValues[specID] = nil
			end
		end

		for specID, specDefaults in pairs(classDefaults) do
			local specValues = classValues[specID]
			if type(specValues) ~= "table" then
				specValues = {}
				classValues[specID] = specValues
			end

			for spellId in pairs(specValues) do
				if specDefaults[spellId] == nil then
					specValues[spellId] = nil
				end
			end

			for spellId, defaultEntry in pairs(specDefaults) do
				local currentEntry = specValues[spellId]
				if type(currentEntry) ~= "table" then
					currentEntry = {}
					specValues[spellId] = currentEntry
				end

				for key, value in pairs(defaultEntry) do
					if key == "name" then
						currentEntry[key] = value
					elseif currentEntry[key] == nil then
						currentEntry[key] = value
					end
				end
			end
		end
	end

	return currentValues
end

local function SyncCustomBuffs(currentValues, defaultValues)
	currentValues = currentValues or {}
	defaultValues = defaultValues or {}

	for className in pairs(currentValues) do
		if defaultValues[className] == nil then
			currentValues[className] = nil
		end
	end

	for className, classDefaults in pairs(defaultValues) do
		local classValues = currentValues[className]
		if type(classValues) ~= "table" then
			classValues = {}
			currentValues[className] = classValues
		end

		for specID in pairs(classValues) do
			if classDefaults[specID] == nil then
				classValues[specID] = nil
			end
		end

		for specID, specDefaults in pairs(classDefaults) do
			local specValues = classValues[specID]
			if type(specValues) ~= "table" then
				specValues = {}
				classValues[specID] = specValues
			end

			for spellId in pairs(specValues) do
				if specDefaults[spellId] == nil or specDefaults[spellId].enabled == false then
					specValues[spellId] = nil
				end
			end

			for spellId, defaultEntry in pairs(specDefaults) do
				if defaultEntry.enabled ~= false then
					local currentEntry = specValues[spellId]
					if type(currentEntry) ~= "table" then
						currentEntry = {}
						specValues[spellId] = currentEntry
					end

					currentEntry.name = defaultEntry.name

					if currentEntry.enabled == nil then
						currentEntry.enabled = false
					end
					if currentEntry.anchor == nil then
						currentEntry.anchor = "CENTER"
					end
					if currentEntry.offsetX == nil then
						currentEntry.offsetX = 0
					end
					if currentEntry.offsetY == nil then
						currentEntry.offsetY = 0
					end
					if currentEntry.iconSize == nil then
						currentEntry.iconSize = 16
					end
					if currentEntry.showStacks == nil then
						currentEntry.showStacks = false
					end
					if currentEntry.stacksFontSize == nil then
						currentEntry.stacksFontSize = 10
					end
					if currentEntry.showCooldown == nil then
						currentEntry.showCooldown = false
					end
					if currentEntry.cooldownFontSize == nil then
						currentEntry.cooldownFontSize = 10
					end
				end
			end
		end
	end

	return currentValues
end

local function SyncProfileCustomAuraDefaults(profileSection)
	if type(profileSection) ~= "table" then
		return
	end

	profileSection.widgets = profileSection.widgets or {}
	profileSection.widgets.icons = profileSection.widgets.icons or {}
	profileSection.widgets.icons.buffs = profileSection.widgets.icons.buffs or {}
	profileSection.widgets.icons.customBuffs = profileSection.widgets.icons.customBuffs or {}

	local buffSettings = profileSection.widgets.icons.buffs
	buffSettings.customAuraValues = SyncCustomAuraValues(buffSettings.customAuraValues, CUSTOM_AURA_DEFAULTS)

	profileSection.widgets.icons.customBuffs =
		SyncCustomBuffs(profileSection.widgets.icons.customBuffs, CUSTOM_AURA_DEFAULTS)
end

local function SyncAllProfilesCustomAuraDefaults(profile)
	if type(profile) ~= "table" then
		return
	end

	SyncProfileCustomAuraDefaults(profile.party)
	SyncProfileCustomAuraDefaults(profile.raid)
end

function Database:GetCustomAuraDefaults()
	return CUSTOM_AURA_DEFAULTS
end

local DEFAULTS = {
	profile = {
		core = {
			showSoloPartyFrame = true,
			hideBlizzardRaidFrames = true,
			hideBlizzardRaidFrameManager = false,
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
					healAbsorbs = {
						enabled = false,
						abbreviate = true,
						anchor = "CENTER",
						position = {
							x = 0,
							y = 0,
						},
						size = 10,
						outline = "OUTLINE",
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
					},
				},
				icons = {
					buffs = {
						enabled = true,
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

						useCustomBuffFilter = false,
						showExternals = false,
						customAuraValues = {},

						borderSizePx = 1,
					},
					customBuffs = {},
					debuffs = {
						enabled = true,
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
						borderColorByDebuffType = false,
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
					dispels = {
						enabled = true,
						anchor = "TOPRIGHT",
						relativeAnchor = "TOPRIGHT",
						growDirection = "LEFT",
						offsetX = -2,
						offsetY = -2,
						maxIcons = 4,

						iconSize = 12,
						spacing = 1,
						alpha = 1.0,
					},
					raidBuffReminder = {
						enabled = true,
						showInCombat = false,
						anchor = "CENTER",
						offsetX = 0,
						offsetY = 0,
						iconSize = 32,
						borderSizePx = 1,
						borderColor = { r = 1, g = 0, b = 0, a = 1 },
					},
				},
				bars = {
					absorbs = {
						texture = "Flat",
						color = {
							r = 0.2,
							g = 0.8,
							b = 1.0,
							a = 0.5,
						},
					},
					healAbsorbs = {
						texture = "Flat",
						color = {
							r = 1,
							g = 0,
							b = 0,
							a = 0.5,
						},
					},
					buffOverlays = {
						overlay1 = {
							bySpec = {
								[65] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[105] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[256] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[257] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[264] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[270] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[1467] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[1473] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
							},
						},
					},
				},
				indicators = {
					readyCheck = {
						enabled = true,
						anchor = "CENTER",
						offsetX = 0,
						offsetY = 0,
						size = 36,
					},
					raidMarker = {
						enabled = true,
						anchor = "TOP",
						offsetX = 0,
						offsetY = 0,
						size = 18,
					},
					roleIcon = {
						enabled = false,
						anchor = "TOPLEFT",
						offsetX = 0,
						offsetY = 0,
						size = 16,
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
					healAbsorbs = {
						enabled = false,
						abbreviate = true,
						anchor = "CENTER",
						position = {
							x = 0,
							y = 0,
						},
						size = 10,
						outline = "OUTLINE",
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
					},
				},
				icons = {
					buffs = {
						enabled = true,
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

						useCustomBuffFilter = false,
						showExternals = false,
						customAuraValues = {},

						borderSizePx = 1,
					},
					customBuffs = {},
					debuffs = {
						enabled = true,
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
						borderColorByDebuffType = false,
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
					dispels = {
						enabled = true,
						anchor = "TOPRIGHT",
						relativeAnchor = "TOPRIGHT",
						growDirection = "LEFT",
						offsetX = -2,
						offsetY = -2,
						maxIcons = 4,

						iconSize = 12,
						spacing = 1,
						alpha = 1.0,
					},
					raidBuffReminder = {
						enabled = true,
						showInCombat = false,
						anchor = "CENTER",
						offsetX = 0,
						offsetY = 0,
						iconSize = 28,
						borderSizePx = 1,
						borderColor = { r = 1, g = 0, b = 0, a = 1 },
					},
				},
				bars = {
					absorbs = {
						texture = "Flat",
						color = {
							r = 0.2,
							g = 0.8,
							b = 1.0,
							a = 0.5,
						},
					},
					healAbsorbs = {
						texture = "Flat",
						color = {
							r = 1,
							g = 0,
							b = 0,
							a = 0.5,
						},
					},
					buffOverlays = {
						overlay1 = {
							bySpec = {
								[65] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[105] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[256] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[257] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[264] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[270] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[1467] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
								[1473] = {
									enabled = false,
									spellId = 0,
									color = { r = 1.0, g = 1.0, b = 1.0 },
								},
							},
						},
					},
				},
				indicators = {
					readyCheck = {
						enabled = true,
						anchor = "CENTER",
						offsetX = 0,
						offsetY = 0,
						size = 36,
					},
					raidMarker = {
						enabled = true,
						anchor = "TOP",
						offsetX = 0,
						offsetY = 0,
						size = 18,
					},
					roleIcon = {
						enabled = false,
						anchor = "TOPLEFT",
						offsetX = 0,
						offsetY = 0,
						size = 16,
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
	local values = {}
	local names = self.db:GetProfiles({})

	for _, name in ipairs(names) do
		values[name] = name
	end

	return values
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
	SyncAllProfilesCustomAuraDefaults(self.db.profile)

	local function OnProfileChanged()
		SyncAllProfilesCustomAuraDefaults(self.db.profile)

		if addon.Options and addon.Options.Data and addon.Options.Data.RefreshProfile then
			addon.Options.Data:RefreshProfile()
		end

		addon.Frames.RangeChecker:UpdateSettings()
		addon.Modules:RequestUpdateAll()
	end

	self.db:RegisterCallback("OnProfileChanged", OnProfileChanged)
	self.db:RegisterCallback("OnProfileCopied", OnProfileChanged)
	self.db:RegisterCallback("OnProfileReset", OnProfileChanged)
	self.db:RegisterCallback("OnProfileDeleted", OnProfileChanged)

	initialized = true
end
