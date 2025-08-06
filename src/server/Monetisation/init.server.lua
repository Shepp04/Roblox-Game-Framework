--!strict
-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketPlaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- // Data
local ProductDefinitions = require('@self/ProductDefinitions')
local ProductHandlers = require('@self/ProductHandlers')

-- // Packages
local SharedPackages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"))
local Remotes = SharedPackages.Remotes

-- // Remotes
local GetMonetisationData = Remotes:GetRemote("RemoteFunction", "GetMonetisationData")

-- // Datastores
local PurchaseHistoryStore = DataStoreService:GetDataStore("PreviousPurchases")

-- // Gamepasses
local function handleGamepass(p: Player, stringID: string): boolean
	local gamepassInfo = ProductDefinitions.Gamepasses[stringID]
	if not gamepassInfo then
		warn("No Gamepass found with name:", stringID)
		return false
	end

	if gamepassInfo.HandledByTycoon then
		return true
	end

	local handler = ProductHandlers.GetHandler("Gamepasses", gamepassInfo.ID)
	if not handler then
		warn("No handler defined for Gamepass:", stringID)
		return false
	end

	local success, err = pcall(function()
		handler(p)
	end)

	if not success then
		warn("Gamepass Handler Error:", err, "Gamepass Name:", stringID, "Player:", p)
		return false
	end

	print("Handled", stringID, "gamepass for", p)
	return true
end

MarketPlaceService.PromptGamePassPurchaseFinished:Connect(function(p, gamepassId, wasPurchased)
	if (wasPurchased) then
		-- Get the gamepass info
		local stringID, gamepassInfo = ProductDefinitions:GetGamepassFromNumericID(gamepassId)
		if not (gamepassInfo) then return end

		if (wasPurchased) then
			handleGamepass(p, stringID)
		end
	end
end)

-- // Dev products
local function processReceipt(receiptInfo)
	local playerkey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
	local purchased = false

	-- Check if already purchased
	local success, errorMessage = pcall(function()
		purchased = PurchaseHistoryStore:GetAsync(playerkey)
	end)

	if (success and purchased) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif not success then
		warn("Datastore error:", errorMessage)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Process purchase logic (outside of UpdateAsync!)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- will retry next session
	end

	local stringID, productInfo = ProductDefinitions:GetProductFromNumericID(receiptInfo.ProductId)
	local handler = ProductHandlers.GetHandler("DevProducts", receiptInfo.ProductId)

	if not handler then
		warn(receiptInfo.ProductId, "/", stringID, "has no handler function in ProductHandlers!")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local handlerSuccess, handlerError = pcall(function()
		handler(player)
	end)

	if not handlerSuccess then
		warn("Failed to process product purchase:", handlerError)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Safely record the purchase
	local recordSuccess, recordError = pcall(function()
		PurchaseHistoryStore:UpdateAsync(playerkey, function()
			return true -- only returning static value (no yields here!)
		end)
	end)

	if not recordSuccess then
		warn("Failed to record purchase:", recordError)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function onCharacterAdded(p : Player, c : Model)
	-- Handle gamepasses
	for stringID, info in ProductDefinitions.Gamepasses do
		if (MarketPlaceService:UserOwnsGamePassAsync(p.UserId, info.ID)) then
			handleGamepass(p, stringID)
		end
	end
end

local function onPlayerAdded(p : Player)
	local char = p.Character or p.CharacterAdded:Wait()
	onCharacterAdded(p, char)
	
	p.CharacterAdded:Connect(function(c : Model)
		onCharacterAdded(p, c)
	end)
end

local function initialise()
	GetMonetisationData.OnServerInvoke = function(p : Player)
		return ProductDefinitions
	end
	
	for _, p in Players:GetPlayers() do
		onPlayerAdded(p)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
end

-- Initialisation
initialise()

MarketPlaceService.ProcessReceipt = processReceipt