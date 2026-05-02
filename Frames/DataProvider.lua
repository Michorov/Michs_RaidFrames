local _, addon = ...

addon.Frames = addon.Frames or {}
local Frames = addon.Frames

Frames.DataProvider = Frames.DataProvider or {}

local DataProvider = Frames.DataProvider

DataProvider.Live = {}
DataProvider.Test = {}

local CLASS_SAMPLES = {
	"WARRIOR",
	"PALADIN",
	"HUNTER",
	"ROGUE",
	"PRIEST",
	"DEATHKNIGHT",
	"SHAMAN",
	"MAGE",
	"WARLOCK",
	"MONK",
	"DRUID",
	"DEMONHUNTER",
	"EVOKER",
}

local function BuildCustomHelpfulTestAuras()
	local defaults = addon.Database:GetCustomAuraDefaults()
	local classFileName = addon.Utilities:GetPlayerClassFileName()
	local specID = addon.Utilities:GetPlayerSpecID()

	local classAuras = defaults and classFileName and defaults[classFileName]
	local specAuras = classAuras and ((specID and classAuras[specID]) or classAuras[-1])

	if type(specAuras) ~= "table" then
		return {}
	end

	local auras = {}

	for spellId, entry in pairs(specAuras) do
		local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellId)

		table.insert(auras, {
			name = entry and entry.name or ("Spell " .. tostring(spellId)),
			icon = icon,
			applications = 2,
			dispelName = nil,
			duration = 12,
			expirationTime = GetTime() + 10,
			sourceUnit = "player",
			spellId = spellId,
			canApplyAura = false,
			isBossAura = false,
			isFromPlayerOrPlayerPet = true,
			isHelpful = true,
			isHarmful = false,
			points = {},
		})
	end

	table.sort(auras, function(a, b)
		return (a.name or "") < (b.name or "")
	end)

	return auras
end

local function GetTestAuraInstanceID(filter, index)
	if filter == "harmful" or filter == "HARMFUL" then
		return 4000 + index
	end

	return 5000 + index
end

function DataProvider.Live:GetHealth(frame)
	if not frame or not frame.unit or not UnitExists(frame.unit) then
		return 0, 1
	end

	return UnitHealth(frame.unit), UnitHealthMax(frame.unit)
end

