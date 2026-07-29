local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

local SubPage = OptionsUILib.SubPage or {}
OptionsUILib.SubPage = SubPage

local Methods = SubPage.Methods or {}
SubPage.Methods = Methods

function SubPage:Create(page, key, config)
	config = config or {}

	local subpage = Mixin({
		page = page,
		key = key,
		titleKey = config.titleKey,
		title = config.title or (config.titleKey and page.panel:Localize(config.titleKey)) or key,
		layoutItems = {},
		controls = {},
	}, Methods)

	if page.body then
		local frame = CreateFrame("Frame", nil, page.body)
		frame.subpage = subpage
		frame:SetAllPoints(page.body)
		frame:Hide()

		subpage.frame = frame
	end

	page.panel:RegisterStateUpdater(subpage, function(profile, mode)
		subpage:UpdateState(profile, mode)
	end)

	return subpage
end

function Methods:UpdateLayout()
	for _, item in ipairs(self.layoutItems) do
		item:UpdateLayout()
	end

	for _, control in ipairs(self.controls) do
		control:UpdateLayout()
	end
end

function Methods:CreateControl(controlType, labelText)
	local controlLabel = type(labelText) == "table" and "" or labelText
	local control = OptionsUILib.Controls[controlType]:Create(self.frame, self.page.panel.instance.PP, controlLabel)
	control.controlType = controlType
	control.localeConfig = labelText
	OptionsUILib.Controls.Binding:Apply(control, self.page.panel)
	self.controls[#self.controls + 1] = control

	return control
end

function Methods:CreateRow(columns)
	local row = OptionsUILib.Layout.Row:Create(self.frame, self.page.panel.instance.PP, self.page.panel, columns)
	self.layoutItems[#self.layoutItems + 1] = row

	return row
end

function Methods:SetTitle(title)
	self.title = title
	self.page:UpdateSubPageDropdown()
end

function Methods:UpdateLocale()
	if self.titleKey then
		self:SetTitle(self.page.panel:Localize(self.titleKey))
	end

	for _, item in ipairs(self.layoutItems) do
		item:UpdateLocale()
	end

	for _, control in ipairs(self.controls) do
		control:UpdateLocale()
	end
end

function Methods:SetStateUpdater(callback)
	self.stateUpdater = callback
end

function Methods:UpdateState(profile, mode)
	for _, item in ipairs(self.layoutItems) do
		item:UpdateState(profile, mode)
	end

	for _, control in ipairs(self.controls) do
		control:UpdateState(profile, mode)
	end

	if self.stateUpdater then
		self.stateUpdater(profile, mode)
	end
end
