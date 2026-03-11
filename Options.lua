local _, addon = ...

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local APP_NAME = "Michs_RaidFrames"
local FOOTER_BUTTON_WIDTH = 90
local FOOTER_BUTTON_HEIGHT = 22
local FOOTER_BUTTON_FONT_SIZE = 12
local FOOTER_BUTTON_SPACING = 2
local FOOTER_CLOSE_RIGHT_INSET = 17

local function AddPageHeader(args, orderStart)
	args.pageTopSpacer = {
		type = "description",
		order = orderStart,
		name = "\n",
		width = "full",
	}

	args.pageHeaderTitle = {
		type = "description",
		order = orderStart + 0.01,
		fontSize = "large",
		name = "|cffff9900   Mich's RaidFrames|r",
		width = "full",
	}

	args.pageHeaderProfile = {
		type = "description",
		order = orderStart + 0.02,
		name = function()
			local current = addon.Database:GetCurrentProfileName() or "Default"
			return "     Active Profile: |cff00ff96" .. current .. "|r"
		end,
		width = "full",
	}

	args.pageHeaderSpacer = {
		type = "description",
		order = orderStart + 0.03,
		name = " ",
		width = "full",
	}
end

local function FindCloseButton(frame)
	if not frame or not frame.GetChildren then
		return nil
	end

	local direct = {
		frame.closebutton,
		frame.closeButton,
		frame.close,
	}
	for _, button in ipairs(direct) do
		if button and button.GetText and button:GetText() == CLOSE then
			return button
		end
	end

	for _, child in ipairs({ frame:GetChildren() }) do
		if child and child.GetObjectType and child:GetObjectType() == "Button" then
			local text = child.GetText and child:GetText()
			if text == CLOSE then
				return child
			end
		end
	end

	return nil
end

local function FindStatusBar(frame, window, closeButton)
	if not frame or not frame.GetChildren then
		return nil
	end

	for _, child in ipairs({ frame:GetChildren() }) do
		if
			child
			and child ~= closeButton
			and child.GetObjectType
			and child:GetObjectType() == "Button"
			and child.obj == window
		then
			return child
		end
	end

	return nil
end

local function EnsureFooterTestButtons()
	local openFrames = AceConfigDialog and AceConfigDialog.OpenFrames
	local window = openFrames and openFrames[APP_NAME]
	if not window then
		return
	end

	local frame = window.frame or window
	if not frame then
		return
	end

	local closeButton = FindCloseButton(frame)
	if not closeButton then
		return
	end

	closeButton:ClearAllPoints()
	closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -FOOTER_CLOSE_RIGHT_INSET, 17)
	closeButton:SetSize(FOOTER_BUTTON_WIDTH, FOOTER_BUTTON_HEIGHT)

	local statusBg = frame.statusbg or window.statusbg or FindStatusBar(frame, window, closeButton)
	if statusBg then
		local reservedRightWidth = (3 * FOOTER_BUTTON_WIDTH) + (3 * FOOTER_BUTTON_SPACING) + FOOTER_CLOSE_RIGHT_INSET
		statusBg:ClearAllPoints()
		statusBg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 17, 15)
		statusBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -reservedRightWidth, 15)

		if statusBg.SetHeight then
			statusBg:SetHeight(FOOTER_BUTTON_HEIGHT + 2)
		end
	end

	local statusText = frame.statustext or window.statustext
	if statusText and statusText.Hide then
		statusText:Hide()
	end

	if not frame.mrfPartyTestButton then
		local parent = closeButton:GetParent() or frame

		frame.mrfPartyTestButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		frame.mrfPartyTestButton:SetSize(FOOTER_BUTTON_WIDTH, FOOTER_BUTTON_HEIGHT)
		frame.mrfPartyTestButton:SetText("Party Test")

		frame.mrfPartyTestButton:SetScript("OnClick", function()
			addon.FrameRegistry:ToggleTestMode("party")
		end)

		frame.mrfRaidTestButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		frame.mrfRaidTestButton:SetSize(FOOTER_BUTTON_WIDTH, FOOTER_BUTTON_HEIGHT)
		frame.mrfRaidTestButton:SetText("Raid Test")
		frame.mrfRaidTestButton:SetScript("OnClick", function()
			addon.FrameRegistry:ToggleTestMode("raid")
		end)
	end

	frame.mrfPartyTestButton:SetWidth(FOOTER_BUTTON_WIDTH)
	frame.mrfRaidTestButton:SetWidth(FOOTER_BUTTON_WIDTH)

	local closeHeight = closeButton:GetHeight() or 20
	frame.mrfPartyTestButton:SetHeight(closeHeight)
	frame.mrfRaidTestButton:SetHeight(closeHeight)

	local normalFont = closeButton:GetNormalFontObject()
	local highlightFont = closeButton:GetHighlightFontObject()
	local disabledFont = closeButton:GetDisabledFontObject()
	if normalFont then
		frame.mrfPartyTestButton:SetNormalFontObject(normalFont)
		frame.mrfRaidTestButton:SetNormalFontObject(normalFont)
	end
	if highlightFont then
		frame.mrfPartyTestButton:SetHighlightFontObject(highlightFont)
		frame.mrfRaidTestButton:SetHighlightFontObject(highlightFont)
	end
	if disabledFont then
		frame.mrfPartyTestButton:SetDisabledFontObject(disabledFont)
		frame.mrfRaidTestButton:SetDisabledFontObject(disabledFont)
	end

	local fontPath, _, fontFlags
	local closeText = closeButton:GetFontString()
	if closeText and closeText.GetFont then
		fontPath, _, fontFlags = closeText:GetFont()
	end
	fontPath = fontPath or STANDARD_TEXT_FONT
	fontFlags = fontFlags or ""

	local function ApplyFooterButtonFontSize(button)
		local text = button and button:GetFontString()
		if text then
			text:SetFont(fontPath, FOOTER_BUTTON_FONT_SIZE, fontFlags)
		end
	end

	ApplyFooterButtonFontSize(closeButton)
	ApplyFooterButtonFontSize(frame.mrfPartyTestButton)
	ApplyFooterButtonFontSize(frame.mrfRaidTestButton)

	local strata = closeButton:GetFrameStrata()
	local level = closeButton:GetFrameLevel() + 3
	frame.mrfPartyTestButton:SetFrameStrata(strata)
	frame.mrfRaidTestButton:SetFrameStrata(strata)
	frame.mrfPartyTestButton:SetFrameLevel(level)
	frame.mrfRaidTestButton:SetFrameLevel(level)

	frame.mrfRaidTestButton:ClearAllPoints()
	frame.mrfRaidTestButton:SetPoint("RIGHT", closeButton, "LEFT", -FOOTER_BUTTON_SPACING, 0)

	frame.mrfPartyTestButton:ClearAllPoints()
	frame.mrfPartyTestButton:SetPoint("RIGHT", frame.mrfRaidTestButton, "LEFT", -FOOTER_BUTTON_SPACING, 0)
end

function addon:IsOptionsOpen()
	local openFrames = AceConfigDialog and AceConfigDialog.OpenFrames
	return openFrames and openFrames[APP_NAME] ~= nil
end

function addon:CloseOptions()
	if AceConfigDialog and AceConfigDialog.Close then
		AceConfigDialog:Close(APP_NAME)
	end
end

function addon:OpenOptions()
	if InCombatLockdown() then
		addon.optionsDeferredOpen = true
		print("|cffff9900Mich's RaidFrames:|r Options will open after combat.")
		return false
	end

	addon.optionsDeferredOpen = false
	AceConfigDialog:Open(APP_NAME)
	C_Timer.After(0, EnsureFooterTestButtons)

	local openFrames = AceConfigDialog and AceConfigDialog.OpenFrames
	local window = openFrames and openFrames[APP_NAME]
	local frame = window and (window.frame or window)

	if frame and not frame.mrfOnHideHooked then
		frame:HookScript("OnHide", function()
			addon.FrameRegistry:DisableTestMode()
		end)
		frame.mrfOnHideHooked = true
	end

	return true
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r Layout changes are disabled during combat.")
end

local profileUI = {
	newName = "",
	copyName = "",
	copyFrom = nil,
	deleteName = nil,
}

local function Trim(s)
	if type(s) ~= "string" then
		return ""
	end
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function GetProfileValues(includeDefault)
	local values = {}
	local db = addon.Database and addon.Database.db
	if not db then
		return values
	end

	local names = db:GetProfiles() or {}

	table.sort(names, function(a, b)
		return string.lower(tostring(a)) < string.lower(tostring(b))
	end)

	for _, name in ipairs(names) do
		if type(name) == "string" then
			if includeDefault or name ~= "Default" then
				values[name] = name
			end
		end
	end

	return values
end

local function PrintProfileMsg(msg)
	print("|cffff9900Mich's RaidFrames:|r " .. msg)
end

local function GetCustomBuffListOptions(layoutKey)
	local classFileName = addon.Utilities:GetPlayerClassFileName()
	local profile = addon.Database:GetProfile()
	local section = profile[layoutKey]
	local buffSettings = (((section or {}).widgets or {}).icons or {}).buffs or {}
	local customAuraValues = buffSettings.customAuraValues or {}
	local classAuras = customAuraValues[classFileName] or {}

	local args = {}
	local order = 10

	local specEntries = {}
	for specID, specAuras in pairs(classAuras) do
		if specID ~= -1 then
			local specName = select(2, GetSpecializationInfoByID(specID)) or ("Spec " .. tostring(specID))
			table.insert(specEntries, {
				specID = specID,
				name = specName,
				auras = specAuras,
			})
		end
	end

	table.sort(specEntries, function(a, b)
		return a.name < b.name
	end)

	for _, specEntry in ipairs(specEntries) do
		local specID = specEntry.specID
		local auraEntries = {}

		for spellId, auraData in pairs(specEntry.auras or {}) do
			table.insert(auraEntries, {
				spellId = spellId,
				name = auraData.name or ("Spell " .. tostring(spellId)),
			})
		end

		table.sort(auraEntries, function(a, b)
			return a.name < b.name
		end)

		local specArgs = {}
		local specOrder = 1

		for _, auraEntry in ipairs(auraEntries) do
			local spellId = auraEntry.spellId
			local label = auraEntry.name

			specArgs["spell_" .. specID .. "_" .. spellId] = {
				type = "toggle",
				name = label,
				order = specOrder,
				width = "full",
				disabled = function()
					return (((addon.Database:GetProfile()[layoutKey] or {}).widgets or {}).icons or {}).buffs.useCustomBuffFilter
						~= true
				end,
				get = function()
					local values = (
						(((addon.Database:GetProfile()[layoutKey] or {}).widgets or {}).icons or {}).buffs or {}
					).customAuraValues or {}
					local classValues = values[classFileName] or {}
					local specValues = classValues[specID] or {}
					local aura = specValues[spellId] or {}
					return aura.enabled == true
				end,
				set = function(_, v)
					local buffs = addon.Database:GetProfile()[layoutKey].widgets.icons.buffs
					buffs.customAuraValues = buffs.customAuraValues or {}
					buffs.customAuraValues[classFileName] = buffs.customAuraValues[classFileName] or {}
					buffs.customAuraValues[classFileName][specID] = buffs.customAuraValues[classFileName][specID] or {}
					buffs.customAuraValues[classFileName][specID][spellId] = buffs.customAuraValues[classFileName][specID][spellId]
						or {}
					buffs.customAuraValues[classFileName][specID][spellId].enabled = v

					addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
					addon.UpdateScheduler:Notify("aurasStateChanged")
				end,
			}

			specOrder = specOrder + 1
		end

		args["spec_" .. specID] = {
			type = "group",
			name = specEntry.name,
			order = order,
			inline = true,
			args = specArgs,
		}

		order = order + 1
	end

	return args
end

