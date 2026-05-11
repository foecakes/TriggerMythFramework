--[[
	GENERAL CONFIGURATION
	Author: @FoeCakes

	DESCRIPTION:
		Centralised configuration file for the TriggerMyth framework.
		Modifying values here alters the global behavior of the trigger system.

	USAGE:
		local GeneralConfig = require(path.to.GeneralConfig)
		print(GeneralConfig.AnimationsOn)

	NOTES:
		Contains the type definitions for strict type checking.
]]

--//Types
export type GeneralConfigT = {
	Model_AnimationsOn: boolean, -->! Whether models animate during appearance/disappearance
	Model_UseStaggeredAnimation: boolean, -->! Whether the animation staggers parts
	Global_ReplicationMode: "Client" | "Server", -->! Determines if triggers run locally (Client) or globally (Server)
	Trigger_DefaultType: string, -->! Fallback when a trigger part lacks a TriggerType attribute
	Trigger_DefaultAction: string, -->! Fallback action ("Appear" or "Disappear")
	Trigger_PartTag: string, -->! CollectionService tag for interactive parts
	Model_UnlockableTag: string, -->! CollectionService tag for hidden models
	Chat_DefaultNormalisation: boolean, -->! Controls if chat triggers ignore casing and whitespace by default
	Console_DefaultOutputType: string, -->! Fallback console output method
	Console_DefaultThrottle: number, -->! Default wait time between repeated console outputs
	Console_DefaultAmount: number -->! Default repeat count for console outputs
}

--//Constants
local GeneralConfig: GeneralConfigT = {
	Model_AnimationsOn = true,
	Model_UseStaggeredAnimation = false,
	Global_ReplicationMode = "Client",
	Trigger_DefaultType = "Touch",
	Trigger_DefaultAction = "Appear",
	Trigger_PartTag = "TRIGGER_PART",
	Model_UnlockableTag = "UnlockableModel",
	Chat_DefaultNormalisation = false,
	Console_DefaultOutputType = "print",
	Console_DefaultThrottle = 0,
	Console_DefaultAmount = 1
}

--//Return
return GeneralConfig