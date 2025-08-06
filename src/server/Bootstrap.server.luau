local ReplicatedStorage = game:GetService("ReplicatedStorage")
print("Hello world, from server!")

-- Require Packages
local Packages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"))

-- Require Core
local PlayerHandler = require('./Core/PlayerHandler')
PlayerHandler:Init()

-- Require Services
local DataInterface = require('./Services/DataInterface')
local CurrencyService = require('./Services/Currency')

-- // Testing
while task.wait(2) do
    for _, p in game.Players:GetPlayers() do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            CurrencyService:GiveCurrency(p, "Cash", 100, true, true)
        end
    end
end