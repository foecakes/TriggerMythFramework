--[[
	TriggerService
	Author: @FoeCakes

	Knit service that observes trigger parts (tagged with GeneralConfig.TriggerPartTag)
	and wires them to summon/reveal "UnlockableModel"-tagged Models and Folders.

	Trigger parts require:
		-> A "ModelToSummon" string attribute (must match the Name of a tagged instance).
		-> An optional "TriggerType" string attribute ("Touch" | "Click"). Falls back to
		  GeneralConfig.DefaultTriggerType when absent.
		-> An optional "SetText" string attribute. When present, sets a Hint in the
		  workspace with the given text when the trigger fires.
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
local observeTag = observers.observeTag
local ChatListenerUtil = require(ReplicatedStorage.Shared.Utilities.ChatListenerUtil)

--//Types
export type TriggerPartData = {
	Part: BasePart,
	ModelToSummon: string,
	TriggerType: string,
	TriggerAction: string,
	SetText: string?,
	PlaySound: string?,
	Connection: RBXScriptConnection?,
	Cleanup: (() -> ())?,
	ChatData: string?,
	ShouldNormalise: boolean?
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
--[[
	parseModelNames – Splits a comma-separated string of model names into
	a list of trimmed, non-empty strings.
]]
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

--[[
	executeForModels – Runs the given action for each model name in the
	comma-separated list, either on the server or by signalling the client.
]]
local function executeForModels(modelNames: { string }, action: string, player: Player?)
	local isServerMode = GeneralConfig.ReplicationMode == "Server"

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

--[[
	processTrigger – Wires a Touch or Click connection to the trigger part.
	When fired, executes the configured action on all listed models either
	on the server or by signalling the client, depending on
	GeneralConfig.ReplicationMode.
]]
local function processTrigger(partData: TriggerPartData)
	local triggerPart = partData.Part
	local modelNames = parseModelNames(partData.ModelToSummon)
	local triggerType = partData.TriggerType
	local action = partData.TriggerAction
	local setText = partData.SetText
	local playSoundName = partData.PlaySound

	if triggerType == "Touch" then
		partData.Connection = triggerPart.Touched:Connect(function(hitPart: BasePart)
			-->! Ensure it's a player touching the part
			local player = Players:GetPlayerFromCharacter(hitPart.Parent)
			if not player then return end

			executeForModels(modelNames, action, player)
			if setText then SetHint(setText) end
			if playSoundName then
				-->! Check if the sound exists inside the trigger part (spatial audio)
				local partSound = triggerPart:FindFirstChild(playSoundName, true) :: Sound?
				if partSound then
					partSound:Play()
				elseif GeneralConfig.ReplicationMode == "Server" then
					SoundLib.PlaySFX(playSoundName)
				else
					TriggerService.Client.PlaySound:Fire(player, playSoundName)
				end
			end
		end)

	elseif triggerType == "Click" then
		-->! Initialize click detector if one doesn't exist
		local clickDetector: ClickDetector = triggerPart:FindFirstChildOfClass("ClickDetector")
		if not clickDetector then
			local nCD: ClickDetector = Instance.new("ClickDetector")
			nCD.Parent = triggerPart
			clickDetector = nCD
		end

		-->! Setup click connection
		partData.Connection = clickDetector.MouseClick:Connect(function(player: Player)
			executeForModels(modelNames, action, player)
			if setText then SetHint(setText) end
			if playSoundName then
				-->! Check if the sound exists inside the trigger part (spatial audio)
				local partSound = triggerPart:FindFirstChild(playSoundName, true) :: Sound?
				if partSound then
					partSound:Play()
				elseif GeneralConfig.ReplicationMode == "Server" then
					SoundLib.PlaySFX(playSoundName)
				else
					TriggerService.Client.PlaySound:Fire(player, playSoundName)
				end
			end
		end)
	elseif triggerType == "Chat" and partData.ChatData then
		local onMatched = function(player: Player, msg: string)
			executeForModels(modelNames, action, player)
			if setText then SetHint(setText) end
			if playSoundName then
				local partSound = triggerPart:FindFirstChild(playSoundName, true) :: Sound?
				if partSound then
					partSound:Play()
				elseif GeneralConfig.ReplicationMode == "Server" then
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
--[[
	handleModelSummonTriggerPart – Observer callback for parts tagged with
	GeneralConfig.TriggerPartTag. Reads the ModelToSummon and TriggerType
	attributes, validates them, wires the trigger, and returns a cleanup
	function that disconnects the connection when the tag is removed.
]]
local function handleModelSummonTriggerPart(part: Part): () -> ()
	assert(part:IsA("BasePart"), "Part expected for trigger part, got " .. part.ClassName)

	-->! Read and validate attributes
	local modelToSummon = part:GetAttribute("ModelToSummon")
	assert(modelToSummon and type(modelToSummon) == "string",
		"ModelToSummon attribute expected on trigger part, got " .. tostring(modelToSummon))

	-->! Get trigger type from part, falling back to the configured default
	local triggerType = part:GetAttribute("TriggerType")
	if not triggerType or type(triggerType) ~= "string" then
		triggerType = GeneralConfig.DefaultTriggerType
	end

	-->! Get trigger action from part, falling back to the configured default
	local triggerAction = part:GetAttribute("TriggerAction")
	if not triggerAction or type(triggerAction) ~= "string" then
		triggerAction = GeneralConfig.DefaultTriggerAction
	end

	-->! Get optional SetText attribute
	local setText = part:GetAttribute("SetText")
	if setText and type(setText) ~= "string" then
		setText = nil
	end

	-->! Get optional PlaySound attribute
	local playSound = part:GetAttribute("PlaySound")
	if playSound and type(playSound) ~= "string" then
		playSound = nil
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
			shouldNormalise = GeneralConfig.DefaultChatNormalisation
		end

	-->! Build part data and wire the trigger
	local partData: TriggerPartData = {
		Part = part,
		ModelToSummon = modelToSummon :: string,
		TriggerType = triggerType :: string,
		TriggerAction = triggerAction :: string,
		SetText = setText :: string?,
		PlaySound = playSound :: string?,
		ShouldNormalise = shouldNormalise :: boolean?,
		ChatData = chatData :: string?
	}



	processTrigger(partData)

	-->! Return cleanup function
	return function()
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

--//Lifecycle
function TriggerService:KnitInit()
	-->! Only hide models globally if we are in Server replication mode
	if GeneralConfig.ReplicationMode == "Server" then
		observeTag(GeneralConfig.UnlockableTag, function(instance: Instance)
			SummonModelUtil.InitModel(instance)

			-->! No teardown needed; weak-keyed caches handle cleanup on destroy
			return function() end
		end)
	end
end

function TriggerService:KnitStart()
	-->! Observe trigger parts and wire their connections
	observeTag(GeneralConfig.TriggerPartTag, handleModelSummonTriggerPart)
end

--//Return
return TriggerService