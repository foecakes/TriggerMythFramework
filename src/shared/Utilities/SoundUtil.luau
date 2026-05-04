--!strict
--[[
    SOUNDLIB UTIL
    ──────────────
    A utility module for playing sounds.

    Passed soundNames are expected to be found as descendants under SoundService.

    ──────────────
    ABLE TO BE CALLED BY CLIENT AND SERVER
]]

--//Services
local SoundService = game:GetService("SoundService")

-->! Declare
local SoundLib = {}

--//Public methods
function SoundLib.PlaySFX(soundName: string, vol: number?, parent: Instance?)
    assert(soundName, "SoundLib.PlaySFX: soundName is nil")

    -->! Find sound
    local sound = (parent or SoundService):FindFirstChild(soundName, true) :: Sound?
    if not sound then
        warn("SoundLib.PlaySFX: sound not found: " .. soundName)
        return
    end
    sound.Volume = vol or sound.Volume

    -->! Play sound
    sound:Play()
end

function SoundLib.StopSFX(soundName: string, parent: Instance?)
    assert(soundName, "SoundLib.StopSFX: soundName is nil")

    --> ! Find sound
    local sound = (parent or SoundService):FindFirstChild(soundName, true) :: Sound?
    if not sound then
        warn("SoundLib.StopSFX: sound not found: " .. soundName)
        return
    end

    --> ! Stop sound
    sound:Stop()
end

return SoundLib