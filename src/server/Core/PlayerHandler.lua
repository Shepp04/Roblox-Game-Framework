--!strict
local Players = game:GetService("Players")

-- // Services
local DataInterface = require('../Services/DataInterface')

local PlayerHandler = {}

-- // Private Functions
local function onPlayerAdded(p: Player)
    -- Logic to handle when a player joins the game
    print(p.Name .. " has joined the game.")
    
    -- Initialise player data or any other setup
    local profile = DataInterface:LoadPlayerProfile(p)
    if not (profile) then
        warn("Failed to load profile for player: " .. p.Name)
        return
    end
end

local function onPlayerRemove(p: Player)
    print(p.Name .. " has left the game.")

    -- Cleanup player data
    DataInterface:ReleasePlayerProfile(p)
end


function PlayerHandler:Init()
    -- Initialization logic for player handler
    print("PlayerHandler initialized")

    for _, p in Players:GetPlayers() do
        onPlayerAdded(p)
    end
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemove)
end


return PlayerHandler