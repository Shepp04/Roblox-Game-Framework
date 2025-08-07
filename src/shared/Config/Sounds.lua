--!strict
-- // Type Defs
export type SoundInfo = {
    ID : string,
    PlaybackSpeed : number?,
    RolloffMaxDistance : number?,
}

local SoundsConfig = {} :: { Sounds : { [string] : SoundInfo}}

SoundsConfig.Sounds = {
    -- // Clicks
    UIClick01 = {
        ID = "rbxassetid://4499400560",
        PlaybackSpeed = 1.0,
        RolloffMaxDistance = 50,
    },
    UIClick02 = {
        ID = "rbxassetid://15675059323",
        PlaybackSpeed = 1.0,
        RolloffMaxDistance = 50,
    },

    -- // Success / Error
    UISuccess01 = {
        ID = "rbxassetid://10593534791",
        PlaybackSpeed = 1.0,
        RolloffMaxDistance = 50,
    },
    UIError = {
        ID = "rbxassetid://10593532102", -- "rbxassetid://116399794334864",
        PlaybackSpeed = 1.0,
        RolloffMaxDistance = 50,
    },
}

function SoundsConfig:GetSoundID(soundName : string): SoundInfo?
    if (SoundsConfig.Sounds[soundName]) then
        return SoundsConfig.Sounds[soundName]
    end
    warn("No sound found with name:", soundName)
    return nil
end

return SoundsConfig