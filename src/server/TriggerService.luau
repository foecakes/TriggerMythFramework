--[[
	TRIGGER SERVICE
	Author: @FoeCakes

	DESCRIPTION:
		Knit service that observes interactive parts and wires them to summon or hide models.
		Listens for Touch, Click, or Chat events based on part attributes.

	USAGE:
		Managed by Knit framework. Trigger parts must be tagged and configured via attributes.

	NOTES:
		Other optional attributes: "ModelToSummon", "TriggerType", "SetHint", "PlaySound".
]]

--//Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Dependencies
local knit = require(ReplicatedStorage.Packages.knit)
local observers = require(ReplicatedStorage.Packages.observers)
local GeneralConfig = require(ReplicatedStorage.Shared.Constants.GeneralConfig)
local SummonModelUtil = require(ReplicatedStorage.Shared.Utilities.SummonModelUtil)
local SetHint = require(ReplicatedStorage.Shared.Utilities.SetHintUtil)
local SoundLib = require(ReplicatedStorage.Shared.Utilities.SoundUtil)
local ChatListenerUtil = require(ReplicatedStorage.Shared.Utilities.ChatListenerUtil)
local ConsoleUtil = require(ReplicatedStorage.Shared.Utilities.ConsoleUtil)

local observeTag = observers.observeTag

--//Types
export type TriggerPartData = {
	Part: BasePart,
	ModelToSummon: string?,
	TriggerType: string,
	TriggerAction: string,
	SetHint: string?,
	PlaySound: string?,
	Connection: RBXScriptConnection?,
	Cleanup: (() -> ())?,
	ChatData: string?,
	ShouldNormalise: boolean?,
	ConsoleOutput: string?,
	ConsoleOutputType: string?,
	ConsoleThrottle: number?,
	ConsoleAmount: number?
}

--//Constructor
local TriggerService = knit.CreateService {
	Name = "TriggerService",
	Client = {
		SummonModel = knit.CreateSignal(),
		PlaySound = knit.CreateSignal(),
	},
}

--//Helpers
-->! Splits a comma-separated string of model names, useful for triggering multiple models at once
local function parseModelNames(raw: string): { string }
	local names: { string } = {}
	for name in string.gmatch(raw, "[^,]+") do
		local trimmed = string.match(name, "^%s*(.-)%s*$")
		if trimmed and trimmed ~= "" then
			table.insert(names, trimmed)
		end
	end
	return names
end

-->! Distributes the action either globally (server mode) or locally via network signals (client mode)
local function executeForModels(modelNames: { string }, action: string, player: Player?)
	local isServerMode = GeneralConfig.Global_ReplicationMode == "Server"

	for _, modelName in modelNames do
		if isServerMode then
			SummonModelUtil.ExecuteAction(modelName, action)
		else
			if player then
				TriggerService.Client.SummonModel:Fire(player, modelName, action)
			end
		end
	end
end

local function processTrigger(partData: TriggerPartData)
	local triggerPart = partData.Part
	local modelNames = partData.ModelToSummon and parseModelNames(partData.ModelToSummon) or {}
	local triggerType = partData.TriggerType
	local action = partData.TriggerAction
	local setHintText = partData.SetHint
	local playSoundName = partData.PlaySound
	local consoleOutput = partData.ConsoleOutput
	local consoleOutputType = partData.ConsoleOutputType
	local consoleThrottle = partData.ConsoleThrottle
	local consoleAmount = partData.ConsoleAmount

	if triggerType == "Touch" then
		partData.Connection = triggerPart.Touched:Connect(function(hitPart: BasePart)
			-->! Ensure the hit part belongs to an actual player character
			local player = Players:GetPlayerFromCharacter(hitPart.Parent)
			if not player then return end

			executeForModels(modelNames, action, player)
			if setHintText then SetHint(setHintText) end
			if consoleOutput then ConsoleUtil.OutputToConsole(consoleOutput, consoleOutputType, consoleThrottle, consoleAmount) end
			if playSoundName then
				-->! Check for spatial audio inside the part before falling back to SoundService
				local partSound = triggerPart:FindFirstChild(playSoundName, true) :: Sound?
				if partSound then
					partSound:Play()
				elseif GeneralConfig.Global_ReplicationMode == "Server" then
					SoundLib.PlaySFX(playSoundName)
				else
					TriggerService.Client.PlaySound:Fire(player, playSoundName)
				end
			end
		end)

	elseif triggerType == "Click" then
		-->! Lazily instance a ClickDetector so developers don't have to add them manually
		local clickDetector: ClickDetector = triggerPart:FindFirstChildOfClass("ClickDetector")
		if not clickDetector then
			local nCD: ClickDetector = Instance.new("ClickDetector")
			nCD.Parent = triggerPart
			clickDetector = nCD
		end

		partData.Connection = clickDetector.MouseClick:Connect(function(player: Player)
			executeForModels(modelNames, action, player)
			if setHintText then SetHint(setHintText) end
			if consoleOutput then ConsoleUtil.OutputToConsole(consoleOutput, consoleOutputType, consoleThrottle, consoleAmount) end
			if playSoundName then
				local partSound = triggerPart:FindFirstChild(playSoundName, true) :: Sound?
				if partSound then
					partSound:Play()
				elseif GeneralConfig.Global_ReplicationMode == "Server" then
					SoundLib.PlaySFX(playSoundName)
				else
					TriggerService.Client.PlaySound:Fire(player, playSoundName)
				end
			end
		end)
	elseif triggerType == "Chat" and partData.ChatData then
		local onMatched = function(player: Player, msg: string)
			executeForModels(modelNames, action, player)
			if setHintText then SetHint(setHintText) end
			if consoleOutput then ConsoleUtil.OutputToConsole(consoleOutput, consoleOutputType, consoleThrottle, consoleAmount) end
			if playSoundName then
				local partSound = triggerPart:FindFirstChild(playSoundName, true) :: Sound?
				if partSound then
					partSound:Play()
				elseif GeneralConfig.Global_ReplicationMode == "Server" then
					SoundLib.PlaySFX(playSoundName)
				else
					TriggerService.Client.PlaySound:Fire(player, playSoundName)
				end
			end
		end
		partData.Cleanup = ChatListenerUtil.BindTrigger(partData.ChatData, onMatched, partData.ShouldNormalise )
	end
