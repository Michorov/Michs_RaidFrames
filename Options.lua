local _, addon = ...

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local APP_NAME = "Michs_RaidFrames"

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
						addon.UpdateScheduler:Notify("layoutChanged")
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
					order = 2,
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
					order = 3,
					args = {
						partyWidth = {
							type = "range",
							name = "Width",
							min = 50,
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
							min = 50,
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
						rowSpacer1 = {
							type = "description",
							name = " ",
							order = 10,
							width = "full",
						},
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
						rowSpacer2 = {
							type = "description",
							name = " ",
							order = 20,
							width = "full",
						},
						partyBorderThickness = {
							type = "range",
							name = "Border Thickness",
							min = 1,
							max = 6,
							step = 1,
							order = 21,
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
						partyBorderColor = {
							type = "color",
							name = "Border Color",
							hasAlpha = true,
							order = 22,
							get = function()
								local profile = addon.Database:GetProfile()
								local c = ((profile.party or {}).border or {}).color or { r = 0, g = 0, b = 0, a = 1 }
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
						rowSpacer3 = {
							type = "description",
							name = " ",
							order = 30,
							width = "full",
						},
						partyBackgroundColor = {
							type = "color",
							name = "Background Color",
							hasAlpha = true,
							order = 31,
							width = "full",
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
					},
				},
				texts = {
					type = "group",
					name = "Texts",
					order = 4,
					childGroups = "tab",
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
				icons = {
					type = "group",
					name = "Icons",
					order = 5,
					childGroups = "tab",
					args = {
						buffs = {
							type = "group",
							name = "Buffs",
							order = 1,
							args = {
								offsetX = {
									type = "range",
									name = "Offset X",
									order = 3,
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
									order = 4,
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
									order = 5,
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
									order = 6,
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
									order = 7,
									min = 1,
									max = 20,
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
									order = 8,
									min = 1,
									max = 20,
									step = 1,
									get = function()
										return addon.Database:GetProfile().party.widgets.icons.buffs.iconsPerRow
									end,
									set = function(_, v)
										addon.Database:GetProfile().party.widgets.icons.buffs.iconsPerRow = v
										addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
									end,
								},
								stacksFontSize = {
									type = "range",
									name = "Stacks Font Size",
									order = 9,
									min = 6,
									max = 32,
									step = 1,
									get = function()
										return addon.Database:GetProfile().party.widgets.icons.buffs.stacksFontSize
									end,
									set = function(_, v)
										addon.Database:GetProfile().party.widgets.icons.buffs.stacksFontSize = v
										addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
									end,
								},
								borderSizePx = {
									type = "range",
									name = "Border Size (px)",
									order = 10,
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
						debuffs = {
							type = "group",
							name = "Debuffs",
							order = 2,
							args = {
								offsetX = {
									type = "range",
									name = "Offset X",
									order = 3,
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
									order = 4,
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
									order = 5,
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
									order = 6,
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
									order = 7,
									min = 1,
									max = 20,
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
									order = 8,
									min = 1,
									max = 20,
									step = 1,
									get = function()
										return addon.Database:GetProfile().party.widgets.icons.debuffs.iconsPerRow
									end,
									set = function(_, v)
										addon.Database:GetProfile().party.widgets.icons.debuffs.iconsPerRow = v
										addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
									end,
								},
								stacksFontSize = {
									type = "range",
									name = "Stacks Font Size",
									order = 9,
									min = 6,
									max = 32,
									step = 1,
									get = function()
										return addon.Database:GetProfile().party.widgets.icons.debuffs.stacksFontSize
									end,
									set = function(_, v)
										addon.Database:GetProfile().party.widgets.icons.debuffs.stacksFontSize = v
										addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
									end,
								},
								borderSizePx = {
									type = "range",
									name = "Border Size (px)",
									order = 10,
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
						bigDefensive = {
							type = "group",
							name = "Big Defensive",
							order = 3,
							args = {
								iconSize = {
									type = "range",
									name = "Icon Size",
									order = 2,
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
										addon.Database:GetProfile().party.widgets.icons.bigDefensive.iconSize = v
										addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
									end,
								},
								borderSizePx = {
									type = "range",
									name = "Border Size",
									order = 3,
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
										addon.Database:GetProfile().party.widgets.icons.bigDefensive.borderSizePx = v
										addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
									end,
								},
								stacksFontSize = {
									type = "range",
									name = "Stacks Font Size",
									order = 4,
									min = 6,
									max = 32,
									step = 1,
									get = function()
										return addon.Database:GetProfile().party.widgets.icons.bigDefensive.stacksFontSize
									end,
									set = function(_, v)
										if InCombatLockdown() then
											return
										end
										addon.Database:GetProfile().party.widgets.icons.bigDefensive.stacksFontSize = v
										addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
									end,
								},

								offsetX = {
									type = "range",
									name = "Offset X",
									order = 7,
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
									order = 8,
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
							},
						},
						privateAuras = {
							type = "group",
							name = "Private Auras",
							order = 4,
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
										addon.Database:GetProfile().party.widgets.icons.privateAuras.maxIcons = v
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
										addon.Database:GetProfile().party.widgets.icons.privateAuras.iconSize = v
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
							},
						},
					},
				},
				indicators = {
					type = "group",
					name = "Indicators",
					order = 6,
					childGroups = "tab",
					args = {
						dispels = {
							type = "group",
							name = "Dispels",
							order = 1,
							args = {
								dispelOffsetX = {
									type = "range",
									name = "Offset X",
									order = 1,
									min = -100,
									max = 100,
									step = 1,
									get = function()
										local p = addon.Database:GetProfile()
										return ((((p.party or {}).widgets or {}).indicators or {}).dispels or {}).offsetX
											or -1
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
										p.party.widgets.indicators.dispels = p.party.widgets.indicators.dispels or {}
										p.party.widgets.indicators.dispels.offsetX = v
										addon.UpdateScheduler:Notify("dispelsSettingsChanged")
									end,
								},

								dispelOffsetY = {
									type = "range",
									name = "Offset Y",
									order = 2,
									min = -100,
									max = 100,
									step = 1,
									get = function()
										local p = addon.Database:GetProfile()
										return ((((p.party or {}).widgets or {}).indicators or {}).dispels or {}).offsetY
											or -1
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
										p.party.widgets.indicators.dispels = p.party.widgets.indicators.dispels or {}
										p.party.widgets.indicators.dispels.offsetY = v
										addon.UpdateScheduler:Notify("dispelsSettingsChanged")
									end,
								},

								dispelIconSize = {
									type = "range",
									name = "Icon Size (px)",
									order = 3,
									min = 6,
									max = 32,
									step = 1,
									get = function()
										local p = addon.Database:GetProfile()
										return ((((p.party or {}).widgets or {}).indicators or {}).dispels or {}).iconSize
											or 14
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
										p.party.widgets.indicators.dispels = p.party.widgets.indicators.dispels or {}
										p.party.widgets.indicators.dispels.iconSize = v
										addon.UpdateScheduler:Notify("dispelsSettingsChanged")
									end,
								},

								dispelSpacing = {
									type = "range",
									name = "Spacing (px)",
									order = 4,
									min = 0,
									max = 12,
									step = 1,
									get = function()
										local p = addon.Database:GetProfile()
										return ((((p.party or {}).widgets or {}).indicators or {}).dispels or {}).spacing
											or 1
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
										p.party.widgets.indicators.dispels = p.party.widgets.indicators.dispels or {}
										p.party.widgets.indicators.dispels.spacing = v
										addon.UpdateScheduler:Notify("dispelsSettingsChanged")
									end,
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
					order = 2,
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

						raidGroupReverse = {
							type = "toggle",
							name = "Reverse Group Order",
							order = 8,
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

						raidGroupFilterHeader = {
							type = "description",
							name = "Enabled Groups",
							order = 9,
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
					order = 3,
					args = {
						raidWidth = {
							type = "range",
							name = "Width",
							min = 50,
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
							min = 50,
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
						rowSpacer1 = {
							type = "description",
							name = " ",
							order = 10,
							width = "full",
						},
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
						rowSpacer2 = {
							type = "description",
							name = " ",
							order = 20,
							width = "full",
						},
						raidBorderThickness = {
							type = "range",
							name = "Border Thickness (px)",
							min = 1,
							max = 6,
							step = 1,
							order = 21,
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
						raidBorderColor = {
							type = "color",
							name = "Border Color",
							hasAlpha = true,
							order = 22,
							get = function()
								local profile = addon.Database:GetProfile()
								local c = ((profile.raid or {}).border or {}).color or { r = 0, g = 0, b = 0, a = 1 }
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
						rowSpacer3 = {
							type = "description",
							name = " ",
							order = 30,
							width = "full",
						},
						raidBackgroundColor = {
							type = "color",
							name = "Background Color",
							hasAlpha = true,
							order = 31,
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
					},
				},
				texts = {
					type = "group",
					name = "Texts",
					order = 4,
					childGroups = "tab",
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
				icons = {
					type = "group",
					name = "Icons",
					order = 5,
					childGroups = "tab",
					args = {
						buffs = {
							type = "group",
							name = "Buffs",
							order = 1,
							args = {
								offsetX = {
									type = "range",
									name = "Offset X",
									order = 3,
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
									order = 4,
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
									order = 5,
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
									order = 6,
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
									order = 7,
									min = 1,
									max = 20,
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
									order = 8,
									min = 1,
									max = 20,
									step = 1,
									get = function()
										return addon.Database:GetProfile().raid.widgets.icons.buffs.iconsPerRow
									end,
									set = function(_, v)
										addon.Database:GetProfile().raid.widgets.icons.buffs.iconsPerRow = v
										addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
									end,
								},
								stacksFontSize = {
									type = "range",
									name = "Stacks Font Size",
									order = 9,
									min = 6,
									max = 32,
									step = 1,
									get = function()
										return addon.Database:GetProfile().raid.widgets.icons.buffs.stacksFontSize
									end,
									set = function(_, v)
										addon.Database:GetProfile().raid.widgets.icons.buffs.stacksFontSize = v
										addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
									end,
								},
								borderSizePx = {
									type = "range",
									name = "Border Size (px)",
									order = 10,
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
						debuffs = {
							type = "group",
							name = "Debuffs",
							order = 2,
							args = {
								offsetX = {
									type = "range",
									name = "Offset X",
									order = 3,
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
									order = 4,
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
									order = 5,
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
									order = 6,
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
									order = 7,
									min = 1,
									max = 20,
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
									order = 8,
									min = 1,
									max = 20,
									step = 1,
									get = function()
										return addon.Database:GetProfile().raid.widgets.icons.debuffs.iconsPerRow
									end,
									set = function(_, v)
										addon.Database:GetProfile().raid.widgets.icons.debuffs.iconsPerRow = v
										addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
									end,
								},
								stacksFontSize = {
									type = "range",
									name = "Stacks Font Size",
									order = 9,
									min = 6,
									max = 32,
									step = 1,
									get = function()
										return addon.Database:GetProfile().raid.widgets.icons.debuffs.stacksFontSize
									end,
									set = function(_, v)
										addon.Database:GetProfile().raid.widgets.icons.debuffs.stacksFontSize = v
										addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
									end,
								},
								borderSizePx = {
									type = "range",
									name = "Border Size (px)",
									order = 10,
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
						bigDefensive = {
							type = "group",
							name = "Big Defensive",
							order = 3,
							args = {
								iconSize = {
									type = "range",
									name = "Icon Size",
									order = 2,
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
									order = 3,
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
										addon.Database:GetProfile().raid.widgets.icons.bigDefensive.borderSizePx = v
										addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
									end,
								},
								stacksFontSize = {
									type = "range",
									name = "Stacks Font Size",
									order = 4,
									min = 6,
									max = 32,
									step = 1,
									get = function()
										return addon.Database:GetProfile().raid.widgets.icons.bigDefensive.stacksFontSize
									end,
									set = function(_, v)
										if InCombatLockdown() then
											return
										end
										addon.Database:GetProfile().raid.widgets.icons.bigDefensive.stacksFontSize = v
										addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
									end,
								},

								offsetX = {
									type = "range",
									name = "Offset X",
									order = 7,
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
									order = 8,
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
							},
						},
						privateAuras = {
							type = "group",
							name = "Private Auras",
							order = 4,
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
							},
						},
					},
				},
				indicators = {
					type = "group",
					name = "Indicators",
					order = 6,
					childGroups = "tab",
					args = {
						dispels = {
							type = "group",
							name = "Dispels",
							order = 1,
							args = {
								dispelOffsetX = {
									type = "range",
									name = "Offset X",
									order = 1,
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
										p.raid.widgets.indicators.dispels = p.raid.widgets.indicators.dispels or {}
										p.raid.widgets.indicators.dispels.offsetX = v
										addon.UpdateScheduler:Notify("dispelsSettingsChanged")
									end,
								},

								dispelOffsetY = {
									type = "range",
									name = "Offset Y",
									order = 2,
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
										p.raid.widgets.indicators.dispels = p.raid.widgets.indicators.dispels or {}
										p.raid.widgets.indicators.dispels.offsetY = v
										addon.UpdateScheduler:Notify("dispelsSettingsChanged")
									end,
								},

								dispelIconSize = {
									type = "range",
									name = "Icon Size (px)",
									order = 3,
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
										p.raid.widgets.indicators.dispels = p.raid.widgets.indicators.dispels or {}
										p.raid.widgets.indicators.dispels.iconSize = v
										addon.UpdateScheduler:Notify("dispelsSettingsChanged")
									end,
								},

								dispelSpacing = {
									type = "range",
									name = "Spacing (px)",
									order = 4,
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
										p.raid.widgets.indicators.dispels = p.raid.widgets.indicators.dispels or {}
										p.raid.widgets.indicators.dispels.spacing = v
										addon.UpdateScheduler:Notify("dispelsSettingsChanged")
									end,
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
