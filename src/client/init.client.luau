--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Dependencies
local knit = require(ReplicatedStorage.Packages.knit)

--//Runtime
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