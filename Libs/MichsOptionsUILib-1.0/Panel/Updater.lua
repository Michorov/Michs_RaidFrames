local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

local Panel = OptionsUILib.Panel

function Panel:UpdateState()
	local profile = self.profileGetter(self)
	local mode = self:GetActiveMode()

	for _, callback in pairs(self.stateUpdaters) do
		callback(profile, mode)
	end
end

function Panel:RegisterStateUpdater(owner, callback)
	self.stateUpdaters[owner] = callback
end

function Panel:SetFooterUpdater(callback)
	self:RegisterStateUpdater(self.frame.footer, function(profile, mode)
		self:SetFooterText(callback(profile, mode))
	end)
end

function Panel:UpdateValue(callback)
	local profile = self.profileGetter(self)
	local mode = self:GetActiveMode()

	callback(profile, mode)
end
