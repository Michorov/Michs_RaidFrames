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

local CUSTOM_BUFF_SETTING_DEFAULTS = {
	enabled = false,
	anchor = "CENTER",
	offsetX = 0,
	offsetY = 0,
	iconSize = 16,
	showStacks = false,
	stacksFontSize = 10,
	showCooldown = false,
	cooldownFontSize = 10,
	colorTexture = false,
	colorTextureColor = {
		r = 1,
		g = 1,
		b = 1,
		a = 1,
	},
}

local function CreateDefaultClickCastingBindings()
	local bindings = {
		{
			action = "target",
			button = "1",
			modifier = "",
			type = "action",
		},
		{
			action = "togglemenu",
			button = "2",
			modifier = "",
			type = "action",
		},
	}

	for i = 3, 10 do
		bindings[i] = {}
	end

	return bindings
end

local function GetPlayerSpecIDs()
	local specIDs = {}
	local _, _, classID = UnitClass("player")

	if not classID then
		return specIDs
	end

	local specCount = C_SpecializationInfo.GetNumSpecializationsForClassID(classID) or 0
	for specIndex = 1, specCount do
		local specID = GetSpecializationInfoForClassID(classID, specIndex)
		specIDs[#specIDs + 1] = specID
	end

	return specIDs
end

local function SyncClickCastingDefaults(profile)
	if type(profile) ~= "table" then
		return
	end

	profile.core = profile.core or {}
	profile.core.clickCasting = profile.core.clickCasting or {}

	local clickCasting = profile.core.clickCasting
	clickCasting.source = clickCasting.source == "local" and "local" or "external"
	clickCasting.specs = type(clickCasting.specs) == "table" and clickCasting.specs or {}

	for _, specID in ipairs(GetPlayerSpecIDs()) do
		local specSettings = clickCasting.specs[specID]
		if type(specSettings) ~= "table" then
			specSettings = {}
			clickCasting.specs[specID] = specSettings
		end

		if type(specSettings.bindings) ~= "table" then
			specSettings.bindings = CreateDefaultClickCastingBindings()
		end
	end
end

local function SyncCustomAuraDefaults(currentValues, defaultValues, entrySettingDefaults)
	currentValues = currentValues or {}
	defaultValues = defaultValues or {}
	local useEntrySettingDefaults = type(entrySettingDefaults) == "table"

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
				local defaultEntry = specDefaults[spellId]
				if defaultEntry == nil or (useEntrySettingDefaults and defaultEntry.enabled == false) then
					specValues[spellId] = nil
				end
			end

			for spellId, defaultEntry in pairs(specDefaults) do
				if not useEntrySettingDefaults or defaultEntry.enabled ~= false then
					local currentEntry = specValues[spellId]
					if type(currentEntry) ~= "table" then
						currentEntry = {}
						specValues[spellId] = currentEntry
					end

					if useEntrySettingDefaults then
						currentEntry.name = defaultEntry.name

						for key, value in pairs(entrySettingDefaults) do
							if currentEntry[key] == nil then
								currentEntry[key] = value
							end
						end
					else
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
	buffSettings.customAuraValues = SyncCustomAuraDefaults(buffSettings.customAuraValues, CUSTOM_AURA_DEFAULTS)

	profileSection.widgets.icons.customBuffs = SyncCustomAuraDefaults(
		profileSection.widgets.icons.customBuffs,
		CUSTOM_AURA_DEFAULTS,
		CUSTOM_BUFF_SETTING_DEFAULTS
	)
end

local function SyncAllProfilesCustomAuraDefaults(profile)
	if type(profile) ~= "table" then
		return
	end

	SyncProfileCustomAuraDefaults(profile.party)
	SyncProfileCustomAuraDefaults(profile.raid)
end

local function NormalizeProfileTextSettings(profileSection)
	if type(profileSection) ~= "table" then
		return
	end

	local widgets = profileSection.widgets
	if type(widgets) ~= "table" then
		return
	end

	local texts = widgets.texts
	if type(texts) ~= "table" then
		return
	end

	if type(texts.name) == "table" then
		local outline = texts.name.outline
		if outline ~= nil then
			texts.name.outline = addon.Utilities:NormalizeFontOutline(outline)
		end
	end

	if type(texts.healAbsorbs) == "table" then
		local outline = texts.healAbsorbs.outline
		if outline ~= nil then
			texts.healAbsorbs.outline = addon.Utilities:NormalizeFontOutline(outline, "OUTLINE")
		end
	end

	if type(texts.away) == "table" then
		local outline = texts.away.outline
		if outline ~= nil then
			texts.away.outline = addon.Utilities:NormalizeFontOutline(outline)
		end
	end

	if type(texts.statusText) == "table" then
		local outline = texts.statusText.outline
		if outline ~= nil then
			texts.statusText.outline = addon.Utilities:NormalizeFontOutline(outline)
		end
	end
end

local function NormalizeCurrentProfileFontSettings(profile)
	if type(profile) ~= "table" then
		return
	end

	NormalizeProfileTextSettings(profile.party)
	NormalizeProfileTextSettings(profile.raid)
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
			lsmTexture = "M-SolidDarker",
			lsmFont = -2,
			clickCasting = {
				source = "external",
				specs = {},
			},
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
				lsmTexture = -1,
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
				lsmTexture = -1,
				height = 8,
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
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
						lsmFont = -1,
						size = 12,
						outline = "",
						truncate = false,
						maxLength = 12,
					},
					healAbsorbs = {
						enabled = false,
						abbreviate = true,
						anchor = "CENTER",
						position = {
							x = 0,
							y = 0,
						},
						lsmFont = -1,
						size = 10,
						outline = "OUTLINE",
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
					},
					away = {
						enabled = true,
						anchor = "CENTER",
						position = {
							x = 0,
							y = -18,
						},
						lsmFont = -1,
						size = 10,
						outline = "",
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
					},
					statusText = {
						anchor = "CENTER",
						position = {
							x = 0,
							y = 0,
						},
						lsmFont = -1,
						size = 16,
						outline = "",
						color = {
							r = 0.55,
							g = 0.55,
							b = 0.55,
							a = 1,
						},
					},
				},
				icons = {
					buffs = {
						enabled = true,
						anchor = "BOTTOMRIGHT",
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
						showTooltips = false,

						useCustomBuffFilter = false,
						showExternals = false,
						customAuraValues = {},

						borderSizePx = 1,
					},
					customBuffs = {},
					debuffs = {
						enabled = true,
						anchor = "BOTTOMLEFT",
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
						showTooltips = false,

						borderSizePx = 1,
						borderColorByDebuffType = false,
						filterBlacklistedDebuffs = true,
						filterPermanentDebuffs = false,
					},
					privateAuras = {
						anchor = "LEFT",
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
						showOnlyPlayerDispellable = true,
						gradientDirection = 0,
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
					pendingSummon = {
						enabled = true,
						anchor = "CENTER",
						offsetX = 0,
						offsetY = 0,
						size = 32,
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
						showTank = true,
						showHealer = true,
						showDps = true,
						anchor = "TOPLEFT",
						offsetX = 0,
						offsetY = 0,
						size = 16,
					},
					groupStatus = {
						enabled = false,
						showLeader = true,
						showAssistant = true,
						anchor = "TOPLEFT",
						offsetX = 1,
						offsetY = 8,
						size = 14,
					},
					threat = {
						enabled = false,
						borderSize = 2,
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
				lsmTexture = -1,
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
				lsmTexture = -1,
				height = 6,
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
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
						lsmFont = -1,
						size = 10,
						outline = "",
						truncate = false,
						maxLength = 12,
					},
					healAbsorbs = {
						enabled = false,
						abbreviate = true,
						anchor = "CENTER",
						position = {
							x = 0,
							y = 0,
						},
						lsmFont = -1,
						size = 10,
						outline = "OUTLINE",
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
					},
					away = {
						enabled = true,
						anchor = "CENTER",
						position = {
							x = 0,
							y = -18,
						},
						lsmFont = -1,
						size = 10,
						outline = "",
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
					},
					statusText = {
						anchor = "CENTER",
						position = {
							x = 0,
							y = 0,
						},
						lsmFont = -1,
						size = 16,
						outline = "",
						color = {
							r = 0.55,
							g = 0.55,
							b = 0.55,
							a = 1,
						},
					},
				},
				icons = {
					buffs = {
						enabled = true,
						anchor = "BOTTOMRIGHT",
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
						showTooltips = false,

						useCustomBuffFilter = false,
						showExternals = false,
						customAuraValues = {},

						borderSizePx = 1,
					},
					customBuffs = {},
					debuffs = {
						enabled = true,
						anchor = "BOTTOMLEFT",
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
						showTooltips = false,

						borderSizePx = 1,
						borderColorByDebuffType = false,
						filterBlacklistedDebuffs = true,
						filterPermanentDebuffs = false,
					},
					privateAuras = {
						anchor = "LEFT",
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
						showOnlyPlayerDispellable = true,
						gradientDirection = 0,
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
					pendingSummon = {
						enabled = true,
						anchor = "CENTER",
						offsetX = 0,
						offsetY = 0,
						size = 32,
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
						showTank = true,
						showHealer = true,
						showDps = true,
						anchor = "TOPLEFT",
						offsetX = 0,
						offsetY = 0,
						size = 16,
					},
					groupStatus = {
						enabled = false,
						showLeader = true,
						showAssistant = true,
						anchor = "TOPLEFT",
						offsetX = 1,
						offsetY = 8,
						size = 14,
					},
					threat = {
						enabled = false,
						borderSize = 2,
					},
				},
			},
		},
	},
	global = {},
	char = {
		specProfiles = {},
	},
}

