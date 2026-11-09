local _, addon = ...

local Database = {}
addon.Database = Database

local AceDB = LibStub("AceDB-3.0")

local initialized = false

local CUSTOM_AURA_DEFAULTS = {
	EVOKER = {
		[1468] = {
			[355941] = { enabled = true, name = "Dream Breath", spellIDs = { 355941 } },
			[363502] = { enabled = true, name = "Dream Flight", spellIDs = { 363502 } },
			[364343] = { enabled = true, name = "Echo", spellIDs = { 364343 } },
			[366155] = { enabled = true, name = "Reversion", spellIDs = { 366155 } },
			[367364] = { enabled = true, name = "Echo Reversion", spellIDs = { 367364 } },
			[373267] = { enabled = true, name = "Lifebind", spellIDs = { 373267 } },
			[376788] = { enabled = true, name = "Echo Dream Breath", spellIDs = { 376788 } },
		},
		[1473] = {
			[360827] = { enabled = true, name = "Blistering Scales", spellIDs = { 360827 } },
			[395152] = { enabled = true, name = "Ebon Might", spellIDs = { 395152 } },
			[410089] = { enabled = true, name = "Prescience", spellIDs = { 410089 } },
			[410263] = { enabled = true, name = "Inferno's Blessing", spellIDs = { 410263 } },
			[410686] = { enabled = true, name = "Symbiotic Bloom", spellIDs = { 410686 } },
			[413984] = { enabled = true, name = "Shifting Sands", spellIDs = { 413984 } },
		},
		[-1] = {
			[360827] = { enabled = true, name = "Blistering Scales", spellIDs = { 360827 } },
			[395152] = { enabled = true, name = "Ebon Might", spellIDs = { 395152 } },
			[410089] = { enabled = true, name = "Prescience", spellIDs = { 410089 } },
			[410263] = { enabled = true, name = "Inferno's Blessing", spellIDs = { 410263 } },
			[410686] = { enabled = true, name = "Symbiotic Bloom", spellIDs = { 410686 } },
			[413984] = { enabled = true, name = "Shifting Sands", spellIDs = { 413984 } },
			[355941] = { enabled = true, name = "Dream Breath", spellIDs = { 355941 } },
			[363502] = { enabled = true, name = "Dream Flight", spellIDs = { 363502 } },
			[364343] = { enabled = true, name = "Echo", spellIDs = { 364343 } },
			[366155] = { enabled = true, name = "Reversion", spellIDs = { 366155 } },
			[367364] = { enabled = true, name = "Echo Reversion", spellIDs = { 367364 } },
			[373267] = { enabled = true, name = "Lifebind", spellIDs = { 373267 } },
			[376788] = { enabled = true, name = "Echo Dream Breath", spellIDs = { 376788 } },
		},
	},

	DRUID = {
		[105] = {
			[774] = { enabled = true, name = "Rejuvenation", spellIDs = { 774 } },
			[8936] = { enabled = true, name = "Regrowth", spellIDs = { 8936 } },
			[33763] = { enabled = true, name = "Lifebloom", spellIDs = { 33763 } },
			[48438] = { enabled = true, name = "Wild Growth", spellIDs = { 48438 } },
			[155777] = { enabled = true, name = "Germination", spellIDs = { 155777 } },
		},
		[1484] = {
			[774] = {
				enabled = true,
				name = "Rejuvenation",
				spellIDs = { 774, 1058, 1430, 2090, 2091, 3627, 8910, 9839, 9840, 9841, 25299 },
			},
			[8936] = {
				enabled = true,
				name = "Regrowth",
				spellIDs = { 8936, 8938, 8939, 8940, 8941, 9750, 9856, 9857, 9858 },
			},
			[408120] = {
				enabled = true,
				name = "Wild Growth",
				spellIDs = { 408120, 1238214, 1238215 },
			},
			[29166] = {
				enabled = true,
				name = "Innervate",
				spellIDs = { 29166 },
			},
			[467] = {
				enabled = true,
				name = "Thorns",
				spellIDs = { 467, 782, 1075, 8914, 9756, 9910 },
			},
		},
		[-1] = {
			[774] = { enabled = true, name = "Rejuvenation", spellIDs = { 774 } },
			[8936] = { enabled = true, name = "Regrowth", spellIDs = { 8936 } },
			[33763] = { enabled = true, name = "Lifebloom", spellIDs = { 33763 } },
			[48438] = { enabled = true, name = "Wild Growth", spellIDs = { 48438 } },
			[155777] = { enabled = true, name = "Germination", spellIDs = { 155777 } },
		},
	},

	PRIEST = {
		[256] = {
			[17] = { enabled = true, name = "Power Word: Shield", spellIDs = { 17 } },
			[194384] = { enabled = true, name = "Atonement", spellIDs = { 194384 } },
			[1253593] = { enabled = true, name = "Void Shield", spellIDs = { 1253593 } },
			[41635] = { enabled = true, name = "Prayer of Mending", spellIDs = { 41635 } },
			[10060] = { enabled = true, name = "Power Infusion", spellIDs = { 10060 } },
		},
		[257] = {
			[139] = { enabled = true, name = "Renew", spellIDs = { 139 } },
			[41635] = { enabled = true, name = "Prayer of Mending", spellIDs = { 41635 } },
			[77489] = { enabled = true, name = "Echo of Light", spellIDs = { 77489 } },
			[10060] = { enabled = true, name = "Power Infusion", spellIDs = { 10060 } },
		},
		[1487] = {
			[139] = {
				enabled = true,
				name = "Renew",
				spellIDs = { 139, 6074, 6075, 6076, 6077, 6078, 10927, 10928, 10929, 25315 },
			},
			[17] = {
				enabled = true,
				name = "Power Word: Shield",
				spellIDs = { 17, 592, 600, 3747, 6065, 6066, 10898, 10899, 10900, 10901 },
			},
			[401877] = {
				enabled = true,
				name = "Prayer of Mending",
				spellIDs = { 401877, 1240848, 1240849 },
			},
			[6346] = {
				enabled = true,
				name = "Fear Ward",
				spellIDs = { 6346 },
			},
			[431624] = {
				enabled = true,
				name = "Divine Aegis",
				spellIDs = { 431624 },
			},
			[10060] = {
				enabled = true,
				name = "Power Infusion",
				spellIDs = { 10060 },
			},
			[14893] = {
				enabled = true,
				name = "Inspiration",
				spellIDs = { 14893 },
			},
			[1277462] = {
				enabled = true,
				name = "Contingency Plan - Ward",
				spellIDs = { 1277462, 1277634, 1277638, 1277639, 1277640 },
			},
			[1277463] = {
				enabled = true,
				name = "Contingency Plan - Shield",
				spellIDs = { 1277463, 1277464, 1277465, 1277467, 1277466 },
			},
			[1277456] = {
				enabled = true,
				name = "Contingency Plan - Healing",
				spellIDs = { 1277456, 1277457, 1277458, 1277459, 1277460 },
			},
		},
		[-1] = {
			[139] = { enabled = true, name = "Renew", spellIDs = { 139 } },
			[41635] = { enabled = true, name = "Prayer of Mending", spellIDs = { 41635 } },
			[77489] = { enabled = true, name = "Echo of Light", spellIDs = { 77489 } },
			[17] = { enabled = true, name = "Power Word: Shield", spellIDs = { 17 } },
			[194384] = { enabled = true, name = "Atonement", spellIDs = { 194384 } },
			[1253593] = { enabled = true, name = "Void Shield", spellIDs = { 1253593 } },
			[10060] = { enabled = true, name = "Power Infusion", spellIDs = { 10060 } },
		},
	},

	MAGE = {
		[1482] = {
			[1008] = {
				enabled = true,
				name = "Amplify Magic",
				spellIDs = { 1008, 8455, 10169, 10170 },
			},
			[604] = {
				enabled = true,
				name = "Dampen Magic",
				spellIDs = { 604, 8450, 8451, 10173, 10174 },
			},
		},
	},

	MONK = {
		[270] = {
			[115175] = { enabled = true, name = "Soothing Mist", spellIDs = { 115175 } },
			[119611] = { enabled = true, name = "Renewing Mist", spellIDs = { 119611 } },
			[124682] = { enabled = true, name = "Enveloping Mist", spellIDs = { 124682 } },
			[450769] = { enabled = true, name = "Aspect of Harmony", spellIDs = { 450769 } },
		},
		[-1] = {
			[115175] = { enabled = true, name = "Soothing Mist", spellIDs = { 115175 } },
			[119611] = { enabled = true, name = "Renewing Mist", spellIDs = { 119611 } },
			[124682] = { enabled = true, name = "Enveloping Mist", spellIDs = { 124682 } },
			[450769] = { enabled = true, name = "Aspect of Harmony", spellIDs = { 450769 } },
		},
	},

	SHAMAN = {
		[264] = {
			[974] = { enabled = true, name = 'Earth Shield "Ally"', spellIDs = { 974 } },
			[383648] = { enabled = true, name = 'Earth Shield "Self"', spellIDs = { 383648 } },
			[61295] = { enabled = true, name = "Riptide", spellIDs = { 61295 } },
			[207400] = { enabled = true, name = "Ancestral Vigor", spellIDs = { 207400 } },
			[382024] = { enabled = true, name = "Earthliving Weapon", spellIDs = { 382024 } },
			-- [444490] = { enabled = true, name = "Hydrobubble", spellIDs = { 444490 }, allowMissingSource = true },
			-- Some issues with filtering Hydrobubble because source is not player but ancestors so can't be filtered by HELPFUL|PLAYER
		},
		[1489] = {
			[408521] = {
				enabled = true,
				name = "Riptide",
				spellIDs = { 408521, 1239242, 1239243 },
			},
			[16177] = {
				enabled = true,
				name = "Ancestral Fortitude",
				spellIDs = { 16177 },
			},
		},
		[-1] = {
			[974] = { enabled = true, name = 'Earth Shield "Ally"', spellIDs = { 974 } },
			[383648] = { enabled = true, name = 'Earth Shield "Self"', spellIDs = { 383648 } },
			[61295] = { enabled = true, name = "Riptide", spellIDs = { 61295 } },
			[207400] = { enabled = true, name = "Ancestral Vigor", spellIDs = { 207400 } },
			[382024] = { enabled = true, name = "Earthliving Weapon", spellIDs = { 382024 } },
			-- [444490] = { enabled = true, name = "Hydrobubble", spellIDs = { 444490 }, allowMissingSource = true },
			-- Some issues with filtering Hydrobubble because source is not player but ancestors so can't be filtered by HELPFUL|PLAYER
		},
	},

	PALADIN = {
		[65] = {
			[53563] = { enabled = true, name = "Beacon of Light", spellIDs = { 53563 } },
			[156322] = { enabled = true, name = "Eternal Flame", spellIDs = { 156322 } },
			[156910] = { enabled = true, name = "Beacon of Faith", spellIDs = { 156910 } },
			[1244893] = { enabled = true, name = "Beacon of the Savior", spellIDs = { 1244893 } },
		},
		[1486] = {
			[1310909] = {
				enabled = true,
				name = "Light's Vigil",
				spellIDs = { 1310909, 1311593, 1311597 },
			},
			[1328548] = {
				enabled = true,
				name = "Oath of Light",
				spellIDs = { 1328548 },
			},
			[1022] = {
				enabled = true,
				name = "Blessing of Protection",
				spellIDs = { 1022, 5599, 10278 },
			},
			[1044] = {
				enabled = true,
				name = "Blessing of Freedom",
				spellIDs = { 1044 },
			},
			[6940] = {
				enabled = true,
				name = "Blessing of Sacrifice",
				spellIDs = { 6940, 20729 },
			},
		},
		[-1] = {
			[53563] = { enabled = true, name = "Beacon of Light", spellIDs = { 53563 } },
			[156322] = { enabled = true, name = "Eternal Flame", spellIDs = { 156322 } },
			[156910] = { enabled = true, name = "Beacon of Faith", spellIDs = { 156910 } },
			[1244893] = { enabled = true, name = "Beacon of the Savior", spellIDs = { 1244893 } },
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
	local bindings = {}

	for i = 1, 10 do
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
						currentEntry.spellIDs = CopyTable(defaultEntry.spellIDs)

						for key, value in pairs(entrySettingDefaults) do
							if currentEntry[key] == nil then
								currentEntry[key] = value
							end
						end
					else
						for key, value in pairs(defaultEntry) do
							if key == "name" then
								currentEntry[key] = value
							elseif key == "spellIDs" then
								currentEntry[key] = CopyTable(value)
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
			minimap = {
				hide = false,
				minimapPos = 225,
			},
			clickCasting = {
				source = "external",
				specs = {},
			},
		},
		party = {
			size = { width = 128, height = 64 },
			position = { x = -400, y = 0 },
			npcEnabled = false,
			npcPosition = { x = -270, y = 0 },
			spacing = { x = -1, y = -1 },
			direction = "VERTICAL",
			npcDirection = "VERTICAL",
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
					r = 0.16,
					g = 0.16,
					b = 0.16,
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
					healthText = {
						enabled = false,
						format = "abbreviated",
						anchor = "CENTER",
						classColor = false,
						position = {
							x = 0,
							y = 0,
						},
						lsmFont = -1,
						size = 16,
						outline = "",
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
					},
					powerText = {
						enabled = false,
						healerOnly = false,
						format = "abbreviated",
						anchor = "BOTTOM",
						colorByPowerType = false,
						position = {
							x = 0,
							y = 1,
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
						showOverlay = true,
						showIcons = true,
						showBorder = true,
						showOnlyPlayerDispellable = true,
						showPoisonForShaman = false,
						showMagicForWarlock = false,
						iconsOnly = false,
						texture = "Gradient",
						gradientDirection = 0,
						anchor = "TOPRIGHT",
						growDirection = "LEFT",
						iconSize = 14,
						spacing = 0,
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
					healPrediction = {
						enabled = false,
						color = { r = 0.1, g = 0.6, b = 0.2, a = 1 },
					},
					ping = {
						enabled = true,
						anchor = "CENTER",
						offsetX = 0,
						offsetY = 0,
						size = 30,
					},
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
					},
					mouseover = {
						enabled = false,
						color = { r = 227 / 255, g = 220 / 255, b = 195 / 255, a = 1 },
					},
				},
			},
		},
		raid = {
			size = { width = 110, height = 56 },
			position = { x = -600, y = 0 },
			npcEnabled = false,
			npcPosition = { x = -270, y = 0 },
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
			npcDirection = "VERTICAL",
			reverse = true,
			showGroupLabel = false,
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
					r = 0.16,
					g = 0.16,
					b = 0.16,
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
					healthText = {
						enabled = false,
						format = "abbreviated",
						anchor = "CENTER",
						classColor = false,
						position = {
							x = 0,
							y = 0,
						},
						lsmFont = -1,
						size = 16,
						outline = "",
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
					},
					powerText = {
						enabled = false,
						healerOnly = false,
						format = "abbreviated",
						anchor = "BOTTOM",
						colorByPowerType = false,
						position = {
							x = 0,
							y = 1,
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
						showOverlay = true,
						showIcons = true,
						showBorder = true,
						showOnlyPlayerDispellable = true,
						showPoisonForShaman = false,
						showMagicForWarlock = false,
						iconsOnly = false,
						texture = "Gradient",
						gradientDirection = 0,
						anchor = "TOPRIGHT",
						growDirection = "LEFT",
						iconSize = 12,
						spacing = 0,
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
					healPrediction = {
						enabled = false,
						color = { r = 0.1, g = 0.6, b = 0.2, a = 1 },
					},
					ping = {
						enabled = true,
						anchor = "CENTER",
						offsetX = 0,
						offsetY = 0,
						size = 30,
					},
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
					},
					mouseover = {
						enabled = false,
						color = { r = 227 / 255, g = 220 / 255, b = 195 / 255, a = 1 },
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
		addon.Utilities.PixelPerfect:SetGlobalScale(self.db.profile.core.uiScale)

		if addon.Options and addon.Options.RefreshState then
			addon.Options:RefreshState()
		end

		addon.Frames.RangeChecker:UpdateSettings()
		if addon.Options and addon.Options.Minimap then
			addon.Options.Minimap:Refresh()
		end

		addon.UpdateScheduler:Notify("clickCastingSettingsChanged")
		addon.UpdateScheduler:Notify("rosterChanged")
		addon.Modules:RequestUpdateAll()
	end

	self.db:RegisterCallback("OnProfileChanged", OnProfileChanged)
	self.db:RegisterCallback("OnProfileCopied", OnProfileChanged)
	self.db:RegisterCallback("OnProfileReset", OnProfileChanged)
	self.db:RegisterCallback("OnProfileDeleted", OnProfileChanged)

	initialized = true
end
