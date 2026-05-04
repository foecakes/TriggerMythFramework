--!strict
--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Dependencies
local knit = require(ReplicatedStorage.Packages.knit)
local observers = require(ReplicatedStorage.Packages.observers)
local GeneralConfig = require(ReplicatedStorage.Shared.Constants.GeneralConfig)
local SummonModelUtil = require(ReplicatedStorage.Shared.Utilities.SummonModelUtil)

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
    if GeneralConfig.ReplicationMode == "Client" then
        observeTag(GeneralConfig.UnlockableTag, function(instance: Instance)
            SummonModelUtil.InitModel(instance)
            return function() end
        end)
    end

    -->! Connect the client summon model function
    TriggerService.SummonModel:Connect(function(modelName)
        SummonModelUtil.Summon(modelName)
    end)
end

return TriggerController