local PRUNE_PROFILE_DEFAULTS_SKIP_PATHS = {
	["core.clickCasting.specs"] = true,
	["party.widgets.icons.buffs.customAuraValues"] = true,
	["party.widgets.icons.customBuffs"] = true,
	["raid.widgets.icons.buffs.customAuraValues"] = true,
	["raid.widgets.icons.customBuffs"] = true,
}

local function JoinProfileDefaultsPath(path, key)
	if path == "" then
		return tostring(key)
	end

	return path .. "." .. tostring(key)
end

local function PruneValuesMissingFromDefaults(currentValues, defaultValues, path)
	if type(currentValues) ~= "table" or type(defaultValues) ~= "table" then
		return
	end

	path = path or ""
	if PRUNE_PROFILE_DEFAULTS_SKIP_PATHS[path] then
		return
	end

	for key, value in pairs(currentValues) do
		local childPath = JoinProfileDefaultsPath(path, key)
		local defaultValue = defaultValues[key]
		if PRUNE_PROFILE_DEFAULTS_SKIP_PATHS[childPath] then
			-- Dynamic aura tables are normalized by their own sync functions.
		elseif defaultValue == nil then
			currentValues[key] = nil
		elseif type(value) == "table" and type(defaultValue) == "table" then
			PruneValuesMissingFromDefaults(value, defaultValue, childPath)
		end
	end
