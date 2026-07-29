local MAJOR, MINOR = "MichsOptionsUILib-1.0", 1

assert(LibStub, MAJOR .. " requires LibStub")

local OptionsUILib = LibStub:NewLibrary(MAJOR, MINOR)
if not OptionsUILib then
	return
end

OptionsUILib.major = MAJOR
OptionsUILib.minor = MINOR
OptionsUILib.Instance = OptionsUILib.Instance or {}
OptionsUILib.Panel = OptionsUILib.Panel or {}
OptionsUILib.PanelSections = OptionsUILib.PanelSections or {}
OptionsUILib.Page = OptionsUILib.Page or {}
OptionsUILib.SubPage = OptionsUILib.SubPage or {}
OptionsUILib.Controls = OptionsUILib.Controls or {}
OptionsUILib.Theme = OptionsUILib.Theme or {}

function OptionsUILib:GetVersion()
	return self.major, self.minor
end