local function GetBuffOverlayOptions(layoutKey)
	local classFileName = addon.Utilities:GetPlayerClassFileName()
	local profile = addon.Database:GetProfile()
	local section = profile[layoutKey] or {}
	local widgets = section.widgets or {}
	local bars = widgets.bars or {}
	local buffOverlays = bars.buffOverlays or {}
	local defaultAuraValues = addon.Database:GetCustomAuraDefaults() or {}
	local classAuras = defaultAuraValues[classFileName] or {}

	local args = {}

	local overlayKeys = {}
	for overlayKey in pairs(buffOverlays) do
		table.insert(overlayKeys, overlayKey)
	end

	table.sort(overlayKeys)

	local specEntries = {}
	for specID, specAuras in pairs(classAuras) do
		if specID ~= -1 then
			local specName = select(2, GetSpecializationInfoByID(specID)) or ("Spec " .. tostring(specID))
			table.insert(specEntries, {
				specID = specID,
				name = specName,
				auras = specAuras,
			})
		end
	end

	table.sort(specEntries, function(a, b)
		return a.name < b.name
	end)

	local order = 10
	for _, specEntry in ipairs(specEntries) do
		local specID = specEntry.specID
		local spellValues = {
			[0] = "None",
		}

		local spellSorting = { 0 }

		local spellEntries = {}
		for spellId, auraData in pairs(specEntry.auras or {}) do
			table.insert(spellEntries, {
				spellId = spellId,
				name = auraData.name or ("Spell " .. tostring(spellId)),
			})
		end

		table.sort(spellEntries, function(a, b)
			return a.name < b.name
		end)

		for _, entry in ipairs(spellEntries) do
			spellValues[entry.spellId] = entry.name
			table.insert(spellSorting, entry.spellId)
		end

		local specArgs = {}
		local specOrder = 1

		for _, overlayKey in ipairs(overlayKeys) do
			local label = "Enable"

			specArgs["enabled_" .. specID .. "_" .. overlayKey] = {
				type = "toggle",
				name = label,
				order = specOrder,
				width = 0.9,
				disabled = function()
					return addon.Database:GetProfile()[layoutKey].widgets.icons.buffs.enabled ~= true
				end,
				get = function()
					local overlay = (
						((((addon.Database:GetProfile()[layoutKey] or {}).widgets or {}).bars or {}).buffOverlays or {})[overlayKey]
						or {}
					)
					local bySpec = overlay.bySpec or {}
					local specSettings = bySpec[specID] or {}
					return specSettings.enabled == true
				end,
				set = function(_, v)
					local overlay = addon.Database:GetProfile()[layoutKey].widgets.bars.buffOverlays[overlayKey]
					overlay.bySpec = overlay.bySpec or {}
					overlay.bySpec[specID] = overlay.bySpec[specID]
						or {
							enabled = false,
							spellId = 0,
							color = { r = 1, g = 1, b = 1 },
						}
					overlay.bySpec[specID].enabled = v
					addon.UpdateScheduler:Notify("buffOverlaySettingsChanged")
					addon.UpdateScheduler:Notify("aurasStateChanged")
				end,
			}

			specArgs["spell_" .. specID .. "_" .. overlayKey] = {
				type = "select",
				name = "",
				order = specOrder + 0.1,
				width = 1.1,
				values = spellValues,
				sorting = spellSorting,
				disabled = function()
					local profileBuffs = addon.Database:GetProfile()[layoutKey].widgets.icons.buffs
					local overlay = addon.Database:GetProfile()[layoutKey].widgets.bars.buffOverlays[overlayKey]
					local bySpec = overlay.bySpec or {}
					local specSettings = bySpec[specID] or {}
					return profileBuffs.enabled ~= true or specSettings.enabled ~= true
				end,
				get = function()
					local overlay = addon.Database:GetProfile()[layoutKey].widgets.bars.buffOverlays[overlayKey]
					local bySpec = overlay.bySpec or {}
					local specSettings = bySpec[specID] or {}
					return specSettings.spellId or 0
				end,
				set = function(_, v)
					local overlay = addon.Database:GetProfile()[layoutKey].widgets.bars.buffOverlays[overlayKey]
					overlay.bySpec = overlay.bySpec or {}
					overlay.bySpec[specID] = overlay.bySpec[specID]
						or {
							enabled = false,
							spellId = 0,
							color = { r = 1, g = 1, b = 1 },
						}
					overlay.bySpec[specID].spellId = v
					addon.UpdateScheduler:Notify("buffOverlaySettingsChanged")
					addon.UpdateScheduler:Notify("aurasStateChanged")
				end,
			}

			specArgs["color_" .. specID .. "_" .. overlayKey] = {
				type = "color",
				name = "",
				order = specOrder + 0.2,
				width = 0.5,
				hasAlpha = false,
				disabled = function()
					local profileBuffs = addon.Database:GetProfile()[layoutKey].widgets.icons.buffs
					local overlay = addon.Database:GetProfile()[layoutKey].widgets.bars.buffOverlays[overlayKey]
					local bySpec = overlay.bySpec or {}
					local specSettings = bySpec[specID] or {}
					return profileBuffs.enabled ~= true or specSettings.enabled ~= true
				end,
				get = function()
					local overlay = addon.Database:GetProfile()[layoutKey].widgets.bars.buffOverlays[overlayKey]
					local bySpec = overlay.bySpec or {}
					local specSettings = bySpec[specID] or {}
					local color = specSettings.color or {}
					return color.r or 1, color.g or 1, color.b or 1
				end,
				set = function(_, r, g, b)
					local overlay = addon.Database:GetProfile()[layoutKey].widgets.bars.buffOverlays[overlayKey]
					overlay.bySpec = overlay.bySpec or {}
					overlay.bySpec[specID] = overlay.bySpec[specID]
						or {
							enabled = false,
							spellId = 0,
							color = { r = 1, g = 1, b = 1 },
						}
					overlay.bySpec[specID].color = { r = r, g = g, b = b }
					addon.UpdateScheduler:Notify("buffOverlaySettingsChanged")
					addon.UpdateScheduler:Notify("aurasStateChanged")
				end,
			}

			specOrder = specOrder + 1
		end

		args["spec_" .. specID] = {
			type = "group",
			name = specEntry.name,
			order = order,
			inline = true,
			args = specArgs,
		}

		order = order + 1
	end

	return args
end