end

local function PruneProfileValuesMissingFromDefaults(profile)
	PruneValuesMissingFromDefaults(profile, DEFAULTS.profile, "")
end

local function EnsureCharData(database)
	if not initialized then
		error("Database is not initialized", 3)
	end

	local charData = database.db.char
	charData.specProfiles = charData.specProfiles or {}

	return charData
end

local function CleanupDeletedProfileReferences(savedCharacters, deletedProfile)
	if type(savedCharacters) ~= "table" then
		return
	end

	for _, charData in pairs(savedCharacters) do
		if type(charData) == "table" then
			if charData.baseProfile == deletedProfile then
				charData.baseProfile = "Default"
			end

			local specProfiles = charData.specProfiles
			if type(specProfiles) == "table" then
				for specID, profileName in pairs(specProfiles) do
					if profileName == deletedProfile then
						specProfiles[specID] = nil
					end
				end
			end
		end
	end
end

function Database:GetCurrentProfileName()
	return self.db:GetCurrentProfile()
end

function Database:GetLocaleOverride()
	if not initialized then
		return nil
	end

	local value = self.db.global and self.db.global.localeOverride or nil
	if type(value) ~= "string" or value == "" then
		return nil
	end

	return value
end

function Database:SetLocaleOverride(locale)
	if not initialized then
		error("Database is not initialized", 2)
	end

	if locale ~= nil and (type(locale) ~= "string" or locale == "") then
		error("Database:SetLocaleOverride requires locale to be a string or nil", 2)
	end

	self.db.global = self.db.global or {}
	self.db.global.localeOverride = locale
end

