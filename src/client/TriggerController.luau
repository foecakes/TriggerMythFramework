--!strict
--[[
	TRIGGER CONTROLLER
	Author: @FoeCakes

	DESCRIPTION:
		Client-side Knit controller handling model visibility.

	USAGE:
		Managed by Knit framework. Should not be required manually.

	NOTES:
		Depends on Global_ReplicationMode in GeneralConfig. If set to Client, this handles initial model hiding.
]]

--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Dependencies
local knit = require(ReplicatedStorage.Packages.knit)
local observers = require(ReplicatedStorage.Packages.observers)
local GeneralConfig = require(ReplicatedStorage.Shared.Constants.GeneralConfig)
local SummonModelUtil = require(ReplicatedStorage.Shared.Utilities.SummonModelUtil)
local SoundLib = require(ReplicatedStorage.Shared.Utilities.SoundUtil)

local observeTag = observers.observeTag
local TriggerService

--//Constructor
local TriggerController = knit.CreateController {
    Name = "TriggerController"
}

--//Lifecycle
function TriggerController:KnitInit()
    TriggerService = knit.GetService("TriggerService")
end

function TriggerController:KnitStart()
    -->! Only hide models locally if we are in Client replication mode, otherwise the server handles it globally
    if GeneralConfig.Global_ReplicationMode == "Client" then
        observeTag(GeneralConfig.Model_UnlockableTag, function(instance: Instance)
            SummonModelUtil.InitModel(instance)
            return function() end
        end)
    end

    TriggerService.SummonModel:Connect(function(modelName, action)
        SummonModelUtil.ExecuteAction(modelName, action)
    end)

    TriggerService.PlaySound:Connect(function(soundName)
        SoundLib.PlaySFX(soundName)
    end)
end

--//Return
return TriggerController