local options = {
	type = "group",
	name = "Mich's RaidFrames",
	args = {
		general = {
			type = "group",
			name = "General",
			order = 1,
			args = {
				showSoloPartyFrame = {
					type = "toggle",
					name = "Show Solo Party Frame",
					order = 1,
					width = "full",
					get = function()
						local profile = addon.Database:GetProfile()
						return profile.core.showSoloPartyFrame == true
					end,
					set = function(_, value)
						local profile = addon.Database:GetProfile()
						profile.core.showSoloPartyFrame = value
						addon.UpdateScheduler:Notify("soloFrameChanged")
					end,
				},
				hideBlizzardRaidFrames = {
					type = "toggle",
					name = "Hide Blizzard Party/Raid Frames",
					order = 2,
					width = "full",
					get = function()
						local profile = addon.Database:GetProfile()
						return profile.core.hideBlizzardRaidFrames == true
					end,
					set = function(_, value)
						local profile = addon.Database:GetProfile()
						profile.core.hideBlizzardRaidFrames = value
						addon.UpdateScheduler:Notify("layoutChanged")
					end,
				},
				rowSpacer1 = {
					type = "description",
					name = " ",
					order = 10,
					width = "full",
				},
				globalScale = {
					type = "range",
					name = "Global Scale",
					min = 0.5,
					max = 2.0,
					step = 0.01,
					isPercent = true,
					order = 12,
					get = function()
						return addon.Database:GetProfile().core.uiScale or 1
					end,
					set = function(_, v)
						local p = addon.Database:GetProfile()
						p.core.uiScale = v
						addon.UpdateScheduler:Notify("layoutChanged")
						addon.Modules:RequestUpdateSettings()
					end,
				},
				outOfRangeAlpha = {
					type = "range",
					name = "Out of Range Alpha",
					order = 11,
					min = 0,
					max = 1,
					step = 0.05,
					isPercent = true,
					get = function()
						return addon.Database:GetProfile().core.outOfRangeAlpha
					end,
					set = function(_, v)
						addon.Database:GetProfile().core.outOfRangeAlpha = v
						addon.UpdateScheduler:Notify("outOfRangeAlphaSettingChanged")
					end,
				},
			},
		},
		party = {
			type = "group",
			name = "Party",
			order = 2,
			childGroups = "tab",
			disabled = function()
				return InCombatLockdown()
			end,
			args = {
				layout = {
					type = "group",
					name = "Layout",
					order = 1,
					args = {
						partyPosX = {
							type = "range",
							name = "Position X",
							min = -2000,
							max = 2000,
							step = 1,
							get = function()
								local profile = addon.Database:GetProfile()
								return (profile.party.position and profile.party.position.x) or 0
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local profile = addon.Database:GetProfile()
								profile.party.position = profile.party.position or { x = 0, y = 0 }
								profile.party.position.x = value

								addon.UpdateScheduler:Notify("layoutChanged")
							end,
							order = 3,
						},
						partyPosY = {
							type = "range",
							name = "Position Y",
							min = -2000,
							max = 2000,
							step = 1,
							get = function()
								local profile = addon.Database:GetProfile()
								return (profile.party.position and profile.party.position.y) or 0
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local profile = addon.Database:GetProfile()
								profile.party.position = profile.party.position or { x = 0, y = 0 }
								profile.party.position.y = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
							order = 4,
						},
						partySpacingX = {
							type = "range",
							name = "Spacing X",
							min = -25,
							max = 25,
							step = 1,
							get = function()
								local profile = addon.Database:GetProfile()
								return (profile.party.spacing and profile.party.spacing.x) or 0
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end
								local profile = addon.Database:GetProfile()
								profile.party.spacing = profile.party.spacing or { x = 0, y = -4 }
								profile.party.spacing.x = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
							order = 5,
						},
						partySpacingY = {
							type = "range",
							name = "Spacing Y",
							min = -25,
							max = 25,
							step = 1,
							get = function()
								local profile = addon.Database:GetProfile()
								return (profile.party.spacing and profile.party.spacing.y) or -4
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end
								local profile = addon.Database:GetProfile()
								profile.party.spacing = profile.party.spacing or { x = 0, y = -4 }
								profile.party.spacing.y = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
							order = 6,
						},
						rowSpacer1 = {
							type = "description",
							name = " ",
							order = 6.01,
							width = "full",
						},
						partyDirection = {
							type = "select",
							name = "Direction",
							order = 7,
							values = {
								VERTICAL = "Vertical",
								HORIZONTAL = "Horizontal",
							},
							get = function()
								local profile = addon.Database:GetProfile()
								local party = profile.party or {}
								return party.direction or "VERTICAL"
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local profile = addon.Database:GetProfile()
								profile.party = profile.party or {}
								profile.party.direction = value

								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
					},
				},
				frames = {
					type = "group",
					name = "Frames",
					order = 2,
					childGroups = "tree",
					args = {
						frame = {
							type = "group",
							name = "Frame",
							order = 1,
							args = {
								partyWidth = {
									type = "range",
									name = "Width",
									min = 25,
									max = 300,
									step = 1,
									order = 1,
									get = function()
										local profile = addon.Database:GetProfile()
										return (profile.party.size and profile.party.size.width) or 110
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end

										local profile = addon.Database:GetProfile()
										profile.party.size = profile.party.size or { width = 128, height = 64 }
										profile.party.size.width = value
										addon.UpdateScheduler:Notify("layoutChanged")
									end,
								},
								partyHeight = {
									type = "range",
									name = "Height",
									min = 25,
									max = 300,
									step = 1,
									order = 2,
									get = function()
										local profile = addon.Database:GetProfile()
										return (profile.party.size and profile.party.size.height) or 36
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end

										local profile = addon.Database:GetProfile()
										profile.party.size = profile.party.size or { width = 128, height = 64 }
										profile.party.size.height = value
										addon.UpdateScheduler:Notify("layoutChanged")
									end,
								},
								partyBorderThickness = {
									type = "range",
									name = "Border Thickness",
									min = 1,
									max = 6,
									step = 1,
									order = 3,
									get = function()
										local profile = addon.Database:GetProfile()
										return ((profile.party or {}).border or {}).thicknessPx or 1
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.border = profile.party.border or {}
										profile.party.border.thicknessPx = value
										addon.UpdateScheduler:Notify("borderSettingsChanged")
									end,
								},
								rowSpacer1 = {
									type = "description",
									name = " ",
									order = 10,
									width = "full",
								},
								partyBackgroundColor = {
									type = "color",
									name = "Background Color",
									hasAlpha = true,
									order = 11,
									get = function()
										local profile = addon.Database:GetProfile()
										local c = ((profile.party or {}).background or {}).color
											or { r = 0.12, g = 0.12, b = 0.12, a = 1.0 }
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.background = profile.party.background or {}
										profile.party.background.color = { r = r, g = g, b = b, a = a }
										addon.UpdateScheduler:Notify("backgroundSettingsChanged")
									end,
								},
								partyBorderColor = {
									type = "color",
									name = "Border Color",
									hasAlpha = true,
									order = 12,
									get = function()
										local profile = addon.Database:GetProfile()
										local c = ((profile.party or {}).border or {}).color
											or { r = 0, g = 0, b = 0, a = 1 }
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.border = profile.party.border or {}
										profile.party.border.color = { r = r, g = g, b = b, a = a }
										addon.UpdateScheduler:Notify("borderSettingsChanged")
									end,
								},
							},
						},
						health = {
							type = "group",
							name = "Health",
							order = 2,
							args = {
								partyHealthUseClassColor = {
									type = "toggle",
									name = "Use Class Color",
									order = 11,
									get = function()
										local profile = addon.Database:GetProfile()
										return ((profile.party or {}).health or {}).classColor == true
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.health = profile.party.health or {}
										profile.party.health.classColor = value
										addon.UpdateScheduler:Notify("healthSettingsChanged")
									end,
								},
								partyHealthColor = {
									type = "color",
									name = "Health Color",
									hasAlpha = true,
									order = 12,
									get = function()
										local profile = addon.Database:GetProfile()
										local c = ((profile.party or {}).health or {}).color
											or { r = 0.12, g = 0.12, b = 0.12, a = 1.0 }
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end

										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.health = profile.party.health or {}
										profile.party.health.color = { r = r, g = g, b = b, a = a }

										addon.UpdateScheduler:Notify("healthSettingsChanged")
									end,
								},
							},
						},
						powerBarGroup = {
							type = "group",
							name = "Power Bar",
							order = 3,
							args = {
								enabled = {
									type = "toggle",
									name = "Enabled",
									order = 1,
									width = 1.0,
									get = function()
										local p = addon.Database:GetProfile()
										return ((p.party or {}).power or {}).enabled == true
									end,
									set = function(_, v)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.party = p.party or {}
										p.party.power = p.party.power or {}
										p.party.power.enabled = v
										addon.UpdateScheduler:Notify("powerSettingsChanged")
									end,
								},
								healerOnly = {
									type = "toggle",
									name = "Healers Only",
									order = 2,
									width = 1.0,
									disabled = function()
										local p = addon.Database:GetProfile()
										return ((p.party or {}).power or {}).enabled ~= true
									end,
									get = function()
										local p = addon.Database:GetProfile()
										return ((p.party or {}).power or {}).healerOnly == true
									end,
									set = function(_, v)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.party = p.party or {}
										p.party.power = p.party.power or {}
										p.party.power.healerOnly = v
										addon.UpdateScheduler:Notify("powerSettingsChanged")
									end,
								},
								height = {
									type = "range",
									name = "Height",
									order = 3,
									width = 1.0,
									min = 1,
									max = 20,
									step = 1,
									disabled = function()
										local p = addon.Database:GetProfile()
										return ((p.party or {}).power or {}).enabled ~= true
									end,
									get = function()
										local p = addon.Database:GetProfile()
										return ((p.party or {}).power or {}).height or 4
									end,
									set = function(_, v)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.party = p.party or {}
										p.party.power = p.party.power or {}
										p.party.power.height = v
										addon.UpdateScheduler:Notify("powerSettingsChanged")
									end,
								},
								borderEnabled = {
									type = "toggle",
									name = "Border",
									order = 4,
									width = 2.0,
									disabled = function()
										local p = addon.Database:GetProfile()
										return ((p.party or {}).power or {}).enabled ~= true
									end,
									get = function()
										local p = addon.Database:GetProfile()
										return ((p.party or {}).power or {}).borderEnabled ~= false
									end,
									set = function(_, v)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.party = p.party or {}
										p.party.power = p.party.power or {}
										p.party.power.borderEnabled = v
										addon.UpdateScheduler:Notify("powerSettingsChanged")
									end,
								},
								borderThickness = {
									type = "range",
									name = "Border Thickness",
									order = 5,
									width = 1.0,
									min = 1,
									max = 6,
									step = 1,
									disabled = function()
										local p = addon.Database:GetProfile()
										local power = ((p.party or {}).power or {})
										return (power.enabled ~= true) or (power.borderEnabled == false)
									end,
									get = function()
										local p = addon.Database:GetProfile()
										return ((p.party or {}).power or {}).borderThicknessPx or 1
									end,
									set = function(_, v)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.party = p.party or {}
										p.party.power = p.party.power or {}
										p.party.power.borderThicknessPx = v
										addon.UpdateScheduler:Notify("powerSettingsChanged")
									end,
								},
							},
						},
						absorbs = {
							type = "group",
							name = "Absorbs",
							order = 4,
							args = {
								partyAbsorbsColor = {
									type = "color",
									name = "Shield Color",
									hasAlpha = true,
									order = 10,
									get = function()
										local p = addon.Database:GetProfile()
										local c = ((((p.party or {}).widgets or {}).bars or {}).absorbs or {}).color
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.party = p.party or {}
										p.party.widgets = p.party.widgets or {}
										p.party.widgets.bars = p.party.widgets.bars or {}
										p.party.widgets.bars.absorbs = p.party.widgets.bars.absorbs or {}
										p.party.widgets.bars.absorbs.color = { r = r, g = g, b = b, a = a }
										addon.UpdateScheduler:Notify("absorbsSettingsChanged")
									end,
								},
							},
						},
						healAbsorbs = {
							type = "group",
							name = "Heal Absorbs",
							order = 5,
							args = {
								partyHealAbsorbsColor = {
									type = "color",
									name = "Heal Absorb Color",
									hasAlpha = true,
									order = 11,
									get = function()
										local p = addon.Database:GetProfile()
										local c = ((((p.party or {}).widgets or {}).bars or {}).healAbsorbs or {}).color
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.party = p.party or {}
										p.party.widgets = p.party.widgets or {}
										p.party.widgets.bars = p.party.widgets.bars or {}
										p.party.widgets.bars.healAbsorbs = p.party.widgets.bars.healAbsorbs or {}
										p.party.widgets.bars.healAbsorbs.color = { r = r, g = g, b = b, a = a }
										addon.UpdateScheduler:Notify("healAbsorbsSettingsChanged")
									end,
								},
							},
						},
					},
				},
				texts = {
					type = "group",
					name = "Texts",
					order = 3,
					childGroups = "tree",
					args = {
						name = {
							type = "group",
							name = "Name",
							order = 1,
							args = {
								partyNameAnchor = {
									type = "select",
									name = "Name Anchor",
									order = 1,
									values = {
										TOPLEFT = "Top Left",
										TOP = "Top Center",
										TOPRIGHT = "Top Right",
										LEFT = "Left",
										CENTER = "Center",
										RIGHT = "Right",
										BOTTOMLEFT = "Bottom Left",
										BOTTOM = "Bottom Center",
										BOTTOMRIGHT = "Bottom Right",
									},
									get = function()
										local profile = addon.Database:GetProfile()
										return ((((profile.party or {}).widgets or {}).texts or {}).name or {}).anchor
											or "TOPLEFT"
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.widgets = profile.party.widgets or {}
										profile.party.widgets.texts = profile.party.widgets.texts or {}
										profile.party.widgets.texts.name = profile.party.widgets.texts.name or {}
										profile.party.widgets.texts.name.anchor = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
								partyNameSize = {
									type = "range",
									name = "Name Size",
									min = 6,
									max = 32,
									step = 1,
									order = 2,
									get = function()
										local profile = addon.Database:GetProfile()
										return ((((profile.party or {}).widgets or {}).texts or {}).name or {}).size
											or 11
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.widgets = profile.party.widgets or {}
										profile.party.widgets.texts = profile.party.widgets.texts or {}
										profile.party.widgets.texts.name = profile.party.widgets.texts.name or {}
										profile.party.widgets.texts.name.size = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
								rowSpacer1 = {
									type = "description",
									name = " ",
									order = 10,
									width = "full",
								},
								partyNameOffsetX = {
									type = "range",
									name = "Name Offset X",
									min = -100,
									max = 100,
									step = 1,
									order = 11,
									get = function()
										local profile = addon.Database:GetProfile()
										local pos = ((((profile.party or {}).widgets or {}).texts or {}).name or {}).position
											or {}
										return pos.x or 2
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.widgets = profile.party.widgets or {}
										profile.party.widgets.texts = profile.party.widgets.texts or {}
										profile.party.widgets.texts.name = profile.party.widgets.texts.name or {}
										profile.party.widgets.texts.name.position = profile.party.widgets.texts.name.position
											or {}
										profile.party.widgets.texts.name.position.x = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
								partyNameOffsetY = {
									type = "range",
									name = "Name Offset Y",
									min = -100,
									max = 100,
									step = 1,
									order = 12,
									get = function()
										local profile = addon.Database:GetProfile()
										local pos = ((((profile.party or {}).widgets or {}).texts or {}).name or {}).position
											or {}
										return pos.y or -2
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.widgets = profile.party.widgets or {}
										profile.party.widgets.texts = profile.party.widgets.texts or {}
										profile.party.widgets.texts.name = profile.party.widgets.texts.name or {}
										profile.party.widgets.texts.name.position = profile.party.widgets.texts.name.position
											or {}
										profile.party.widgets.texts.name.position.y = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
								rowSpacer2 = {
									type = "description",
									name = " ",
									order = 20,
									width = "full",
								},
								partyNameClassColor = {
									type = "toggle",
									name = "Name Class Color",
									order = 21,
									get = function()
										local profile = addon.Database:GetProfile()
										return ((((profile.party or {}).widgets or {}).texts or {}).name or {}).classColor
											== true
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.widgets = profile.party.widgets or {}
										profile.party.widgets.texts = profile.party.widgets.texts or {}
										profile.party.widgets.texts.name = profile.party.widgets.texts.name or {}
										profile.party.widgets.texts.name.classColor = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},

								partyNameColor = {
									type = "color",
									name = "Name Color",
									hasAlpha = true,
									order = 22,
									disabled = function()
										local profile = addon.Database:GetProfile()
										return ((((profile.party or {}).widgets or {}).texts or {}).name or {}).classColor
											== true
									end,
									get = function()
										local profile = addon.Database:GetProfile()
										local c = ((((profile.party or {}).widgets or {}).texts or {}).name or {}).color
											or { r = 0, g = 0, b = 0, a = 1 }
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.widgets = profile.party.widgets or {}
										profile.party.widgets.texts = profile.party.widgets.texts or {}
										profile.party.widgets.texts.name = profile.party.widgets.texts.name or {}
										profile.party.widgets.texts.name.color = { r = r, g = g, b = b, a = a }
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
								rowSpacer3 = {
									type = "description",
									name = " ",
									order = 30,
									width = "full",
								},
								partyNameOutline = {
									type = "select",
									name = "Name Outline",
									order = 31,
									values = {
										NONE = "None",
										OUTLINE = "Outline",
										THICKOUTLINE = "Thick Outline",
										MONOCHROME = "Monochrome",
									},
									get = function()
										local profile = addon.Database:GetProfile()
										return ((((profile.party or {}).widgets or {}).texts or {}).name or {}).outline
											or "NONE"
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.party = profile.party or {}
										profile.party.widgets = profile.party.widgets or {}
										profile.party.widgets.texts = profile.party.widgets.texts or {}
										profile.party.widgets.texts.name = profile.party.widgets.texts.name or {}
										profile.party.widgets.texts.name.outline = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
							},
						},
					},
				},
				auras = {
					type = "group",
					name = "Auras",
					order = 4,
					childGroups = "tree",
					args = {
						buffs = {
							type = "group",
							name = "Buffs",
							order = 1,
							childGroups = "tree",
							args = {
								layout = {
									type = "group",
									name = "Layout",
									inline = true,
									order = 1,
									disabled = function()
										return addon.Database:GetProfile().party.widgets.icons.buffs.enabled ~= true
									end,
									args = {
										offsetX = {
											type = "range",
											name = "Offset X",
											order = 1,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.offsetX
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.offsetX = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										offsetY = {
											type = "range",
											name = "Offset Y",
											order = 2,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.offsetY
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.offsetY = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										iconSize = {
											type = "range",
											name = "Icon Size",
											order = 3,
											min = 8,
											max = 64,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.iconSize
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.iconSize = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										spacing = {
											type = "range",
											name = "Spacing",
											order = 4,
											min = -10,
											max = 20,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.spacing
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.spacing = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										maxIcons = {
											type = "range",
											name = "Max Icons",
											order = 5,
											min = 1,
											max = 10,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.maxIcons
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.maxIcons = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										iconsPerRow = {
											type = "range",
											name = "Icons Per Row",
											order = 6,
											min = 1,
											max = 10,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.iconsPerRow
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.iconsPerRow = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										borderSizePx = {
											type = "range",
											name = "Border Size (px)",
											order = 7,
											min = 1,
											max = 4,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.borderSizePx
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.borderSizePx = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
									},
								},
								stacks = {
									type = "group",
									name = "Stacks",
									inline = true,
									order = 2,
									disabled = function()
										return addon.Database:GetProfile().party.widgets.icons.buffs.enabled ~= true
									end,
									args = {
										showStacks = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.showStacks
													~= false
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.showStacks = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										stacksFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												local buffs = addon.Database:GetProfile().party.widgets.icons.buffs
												return buffs.enabled ~= true or buffs.showStacks == false
											end,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.stacksFontSize
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.stacksFontSize = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
									},
								},
								duration = {
									type = "group",
									name = "Duration",
									inline = true,
									order = 3,
									disabled = function()
										return addon.Database:GetProfile().party.widgets.icons.buffs.enabled ~= true
									end,
									args = {
										showCooldown = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.showCooldown
													== true
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.showCooldown = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										cooldownFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												local buffs = addon.Database:GetProfile().party.widgets.icons.buffs
												return buffs.enabled ~= true or buffs.showCooldown ~= true
											end,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.cooldownFontSize
													or 10
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.cooldownFontSize =
													v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
									},
								},
								general = {
									type = "group",
									name = "General",
									inline = true,
									order = 0,
									args = {
										enabled = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											width = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.enabled
													== true
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.enabled = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
												addon.UpdateScheduler:Notify("aurasStateChanged")
											end,
										},
										useCustomBuffFilter = {
											type = "toggle",
											name = "Custom Filter",
											order = 2,
											width = 1,
											disabled = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.enabled
													~= true
											end,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.buffs.useCustomBuffFilter
													== true
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.buffs.useCustomBuffFilter =
													v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
												addon.UpdateScheduler:Notify("aurasStateChanged")
											end,
										},
										openCustomBuffs = {
											type = "execute",
											name = "Custom Filter",
											order = 3,
											width = 1,
											disabled = function()
												local buffs = addon.Database:GetProfile().party.widgets.icons.buffs
												return buffs.enabled ~= true or buffs.useCustomBuffFilter ~= true
											end,
											func = function()
												AceConfigDialog:SelectGroup(
													APP_NAME,
													"party",
													"auras",
													"buffs",
													"customBuffs"
												)
											end,
										},
									},
								},
								customBuffs = {
									type = "group",
									name = "Custom Filter",
									order = 100,
									disabled = function()
										local buffs = addon.Database:GetProfile().party.widgets.icons.buffs
										return buffs.enabled ~= true or buffs.useCustomBuffFilter ~= true
									end,
									args = {},
								},
							},
						},
						buffOverlays = {
							type = "group",
							name = "Buff Overlays",
							order = 2,
							args = {},
						},
						debuffs = {
							type = "group",
							name = "Debuffs",
							order = 2,
							args = {
								layout = {
									type = "group",
									name = "Layout",
									inline = true,
									order = 1,
									disabled = function()
										return addon.Database:GetProfile().party.widgets.icons.buffs.enabled ~= true
									end,
									args = {
										offsetX = {
											type = "range",
											name = "Offset X",
											order = 1,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.offsetX
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.debuffs.offsetX = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										offsetY = {
											type = "range",
											name = "Offset Y",
											order = 2,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.offsetY
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.debuffs.offsetY = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										iconSize = {
											type = "range",
											name = "Icon Size",
											order = 3,
											min = 8,
											max = 64,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.iconSize
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.debuffs.iconSize = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										spacing = {
											type = "range",
											name = "Spacing",
											order = 4,
											min = -10,
											max = 20,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.spacing
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.debuffs.spacing = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										maxIcons = {
											type = "range",
											name = "Max Icons",
											order = 5,
											min = 1,
											max = 10,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.maxIcons
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.debuffs.maxIcons = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										iconsPerRow = {
											type = "range",
											name = "Icons Per Row",
											order = 6,
											min = 1,
											max = 10,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.iconsPerRow
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.debuffs.iconsPerRow = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										borderSizePx = {
											type = "range",
											name = "Border Size (px)",
											order = 7,
											min = 1,
											max = 4,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.borderSizePx
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.debuffs.borderSizePx = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
									},
								},
								stacks = {
									type = "group",
									name = "Stacks",
									inline = true,
									order = 2,
									disabled = function()
										return addon.Database:GetProfile().party.widgets.icons.buffs.enabled == false
									end,
									args = {
										showStacks = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.showStacks
													~= false
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.debuffs.showStacks = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										stacksFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.showStacks
													== false
											end,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.stacksFontSize
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.debuffs.stacksFontSize =
													v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
									},
								},
								duration = {
									type = "group",
									name = "Duration",
									inline = true,
									order = 3,
									disabled = function()
										return addon.Database:GetProfile().party.widgets.icons.buffs.enabled == false
									end,
									args = {
										showCooldown = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.showCooldown
													== true
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.debuffs.showCooldown = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										cooldownFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.showCooldown
													~= true
											end,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.debuffs.cooldownFontSize
													or 10
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.debuffs.cooldownFontSize =
													v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
									},
								},
							},
						},
						bigDefensive = {
							type = "group",
							name = "Big Defensive",
							order = 3,
							args = {
								layout = {
									type = "group",
									name = "Layout",
									inline = true,
									order = 1,
									disabled = function()
										return addon.Database:GetProfile().party.widgets.icons.buffs.enabled ~= true
									end,
									args = {
										offsetX = {
											type = "range",
											name = "Offset X",
											order = 1,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.bigDefensive.offsetX
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().party.widgets.icons.bigDefensive.offsetX = v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
										offsetY = {
											type = "range",
											name = "Offset Y",
											order = 2,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.bigDefensive.offsetY
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().party.widgets.icons.bigDefensive.offsetY = v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
										iconSize = {
											type = "range",
											name = "Icon Size",
											order = 3,
											min = 8,
											max = 128,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.bigDefensive.iconSize
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().party.widgets.icons.bigDefensive.iconSize =
													v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
										borderSizePx = {
											type = "range",
											name = "Border Size",
											order = 4,
											min = 0,
											max = 6,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.bigDefensive.borderSizePx
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().party.widgets.icons.bigDefensive.borderSizePx =
													v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
									},
								},
								stacks = {
									type = "group",
									name = "Stacks",
									inline = true,
									order = 2,
									disabled = function()
										return addon.Database:GetProfile().party.widgets.icons.buffs.enabled ~= true
									end,
									args = {
										showStacks = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.bigDefensive.showStacks
													~= false
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().party.widgets.icons.bigDefensive.showStacks =
													v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
										stacksFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												return addon.Database:GetProfile().party.widgets.icons.bigDefensive.showStacks
													== false
											end,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.bigDefensive.stacksFontSize
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().party.widgets.icons.bigDefensive.stacksFontSize =
													v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
									},
								},
								duration = {
									type = "group",
									name = "Duration",
									inline = true,
									order = 3,
									args = {
										showCooldown = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.bigDefensive.showCooldown
													== true
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().party.widgets.icons.bigDefensive.showCooldown =
													v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
										cooldownFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												return addon.Database:GetProfile().party.widgets.icons.bigDefensive.showCooldown
													~= true
											end,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.bigDefensive.cooldownFontSize
													or 10
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().party.widgets.icons.bigDefensive.cooldownFontSize =
													v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
									},
								},
							},
						},
						privateAuras = {
							type = "group",
							name = "Private Auras",
							order = 4,
							args = {
								layout = {
									type = "group",
									name = "Layout",
									inline = true,
									order = 1,
									disabled = function()
										return addon.Database:GetProfile().party.widgets.icons.buffs.enabled ~= true
									end,
									args = {
										offsetX = {
											type = "range",
											name = "Offset X",
											order = 1,
											min = -200,
											max = 200,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.privateAuras.offsetX
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.privateAuras.offsetX = v
												addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
											end,
										},
										offsetY = {
											type = "range",
											name = "Offset Y",
											order = 2,
											min = -200,
											max = 200,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.privateAuras.offsetY
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.privateAuras.offsetY = v
												addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
											end,
										},
										iconSize = {
											type = "range",
											name = "Icon Size",
											order = 3,
											min = 8,
											max = 64,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.privateAuras.iconSize
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.privateAuras.iconSize =
													v
												addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
											end,
										},
										spacing = {
											type = "range",
											name = "Spacing",
											order = 4,
											min = 0,
											max = 20,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.privateAuras.spacing
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.privateAuras.spacing = v
												addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
											end,
										},
										maxIcons = {
											type = "range",
											name = "Max Icons",
											order = 5,
											min = 1,
											max = 10,
											step = 1,
											get = function()
												return addon.Database:GetProfile().party.widgets.icons.privateAuras.maxIcons
											end,
											set = function(_, v)
												addon.Database:GetProfile().party.widgets.icons.privateAuras.maxIcons =
													v
												addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
											end,
										},
									},
								},
							},
						},
					},
				},
				indicators = {
					type = "group",
					name = "Indicators",
					order = 6,
					childGroups = "tree",
					args = {
						dispels = {
							type = "group",
							name = "Dispels",
							order = 1,
							args = {
								anchors = {
									type = "group",
									name = "Anchors",
									inline = true,
									order = 1,
									args = {
										anchor = {
											type = "select",
											name = "Anchor",
											order = 1,
											values = {
												TOPLEFT = "Top Left",
												TOP = "Top",
												TOPRIGHT = "Top Right",
												LEFT = "Left",
												CENTER = "Center",
												RIGHT = "Right",
												BOTTOMLEFT = "Bottom Left",
												BOTTOM = "Bottom",
												BOTTOMRIGHT = "Bottom Right",
											},
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).dispels or {}
												).anchor or "TOPRIGHT"
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.dispels = p.party.widgets.indicators.dispels
													or {}
												p.party.widgets.indicators.dispels.anchor = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
										relativeAnchor = {
											type = "select",
											name = "To Frame's",
											order = 2,
											values = {
												TOPLEFT = "Top Left",
												TOP = "Top",
												TOPRIGHT = "Top Right",
												LEFT = "Left",
												CENTER = "Center",
												RIGHT = "Right",
												BOTTOMLEFT = "Bottom Left",
												BOTTOM = "Bottom",
												BOTTOMRIGHT = "Bottom Right",
											},
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).dispels or {}
												).relativeAnchor or "TOPRIGHT"
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.dispels = p.party.widgets.indicators.dispels
													or {}
												p.party.widgets.indicators.dispels.relativeAnchor = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
									},
								},
								layout = {
									type = "group",
									name = "Layout",
									inline = true,
									order = 2,
									args = {
										growDirection = {
											type = "select",
											name = "Grow Direction",
											order = 1,
											values = {
												LEFT = "Left",
												RIGHT = "Right",
											},
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).dispels or {}
												).growDirection or "LEFT"
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.dispels = p.party.widgets.indicators.dispels
													or {}
												p.party.widgets.indicators.dispels.growDirection = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
										dispelSpacing = {
											type = "range",
											name = "Spacing",
											order = 2,
											min = 0,
											max = 12,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).dispels or {}
												).spacing or 1
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party = p.party or {}
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.dispels = p.party.widgets.indicators.dispels
													or {}
												p.party.widgets.indicators.dispels.spacing = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
									},
								},
								position = {
									type = "group",
									name = "Position",
									inline = true,
									order = 3,
									args = {
										dispelOffsetX = {
											type = "range",
											name = "Offset X",
											order = 3,
											min = -100,
											max = 100,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).dispels or {}
												).offsetX or -1
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party = p.party or {}
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.dispels = p.party.widgets.indicators.dispels
													or {}
												p.party.widgets.indicators.dispels.offsetX = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
										dispelOffsetY = {
											type = "range",
											name = "Offset Y",
											order = 4,
											min = -100,
											max = 100,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).dispels or {}
												).offsetY or -1
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party = p.party or {}
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.dispels = p.party.widgets.indicators.dispels
													or {}
												p.party.widgets.indicators.dispels.offsetY = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
									},
								},
								indicator = {
									type = "group",
									name = "Indicator",
									inline = true,
									order = 4,
									args = {
										dispelIconSize = {
											type = "range",
											name = "Icon Size",
											order = 6,
											min = 6,
											max = 32,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).dispels or {}
												).iconSize or 14
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party = p.party or {}
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.dispels = p.party.widgets.indicators.dispels
													or {}
												p.party.widgets.indicators.dispels.iconSize = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
									},
								},
							},
						},
						readyCheck = {
							type = "group",
							name = "Ready Check",
							order = 2,
							args = {
								anchors = {
									type = "group",
									name = "Anchors",
									inline = true,
									order = 1,
									args = {
										anchor = {
											type = "select",
											name = "Anchor",
											order = 1,
											values = {
												TOPLEFT = "Top Left",
												TOP = "Top",
												TOPRIGHT = "Top Right",
												LEFT = "Left",
												CENTER = "Center",
												RIGHT = "Right",
												BOTTOMLEFT = "Bottom Left",
												BOTTOM = "Bottom",
												BOTTOMRIGHT = "Bottom Right",
											},
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).readyCheck or {}
												).anchor or "CENTER"
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.readyCheck = p.party.widgets.indicators.readyCheck
													or {}
												p.party.widgets.indicators.readyCheck.anchor = v
												addon.UpdateScheduler:Notify("readyCheckSettingsChanged")
											end,
										},
										relativeAnchor = {
											type = "select",
											name = "To Frame's",
											order = 2,
											values = {
												TOPLEFT = "Top Left",
												TOP = "Top",
												TOPRIGHT = "Top Right",
												LEFT = "Left",
												CENTER = "Center",
												RIGHT = "Right",
												BOTTOMLEFT = "Bottom Left",
												BOTTOM = "Bottom",
												BOTTOMRIGHT = "Bottom Right",
											},
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).readyCheck or {}
												).relativeAnchor or "CENTER"
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.readyCheck = p.party.widgets.indicators.readyCheck
													or {}
												p.party.widgets.indicators.readyCheck.relativeAnchor = v
												addon.UpdateScheduler:Notify("readyCheckSettingsChanged")
											end,
										},
									},
								},
								position = {
									type = "group",
									name = "Position",
									inline = true,
									order = 2,
									args = {
										offsetX = {
											type = "range",
											name = "Offset X",
											order = 3,
											min = -200,
											max = 200,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).readyCheck or {}
												).offsetX or 0
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.readyCheck = p.party.widgets.indicators.readyCheck
													or {}
												p.party.widgets.indicators.readyCheck.offsetX = v
												addon.UpdateScheduler:Notify("readyCheckSettingsChanged")
											end,
										},
										offsetY = {
											type = "range",
											name = "Offset Y",
											order = 4,
											min = -200,
											max = 200,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).readyCheck or {}
												).offsetY or 0
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.readyCheck = p.party.widgets.indicators.readyCheck
													or {}
												p.party.widgets.indicators.readyCheck.offsetY = v
												addon.UpdateScheduler:Notify("readyCheckSettingsChanged")
											end,
										},
									},
								},
								indicator = {
									type = "group",
									name = "Indicator",
									inline = true,
									order = 3,
									args = {
										size = {
											type = "range",
											name = "Size",
											order = 1,
											min = 8,
											max = 96,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.party or {}).widgets or {}).indicators or {}).readyCheck or {}
												).size or 36
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.party.widgets = p.party.widgets or {}
												p.party.widgets.indicators = p.party.widgets.indicators or {}
												p.party.widgets.indicators.readyCheck = p.party.widgets.indicators.readyCheck
													or {}
												p.party.widgets.indicators.readyCheck.size = v
												addon.UpdateScheduler:Notify("readyCheckSettingsChanged")
											end,
										},
									},
								},
							},
						},
					},
				},
			},
		},
		raid = {
			type = "group",
			name = "Raid",
			order = 3,
			childGroups = "tab",
			disabled = function()
				return InCombatLockdown()
			end,
			args = {
				layout = {
					type = "group",
					name = "Layout",
					order = 1,
					args = {
						raidPosX = {
							type = "range",
							name = "Position X",
							min = -2000,
							max = 2000,
							step = 1,
							order = 3,
							get = function()
								local profile = addon.Database:GetProfile()
								return (profile.raid.position and profile.raid.position.x) or 0
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local profile = addon.Database:GetProfile()
								profile.raid.position = profile.raid.position or { x = 0, y = 0 }
								profile.raid.position.x = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						raidPosY = {
							type = "range",
							name = "Position Y",
							min = -2000,
							max = 2000,
							step = 1,
							order = 4,
							get = function()
								local profile = addon.Database:GetProfile()
								return (profile.raid.position and profile.raid.position.y) or 0
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local profile = addon.Database:GetProfile()
								profile.raid.position = profile.raid.position or { x = 0, y = 0 }
								profile.raid.position.y = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						raidSpacingX = {
							type = "range",
							name = "Spacing X",
							min = -25,
							max = 25,
							step = 1,
							order = 5,
							get = function()
								local profile = addon.Database:GetProfile()
								return (profile.raid.spacing and profile.raid.spacing.x) or 0
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local profile = addon.Database:GetProfile()
								profile.raid.spacing = profile.raid.spacing or { x = 0, y = 0 }
								profile.raid.spacing.x = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						raidSpacingY = {
							type = "range",
							name = "Spacing Y",
							min = -25,
							max = 25,
							step = 1,
							order = 6,
							get = function()
								local profile = addon.Database:GetProfile()
								return (profile.raid.spacing and profile.raid.spacing.y) or 0
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local profile = addon.Database:GetProfile()
								profile.raid.spacing = profile.raid.spacing or { x = 0, y = 0 }
								profile.raid.spacing.y = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						rowSpacer1 = {
							type = "description",
							name = " ",
							order = 6.01,
							width = "full",
						},
						raidGroupDirection = {
							type = "select",
							name = "Group Direction",
							order = 7,
							values = {
								HORIZONTAL = "Horizontal",
								VERTICAL = "Vertical",
							},
							get = function()
								local profile = addon.Database:GetProfile()
								local raid = profile.raid or {}
								return raid.direction or "HORIZONTAL"
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local profile = addon.Database:GetProfile()
								profile.raid = profile.raid or {}
								profile.raid.direction = value

								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						rowSpacer2 = {
							type = "description",
							name = " ",
							order = 7.01,
							width = "full",
						},
						raidGroupReverse = {
							type = "toggle",
							name = "Reverse Group Order",
							order = 8,
							width = "full",
							get = function()
								local profile = addon.Database:GetProfile()
								local raid = profile.raid or {}
								return raid.reverse == true
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local profile = addon.Database:GetProfile()
								profile.raid = profile.raid or {}
								profile.raid.reverse = value

								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						rowSpacer3 = {
							type = "description",
							name = " ",
							order = 8.01,
							width = "full",
						},
						raidGroup1 = {
							type = "toggle",
							name = "Group 1",
							order = 10,
							width = "half",
							get = function()
								local profile = addon.Database:GetProfile()
								local groups = (profile.raid and profile.raid.groups) or {}
								local v = groups[1]
								if v == nil then
									return true
								end
								return v == true
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end
								local profile = addon.Database:GetProfile()
								profile.raid = profile.raid or {}
								profile.raid.groups = profile.raid.groups or {}
								profile.raid.groups[1] = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						raidGroup2 = {
							type = "toggle",
							name = "Group 2",
							order = 11,
							width = "half",
							get = function()
								local groups = (
									addon.Database:GetProfile().raid and addon.Database:GetProfile().raid.groups
								) or {}
								local v = groups[2]
								if v == nil then
									return true
								end
								return v == true
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end
								local p = addon.Database:GetProfile()
								p.raid = p.raid or {}
								p.raid.groups = p.raid.groups or {}
								p.raid.groups[2] = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						raidGroup3 = {
							type = "toggle",
							name = "Group 3",
							order = 12,
							width = "half",
							get = function()
								local groups = (
									addon.Database:GetProfile().raid and addon.Database:GetProfile().raid.groups
								) or {}
								local v = groups[3]
								if v == nil then
									return true
								end
								return v == true
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end
								local p = addon.Database:GetProfile()
								p.raid = p.raid or {}
								p.raid.groups = p.raid.groups or {}
								p.raid.groups[3] = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						raidGroup4 = {
							type = "toggle",
							name = "Group 4",
							order = 13,
							width = "half",
							get = function()
								local groups = (
									addon.Database:GetProfile().raid and addon.Database:GetProfile().raid.groups
								) or {}
								local v = groups[4]
								if v == nil then
									return true
								end
								return v == true
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end
								local p = addon.Database:GetProfile()
								p.raid = p.raid or {}
								p.raid.groups = p.raid.groups or {}
								p.raid.groups[4] = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						raidGroup5 = {
							type = "toggle",
							name = "Group 5",
							order = 14,
							width = "half",
							get = function()
								local groups = (
									addon.Database:GetProfile().raid and addon.Database:GetProfile().raid.groups
								) or {}
								local v = groups[5]
								if v == nil then
									return true
								end
								return v == true
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end
								local p = addon.Database:GetProfile()
								p.raid = p.raid or {}
								p.raid.groups = p.raid.groups or {}
								p.raid.groups[5] = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						raidGroup6 = {
							type = "toggle",
							name = "Group 6",
							order = 15,
							width = "half",
							get = function()
								local groups = (
									addon.Database:GetProfile().raid and addon.Database:GetProfile().raid.groups
								) or {}
								local v = groups[6]
								if v == nil then
									return true
								end
								return v == true
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end
								local p = addon.Database:GetProfile()
								p.raid = p.raid or {}
								p.raid.groups = p.raid.groups or {}
								p.raid.groups[6] = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						raidGroup7 = {
							type = "toggle",
							name = "Group 7",
							order = 16,
							width = "half",
							get = function()
								local groups = (
									addon.Database:GetProfile().raid and addon.Database:GetProfile().raid.groups
								) or {}
								local v = groups[7]
								if v == nil then
									return true
								end
								return v == true
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end
								local p = addon.Database:GetProfile()
								p.raid = p.raid or {}
								p.raid.groups = p.raid.groups or {}
								p.raid.groups[7] = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
						raidGroup8 = {
							type = "toggle",
							name = "Group 8",
							order = 17,
							width = "half",
							get = function()
								local groups = (
									addon.Database:GetProfile().raid and addon.Database:GetProfile().raid.groups
								) or {}
								local v = groups[8]
								if v == nil then
									return true
								end
								return v == true
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end
								local p = addon.Database:GetProfile()
								p.raid = p.raid or {}
								p.raid.groups = p.raid.groups or {}
								p.raid.groups[8] = value
								addon.UpdateScheduler:Notify("layoutChanged")
							end,
						},
					},
				},
				frames = {
					type = "group",
					name = "Frames",
					order = 2,
					childGroups = "tree",
					args = {
						frame = {
							type = "group",
							name = "Frame",
							order = 1,
							args = {
								raidWidth = {
									type = "range",
									name = "Width",
									min = 25,
									max = 300,
									step = 1,
									order = 1,
									get = function()
										local profile = addon.Database:GetProfile()
										return (profile.raid.size and profile.raid.size.width) or 112
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end

										local profile = addon.Database:GetProfile()
										profile.raid.size = profile.raid.size or { width = 112, height = 56 }
										profile.raid.size.width = value
										addon.UpdateScheduler:Notify("layoutChanged")
									end,
								},
								raidHeight = {
									type = "range",
									name = "Height",
									min = 25,
									max = 300,
									step = 1,
									order = 2,
									get = function()
										local profile = addon.Database:GetProfile()
										return (profile.raid.size and profile.raid.size.height) or 56
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end

										local profile = addon.Database:GetProfile()
										profile.raid.size = profile.raid.size or { width = 112, height = 56 }
										profile.raid.size.height = value
										addon.UpdateScheduler:Notify("layoutChanged")
									end,
								},
								raidBorderThickness = {
									type = "range",
									name = "Border Thickness",
									min = 1,
									max = 6,
									step = 1,
									order = 3,
									get = function()
										local profile = addon.Database:GetProfile()
										return ((profile.raid or {}).border or {}).thicknessPx or 1
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.border = profile.raid.border or {}
										profile.raid.border.thicknessPx = value
										addon.UpdateScheduler:Notify("borderSettingsChanged")
									end,
								},
								rowSpacer1 = {
									type = "description",
									name = " ",
									order = 10,
									width = "full",
								},
								raidBackgroundColor = {
									type = "color",
									name = "Background Color",
									hasAlpha = true,
									order = 11,
									get = function()
										local profile = addon.Database:GetProfile()
										local c = ((profile.raid or {}).background or {}).color
											or { r = 0.12, g = 0.12, b = 0.12, a = 1.0 }
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.background = profile.raid.background or {}
										profile.raid.background.color = { r = r, g = g, b = b, a = a }
										addon.UpdateScheduler:Notify("backgroundSettingsChanged")
									end,
								},
								raidBorderColor = {
									type = "color",
									name = "Border Color",
									hasAlpha = true,
									order = 12,
									get = function()
										local profile = addon.Database:GetProfile()
										local c = ((profile.raid or {}).border or {}).color
											or { r = 0, g = 0, b = 0, a = 1 }
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.border = profile.raid.border or {}
										profile.raid.border.color = { r = r, g = g, b = b, a = a }
										addon.UpdateScheduler:Notify("borderSettingsChanged")
									end,
								},
							},
						},
						health = {
							type = "group",
							name = "Health",
							order = 2,
							args = {
								raidHealthUseClassColor = {
									type = "toggle",
									name = "Use Class Color",
									order = 11,
									get = function()
										local profile = addon.Database:GetProfile()
										return ((profile.raid or {}).health or {}).classColor == true
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.health = profile.raid.health or {}
										profile.raid.health.classColor = value
										addon.UpdateScheduler:Notify("healthSettingsChanged")
									end,
								},
								raidHealthColor = {
									type = "color",
									name = "Health Color",
									hasAlpha = true,
									order = 12,
									get = function()
										local profile = addon.Database:GetProfile()
										local c = ((profile.raid or {}).health or {}).color
											or { r = 0.12, g = 0.12, b = 0.12, a = 1.0 }
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end

										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.health = profile.raid.health or {}
										profile.raid.health.color = { r = r, g = g, b = b, a = a }

										addon.UpdateScheduler:Notify("healthSettingsChanged")
									end,
								},
							},
						},
						powerBar = {
							type = "group",
							name = "Power",
							order = 3,
							args = {
								enabled = {
									type = "toggle",
									name = "Enabled",
									order = 1,
									width = 1.0,
									get = function()
										local p = addon.Database:GetProfile()
										return ((p.raid or {}).power or {}).enabled == true
									end,
									set = function(_, v)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.raid = p.raid or {}
										p.raid.power = p.raid.power or {}
										p.raid.power.enabled = v
										addon.UpdateScheduler:Notify("powerSettingsChanged")
									end,
								},
								healerOnly = {
									type = "toggle",
									name = "Healers Only",
									order = 2,
									width = 1.0,
									disabled = function()
										local p = addon.Database:GetProfile()
										return ((p.raid or {}).power or {}).enabled ~= true
									end,
									get = function()
										local p = addon.Database:GetProfile()
										return ((p.raid or {}).power or {}).healerOnly == true
									end,
									set = function(_, v)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.raid = p.raid or {}
										p.raid.power = p.raid.power or {}
										p.raid.power.healerOnly = v
										addon.UpdateScheduler:Notify("powerSettingsChanged")
									end,
								},
								height = {
									type = "range",
									name = "Height",
									order = 3,
									width = 1.0,
									min = 1,
									max = 20,
									step = 1,
									disabled = function()
										local p = addon.Database:GetProfile()
										return ((p.raid or {}).power or {}).enabled ~= true
									end,
									get = function()
										local p = addon.Database:GetProfile()
										return ((p.raid or {}).power or {}).height or 4
									end,
									set = function(_, v)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.raid = p.raid or {}
										p.raid.power = p.raid.power or {}
										p.raid.power.height = v
										addon.UpdateScheduler:Notify("powerSettingsChanged")
									end,
								},
								borderEnabled = {
									type = "toggle",
									name = "Border",
									order = 4,
									width = 2.0,
									disabled = function()
										local p = addon.Database:GetProfile()
										return ((p.raid or {}).power or {}).enabled ~= true
									end,
									get = function()
										local p = addon.Database:GetProfile()
										return ((p.raid or {}).power or {}).borderEnabled ~= false
									end,
									set = function(_, v)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.raid = p.raid or {}
										p.raid.power = p.raid.power or {}
										p.raid.power.borderEnabled = v
										addon.UpdateScheduler:Notify("powerSettingsChanged")
									end,
								},
								borderThickness = {
									type = "range",
									name = "Border Thickness",
									order = 5,
									width = 1.0,
									min = 1,
									max = 6,
									step = 1,
									disabled = function()
										local p = addon.Database:GetProfile()
										local power = ((p.raid or {}).power or {})
										return (power.enabled ~= true) or (power.borderEnabled == false)
									end,
									get = function()
										local p = addon.Database:GetProfile()
										return ((p.raid or {}).power or {}).borderThicknessPx or 1
									end,
									set = function(_, v)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.raid = p.raid or {}
										p.raid.power = p.raid.power or {}
										p.raid.power.borderThicknessPx = v
										addon.UpdateScheduler:Notify("powerSettingsChanged")
									end,
								},
							},
						},
						absorbs = {
							type = "group",
							name = "Absorbs",
							order = 4,
							args = {
								raidAbsorbsColor = {
									type = "color",
									name = "Shields Color",
									hasAlpha = true,
									order = 10,
									get = function()
										local p = addon.Database:GetProfile()
										local c = ((((p.raid or {}).widgets or {}).bars or {}).absorbs or {}).color
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.raid = p.raid or {}
										p.raid.widgets = p.raid.widgets or {}
										p.raid.widgets.bars = p.raid.widgets.bars or {}
										p.raid.widgets.bars.absorbs = p.raid.widgets.bars.absorbs or {}
										p.raid.widgets.bars.absorbs.color = { r = r, g = g, b = b, a = a }
										addon.UpdateScheduler:Notify("absorbsSettingsChanged")
									end,
								},
							},
						},
						healAbsorbs = {
							type = "group",
							name = "Heal Absorbs",
							order = 5,
							args = {
								raidHealAbsorbsColor = {
									type = "color",
									name = "Heal Absorb Color",
									hasAlpha = true,
									order = 11,
									get = function()
										local p = addon.Database:GetProfile()
										local c = ((((p.raid or {}).widgets or {}).bars or {}).healAbsorbs or {}).color
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local p = addon.Database:GetProfile()
										p.raid = p.raid or {}
										p.raid.widgets = p.raid.widgets or {}
										p.raid.widgets.bars = p.raid.widgets.bars or {}
										p.raid.widgets.bars.healAbsorbs = p.raid.widgets.bars.healAbsorbs or {}
										p.raid.widgets.bars.healAbsorbs.color = { r = r, g = g, b = b, a = a }
										addon.UpdateScheduler:Notify("healAbsorbsSettingsChanged")
									end,
								},
							},
						},
					},
				},
				texts = {
					type = "group",
					name = "Texts",
					order = 3,
					childGroups = "tree",
					args = {
						name = {
							type = "group",
							name = "Name",
							order = 1,
							args = {
								raidNameAnchor = {
									type = "select",
									name = "Name Anchor",
									order = 1,
									values = {
										TOPLEFT = "Top Left",
										TOP = "Top Center",
										TOPRIGHT = "Top Right",
										LEFT = "Left",
										CENTER = "Center",
										RIGHT = "Right",
										BOTTOMLEFT = "Bottom Left",
										BOTTOM = "Bottom Center",
										BOTTOMRIGHT = "Bottom Right",
									},
									get = function()
										local profile = addon.Database:GetProfile()
										return ((((profile.raid or {}).widgets or {}).texts or {}).name or {}).anchor
											or "TOPLEFT"
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.widgets = profile.raid.widgets or {}
										profile.raid.widgets.texts = profile.raid.widgets.texts or {}
										profile.raid.widgets.texts.name = profile.raid.widgets.texts.name or {}
										profile.raid.widgets.texts.name.anchor = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
								raidNameSize = {
									type = "range",
									name = "Name Size",
									min = 6,
									max = 32,
									step = 1,
									order = 2,
									get = function()
										local profile = addon.Database:GetProfile()
										return ((((profile.raid or {}).widgets or {}).texts or {}).name or {}).size
											or 11
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.widgets = profile.raid.widgets or {}
										profile.raid.widgets.texts = profile.raid.widgets.texts or {}
										profile.raid.widgets.texts.name = profile.raid.widgets.texts.name or {}
										profile.raid.widgets.texts.name.size = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
								rowSpacer1 = {
									type = "description",
									name = " ",
									order = 10,
									width = "full",
								},
								raidNameOffsetX = {
									type = "range",
									name = "Name Offset X",
									min = -100,
									max = 100,
									step = 1,
									order = 11,
									get = function()
										local profile = addon.Database:GetProfile()
										local pos = ((((profile.raid or {}).widgets or {}).texts or {}).name or {}).position
											or {}
										return pos.x or 2
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.widgets = profile.raid.widgets or {}
										profile.raid.widgets.texts = profile.raid.widgets.texts or {}
										profile.raid.widgets.texts.name = profile.raid.widgets.texts.name or {}
										profile.raid.widgets.texts.name.position = profile.raid.widgets.texts.name.position
											or {}
										profile.raid.widgets.texts.name.position.x = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
								raidNameOffsetY = {
									type = "range",
									name = "Name Offset Y",
									min = -100,
									max = 100,
									step = 1,
									order = 12,
									get = function()
										local profile = addon.Database:GetProfile()
										local pos = ((((profile.raid or {}).widgets or {}).texts or {}).name or {}).position
											or {}
										return pos.y or -2
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.widgets = profile.raid.widgets or {}
										profile.raid.widgets.texts = profile.raid.widgets.texts or {}
										profile.raid.widgets.texts.name = profile.raid.widgets.texts.name or {}
										profile.raid.widgets.texts.name.position = profile.raid.widgets.texts.name.position
											or {}
										profile.raid.widgets.texts.name.position.y = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
								rowSpacer2 = {
									type = "description",
									name = " ",
									order = 20,
									width = "full",
								},
								raidNameClassColor = {
									type = "toggle",
									name = "Name Class Color",
									order = 21,
									get = function()
										local profile = addon.Database:GetProfile()
										return ((((profile.raid or {}).widgets or {}).texts or {}).name or {}).classColor
											== true
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.widgets = profile.raid.widgets or {}
										profile.raid.widgets.texts = profile.raid.widgets.texts or {}
										profile.raid.widgets.texts.name = profile.raid.widgets.texts.name or {}
										profile.raid.widgets.texts.name.classColor = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
								raidNameColor = {
									type = "color",
									name = "Name Color",
									hasAlpha = true,
									order = 22,
									disabled = function()
										local profile = addon.Database:GetProfile()
										return ((((profile.raid or {}).widgets or {}).texts or {}).name or {}).classColor
											== true
									end,
									get = function()
										local profile = addon.Database:GetProfile()
										local c = ((((profile.raid or {}).widgets or {}).texts or {}).name or {}).color
											or { r = 0, g = 0, b = 0, a = 1 }
										return c.r, c.g, c.b, c.a
									end,
									set = function(_, r, g, b, a)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.widgets = profile.raid.widgets or {}
										profile.raid.widgets.texts = profile.raid.widgets.texts or {}
										profile.raid.widgets.texts.name = profile.raid.widgets.texts.name or {}
										profile.raid.widgets.texts.name.color = { r = r, g = g, b = b, a = a }
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
								rowSpacer3 = {
									type = "description",
									name = " ",
									order = 30,
									width = "full",
								},
								raidNameOutline = {
									type = "select",
									name = "Name Outline",
									order = 31,
									values = {
										NONE = "None",
										OUTLINE = "Outline",
										THICKOUTLINE = "Thick Outline",
										MONOCHROME = "Monochrome",
									},
									get = function()
										local profile = addon.Database:GetProfile()
										return ((((profile.raid or {}).widgets or {}).texts or {}).name or {}).outline
											or "NONE"
									end,
									set = function(_, value)
										if InCombatLockdown() then
											ShowCombatLockMessage()
											return
										end
										local profile = addon.Database:GetProfile()
										profile.raid = profile.raid or {}
										profile.raid.widgets = profile.raid.widgets or {}
										profile.raid.widgets.texts = profile.raid.widgets.texts or {}
										profile.raid.widgets.texts.name = profile.raid.widgets.texts.name or {}
										profile.raid.widgets.texts.name.outline = value
										addon.UpdateScheduler:Notify("nameSettingsChanged")
									end,
								},
							},
						},
					},
				},
				auras = {
					type = "group",
					name = "Auras",
					order = 4,
					childGroups = "tree",
					args = {
						buffs = {
							type = "group",
							name = "Buffs",
							order = 1,
							childGroups = "tree",
							args = {
								layout = {
									type = "group",
									name = "Layout",
									inline = true,
									order = 1,
									disabled = function()
										return addon.Database:GetProfile().raid.widgets.icons.buffs.enabled ~= true
									end,
									args = {
										offsetX = {
											type = "range",
											name = "Offset X",
											order = 1,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.offsetX
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.offsetX = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										offsetY = {
											type = "range",
											name = "Offset Y",
											order = 2,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.offsetY
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.offsetY = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										iconSize = {
											type = "range",
											name = "Icon Size",
											order = 3,
											min = 8,
											max = 64,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.iconSize
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.iconSize = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										spacing = {
											type = "range",
											name = "Spacing",
											order = 4,
											min = -10,
											max = 20,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.spacing
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.spacing = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										maxIcons = {
											type = "range",
											name = "Max Icons",
											order = 5,
											min = 1,
											max = 10,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.maxIcons
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.maxIcons = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										iconsPerRow = {
											type = "range",
											name = "Icons Per Row",
											order = 6,
											min = 1,
											max = 10,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.iconsPerRow
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.iconsPerRow = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										borderSizePx = {
											type = "range",
											name = "Border Size (px)",
											order = 7,
											min = 1,
											max = 4,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.borderSizePx
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.borderSizePx = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
									},
								},
								stacks = {
									type = "group",
									name = "Stacks",
									inline = true,
									order = 2,
									disabled = function()
										return addon.Database:GetProfile().raid.widgets.icons.buffs.enabled ~= true
									end,
									args = {
										showStacks = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											disabled = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.enabled
													~= true
											end,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.showStacks
													~= false
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.showStacks = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										stacksFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												local buffs = addon.Database:GetProfile().raid.widgets.icons.buffs
												return buffs.enabled ~= true or buffs.showStacks == false
											end,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.stacksFontSize
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.stacksFontSize = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
									},
								},
								duration = {
									type = "group",
									name = "Duration",
									inline = true,
									order = 3,
									disabled = function()
										return addon.Database:GetProfile().raid.widgets.icons.buffs.enabled ~= true
									end,
									args = {
										showCooldown = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.showCooldown
													== true
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.showCooldown = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
										cooldownFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												local buffs = addon.Database:GetProfile().raid.widgets.icons.buffs
												return buffs.enabled ~= true or buffs.showCooldown ~= true
											end,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.cooldownFontSize
													or 10
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.cooldownFontSize =
													v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
											end,
										},
									},
								},
								general = {
									type = "group",
									name = "General",
									inline = true,
									order = 0,
									args = {
										enabled = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											width = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.enabled
													== true
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.enabled = v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
												addon.UpdateScheduler:Notify("aurasStateChanged")
											end,
										},
										useCustomBuffFilter = {
											type = "toggle",
											name = "Custom Filter",
											order = 2,
											width = 1,
											disabled = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.enabled
													~= true
											end,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.buffs.useCustomBuffFilter
													== true
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.buffs.useCustomBuffFilter =
													v
												addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
												addon.UpdateScheduler:Notify("aurasStateChanged")
											end,
										},
										openCustomBuffs = {
											type = "execute",
											name = "Custom Filter",
											order = 3,
											width = 1,
											disabled = function()
												local buffs = addon.Database:GetProfile().raid.widgets.icons.buffs
												return buffs.enabled ~= true or buffs.useCustomBuffFilter ~= true
											end,
											func = function()
												AceConfigDialog:SelectGroup(
													APP_NAME,
													"raid",
													"auras",
													"buffs",
													"customBuffs"
												)
											end,
										},
									},
								},
								customBuffs = {
									type = "group",
									name = "Custom Filter",
									order = 100,
									disabled = function()
										local buffs = addon.Database:GetProfile().raid.widgets.icons.buffs
										return buffs.enabled ~= true or buffs.useCustomBuffFilter ~= true
									end,
									args = {},
								},
							},
						},
						buffOverlays = {
							type = "group",
							name = "Buff Overlays",
							order = 2,
							disabled = function()
								return addon.Database:GetProfile().raid.widgets.icons.buffs.enabled ~= true
							end,
							args = {},
						},
						debuffs = {
							type = "group",
							name = "Debuffs",
							order = 2,
							args = {
								layout = {
									type = "group",
									name = "Layout",
									inline = true,
									order = 1,
									args = {
										offsetX = {
											type = "range",
											name = "Offset X",
											order = 1,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.offsetX
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.debuffs.offsetX = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										offsetY = {
											type = "range",
											name = "Offset Y",
											order = 2,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.offsetY
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.debuffs.offsetY = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										iconSize = {
											type = "range",
											name = "Icon Size",
											order = 3,
											min = 8,
											max = 64,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.iconSize
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.debuffs.iconSize = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										spacing = {
											type = "range",
											name = "Spacing",
											order = 4,
											min = -10,
											max = 20,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.spacing
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.debuffs.spacing = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										maxIcons = {
											type = "range",
											name = "Max Icons",
											order = 5,
											min = 1,
											max = 10,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.maxIcons
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.debuffs.maxIcons = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										iconsPerRow = {
											type = "range",
											name = "Icons Per Row",
											order = 6,
											min = 1,
											max = 10,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.iconsPerRow
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.debuffs.iconsPerRow = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										borderSizePx = {
											type = "range",
											name = "Border Size (px)",
											order = 7,
											min = 1,
											max = 4,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.borderSizePx
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.debuffs.borderSizePx = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
									},
								},
								stacks = {
									type = "group",
									name = "Stacks",
									inline = true,
									order = 2,
									args = {
										showStacks = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.showStacks
													~= false
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.debuffs.showStacks = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										stacksFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.showStacks
													== false
											end,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.stacksFontSize
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.debuffs.stacksFontSize =
													v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
									},
								},
								duration = {
									type = "group",
									name = "Duration",
									inline = true,
									order = 3,
									args = {
										showCooldown = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.showCooldown
													== true
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.debuffs.showCooldown = v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
										cooldownFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.showCooldown
													~= true
											end,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.debuffs.cooldownFontSize
													or 10
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.debuffs.cooldownFontSize =
													v
												addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
											end,
										},
									},
								},
							},
						},
						bigDefensive = {
							type = "group",
							name = "Big Defensive",
							order = 3,
							args = {
								layout = {
									type = "group",
									name = "Layout",
									inline = true,
									order = 1,
									args = {
										offsetX = {
											type = "range",
											name = "Offset X",
											order = 1,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.bigDefensive.offsetX
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().raid.widgets.icons.bigDefensive.offsetX = v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
										offsetY = {
											type = "range",
											name = "Offset Y",
											order = 2,
											min = -300,
											max = 300,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.bigDefensive.offsetY
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().raid.widgets.icons.bigDefensive.offsetY = v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
										iconSize = {
											type = "range",
											name = "Icon Size",
											order = 3,
											min = 8,
											max = 128,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.bigDefensive.iconSize
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().raid.widgets.icons.bigDefensive.iconSize = v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
										borderSizePx = {
											type = "range",
											name = "Border Size",
											order = 4,
											min = 0,
											max = 6,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.bigDefensive.borderSizePx
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().raid.widgets.icons.bigDefensive.borderSizePx =
													v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
									},
								},
								stacks = {
									type = "group",
									name = "Stacks",
									inline = true,
									order = 2,
									args = {
										showStacks = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.bigDefensive.showStacks
													~= false
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().raid.widgets.icons.bigDefensive.showStacks =
													v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
										stacksFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												return addon.Database:GetProfile().raid.widgets.icons.bigDefensive.showStacks
													== false
											end,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.bigDefensive.stacksFontSize
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().raid.widgets.icons.bigDefensive.stacksFontSize =
													v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
									},
								},
								duration = {
									type = "group",
									name = "Duration",
									inline = true,
									order = 3,
									args = {
										showCooldown = {
											type = "toggle",
											name = "Enabled",
											order = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.bigDefensive.showCooldown
													== true
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().raid.widgets.icons.bigDefensive.showCooldown =
													v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
										cooldownFontSize = {
											type = "range",
											name = "Font Size",
											order = 2,
											min = 6,
											max = 32,
											step = 1,
											disabled = function()
												return addon.Database:GetProfile().raid.widgets.icons.bigDefensive.showCooldown
													~= true
											end,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.bigDefensive.cooldownFontSize
													or 10
											end,
											set = function(_, v)
												if InCombatLockdown() then
													return
												end
												addon.Database:GetProfile().raid.widgets.icons.bigDefensive.cooldownFontSize =
													v
												addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
											end,
										},
									},
								},
							},
						},
						privateAuras = {
							type = "group",
							name = "Private Auras",
							order = 4,
							args = {
								layout = {
									type = "group",
									name = "Layout",
									inline = true,
									order = 1,
									args = {
										offsetX = {
											type = "range",
											name = "Offset X",
											order = 1,
											min = -200,
											max = 200,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.privateAuras.offsetX
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.privateAuras.offsetX = v
												addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
											end,
										},
										offsetY = {
											type = "range",
											name = "Offset Y",
											order = 2,
											min = -200,
											max = 200,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.privateAuras.offsetY
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.privateAuras.offsetY = v
												addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
											end,
										},
										iconSize = {
											type = "range",
											name = "Icon Size",
											order = 3,
											min = 8,
											max = 64,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.privateAuras.iconSize
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.privateAuras.iconSize = v
												addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
											end,
										},
										spacing = {
											type = "range",
											name = "Spacing",
											order = 4,
											min = 0,
											max = 20,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.privateAuras.spacing
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.privateAuras.spacing = v
												addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
											end,
										},
										maxIcons = {
											type = "range",
											name = "Max Icons",
											order = 5,
											min = 1,
											max = 10,
											step = 1,
											get = function()
												return addon.Database:GetProfile().raid.widgets.icons.privateAuras.maxIcons
											end,
											set = function(_, v)
												addon.Database:GetProfile().raid.widgets.icons.privateAuras.maxIcons = v
												addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
											end,
										},
									},
								},
							},
						},
					},
				},
				indicators = {
					type = "group",
					name = "Indicators",
					order = 6,
					childGroups = "tree",
					args = {
						dispels = {
							type = "group",
							name = "Dispels",
							order = 1,
							args = {
								anchors = {
									type = "group",
									name = "Anchors",
									inline = true,
									order = 1,
									args = {
										anchor = {
											type = "select",
											name = "Anchor",
											order = 1,
											values = {
												TOPLEFT = "Top Left",
												TOP = "Top",
												TOPRIGHT = "Top Right",
												LEFT = "Left",
												CENTER = "Center",
												RIGHT = "Right",
												BOTTOMLEFT = "Bottom Left",
												BOTTOM = "Bottom",
												BOTTOMRIGHT = "Bottom Right",
											},
											get = function()
												local p = addon.Database:GetProfile()
												return ((((p.raid or {}).widgets or {}).indicators or {}).dispels or {}).anchor
													or "TOPRIGHT"
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.dispels = p.raid.widgets.indicators.dispels
													or {}
												p.raid.widgets.indicators.dispels.anchor = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
										relativeAnchor = {
											type = "select",
											name = "To Frame's",
											order = 2,
											values = {
												TOPLEFT = "Top Left",
												TOP = "Top",
												TOPRIGHT = "Top Right",
												LEFT = "Left",
												CENTER = "Center",
												RIGHT = "Right",
												BOTTOMLEFT = "Bottom Left",
												BOTTOM = "Bottom",
												BOTTOMRIGHT = "Bottom Right",
											},
											get = function()
												local p = addon.Database:GetProfile()
												return ((((p.raid or {}).widgets or {}).indicators or {}).dispels or {}).relativeAnchor
													or "TOPRIGHT"
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.dispels = p.raid.widgets.indicators.dispels
													or {}
												p.raid.widgets.indicators.dispels.relativeAnchor = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
									},
								},
								layout = {
									type = "group",
									name = "Layout",
									inline = true,
									order = 2,
									args = {
										growDirection = {
											type = "select",
											name = "Grow Direction",
											order = 1,
											values = {
												LEFT = "Left",
												RIGHT = "Right",
											},
											get = function()
												local p = addon.Database:GetProfile()
												return ((((p.raid or {}).widgets or {}).indicators or {}).dispels or {}).growDirection
													or "LEFT"
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.dispels = p.raid.widgets.indicators.dispels
													or {}
												p.raid.widgets.indicators.dispels.growDirection = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
										dispelSpacing = {
											type = "range",
											name = "Spacing",
											order = 2,
											min = 0,
											max = 12,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return ((((p.raid or {}).widgets or {}).indicators or {}).dispels or {}).spacing
													or 1
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid = p.raid or {}
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.dispels = p.raid.widgets.indicators.dispels
													or {}
												p.raid.widgets.indicators.dispels.spacing = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
									},
								},
								position = {
									type = "group",
									name = "Position",
									inline = true,
									order = 3,
									args = {
										dispelOffsetX = {
											type = "range",
											name = "Offset X",
											order = 3,
											min = -100,
											max = 100,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return ((((p.raid or {}).widgets or {}).indicators or {}).dispels or {}).offsetX
													or -1
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid = p.raid or {}
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.dispels = p.raid.widgets.indicators.dispels
													or {}
												p.raid.widgets.indicators.dispels.offsetX = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
										dispelOffsetY = {
											type = "range",
											name = "Offset Y",
											order = 4,
											min = -100,
											max = 100,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return ((((p.raid or {}).widgets or {}).indicators or {}).dispels or {}).offsetY
													or -1
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid = p.raid or {}
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.dispels = p.raid.widgets.indicators.dispels
													or {}
												p.raid.widgets.indicators.dispels.offsetY = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
									},
								},
								indicator = {
									type = "group",
									name = "Indicator",
									inline = true,
									order = 4,
									args = {
										dispelIconSize = {
											type = "range",
											name = "Icon Size",
											order = 6,
											min = 6,
											max = 32,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return ((((p.raid or {}).widgets or {}).indicators or {}).dispels or {}).iconSize
													or 14
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid = p.raid or {}
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.dispels = p.raid.widgets.indicators.dispels
													or {}
												p.raid.widgets.indicators.dispels.iconSize = v
												addon.UpdateScheduler:Notify("dispelsSettingsChanged")
											end,
										},
									},
								},
							},
						},
						readyCheck = {
							type = "group",
							name = "Ready Check",
							order = 2,
							args = {
								anchors = {
									type = "group",
									name = "Anchors",
									inline = true,
									order = 1,
									args = {
										anchor = {
											type = "select",
											name = "Anchor",
											order = 1,
											values = {
												TOPLEFT = "Top Left",
												TOP = "Top",
												TOPRIGHT = "Top Right",
												LEFT = "Left",
												CENTER = "Center",
												RIGHT = "Right",
												BOTTOMLEFT = "Bottom Left",
												BOTTOM = "Bottom",
												BOTTOMRIGHT = "Bottom Right",
											},
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.raid or {}).widgets or {}).indicators or {}).readyCheck or {}
												).anchor or "CENTER"
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.readyCheck = p.raid.widgets.indicators.readyCheck
													or {}
												p.raid.widgets.indicators.readyCheck.anchor = v
												addon.UpdateScheduler:Notify("readyCheckSettingsChanged")
											end,
										},
										relativeAnchor = {
											type = "select",
											name = "To Frame's",
											order = 2,
											values = {
												TOPLEFT = "Top Left",
												TOP = "Top",
												TOPRIGHT = "Top Right",
												LEFT = "Left",
												CENTER = "Center",
												RIGHT = "Right",
												BOTTOMLEFT = "Bottom Left",
												BOTTOM = "Bottom",
												BOTTOMRIGHT = "Bottom Right",
											},
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.raid or {}).widgets or {}).indicators or {}).readyCheck or {}
												).relativeAnchor or "CENTER"
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.readyCheck = p.raid.widgets.indicators.readyCheck
													or {}
												p.raid.widgets.indicators.readyCheck.relativeAnchor = v
												addon.UpdateScheduler:Notify("readyCheckSettingsChanged")
											end,
										},
									},
								},
								position = {
									type = "group",
									name = "Position",
									inline = true,
									order = 2,
									args = {
										offsetX = {
											type = "range",
											name = "Offset X",
											order = 3,
											min = -200,
											max = 200,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.raid or {}).widgets or {}).indicators or {}).readyCheck or {}
												).offsetX or 0
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.readyCheck = p.raid.widgets.indicators.readyCheck
													or {}
												p.raid.widgets.indicators.readyCheck.offsetX = v
												addon.UpdateScheduler:Notify("readyCheckSettingsChanged")
											end,
										},
										offsetY = {
											type = "range",
											name = "Offset Y",
											order = 4,
											min = -200,
											max = 200,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.raid or {}).widgets or {}).indicators or {}).readyCheck or {}
												).offsetY or 0
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.readyCheck = p.raid.widgets.indicators.readyCheck
													or {}
												p.raid.widgets.indicators.readyCheck.offsetY = v
												addon.UpdateScheduler:Notify("readyCheckSettingsChanged")
											end,
										},
									},
								},
								indicator = {
									type = "group",
									name = "Indicator",
									inline = true,
									order = 3,
									args = {
										size = {
											type = "range",
											name = "Size",
											order = 1,
											min = 8,
											max = 96,
											step = 1,
											get = function()
												local p = addon.Database:GetProfile()
												return (
													(((p.raid or {}).widgets or {}).indicators or {}).readyCheck or {}
												).size or 36
											end,
											set = function(_, v)
												if InCombatLockdown() then
													ShowCombatLockMessage()
													return
												end
												local p = addon.Database:GetProfile()
												p.raid.widgets = p.raid.widgets or {}
												p.raid.widgets.indicators = p.raid.widgets.indicators or {}
												p.raid.widgets.indicators.readyCheck = p.raid.widgets.indicators.readyCheck
													or {}
												p.raid.widgets.indicators.readyCheck.size = v
												addon.UpdateScheduler:Notify("readyCheckSettingsChanged")
											end,
										},
									},
								},
							},
						},
					},
				},
			},
		},
		profiles = {
			type = "group",
			name = "Profiles",
			order = 4,
			disabled = function()
				return InCombatLockdown()
			end,
			args = {
				activeGroup = {
					type = "group",
					name = "Select Active Profile",
					inline = true,
					order = 10,
					width = "full",
					args = {
						activeProfile = {
							type = "select",
							name = "Profile",
							order = 1,
							width = 1.2,
							values = function()
								return GetProfileValues(true)
							end,
							get = function()
								return addon.Database:GetCurrentProfileName()
							end,
							set = function(_, value)
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end
								addon.Database:SetProfile(value)
								PrintProfileMsg("Switched profile to '" .. value .. "'.")
							end,
						},
					},
				},

				createGroup = {
					type = "group",
					name = "Create New Profile",
					inline = true,
					order = 20,
					width = "full",
					args = {
						newName = {
							type = "input",
							name = "New Profile Name",
							order = 1,
							width = 1.5,
							get = function()
								return profileUI.newName
							end,
							set = function(_, value)
								profileUI.newName = value or ""
							end,
						},
						createBtn = {
							type = "execute",
							name = "Create & Switch",
							order = 2,
							width = 1.0,
							func = function()
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local name = Trim(profileUI.newName)
								if name == "" then
									PrintProfileMsg("Enter a profile name first.")
									return
								end
								if addon.Database:HasProfile(name) then
									PrintProfileMsg("Profile '" .. name .. "' already exists.")
									return
								end

								addon.Database:SetProfile(name)
								profileUI.newName = ""
								PrintProfileMsg("Created and switched to '" .. name .. "'.")
							end,
						},
					},
				},

				copyGroup = {
					type = "group",
					name = "Copy Profile",
					inline = true,
					order = 30,
					width = "full",
					args = {
						copyFrom = {
							type = "select",
							name = "Copy From",
							order = 1,
							width = 1.0,
							values = function()
								return GetProfileValues(true)
							end,
							get = function()
								return profileUI.copyFrom
							end,
							set = function(_, value)
								profileUI.copyFrom = value
							end,
						},
						copyName = {
							type = "input",
							name = "New Profile Name",
							order = 2,
							width = 1.2,
							get = function()
								return profileUI.copyName
							end,
							set = function(_, value)
								profileUI.copyName = value or ""
							end,
						},
						copyBtn = {
							type = "execute",
							name = "Create Copy",
							order = 3,
							width = 0.8,
							func = function()
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local source = profileUI.copyFrom
								local name = Trim(profileUI.copyName)

								if not source or source == "" then
									PrintProfileMsg("Select a source profile.")
									return
								end
								if name == "" then
									PrintProfileMsg("Enter a new profile name.")
									return
								end
								if addon.Database:HasProfile(name) then
									PrintProfileMsg("Profile '" .. name .. "' already exists.")
									return
								end

								addon.Database:SetProfile(name)
								addon.Database:CopyProfile(source)

								profileUI.copyName = ""
								profileUI.copyFrom = nil
								PrintProfileMsg("Created '" .. name .. "' by copying '" .. source .. "'.")
							end,
						},
					},
				},

				deleteGroup = {
					type = "group",
					name = "Delete Profile",
					inline = true,
					order = 40,
					width = "full",
					args = {
						deleteProfile = {
							type = "select",
							name = "Profile",
							order = 1,
							width = 1.2,
							values = function()
								return GetProfileValues(false) -- excludes Default
							end,
							get = function()
								return profileUI.deleteName
							end,
							set = function(_, value)
								profileUI.deleteName = value
							end,
						},
						deleteBtn = {
							type = "execute",
							name = "Delete",
							order = 2,
							width = 0.8,
							confirm = true,
							confirmText = "Delete selected profile?",
							func = function()
								if InCombatLockdown() then
									ShowCombatLockMessage()
									return
								end

								local target = profileUI.deleteName
								if not target or target == "" then
									PrintProfileMsg("Select a profile to delete.")
									return
								end
								if target == "Default" then
									PrintProfileMsg("Default profile cannot be deleted.")
									return
								end
								if not addon.Database:HasProfile(target) then
									PrintProfileMsg("Profile '" .. target .. "' does not exist.")
									return
								end

								local current = addon.Database:GetCurrentProfileName()
								if current == target then
									addon.Database:SetProfile("Default")
								end

								addon.Database:DeleteProfile(target)
								profileUI.deleteName = nil
								PrintProfileMsg("Deleted profile '" .. target .. "'.")
							end,
						},
					},
				},
			},
		},
	},
}

AddPageHeader(options.args.general.args, 0)
AddPageHeader(options.args.party.args, 0)
AddPageHeader(options.args.raid.args, 0)
AddPageHeader(options.args.profiles.args, 0)

function addon:RegisterOptions()
	options.args.party.args.auras.args.buffs.args.customBuffs.args = GetCustomBuffListOptions("party")
	options.args.party.args.auras.args.buffOverlays.args = GetBuffOverlayOptions("party")

	options.args.raid.args.auras.args.buffs.args.customBuffs.args = GetCustomBuffListOptions("raid")
	options.args.raid.args.auras.args.buffOverlays.args = GetBuffOverlayOptions("raid")

	AceConfig:RegisterOptionsTable(APP_NAME, options)
	AceConfigDialog:SetDefaultSize(APP_NAME, 980, 740)

	if not addon.optionsSlashRegistered then
		SLASH_MRF1 = "/mrf"
		SlashCmdList["MRF"] = function()
			addon:OpenOptions()
		end
		addon.optionsSlashRegistered = true
	end
end