function Database:GetBaseProfileName()
	local charData = EnsureCharData(self)
	local baseProfile = charData.baseProfile

	if type(baseProfile) == "string" and baseProfile ~= "" and self:HasProfile(baseProfile) then
		return baseProfile
	end

	if self:HasProfile("Default") then
		charData.baseProfile = "Default"
	else
		charData.baseProfile = self.db:GetCurrentProfile()
	end

	return charData.baseProfile
end

function Database:SetBaseProfileName(name)
	if type(name) ~= "string" or name == "" then
		error("Database:SetBaseProfileName requires a non-empty profile name", 2)
	end

	if not self:HasProfile(name) then
		error(("Profile %q does not exist."):format(name), 2)
	end

	local charData = EnsureCharData(self)
	charData.baseProfile = name
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
	CleanupDeletedProfileReferences(self.db.sv and self.db.sv.char, name)
end

function Database:GetSpecProfileName(specID)
	if type(specID) ~= "number" then
		return nil
	end

	local charData = EnsureCharData(self)
	local profileName = charData.specProfiles[specID]

	if type(profileName) ~= "string" or profileName == "" then
		if profileName ~= nil then
			charData.specProfiles[specID] = nil
		end

		return nil
	end

	if not self:HasProfile(profileName) then
		charData.specProfiles[specID] = nil
		return nil
	end

	return profileName
end

function Database:SetSpecProfileName(specID, profileName)
	if type(specID) ~= "number" then
		error("Database:SetSpecProfileName requires a numeric specID", 2)
	end

	local charData = EnsureCharData(self)

	if profileName == nil or profileName == "" then
		charData.specProfiles[specID] = nil
		return
	end

	if type(profileName) ~= "string" then
		error("Database:SetSpecProfileName requires profileName to be a string or nil", 2)
	end

	if not self:HasProfile(profileName) then
		error(("Profile %q does not exist."):format(profileName), 2)
	end

	charData.specProfiles[specID] = profileName
end

function Database:ClearSpecProfileName(specID)
	if type(specID) ~= "number" then
		error("Database:ClearSpecProfileName requires a numeric specID", 2)
	end

	local charData = EnsureCharData(self)
	charData.specProfiles[specID] = nil
end

function Database:GetResolvedProfileName(specID)
	local specProfileName = self:GetSpecProfileName(specID)
	if specProfileName then
		return specProfileName
	end

	return self:GetBaseProfileName()
end

function Database:ApplyProfileForSpec(specID)
	local targetProfileName = self:GetResolvedProfileName(specID)
	local currentProfileName = self.db:GetCurrentProfile()

	if type(targetProfileName) == "string" and targetProfileName ~= "" and targetProfileName ~= currentProfileName then
		self.db:SetProfile(targetProfileName)
		return true
	end

	SyncClickCastingDefaults(self.db.profile)

	return false
end

function Database:ApplyProfileForCurrentSpec()
	local specID = addon.Utilities and addon.Utilities.GetPlayerSpecID and addon.Utilities:GetPlayerSpecID() or nil
	return self:ApplyProfileForSpec(specID)
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

	if self.db.char.baseProfile == nil or self.db.char.baseProfile == "" then
		self.db.char.baseProfile = self.db:GetCurrentProfile()
	end

	SyncClickCastingDefaults(self.db.profile)
	PruneProfileValuesMissingFromDefaults(self.db.profile)
	SyncAllProfilesCustomAuraDefaults(self.db.profile)
	NormalizeCurrentProfileFontSettings(self.db.profile)

	local function OnProfileChanged()
		SyncClickCastingDefaults(self.db.profile)
		PruneProfileValuesMissingFromDefaults(self.db.profile)
		SyncAllProfilesCustomAuraDefaults(self.db.profile)
		NormalizeCurrentProfileFontSettings(self.db.profile)

		if addon.Options and addon.Options.RefreshState then
			addon.Options:RefreshState()
		end

		addon.Frames.RangeChecker:UpdateSettings()
		addon.UpdateScheduler:Notify("clickCastingSettingsChanged")
		addon.Modules:RequestUpdateAll()
	end

	self.db:RegisterCallback("OnProfileChanged", OnProfileChanged)
	self.db:RegisterCallback("OnProfileCopied", OnProfileChanged)
	self.db:RegisterCallback("OnProfileReset", OnProfileChanged)
	self.db:RegisterCallback("OnProfileDeleted", OnProfileChanged)

	initialized = true
end
