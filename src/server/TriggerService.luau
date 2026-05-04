--[[
	TriggerService
	Author: @FoeCakes

	Knit service that observes trigger parts (tagged with GeneralConfig.TriggerPartTag)
	and wires them to summon/reveal "UnlockableModel"-tagged Models and Folders.

	Trigger parts require:
		• A "ModelToSummon" string attribute (must match the Name of a tagged instance).
		• An optional "TriggerType" string attribute ("Touch" | "Click"). Falls back to
		  GeneralConfig.DefaultTriggerType when absent.
]]

--//Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Dependencies
local knit = require(ReplicatedStorage.Packages.knit)
local observers = require(ReplicatedStorage.Packages.observers)
local GeneralConfig = require(ReplicatedStorage.Shared.Constants.GeneralConfig)
local SummonModelUtil = require(ReplicatedStorage.Shared.Utilities.SummonModelUtil)
local observeTag = observers.observeTag

--//Types
export type TriggerPartData = {
	Part: BasePart,
	ModelToSummon: string,
	TriggerType: string,
	Connection: RBXScriptConnection?,
}

--//Constructor
local TriggerService = knit.CreateService {
	Name = "TriggerService",
	Client = { SummonModel = knit.CreateSignal() },
}

--//Helpers
--[[
	processTrigger – Wires a Touch or Click connection to the trigger part.
	When fired, summons the associated model either on the server or by
	signalling the client, depending on GeneralConfig.ReplicationMode.
]]
local function processTrigger(partData: TriggerPartData)
	local triggerPart = partData.Part
	local modelToSummonName = partData.ModelToSummon
	local triggerType = partData.TriggerType
	local isServerMode = GeneralConfig.ReplicationMode == "Server"

	if triggerType == "Touch" then
		partData.Connection = triggerPart.Touched:Connect(function(hitPart: BasePart)
			-->! Ensure it's a player touching the part
			local player = Players:GetPlayerFromCharacter(hitPart.Parent)
			if not player then return end

			-->! Summon model depending on set replication mode
			if isServerMode then
				SummonModelUtil.Summon(modelToSummonName)
			else
				TriggerService.Client.SummonModel:Fire(player, modelToSummonName)
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
			-->! Summon model depending on set replication mode
			if isServerMode then
				SummonModelUtil.Summon(modelToSummonName)
			else
				TriggerService.Client.SummonModel:Fire(player, modelToSummonName)
			end
		end)
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

	-->! Build part data and wire the trigger
	local partData: TriggerPartData = {
		Part = part,
		ModelToSummon = modelToSummon :: string,
		TriggerType = triggerType :: string,
	}

	processTrigger(partData)

	-->! Return cleanup function
	return function()
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