--!strict
local Players = game:GetService("Players")

-- // Services
local DataInterface = require('../Services/DataInterface')

-- // Components
local Components = {}

local PlayerHandler = {}

-- // Private Functions
local function onCharacterAdded(p : Player, char : Model)
    -- Load a nametag
    if (Components.Nametags) then
        Components.Nametags:Update(p)
    end
end

local function onPlayerAdded(p: Player)
    -- Logic to handle when a player joins the game
    print(p.Name .. " has joined the game.")
    
    -- Initialise player data or any other setup
    local profile = DataInterface:LoadPlayerProfile(p)
    if not (profile) then
        warn("Failed to load profile for player: " .. p.Name)
        return
    end
    
    -- Wait for their character to load
    local char = p.Character or p.CharacterAdded:Wait()
    onCharacterAdded(p, char)

    p.CharacterAdded:Connect(function(c : Model)
        onCharacterAdded(p, c)
    end)
end

local function onPlayerRemove(p: Player)
    print(p.Name .. " has left the game.")

    -- Cleanup player data
    DataInterface:ReleasePlayerProfile(p)
end

function PlayerHandler:Init()
    -- Require Components
    for _, m in script:WaitForChild("Components"):GetChildren() do
        if (m:IsA("ModuleScript")) then
            Components[m.Name] = require(m)
        end
    end

    for _, p in Players:GetPlayers() do
        onPlayerAdded(p)
    end
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemove)
end


return PlayerHandler