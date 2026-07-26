local _, addon = ...

addon.PixelPerfect = LibStub("MichsPixelPerfectLib-1.0"):CreateScaler()

addon.OptionsUI = LibStub("MichsOptionsUILib-1.0"):CreateInstance({
	addonName = "Michs_RaidFrames",
	title = "Mich's Raid Frames",
})
