local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

local PixelPerfectLib = LibStub("MichsPixelPerfectLib-1.0")

local Instance = OptionsUILib.Instance
Instance.__index = Instance

function OptionsUILib:CreateInstance(config)
	config = config or {}

	local instance = {
		addonName = config.addonName,
		title = config.title or config.addonName,
		PP = PixelPerfectLib:CreateScaler(),
		globalScale = 1,
		panels = {},
	}

	return setmetatable(instance, Instance)
end

function Instance:GetAddonName()
	return self.addonName
end

function Instance:GetTitle()
	return self.title
end

function Instance:SetGlobalScale(value)
	if type(value) ~= "number" then
		return
	end

	self.globalScale = math.min(2, math.max(0.5, value))
	self.PP:SetGlobalScale(self.globalScale)
end

function Instance:GetGlobalScale()
	return self.globalScale
end
