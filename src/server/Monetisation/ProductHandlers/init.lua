--!strict

-- // NOTE: Define product handlers for monetisation products at the bottom of this file!

--// Services
local CurrencyService = require("../Services/Currency")
local DataInterface = require("../Services/DataInterface")

--// Assets
local Assets = script:WaitForChild("Assets")

--// Data
local ProductDefinitions = require("./ProductDefinitions")
local DevProducts = ProductDefinitions.DevProducts
local Gamepasses = ProductDefinitions.Gamepasses

--// Types
type ProductHandler = (Player) -> (boolean, string?)

--// Handler Tables
local DevProductHandlers: { [number]: ProductHandler } = {}
local GamepassHandlers: { [number]: ProductHandler } = {}

--// Main Handlers Table
local Handlers = {
	DevProducts = DevProductHandlers,
	Gamepasses = GamepassHandlers,
} :: {
	DevProducts: { [number]: ProductHandler },
	Gamepasses: { [number]: ProductHandler },
	GetHandler: ((productType: "DevProducts" | "Gamepasses", id: number) -> ProductHandler?)?
}

--// Helper Functions

local function isPlayerValid(p: Player?): boolean
	return p ~= nil and p:IsDescendantOf(game)
end

local function processCurrencyProduct(p: Player, currencyID: string, amount: number): (boolean, string?)
	if not isPlayerValid(p) then
		return false, "Invalid player"
	end

	local success, err = CurrencyService:GiveCurrency(p, currencyID, amount, false, true)
	return success, err
end

local function processToolGamepass(p: Player, toolName: string): (boolean, string?)
	if not isPlayerValid(p) then
		return false, "Invalid player"
	end

	local toolID = string.format("_%s_", toolName)
	local backpack = p:FindFirstChild("Backpack")
	if backpack and backpack:FindFirstChild(toolID) then
		return true, nil
	end

	local char = p.Character
	if char and char:FindFirstChild(toolID) then
		return true, nil
	end

	local template = Assets:FindFirstChild(toolName)
	if not template then
		return false, `Missing tool asset: {toolName}`
	end

	local clone = template:Clone()
	clone.Name = toolID
	clone.CanBeDropped = false
	clone.Parent = backpack or p:WaitForChild("Backpack")

	return true, nil
end

local function defineGamepassHandler(gamepassName: string, handler: ProductHandler)
	local gamepassInfo = Gamepasses[gamepassName]
	if gamepassInfo then
		GamepassHandlers[gamepassInfo.ID] = handler
	else
		warn(`[ProductHandlers] No gamepass definition for '{gamepassName}'`)
	end
end

--// Define Gamepass Handlers Below

-- Add/edit gamepass handlers here using defineGamepassHandler("GamepassName", function(player)...end)

defineGamepassHandler("GravityCoil", function(p)
	return processToolGamepass(p, "GravityCoil")
end)

defineGamepassHandler("SpeedCoil", function(p)
	return processToolGamepass(p, "SpeedCoil")
end)

defineGamepassHandler("DoubleCash", function(p)
	if not isPlayerValid(p) then
		return false, "Invalid player"
	end

	local gamepassID = Gamepasses["DoubleCash"].ID
	local currencyID = "Cash"
	local multiplier = 2.0

	local success = CurrencyService:SetMultiplier(p, gamepassID, currencyID, multiplier, nil)
	return success, success and nil or "Failed to set multiplier"
end)

--// Define Dev Product Handlers Automatically
for stringID, info in DevProducts do
	if info.Category == "Currency" then
		DevProductHandlers[info.ID] = function(p: Player)
			return processCurrencyProduct(p, info.CurrencyID, info.Amount)
		end
	end
end

--// Handler Lookup Function
function Handlers.GetHandler(productType: "DevProducts" | "Gamepasses", id: number): ProductHandler?
	return Handlers[productType][id]
end

return Handlers
