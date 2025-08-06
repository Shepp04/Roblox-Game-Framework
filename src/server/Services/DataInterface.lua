--!strict
-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- // Packages
local Packages = require('../Packages')
local DataManager = Packages.DataManager

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local DataInterface = {}

-- // Public API
function DataInterface:GetPlayerProfile(p: Player, yield: boolean?): Config.PlayerProfile?
    -- Check if profile exists
    local profile = DataManager:GetPlayerProfile(p, yield)
    if not profile then
        return nil
    end

    return DataManager.DeepClone(profile)
end

function DataInterface:LoadPlayerProfile(p: Player): Config.PlayerProfile?
    -- Load the player profile
    local profile = DataManager:LoadPlayerProfile(p)
    if not profile then
        warn("Failed to load profile for player: " .. p.Name)
        return nil
    end

    return profile
end

function DataInterface:ReleasePlayerProfile(p: Player): boolean
    -- Release the profile to free up resources
    return DataManager:ReleasePlayerProfile(p)
end

return DataInterface
