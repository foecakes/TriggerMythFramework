--[[
	GENERAL CONFIGURATION FILE - DOCUMENTATION & GUIDE
	Author: @FoeCakes

	
]]
--//Types
export type GeneralConfigT = {
	AnimationsOn: boolean, -->! Whether or not to animate models when they appear
	ReplicationMode: "Client" | "Server", -->! Whether to make detections & summon models on the client or server.
	DefaultTriggerType: string, -->! The default trigger type to use if no TriggerType attribute is found on a trigger part
	TriggerPartTag: string, -->! The tag used to identify trigger parts
}

local GeneralConfig: GeneralConfigT = {
	AnimationsOn = true, -->! Whether or not to animate models when they appear
	ReplicationMode = "Server", -->! Whether to make detections & summon models on the client or server.
	DefaultTriggerType = "Touch", -->! The default trigger type to use if no TriggerType attribute is found on a trigger part
	TriggerPartTag = "TRIGGER_PART", -->! The tag used to identify trigger parts
}

return GeneralConfig