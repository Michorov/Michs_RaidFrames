local _, addon = ...

addon.Data = addon.Data or {}

addon.Data.CustomAuraDefaults = {
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
			[1277462] = { enabled = true, name = "Contingency Plan" },
			[600] = { enabled = true, name = "Power Word: Shield" },
			[6074] = { enabled = true, name = "Renew" },
			[17] = { enabled = true, name = "Power Word: Shield" },
			[194384] = { enabled = true, name = "Atonement" },
			[1253593] = { enabled = true, name = "Void Shield" },
			[41635] = { enabled = true, name = "Prayer of Mending" },
			[10060] = { enabled = true, name = "Power Infusion" },
		},
		[257] = {
			[1277462] = { enabled = true, name = "Contingency Plan" },
			[600] = { enabled = true, name = "Power Word: Shield" },
			[6074] = { enabled = true, name = "Renew" },
			[139] = { enabled = true, name = "Renew" },
			[41635] = { enabled = true, name = "Prayer of Mending" },
			[77489] = { enabled = true, name = "Echo of Light" },
			[10060] = { enabled = true, name = "Power Infusion" },
		},
		[-1] = {
			[139] = { enabled = true, name = "Renew" },
			[6074] = { enabled = true, name = "Renew" },
			[41635] = { enabled = true, name = "Prayer of Mending" },
			[77489] = { enabled = true, name = "Echo of Light" },
			[17] = { enabled = true, name = "Power Word: Shield" },
			[600] = { enabled = true, name = "Power Word: Shield" },
			[1277462] = { enabled = true, name = "Contingency Plan" },
			[194384] = { enabled = true, name = "Atonement" },
			[1253593] = { enabled = true, name = "Void Shield" },
			[10060] = { enabled = true, name = "Power Infusion" },
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

local interfaceVersion = select(4, GetBuildInfo())
if interfaceVersion < 16000 or interfaceVersion >= 17000 then
	return
end

local foreverAuraSpellIDs = {
	DRUID = {
		["Rejuvenation"] = { 774, 1058, 1430, 2090, 2091, 3627, 8910, 9839, 9840, 9841, 25299 },
		["Regrowth"] = { 8936, 8938, 8939, 8940, 8941, 9750, 9856, 9857, 9858 },
		["Wild Growth"] = { 408120, 1238214, 1238215 },
	},
	PRIEST = {
		["Renew"] = { 139, 6074, 6075, 6076, 6077, 6078, 10927, 10928, 10929, 25315 },
		["Power Word: Shield"] = { 17, 592, 600, 3747, 6065, 6066, 10898, 10899, 10900, 10901 },
		["Prayer of Mending"] = { 401877, 1240848, 1240849 },
		["Contingency Plan"] = {
			-- Wards, ranks 1-5.
			1277462, 1277634, 1277638, 1277639, 1277640,
			-- Triggered shields, ranks 1-5 (rank 4 is 1277467; rank 5 is 1277466).
			1277463, 1277464, 1277465, 1277467, 1277466,
			-- Triggered healing over time, ranks 1-5.
			1277456, 1277457, 1277458, 1277459, 1277460,
		},
	},
	SHAMAN = {
		["Riptide"] = { 408521, 1239242, 1239243 },
	},
}

for classFileName, auraSpellIDs in pairs(foreverAuraSpellIDs) do
	for _, specDefaults in pairs(addon.Data.CustomAuraDefaults[classFileName]) do
		for auraName, spellIDs in pairs(auraSpellIDs) do
			for _, spellID in ipairs(spellIDs) do
				if not specDefaults[spellID] then
					specDefaults[spellID] = { enabled = true, name = auraName }
				end
			end
		end
	end
end
