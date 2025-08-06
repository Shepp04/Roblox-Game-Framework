--!strict
-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketPlaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

-- // Packages
local SharedPackages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"))
local Remotes = SharedPackages.Remotes	

-- // Remotes
local PromptSaleRemote : RemoteEvent = Remotes:GetRemote("RemoteEvent", "PromptSale")

-- // Type Defs
export type DevProduct = {
    Category: string,
    ID: number,
    DisplayName: string,
    CurrencyID: string?,
    Amount: number?,
    Image: string?,
    Description: string?,
    PriceInRobux: number?,
}

export type Gamepass = {
    ID: number,
    DisplayName: string,
    Image: string?,
}

-- // Data
local ProductDefinitions = {}

ProductDefinitions = {
	DevProducts = {
		CurrencyPack1 = {
			Category = "Currency",
			ID = 3336725329,
			DisplayName = "Tiny Currency Pack",
			CurrencyID = "Cash",
			Amount = 10000,
		},
		CurrencyPack2 = {
			Category = "Currency",
			ID = 3336725326,
			DisplayName = "Small Currency Pack",
			CurrencyID = "Cash",
			Amount = 45000,
		},
		CurrencyPack3 = {
			Category = "Currency",
			ID = 3336725324,
			DisplayName = "Medium Currency Pack",
			CurrencyID = "Cash",
			Amount = 80000,
		},
		CurrencyPack4 = {
			Category = "Currency",
			ID = 3336725327,
			DisplayName = "Big Currency Pack",
			CurrencyID = "Cash",
			Amount = 250000,
		},
		CurrencyPack5 = {
			Category = "Currency",
			ID = 3336725330,
			DisplayName = "Huge Currency Pack",
			CurrencyID = "Cash",
			Amount = 600000,
		},
		CurrencyPack6 = {
			Category = "Currency",
			ID = 3336725328,
			DisplayName = "Massive Currency Pack",
			CurrencyID = "Cash",
			Amount = 1200000,
		},
	} :: { [string]: DevProduct };
	Gamepasses = {
		DoubleCash = {
			ID = 1321344434,
			DisplayName = "💰2X Cash💰",
			Image = nil,
		};
		GravityCoil = {
			ID = 1320712608,
			DisplayName = "🚀Gravity Coil🚀",
			Image = nil,
		};
		SpeedCoil = {
			ID = 1320622677,
			DisplayName = "💨Speed Coil💨",
			Image = nil,
		};
	} :: { [string]: Gamepass };
}

-- // Helpers
local function loadProductInfo(productID: number, infoType: Enum.InfoType)
	local success, result = pcall(function()
		return MarketPlaceService:GetProductInfo(productID, infoType)
	end)
	if success and result then
		return {
			PriceInRobux = result.PriceInRobux,
			Image = "rbxassetid://" .. result.IconImageAssetId,
			Description = result.Description,
		}
	end
	return {
		PriceInRobux = 0,
		Image = "",
		Description = "",
	}
end

-- // Private Functions
local function showOverlay(p : Player)
	local playerGui = p:FindFirstChild("PlayerGui")
	if (playerGui) then
		local old = playerGui:FindFirstChild("MonetisationOverlay")
		if (old) then return end
		
		local overlayGui = script.MonetisationOverlay:Clone()
		overlayGui.Parent = playerGui
	end
end

local function hideOverlay(p : Player)
	local playerGui = p:FindFirstChild("PlayerGui")
	local overlayGui = playerGui and playerGui:FindFirstChild("MonetisationOverlay")
	if (overlayGui) then
		task.spawn(function()
			for _, v in overlayGui:GetChildren() do
				if (v:IsA("CanvasGroup")) then
					for i = 0, 1, 0.05 do
						v.GroupTransparency = i
						task.wait()
					end
				end
			end
			overlayGui:Destroy()
		end)
	end
end

local function getAmountFromCurrencyProduct(stringID : string): number
	local productInfo = ProductDefinitions.DevProducts[stringID]
	local baseAmount = productInfo and productInfo.Amount
	if not (baseAmount) then
		warn("PRODUCT DEFINITION ERROR: No product exists named", stringID, "or it doesn't contain a property named Amount")
		return 0
	end
	
	local amount = baseAmount

	-- TODO: Apply scaling here
	
	return amount
