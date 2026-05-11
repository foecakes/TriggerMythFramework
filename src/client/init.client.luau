--[[
	CLIENT ENTRY POINT
	Author: @FoeCakes

	DESCRIPTION:
		Bootstraps the client environment by loading all local Knit controllers
		and starting the framework.

	USAGE:
		Runs automatically when player joins.
]]

--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Dependencies
local knit = require(ReplicatedStorage.Packages.knit)

--//Runtime
-->! Dynamically require all child module scripts to register them with Knit
for _, serviceModule in script:GetDescendants() do
    if serviceModule:IsA("ModuleScript") then
        local s, err = pcall(function()
            require(serviceModule)
        end)
        if not s then
            warn(err, "-- Failed to load service: " .. serviceModule.Name)
        end
    end
end

knit.Start():andThen(function()
    print("[Fa'okhekh] La'ikhfa'ekh ba'ekhga'ikhnasa")
end):catch(warn)