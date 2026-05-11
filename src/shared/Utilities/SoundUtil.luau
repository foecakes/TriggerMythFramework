--!strict
--[[
	SOUND UTILITY
	Author: @FoeCakes

	DESCRIPTION:
		A utility module for playing sounds. Sounds are expected to be pre-loaded
		and parented under SoundService or a specified parent instance.

	USAGE:
		local SoundLib = require(path.to.SoundUtil)
		SoundLib.PlaySFX("Click", 0.5)

	PARAMETERS:
		soundName (string): The name of the Sound instance to find.
		vol (number?): Optional volume override.
		parent (Instance?): Optional parent to search within, defaults to SoundService.

	NOTES:
		Can be called by both client and server.
]]

--//Services
local SoundService = game:GetService("SoundService")

--//Constructor
local SoundLib = {}

--//Public methods
function SoundLib.PlaySFX(soundName: string, vol: number?, parent: Instance?)
    assert(soundName, "SoundLib.PlaySFX: soundName is nil")

    -->! FindFirstChild with recursive search allows sounds to be deeply nested in folders
    -->! without requiring the exact path, improving flexibility when reorganising SoundService
    local sound = (parent or SoundService):FindFirstChild(soundName, true) :: Sound?
    if not sound then
        warn("SoundLib.PlaySFX: sound not found: " .. soundName)
        return
    end
    
    -->! Only override the volume if explicitly provided, preserving the original sound properties
    sound.Volume = vol or sound.Volume
    sound:Play()
end

function SoundLib.StopSFX(soundName: string, parent: Instance?)
    assert(soundName, "SoundLib.StopSFX: soundName is nil")

    local sound = (parent or SoundService):FindFirstChild(soundName, true) :: Sound?
    if not sound then
        warn("SoundLib.StopSFX: sound not found: " .. soundName)
        return
    end

    sound:Stop()
end

--//Return
return SoundLib