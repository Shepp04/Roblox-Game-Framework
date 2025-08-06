local ReplicatedStorage = game:GetService("ReplicatedStorage")
print("Hello world, from server!")

-- Require Packages
local Packages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"))

-- Require Services
local DataInterface = require('./Services/DataInterface')
local CurrencyService = require('./Services/Currency')

workspace.GivePart.ClickDetector.MouseClick:Connect(function(p : Player)
    local currencyID = math.random(1, 2) == 1 and "Cash" or "Rebirths"
    CurrencyService:GiveCurrency(p, currencyID, 1, false, true)
end)

workspace.SpendPart.ClickDetector.MouseClick:Connect(function(p : Player)
    local currencyID = math.random(1, 2) == 1 and "Cash" or "Rebirths"
    CurrencyService:SpendCurrency(p, currencyID, 1)
end)