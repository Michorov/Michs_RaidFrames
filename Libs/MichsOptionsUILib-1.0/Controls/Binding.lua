local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

OptionsUILib.Controls = OptionsUILib.Controls or {}
OptionsUILib.Controls.Binding = OptionsUILib.Controls.Binding or {}

local Binding = OptionsUILib.Controls.Binding

function Binding:Apply(control, panel)
	control.panel = panel

	if type(control.localeConfig) == "table" then
		control.labelKey = control.localeConfig.labelKey
		control.labelArgs = control.localeConfig.labelArgs
		control.textKey = control.localeConfig.textKey
		control.textArgs = control.localeConfig.textArgs
		control.placeholderKey = control.localeConfig.placeholderKey
		control.placeholderArgs = control.localeConfig.placeholderArgs
	end

	function control:SetLabelKey(key, args)
		self.labelKey = key
		self.labelArgs = args
		self:UpdateLocale()
	end

	function control:SetTextKey(key, args)
		self.textKey = key
		self.textArgs = args
		self:UpdateLocale()
	end

	function control:SetPlaceholderKey(key, args)
		self.placeholderKey = key
		self.placeholderArgs = args
		self:UpdateLocale()
	end

	function control:BindValue(binding)
		self.binding = binding
	end

	function control:HandleValueChanged(value)
		if self.onValueChanged then
			self.onValueChanged(self, value)
			return
		end

		if self.binding then
			panel:UpdateValue(function(profile, mode)
				self.binding.set(profile, mode, value)
			end)

			if self.binding.onChange then
				self.binding.onChange(value)
			end
		end
	end

	function control:UpdateState(profile, mode)
		if self.binding then
			self:SetBoundValue(self.binding.get(profile, mode))
		end
	end

	function control:UpdateLocale()
		if self.labelKey then
			local text = panel:Localize(self.labelKey, self.labelArgs)
			if self.SetLabel then
				self:SetLabel(text)
			elseif self.SetText then
				self:SetText(text)
			end
		end

		if self.textKey then
			local text = panel:Localize(self.textKey, self.textArgs)
			if self.SetText then
				self:SetText(text)
			elseif self.SetLabel then
				self:SetLabel(text)
			end
		end

		if self.placeholderKey and self.SetPlaceholder then
			self:SetPlaceholder(panel:Localize(self.placeholderKey, self.placeholderArgs))
		end

		if self.SetOptions and self.options then
			self:SetOptions(self.options)
		end
	end

	control:UpdateLocale()
end
