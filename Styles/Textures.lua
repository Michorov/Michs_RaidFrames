local _, addon = ...

addon.Styles = addon.Styles or {}
addon.Styles.Textures = addon.Styles.Textures or {}

local Textures = addon.Styles.Textures
local LSM = LibStub("LibSharedMedia-3.0")
local callbacksRegistered = false
local FALLBACK_TEXTURE = "M-SolidDarker"

LSM:Register(
	"statusbar",
	"M-SolidDarker",
	"Interface\\AddOns\\Michs_RaidFrames\\Media\\Textures\\M-SolidDarker"
)

local excludedTextureNames = {
	play_icon = true,
	stop_icon = true,
	user_icon = true,
	users_icon = true,
}

function Textures:GetOptions(selectedTextureName, includeGlobal)
	local options = {}
	local selectedTextureListed = false

	if includeGlobal then
		options[#options + 1] = {
			value = -1,
			textKey = "Use Global",
			textColor = { 0.50, 0.52, 0.56, 1 },
		}
	end

	for _, textureName in ipairs(LSM:List("statusbar")) do
		if not excludedTextureNames[textureName] and LSM:IsValid("statusbar", textureName) then
			options[#options + 1] = {
				value = textureName,
				text = textureName,
				texture = LSM:Fetch("statusbar", textureName),
			}

			if textureName == selectedTextureName then
				selectedTextureListed = true
			end
		end
	end

	if selectedTextureName and selectedTextureName ~= -1 and not selectedTextureListed then
		options[#options + 1] = {
			value = selectedTextureName,
			text = selectedTextureName .. " (Unavailable)",
		}
	end

	return options
end

function Textures:Fetch(textureName)
	if not LSM:IsValid("statusbar", textureName) then
		textureName = FALLBACK_TEXTURE
	end

	return LSM:Fetch("statusbar", textureName)
end

function Textures:RegisterCallbacks()
	if callbacksRegistered then
		return
	end

	LSM.RegisterCallback(self, "LibSharedMedia_Registered", function(_, mediaType, textureName)
		if mediaType ~= "statusbar" then
			return
		end

		if addon.Options and addon.Options.RefreshState then
			addon.Options:RefreshState()
		end

		local profile = addon.Database:GetProfile()
		local coreTexture = profile and profile.core and profile.core.lsmTexture
		local partyHealthTexture = profile and profile.party and profile.party.health and profile.party.health.lsmTexture
		local raidHealthTexture = profile and profile.raid and profile.raid.health and profile.raid.health.lsmTexture
		local partyPowerTexture = profile and profile.party and profile.party.power and profile.party.power.lsmTexture
		local raidPowerTexture = profile and profile.raid and profile.raid.power and profile.raid.power.lsmTexture

		if
			partyHealthTexture == textureName
			or raidHealthTexture == textureName
			or (coreTexture == textureName and (partyHealthTexture == -1 or raidHealthTexture == -1))
		then
			addon.UpdateScheduler:Notify("healthSettingsChanged")
		end

		if
			partyPowerTexture == textureName
			or raidPowerTexture == textureName
			or (coreTexture == textureName and (partyPowerTexture == -1 or raidPowerTexture == -1))
		then
			addon.UpdateScheduler:Notify("powerSettingsChanged")
		end
	end)

	callbacksRegistered = true
end
