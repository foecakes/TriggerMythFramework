--[[
	GENERAL CONFIGURATION FILE - DOCUMENTATION & GUIDE
	Author: @FoeCakes

	
]]
--//Types
export type GeneralConfigT = {
	AnimationsOn: boolean, -->! Whether or not to animate models when they appear
	ReplicationMode: "Client" | "Server", -->! Whether to make detections & summon models on the client or server.
	DefaultTriggerType: string, -->! The default trigger type to use if no TriggerType attribute is found on a trigger part
	DefaultTriggerAction: string, -->! The default trigger action ("Appear" | "Disappear") when no TriggerAction attribute is found
	TriggerPartTag: string, -->! The tag used to identify trigger parts
	UnlockableTag: string, -->! The tag used to identify unlockable models
	DefaultChatNormalisation: boolean -->! Whether or not chat messages should be normalised before being compared
	
}

local GeneralConfig: GeneralConfigT = {
	AnimationsOn = true, -->! Whether or not to animate models when they appear
	ReplicationMode = "Client", -->! Whether to make detections & summon models on the client or server.
	DefaultTriggerType = "Touch", -->! The default trigger type to use if no TriggerType attribute is found on a trigger part
	DefaultTriggerAction = "Appear", -->! The default trigger action ("Appear" | "Disappear") when no TriggerAction attribute is found
	TriggerPartTag = "TRIGGER_PART", -->! The tag used to identify trigger parts
	UnlockableTag = "UnlockableModel", -->! The tag used to identify unlockable models
	DefaultChatNormalisation = false -->! Whether or not chat messages should be normalised before being compared
}

return GeneralConfig