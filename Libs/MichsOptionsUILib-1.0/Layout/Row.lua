local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

OptionsUILib.Layout = OptionsUILib.Layout or {}
OptionsUILib.Layout.Row = OptionsUILib.Layout.Row or {}

local Row = OptionsUILib.Layout.Row

local Methods = Row.Methods or {}
Row.Methods = Methods

local SlotMethods = Row.SlotMethods or {}
Row.SlotMethods = SlotMethods

local columnPresets = {
	[2] = {
		width = 272,
		gap = 32,
	},
	[3] = {
		width = 176,
		gap = 24,
	},
	[4] = {
		width = 132,
		gap = 16,
	},
	[8] = {
		width = 58,
		gap = 16,
	},
}

function Row:Create(parent, PP, panel, columns)
	local frame = CreateFrame("Frame", nil, parent)
	local row = Mixin({
		frame = frame,
		parent = parent,
		PP = PP,
		panel = panel,
		columns = columns or 1,
		items = {},
		layout = {
			width = 576,
			height = 44,
			point = nil,
			relativeTo = parent,
			relativePoint = nil,
			offsetX = 0,
			offsetY = 0,
		},
	}, Methods)

	frame.row = row

	return row
end

function Methods:CreateCheckboxSlot(position)
	local frame = CreateFrame("Frame", nil, self.frame)
	local slot = Mixin({
		frame = frame,
		row = self,
		position = position or "bottom",
		controls = {},
		layout = {
			width = 0,
			height = self.layout.height,
		},
	}, SlotMethods)

	frame.slot = slot

	self.items[#self.items + 1] = slot
	self:UpdateLayout()

	return slot
end

function Methods:SetLayoutWidth(width)
	self.layout.width = width
	self:UpdateLayout()
end

function Methods:SetLayoutHeight(height)
	self.layout.height = height
	self:UpdateLayout()
end

function Methods:SetLayoutSize(width, height)
	self.layout.width = width
	self.layout.height = height
	self:UpdateLayout()
end

function Methods:SetLayoutPoint(point, relativeTo, relativePoint, offsetX, offsetY)
	self.layout.point = point
	self.layout.relativeTo = relativeTo or self.parent
	self.layout.relativePoint = relativePoint or point
	self.layout.offsetX = offsetX or 0
	self.layout.offsetY = offsetY or 0
	self:UpdateLayout()
end

function Methods:AddControl(control)
	self.items[#self.items + 1] = control
	self:UpdateLayout()

	return control
end

function Methods:CreateControl(controlType, labelText)
	local controlLabel = type(labelText) == "table" and "" or labelText
	local control = OptionsUILib.Controls[controlType]:Create(self.frame, self.PP, controlLabel)
	control.controlType = controlType
	control.localeConfig = labelText
	OptionsUILib.Controls.Binding:Apply(control, self.panel)

	self.items[#self.items + 1] = control
	self:UpdateLayout()

	return control
end

function Methods:UpdateState(profile, mode)
	for _, item in ipairs(self.items) do
		item:UpdateState(profile, mode)
	end
end

function Methods:UpdateLocale()
	for _, item in ipairs(self.items) do
		item:UpdateLocale()
	end
end

function Methods:UpdateLayout()
	local PP = self.PP
	local width = PP:ToUIScaled(self.layout.width)
	local height = PP:ToUIScaled(self.layout.height)

	self.frame:SetSize(width, height)

	if self.layout.point then
		self.frame:ClearAllPoints()
		self.frame:SetPoint(
			self.layout.point,
			self.layout.relativeTo,
			self.layout.relativePoint,
			PP:ToUIScaled(self.layout.offsetX),
			PP:ToUIScaled(self.layout.offsetY)
		)
	end

	local columnPreset = columnPresets[self.columns]
	local columnWidth = columnPreset.width
	local columnGap = columnPreset.gap

	for index, item in ipairs(self.items) do
		local columnIndex = ((index - 1) % self.columns) + 1
		local offsetX = (columnIndex - 1) * (columnWidth + columnGap)

		if item.frame then
			item.layout.width = columnWidth
			item.layout.height = self.layout.height
			item.frame:ClearAllPoints()
			item.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", PP:ToUIScaled(offsetX), 0)
			item:UpdateLayout()
		else
			item:SetLayoutWidth(columnWidth)
			item:SetLayoutPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", offsetX, 0)
		end
	end
end

function SlotMethods:AddControl(control)
	self.controls[#self.controls + 1] = control
	self:UpdateLayout()

	return control
end

function SlotMethods:CreateControl(controlType, labelText)
	local controlLabel = type(labelText) == "table" and "" or labelText
	local control = OptionsUILib.Controls[controlType]:Create(self.frame, self.row.PP, controlLabel)
	control.controlType = controlType
	control.localeConfig = labelText
	OptionsUILib.Controls.Binding:Apply(control, self.row.panel)
	self.controls[#self.controls + 1] = control
	self:UpdateLayout()

	return control
end

function SlotMethods:UpdateState(profile, mode)
	for _, control in ipairs(self.controls) do
		control:UpdateState(profile, mode)
	end
end

function SlotMethods:UpdateLocale()
	for _, control in ipairs(self.controls) do
		control:UpdateLocale()
	end
end

function SlotMethods:UpdateLayout()
	local PP = self.row.PP
	local controlCount = #self.controls

	self.frame:SetSize(PP:ToUIScaled(self.layout.width), PP:ToUIScaled(self.layout.height))

	if controlCount == 1 then
		local control = self.controls[1]
		control:SetLayoutWidth(self.layout.width)
		if self.position == "top" then
			control:SetLayoutHeight(16)
			control:SetLayoutPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -2)
		else
			control:SetLayoutHeight(24)
			control:SetLayoutPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, 0)
		end

		return
	end

	if controlCount == 2 then
		local topControl = self.controls[1]
		local bottomControl = self.controls[2]

		topControl:SetLayoutWidth(self.layout.width)
		topControl:SetLayoutHeight(16)
		topControl:SetLayoutPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -2)

		bottomControl:SetLayoutWidth(self.layout.width)
		bottomControl:SetLayoutHeight(16)
		bottomControl:SetLayoutPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, 0)
		return
	end
end
