--!strict
--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Dependencies
local knit = require(ReplicatedStorage.Packages.knit)
local observers = require(ReplicatedStorage.Packages.observers)
local GeneralConfig = require(ReplicatedStorage.Shared.Constants.GeneralConfig)
local SummonModelUtil = require(ReplicatedStorage.Shared.Utilities.SummonModelUtil)
local SoundLib = require(ReplicatedStorage.Shared.Utilities.SoundUtil)

local observeTag = observers.observeTag
local TriggerService -->! Initialized in knitInit

--//Constructor
local TriggerController = knit.CreateController {
    Name = "TriggerController"
}

--//Lifecycle
function TriggerController:KnitInit()
    TriggerService = knit.GetService("TriggerService")
end

function TriggerController:KnitStart()
    -->! Only hide models locally if we are in Client replication mode
    if GeneralConfig.Global_ReplicationMode == "Client" then
        observeTag(GeneralConfig.Model_UnlockableTag, function(instance: Instance)
            SummonModelUtil.InitModel(instance)
            return function() end
        end)
    end

    -->! Connect the client trigger action function
    TriggerService.SummonModel:Connect(function(modelName, action)
        SummonModelUtil.ExecuteAction(modelName, action)
    end)

    -->! Connect the client play sound function
    TriggerService.PlaySound:Connect(function(soundName)
        SoundLib.PlaySFX(soundName)
    end)
end

--//Return
return TriggerController