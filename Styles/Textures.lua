local _, addon = ...

addon.Styles = addon.Styles or {}
addon.Styles.Textures = addon.Styles.Textures or {}

local Textures = addon.Styles.Textures
local LSM = LibStub("LibSharedMedia-3.0")
local callbacksRegistered = false

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
			text = "Use Global",
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
		local partyTexture = profile and profile.party and profile.party.health and profile.party.health.lsmTexture
		local raidTexture = profile and profile.raid and profile.raid.health and profile.raid.health.lsmTexture

		if
			partyTexture == textureName
			or raidTexture == textureName
			or (coreTexture == textureName and (partyTexture == -1 or raidTexture == -1))
		then
			addon.UpdateScheduler:Notify("healthSettingsChanged")
		end
	end)

	callbacksRegistered = true
end
