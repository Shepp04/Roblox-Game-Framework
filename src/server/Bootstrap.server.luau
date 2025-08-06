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