end

--//Private functions
-->! Extracts configuration attributes from the part and sets up the observer lifecycle
local function handleModelSummonTriggerPart(part: Part): () -> ()
	assert(part:IsA("BasePart"), "Part expected for trigger part, got " .. part.ClassName)

	local modelToSummon = part:GetAttribute("ModelToSummon")
	if modelToSummon and type(modelToSummon) ~= "string" then
		modelToSummon = nil
	end

	-->! Retrieve optional attributes with fallbacks to GeneralConfig defaults
	local triggerType = part:GetAttribute("TriggerType")
	if not triggerType or type(triggerType) ~= "string" then
		triggerType = GeneralConfig.Trigger_DefaultType
	end

	local triggerAction = part:GetAttribute("TriggerAction")
	if not triggerAction or type(triggerAction) ~= "string" then
		triggerAction = GeneralConfig.Trigger_DefaultAction
	end

	local setHintText = part:GetAttribute("SetHint")
	if setHintText and type(setHintText) ~= "string" then
		setHintText = nil
	end

	local playSound = part:GetAttribute("PlaySound")
	if playSound and type(playSound) ~= "string" then
		playSound = nil
	end

	local consoleOutput = part:GetAttribute("ConsoleOutput")
	if consoleOutput and type(consoleOutput) ~= "string" then
		consoleOutput = nil
	end

	local consoleOutputType = part:GetAttribute("ConsoleOutputType")
	if consoleOutputType and type(consoleOutputType) ~= "string" then
		consoleOutputType = nil
	end

	local consoleThrottle = part:GetAttribute("ConsoleThrottle")
	if consoleThrottle and type(consoleThrottle) ~= "number" then
		consoleThrottle = nil
	end

	local consoleAmount = part:GetAttribute("ConsoleAmount")
	if consoleAmount and type(consoleAmount) ~= "number" then
		consoleAmount = nil
	end

	local chatData = part:GetAttribute("ChatTrigger")
	if chatData and type(chatData) ~= "string" then
		chatData = nil
	end

	local shouldNormalise = part:GetAttribute("ShouldNormalise")
	if shouldNormalise and type(shouldNormalise) == "string" then
		if string.lower(shouldNormalise) == "true" then
			shouldNormalise = true
		else 
			shouldNormalise = false
		end
	elseif shouldNormalise and type(shouldNormalise) ~= "boolean" then
		shouldNormalise = nil
	end
	if shouldNormalise == nil then
		shouldNormalise = GeneralConfig.Chat_DefaultNormalisation
	end

	local partData: TriggerPartData = {
		Part = part,
		ModelToSummon = modelToSummon :: string?,
		TriggerType = triggerType :: string,
		TriggerAction = triggerAction :: string,
		SetHint = setHintText :: string?,
		PlaySound = playSound :: string?,
		ShouldNormalise = shouldNormalise :: boolean?,
		ChatData = chatData :: string?,
		ConsoleOutput = consoleOutput :: string?,
		ConsoleOutputType = consoleOutputType :: string?,
		ConsoleThrottle = consoleThrottle :: number?,
		ConsoleAmount = consoleAmount :: number?
	}

	processTrigger(partData)

	-->! Disconnect events if the trigger tag is removed during runtime
	return function()
		if GeneralConfig.Global_ReplicationMode == "Server" then
			if partData.Cleanup then
				partData.Cleanup()
				partData.Cleanup = nil
			end
		
			if partData.Connection then
				partData.Connection:Disconnect()
				partData.Connection = nil
			end
		end
	end
end

--//Lifecycle
function TriggerService:KnitInit()
	-->! Models are hidden by the server immediately to prevent loading flicker for all clients
	if GeneralConfig.Global_ReplicationMode == "Server" then
		observeTag(GeneralConfig.Model_UnlockableTag, function(instance: Instance)
			SummonModelUtil.InitModel(instance)

			return function() end
		end)
	end
end

function TriggerService:KnitStart()
	observeTag(GeneralConfig.Trigger_PartTag, handleModelSummonTriggerPart)
end

--//Return
return TriggerService