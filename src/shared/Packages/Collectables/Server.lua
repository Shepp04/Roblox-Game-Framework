--!strict
-- // Services
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Dependencies
local Remotes = require('../Remotes')
local Debounce = require('../Debounce')

-- // Remotes
local DropCurrencyRemote = Remotes:GetRemote("RemoteEvent", "DropCurrency")

local CollectableCurrency = {}

function CollectableCurrency:DropCurrency(p: Player, currencyID: string, value: number)
    if not (p and p:IsA("Player")) then
        warn("Invalid player provided to DropCurrency")
        return
    end
	if not (Debounce:Try(p.UserId .. "Drop" .. currencyID, 1)) then return end
	DropCurrencyRemote:FireClient(p, currencyID, value)
end

-- Register collision groups
local function setupCollisionGroups()
	if not PhysicsService:IsCollisionGroupRegistered("Collectables") then
		PhysicsService:RegisterCollisionGroup("Collectables")
		PhysicsService:CollisionGroupSetCollidable("Collectables", "Collectables", false)

		task.spawn(function()
			if not PhysicsService:IsCollisionGroupRegistered("Players") then
				repeat task.wait(0.2)
				until PhysicsService:IsCollisionGroupRegistered("Players")
			end
			PhysicsService:CollisionGroupSetCollidable("Collectables", "Players", false)
			print("-- // Created Collectables Collision Group // --")
		end)
	end
end

setupCollisionGroups()

return CollectableCurrency