function DataProvider.Test:GetHealth(frame)
	local healthSamples = {
		{ current = 100000, max = 100000 },
		{ current = 87300, max = 100000 },
		{ current = 74200, max = 100000 },
		{ current = 61500, max = 100000 },
		{ current = 48800, max = 100000 },
		{ current = 35100, max = 100000 },
		{ current = 52645, max = 100000 },
		{ current = 6300, max = 100000 },
	}

	local healthIndex = frame and frame.testHealthIndex or 1
	healthIndex = ((healthIndex - 1) % #healthSamples) + 1

	local sample = healthSamples[healthIndex]
	return sample.current, sample.max
end

function DataProvider.Live:GetClassColor(frame, fallbackColor)
	return addon.Utilities:GetUnitClassColor(frame and frame.unit, fallbackColor)
end

function DataProvider.Test:GetClassColor(frame, fallbackColor)
	local index = frame and frame.testClassIndex or 1
	index = ((index - 1) % #CLASS_SAMPLES) + 1

	local classToken = CLASS_SAMPLES[index]
	local color = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]

	if color then
		return color.r, color.g, color.b, 1
	end

	return fallbackColor.r or 1, fallbackColor.g or 1, fallbackColor.b or 1, fallbackColor.a or 1
end

function DataProvider.Live:GetName(frame)
	if not frame or not frame.unit or not UnitExists(frame.unit) then
		return ""
	end

	return UnitName(frame.unit) or ""
end

function DataProvider.Test:GetName(frame)
	if frame and frame.testName then
		return frame.testName
	end

	local names = {
		"Aelrin",
		"Brakka",
		"Caelynn",
		"Dorun",
		"Elyra",
		"Faelor",
		"Garrik",
		"Halyra",
		"Irven",
		"Jorik",
		"Kaelis",
		"Lunara",
		"Morven",
		"Nyra",
		"Orin",
		"Pyrel",
		"Quorin",
		"Rhyssa",
		"Selric",
		"Thalen",
		"Vaelor",
		"Wrenna",
		"Xalor",
		"Yselle",
		"Zorik",
		"Ashara",
		"Belric",
		"Corven",
		"Daelis",
		"Elthor",
		"Fenra",
		"Galric",
		"Helra",
		"Ilyndra",
		"Jareth",
		"Kelza",
		"Lorven",
		"Myrra",
		"Nareth",
		"Olyra",
		"Perin",
		"Quella",
		"Raelor",
		"Syra",
		"Torven",
		"Ulric",
		"Velyra",
		"Wystan",
		"Xyra",
		"Yorik",
		"Zelra",
		"Althor",
		"Brynna",
		"Cerik",
		"Draven",
		"Esmira",
		"Falkor",
		"Glynn",
		"Heron",
		"Isolde",
		"Jandor",
		"Kyrra",
		"Lethan",
		"Maelis",
		"Nymor",
		"Orla",
		"Praxis",
		"Quenra",
		"Rovan",
		"Seris",
		"Tyral",
		"Ulnar",
		"Vaelis",
		"Wyra",
		"Xandor",
		"Ysara",
		"Zarek",
	}

	local index = frame and frame.testIndex or 1
	index = ((index - 1) % #names) + 1

	return names[index]
end

function DataProvider.Live:IsHealer(frame)
	local unit = frame and frame.unit
	if type(unit) ~= "string" or unit == "" then
		return false
	end

	local role = UnitGroupRolesAssigned(unit)
	if role == "HEALER" then
		return true
	end

	if UnitIsUnit(unit, "player") then
		local specIndex = GetSpecialization and GetSpecialization()
		if specIndex then
			local specRole = select(5, GetSpecializationInfo(specIndex))
			if specRole == "HEALER" then
				return true
			end
		end
	end

	return false
end

function DataProvider.Test:IsHealer(frame)
	local healerClasses = {
		DRUID = true,
		EVOKER = true,
		MONK = true,
		PALADIN = true,
		PRIEST = true,
		SHAMAN = true,
	}

	local classIndex = frame and frame.testClassIndex or 1
	classIndex = ((classIndex - 1) % #CLASS_SAMPLES) + 1

	local classToken = CLASS_SAMPLES[classIndex]
	if healerClasses[classToken] ~= true then
		return false
	end

	local index = frame and frame.testIndex or 1

	if index == 2 or index == 7 or index == 14 or index == 19 then
		return true
	end

	return false
end

function DataProvider.Live:GetPower(frame)
	local unit = frame and frame.unit
	if type(unit) ~= "string" or unit == "" or not UnitExists(unit) then
		return nil, nil, nil
	end

	if self:IsHealer(frame) then
		local manaType = Enum.PowerType and Enum.PowerType.Mana or 0
		return UnitPower(unit, manaType), UnitPowerMax(unit, manaType), "MANA"
	end

	local _, token = UnitPowerType(unit)
	return UnitPower(unit), UnitPowerMax(unit), token
end

function DataProvider.Test:GetPower(frame)
	local powerSamples = {
		{ current = 100, max = 100 },
		{ current = 80, max = 100 },
		{ current = 60, max = 100 },
		{ current = 45, max = 100 },
		{ current = 30, max = 100 },
		{ current = 90, max = 100 },
		{ current = 25, max = 100 },
		{ current = 70, max = 100 },
	}

	local classToPowerType = {
		WARRIOR = "RAGE",
		PALADIN = "MANA",
		HUNTER = "FOCUS",
		ROGUE = "ENERGY",
		PRIEST = "MANA",
		DEATHKNIGHT = "RUNIC_POWER",
		SHAMAN = "MANA",
		MAGE = "MANA",
		WARLOCK = "MANA",
		MONK = "ENERGY",
		DRUID = "MANA",
		DEMONHUNTER = "FURY",
		EVOKER = "ESSENCE",
	}

	local powerIndex = frame and frame.testPowerIndex or 1
	powerIndex = ((powerIndex - 1) % #powerSamples) + 1

	local sample = powerSamples[powerIndex]
	if self:IsHealer(frame) then
		return sample.current, sample.max, "MANA"
	end

	local classIndex = frame and frame.testClassIndex or 1
	classIndex = ((classIndex - 1) % #CLASS_SAMPLES) + 1

	local classToken = CLASS_SAMPLES[classIndex]
	local powerType = classToPowerType[classToken] or "MANA"

	return sample.current, sample.max, powerType
end

function DataProvider.Live:GetAbsorbs(frame)
	local unit = frame and frame.unit
	if type(unit) ~= "string" or unit == "" then
		return nil, nil
	end

	if not UnitExists(unit) or UnitCanAttack("player", unit) then
		return nil, nil
	end

	local maxHealth = UnitHealthMax(unit)
	if not maxHealth or maxHealth <= 0 then
		return nil, nil
	end

	local absorbValue

	if CreateUnitHealPredictionCalculator and UnitGetDetailedHealPrediction then
		frame.absorbCalculator = frame.absorbCalculator or CreateUnitHealPredictionCalculator()
		local calc = frame.absorbCalculator

		if calc.SetAbsorbClampMode then
			pcall(calc.SetAbsorbClampMode, calc, 0)
		end

		UnitGetDetailedHealPrediction(unit, nil, calc)

		if calc.GetAbsorbs then
			local ok, value = pcall(calc.GetAbsorbs, calc)
			if ok then
				absorbValue = value
			end
		end

		if absorbValue == nil and calc.GetTotalAbsorbs then
			local ok, value = pcall(calc.GetTotalAbsorbs, calc)
			if ok then
				absorbValue = value
			end
		end
	end

	if absorbValue == nil and UnitGetTotalAbsorbs then
		absorbValue = UnitGetTotalAbsorbs(unit)
	end

	if absorbValue == nil then
		return nil, nil
	end

	return absorbValue, maxHealth
end

function DataProvider.Test:GetAbsorbs(frame)
	local absorbSamples = {
		0,
		0,
		6000,
		0,
		11000,
		0,
		17777,
		25000,
	}

	local maxHealth = 100000
	local index = frame and frame.testAbsorbIndex or 1
	index = ((index - 1) % #absorbSamples) + 1

	return absorbSamples[index], maxHealth
end

function DataProvider.Live:GetHealAbsorbs(frame)
	local unit = frame and frame.unit
	if type(unit) ~= "string" or unit == "" then
		return nil, nil
	end

	if not UnitExists(unit) or UnitCanAttack("player", unit) then
		return nil, nil
	end

	local healAbsorbValue
	local totalHealAbsorbValue

	if CreateUnitHealPredictionCalculator and UnitGetDetailedHealPrediction then
		frame.healAbsorbCalculator = frame.healAbsorbCalculator or CreateUnitHealPredictionCalculator()
		local calc = frame.healAbsorbCalculator

		if calc.SetHealAbsorbClampMode then
			pcall(calc.SetHealAbsorbClampMode, calc, 0)
		end

		UnitGetDetailedHealPrediction(unit, nil, calc)

		if calc.GetHealAbsorbs then
			local ok, value = pcall(calc.GetHealAbsorbs, calc)
			if ok then
				healAbsorbValue = value
			end
		end

		if calc.GetTotalHealAbsorbs then
			local ok, value = pcall(calc.GetTotalHealAbsorbs, calc)
			if ok then
				totalHealAbsorbValue = value
			end
		end
	end

	if healAbsorbValue == nil and UnitGetTotalHealAbsorbs then
		healAbsorbValue = UnitGetTotalHealAbsorbs(unit)
		totalHealAbsorbValue = healAbsorbValue
	end

	if healAbsorbValue == nil then
		return nil, nil
	end

	return healAbsorbValue, totalHealAbsorbValue or healAbsorbValue
end

function DataProvider.Test:GetHealAbsorbs(frame)
	local healAbsorbSamples = {
		0,
		0,
		0,
		0,
		0,
		4000,
		15000,
		23000,
	}

	local index = frame and frame.testHealAbsorbIndex or 1
	index = ((index - 1) % #healAbsorbSamples) + 1

	return healAbsorbSamples[index], healAbsorbSamples[index]
end

function DataProvider.Live:GetRole(frame)
	local unit = frame and frame.unit
	if type(unit) ~= "string" or unit == "" then
		return nil
	end

	local role = UnitGroupRolesAssigned(unit)
	if role == "TANK" or role == "HEALER" or role == "DAMAGER" then
		return role
	end

	return nil
end

function DataProvider.Test:GetRole(frame)
	return nil
end

function DataProvider.Live:GetThreatStatus(frame)
	local unit = frame and frame.unit
	if type(unit) ~= "string" or unit == "" or not UnitExists(unit) then
		return nil
	end

	return UnitThreatSituation(unit)
end

function DataProvider.Test:GetThreatStatus(frame)
	local threatSamples = {
		nil,
		nil,
		1,
		2,
		3,
		nil,
		1,
		2,
	}

	local index = frame and frame.testIndex or 1
	index = ((index - 1) % #threatSamples) + 1

	return threatSamples[index]
end

function DataProvider.Live:GetAuraApplicationDisplayCount(frame, aura, minCount, maxCount)
	local unit = frame and frame.unit
	local auraInstanceID = aura and aura.auraInstanceID

	if type(unit) ~= "string" or unit == "" or auraInstanceID == nil then
		return nil
	end

	if not C_UnitAuras.GetAuraApplicationDisplayCount then
		return nil
	end

	return C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, minCount, maxCount)
end

function DataProvider.Test:GetAuraApplicationDisplayCount(frame, aura, minCount, maxCount)
	local applications = aura and aura.applications
	if type(applications) ~= "number" or applications <= 0 then
		return nil
	end

	minCount = minCount or 1
	maxCount = maxCount or applications

	if applications < minCount or applications > maxCount then
		return nil
	end

	return tostring(applications)
end

function DataProvider.Live:DoesAuraHaveExpirationTime(frame, aura)
	local unit = frame and frame.unit
	local auraInstanceID = aura and aura.auraInstanceID

	if type(unit) ~= "string" or unit == "" or auraInstanceID == nil then
		return false
	end

	if not C_UnitAuras.DoesAuraHaveExpirationTime then
		return false
	end

	return C_UnitAuras.DoesAuraHaveExpirationTime(unit, auraInstanceID)
end

function DataProvider.Test:DoesAuraHaveExpirationTime(frame, aura)
	if not aura then
		return false
	end

	return type(aura.duration) == "number"
		and aura.duration > 0
		and type(aura.expirationTime) == "number"
		and aura.expirationTime > 0
end

function DataProvider.Live:GetAuraDispelTypeColor(frame, aura, curve)
	local unit = frame and frame.unit
	local auraInstanceID = aura and aura.auraInstanceID

	if type(unit) ~= "string" or unit == "" or auraInstanceID == nil then
		return nil
	end

	if not C_UnitAuras.GetAuraDispelTypeColor then
		return nil
	end

	return C_UnitAuras.GetAuraDispelTypeColor(unit, auraInstanceID, curve)
end

function DataProvider.Test:GetAuraDispelTypeColor(frame, aura, curve)
	local dispelName = aura and aura.dispelName
	if dispelName == "Magic" then
		return DEBUFF_TYPE_MAGIC_COLOR
	elseif dispelName == "Curse" then
		return DEBUFF_TYPE_CURSE_COLOR
	elseif dispelName == "Disease" then
		return DEBUFF_TYPE_DISEASE_COLOR
	elseif dispelName == "Poison" then
		return DEBUFF_TYPE_POISON_COLOR
	elseif dispelName == "Enrage" or dispelName == "Bleed" then
		return DEBUFF_TYPE_BLEED_COLOR
	end

	return DEBUFF_TYPE_NONE_COLOR
end

function DataProvider.Live:GetUnitAuras(frame, collectionKey)
	local unit = frame and frame.unit
	if type(unit) ~= "string" or unit == "" then
		return {}
	end

	return addon.AuraHandler:GetUnitAuras(unit, collectionKey)
end

function DataProvider.Test:GetUnitAuras(frame, filter)
	local helpfulAuras = BuildCustomHelpfulTestAuras()

	if #helpfulAuras == 0 then
		helpfulAuras = {
			{
				name = "Renew",
				icon = 135953,
				applications = 0,
				dispelName = nil,
				duration = 12,
				expirationTime = GetTime() + 10,
				sourceUnit = "player",
				spellId = 139,
				canApplyAura = false,
				isBossAura = false,
				isFromPlayerOrPlayerPet = true,
				isHelpful = true,
				isHarmful = false,
				points = {},
			},
			{
				name = "Power Word: Shield",
				icon = 135940,
				applications = 0,
				dispelName = nil,
				duration = 15,
				expirationTime = GetTime() + 13,
				sourceUnit = "player",
				spellId = 17,
				canApplyAura = false,
				isBossAura = false,
				isFromPlayerOrPlayerPet = true,
				isHelpful = true,
				isHarmful = false,
				points = {},
			},
		}
	end

	local harmfulAuras = {
		{
			name = "Shadow Word: Pain",
			icon = 136207,
			applications = 0,
			dispelName = "Magic",
			duration = 14,
			expirationTime = GetTime() + 9,
			sourceUnit = "target",
			spellId = 589,
			canApplyAura = false,
			isBossAura = false,
			isFromPlayerOrPlayerPet = false,
			isHelpful = false,
			isHarmful = true,
			points = {},
		},
		{
			name = "Serpent Sting",
			icon = 132204,
			applications = 0,
			dispelName = "Poison",
			duration = 12,
			expirationTime = GetTime() + 6,
			sourceUnit = "target",
			spellId = 271788,
			canApplyAura = false,
			isBossAura = false,
			isFromPlayerOrPlayerPet = false,
			isHelpful = false,
			isHarmful = true,
			points = {},
		},
		{
			name = "Mortal Wound",
			icon = 132090,
			applications = 3,
			dispelName = nil,
			duration = 12,
			expirationTime = GetTime() + 6,
			sourceUnit = "target",
			spellId = 115804,
			canApplyAura = false,
			isBossAura = false,
			isFromPlayerOrPlayerPet = false,
			isHelpful = false,
			isHarmful = true,
			points = {},
		},
	}

	local helpfulBigDefensiveAuras = {
		{
			name = "Pain Suppression",
			icon = 135936,
			applications = 0,
			dispelName = nil,
			duration = 8,
			expirationTime = GetTime() + 6,
			sourceUnit = "party1",
			spellId = 33206,
			auraInstanceID = 2001,
			canApplyAura = false,
			isBossAura = false,
			isFromPlayerOrPlayerPet = false,
			isHelpful = true,
			isHarmful = false,
			points = {},
		},
	}

	local dispellableHarmfulAuras = {
		{
			name = "Unstable Affliction",
			icon = 136228,
			applications = 0,
			dispelName = "Magic",
			duration = 14,
			expirationTime = GetTime() + 11,
			sourceUnit = "target",
			spellId = 30108,
			auraInstanceID = 1001,
			canApplyAura = false,
			isBossAura = false,
			isFromPlayerOrPlayerPet = false,
			isHelpful = false,
			isHarmful = true,
			points = {},
		},
		{
			name = "Unstable Affliction",
			icon = 136228,
			applications = 0,
			dispelName = "Magic",
			duration = 14,
			expirationTime = GetTime() + 11,
			sourceUnit = "target",
			spellId = 30108,
			auraInstanceID = 1001,
			canApplyAura = false,
			isBossAura = false,
			isFromPlayerOrPlayerPet = false,
			isHelpful = false,
			isHarmful = true,
			points = {},
		},
		{
			name = "Hex",
			icon = 237579,
			applications = 0,
			dispelName = "Curse",
			duration = 30,
			expirationTime = GetTime() + 18,
			sourceUnit = "target",
			spellId = 51514,
			auraInstanceID = 1003,
			canApplyAura = false,
			isBossAura = false,
			isFromPlayerOrPlayerPet = false,
			isHelpful = false,
			isHarmful = true,
			points = {},
		},
		{
			name = "Virulent Plague",
			icon = 136181,
			applications = 0,
			dispelName = "Disease",
			duration = 21,
			expirationTime = GetTime() + 16,
			sourceUnit = "target",
			spellId = 191587,
			auraInstanceID = 1005,
			canApplyAura = false,
			isBossAura = false,
			isFromPlayerOrPlayerPet = false,
			isHelpful = false,
			isHarmful = true,
			points = {},
		},
		{
			name = "Serpent Sting",
			icon = 132204,
			applications = 0,
			dispelName = "Poison",
			duration = 12,
			expirationTime = GetTime() + 7,
			sourceUnit = "target",
			spellId = 271788,
			auraInstanceID = 1007,
			canApplyAura = false,
			isBossAura = false,
			isFromPlayerOrPlayerPet = false,
			isHelpful = false,
			isHarmful = true,
			points = {},
		},
		{
			name = "Deadly Poison",
			icon = 132290,
			applications = 2,
			dispelName = "Poison",
			duration = 12,
			expirationTime = GetTime() + 10,
			sourceUnit = "target",
			spellId = 2818,
			auraInstanceID = 1008,
			canApplyAura = false,
			isBossAura = false,
			isFromPlayerOrPlayerPet = false,
			isHelpful = false,
			isHarmful = true,
			points = {},
		},
	}

	local list
	if filter == "helpfulBigDefensive" then
		list = helpfulBigDefensiveAuras
	elseif filter == "harmfulRaidPlayerDispellable" then
		list = dispellableHarmfulAuras
	elseif filter == "harmful" or filter == "HARMFUL" then
		list = harmfulAuras
	elseif filter == "helpful" or filter == "helpfulPlayer" or filter == "HELPFUL" then
		list = helpfulAuras
	end

	if not list then
		return {}
	end

	local map = {}
	for index, aura in ipairs(list) do
		if aura and aura.auraInstanceID == nil then
			aura.auraInstanceID = GetTestAuraInstanceID(filter, index)
		end

		local id = aura and aura.auraInstanceID
		if id then
			map[id] = aura
		end
	end
	return map
end

function DataProvider.Live:GetUnitAuraInstanceIDs(frame, filterKey)
	local unit = frame and frame.unit
	if type(unit) ~= "string" or unit == "" then
		return {}
	end

	return addon.AuraHandler:GetUnitAuraInstanceIDs(unit, filterKey)
end

function DataProvider.Test:GetUnitAuraInstanceIDs(frame, filterKey)
	local auraInstanceIDs = {}
	local auras = self:GetUnitAuras(frame, filterKey)

	for _, aura in pairs(auras) do
		local auraInstanceID = aura and aura.auraInstanceID
		if auraInstanceID then
			auraInstanceIDs[auraInstanceID] = true
		end
	end

	return auraInstanceIDs
end

function DataProvider.Live:GetAuraDuration(frame, aura)
	local unit = frame and frame.unit
	local auraInstanceID = aura and aura.auraInstanceID
	if not unit or not auraInstanceID or not C_UnitAuras.GetAuraDuration then
		return nil
	end
	return C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
end

function DataProvider.Test:GetAuraDuration(frame, aura)
	if not aura or not C_DurationUtil or not C_DurationUtil.CreateDuration then
		return nil
	end
	local duration = type(aura.duration) == "number" and aura.duration or 0
	local expirationTime = type(aura.expirationTime) == "number" and aura.expirationTime or 0
	if duration <= 0 or expirationTime <= 0 then
		return nil
	end
	local durationObj = C_DurationUtil.CreateDuration()
	if durationObj and durationObj.SetTimeFromEnd then
		durationObj:SetTimeFromEnd(expirationTime, duration, 1)
	end
	return durationObj
end