end

-- // Public API
function ProductDefinitions:PromptSale(productType: "Gamepass" | "DevProduct", productID: number, p: Player?)
	if not p then
		if RunService:IsServer() then
			warn("Product Sale Error: Prompting sale from server without player")
			return
		end
		p = Players.LocalPlayer
	end

	showOverlay(p)

	local function cleanupConnection(signal: RBXScriptSignal)
		local con
		con = signal:Connect(function()
			hideOverlay(p)
			con:Disconnect()
		end)
	end

	if productType == "Gamepass" then
		MarketPlaceService:PromptGamePassPurchase(p, productID)
		cleanupConnection(MarketPlaceService.PromptGamePassPurchaseFinished)
	else
		MarketPlaceService:PromptProductPurchase(p, productID)
		cleanupConnection(MarketPlaceService.PromptProductPurchaseFinished)
	end
end

function ProductDefinitions:GetSortedCurrencyProducts(currencyID: string): { string }
	local productList = {}
	for stringID, info in ProductDefinitions.DevProducts do
		if info.CurrencyID == currencyID then
			table.insert(productList, { StringID = stringID, Amount = info.Amount or 0 })
		end
	end
	table.sort(productList, function(a, b)
		return a.Amount < b.Amount
	end)
	local result = {}
	for _, entry in productList do
		table.insert(result, entry.StringID)
	end
	return result
end

function ProductDefinitions:GetSmallestRequiredCurrencyPack(currencyID : string, amountRequired : number): string?
	-- Get an array of applicable products
	-- Also track the biggest currency pack for this currency
	local productArray = {}
	local biggestCurrencyPack = nil
	for stringID, info in ProductDefinitions.DevProducts do
		if (info.Category == "Currency" and info.CurrencyID == currencyID) then
			-- Get the amount of currency this gives
			local amount = getAmountFromCurrencyProduct(stringID)
			if not (amount) then continue end
			
			if (not biggestCurrencyPack) or (biggestCurrencyPack.Amount < amount) then
				biggestCurrencyPack = {Amount = amount, StringID = stringID}
			end
			
			if (amount < amountRequired) then continue end
			
			table.insert(productArray, {StringID = stringID, Info = info, Amount = amount})
		end
	end
	
	-- Get the smallest pack that fits this requirement
	-- If all packs are too small, recommend the biggest pack
	table.sort(productArray, function(a, b)
		return a.Amount < b.Amount
	end)
	
	if (#productArray == 0) then
		return biggestCurrencyPack and biggestCurrencyPack.StringID or "nil"
	end

	local stringID = #productArray > 0 and productArray[1].StringID or "nil"
	return stringID
end

function ProductDefinitions:GetGamepassFromNumericID(gamepassID : number): (string?, Gamepass?)
	for stringID, info in pairs(ProductDefinitions.Gamepasses) do
		if info.ID == gamepassID then
			return stringID, info
		end
	end
	warn("No gamepass with gamepass ID:", gamepassID)
	return nil
end

function ProductDefinitions:GetProductFromNumericID(productID : number): (string?, DevProduct?)
	for stringID, info in pairs(ProductDefinitions.DevProducts) do
		if info.ID == productID then
			return stringID, info
		end
	end
	warn("No product with product ID:", productID)
	return nil
end

local function initialise()
	for _, info in ProductDefinitions.Gamepasses do
		local data = loadProductInfo(info.ID, Enum.InfoType.GamePass)
		info.PriceInRobux = data.PriceInRobux
		info.Image = data.Image
	end

	for _, info in ProductDefinitions.DevProducts do
		local data = loadProductInfo(info.ID, Enum.InfoType.Product)
		info.PriceInRobux = data.PriceInRobux
		info.Image = data.Image
		info.Description = data.Description
	end

	if RunService:IsClient() then
		MarketPlaceService.PromptGamePassPurchaseFinished:Connect(function()
			hideOverlay()
		end)
		MarketPlaceService.PromptProductPurchaseFinished:Connect(function()
			hideOverlay()
		end)
	else
		PromptSaleRemote.OnServerEvent:Connect(function(p, t, id)
			ProductDefinitions:PromptSale(t, id, p)
		end)
	end
end

-- Initialisation
initialise()

return ProductDefinitions