--!strict
-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataInterface = require('./DataInterface')

-- // Config
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- // Packages
local SharedPackages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"))
local CollectableCurrency = SharedPackages.Collectables
local Remotes = SharedPackages.Remotes
local UI = SharedPackages.UI

-- // Remotes
local PromoteProductRemote = Remotes:GetRemote("RemoteEvent", "PromoteProduct")

-- // Monetisation
local ProductDefinitions = require('../Monetisation/ProductDefinitions')

local CurrencyService = {}

-- // Public API
function CurrencyService:CanAfford(p : Player, currencyID : string, amount : number, promptUser : boolean?, promptPurchase : boolean?): boolean
	-- Get player data
	local profile = DataInterface:GetPlayerProfile(p)
	if not (profile) then
		warn("Currency Error: Couldn't load profile for", p)
		return false
	end

	-- Check that the currency ID is valid
	local currencyInfo = Config.CURRENCY:GetCurrencyFromID(currencyID)
	if not (currencyInfo) then return false end
	
	local balance = currencyInfo.Get(profile)
	if not (balance and typeof(balance) == "number") then
		warn("Currency Error: Couldn't get data for currency", currencyID)
		return false
	end
	
	if (balance < amount) then
		local amountRequired = amount - balance

		-- Prompt the user
		if (promptUser) then
			local text = "You need " .. Config.CURRENCY:GetCurrencyText(currencyID, amountRequired) .. " more!"
			UI.Messages:ShowMessage(p, text, "Error")
		end

		-- Prompt purchase
		local stringID = ProductDefinitions:GetSmallestRequiredCurrencyPack(currencyID, amountRequired)
		if (stringID) then
			PromoteProductRemote:FireClient(p, "DevProduct", stringID)
		end
		return false
	end
	return true
end

function CurrencyService:GiveCurrency(p : Player, currencyID : string, amount : number, useMultipliers : boolean, showDrops : boolean)
	print(p, currencyID, amount, useMultipliers, showDrops)
	-- Get player data
	local profile = DataInterface:GetPlayerProfile(p)
	if not (profile) then
		warn("Currency Error: Couldn't load profile for", p)
		return
	end
	
	-- Check that the currency ID is valid
	local currencyInfo = Config.CURRENCY:GetCurrencyFromID(currencyID)
	if not (currencyInfo) then return end
	
	-- Make sure amount is positive
	amount = math.clamp(amount, 0, math.huge)
	
	-- Apply multipliers if necessary
	if (useMultipliers) then
		local multiplier = CurrencyService:GetCurrencyMultiplier(p, currencyID) or 1.0
		amount *= multiplier
	end
	
	currencyInfo.Update(profile, math.ceil(amount))
	
	-- Replicate to leaderstats
	if (currencyInfo.UseLeaderstats) then
		local leaderstats = p:FindFirstChild("leaderstats")
		if (leaderstats) then
			local val = leaderstats:FindFirstChild(currencyID)
			if (val) then
				val.Value = currencyInfo.Get(profile)
			else
				warn("Currency Error: Couldn't find leaderstats value for", currencyID)
			end
		end
	end
	
	-- If should drop currency, drop it
	if (showDrops) then
		task.spawn(function()
			CollectableCurrency:DropCurrency(p, currencyID, math.ceil(amount))
		end)
	end
	
	print("Gave", p, amount, currencyID)
	return true -- Success
end

function CurrencyService:SpendCurrency(p : Player, currencyID : string, amount : number)
	-- Get player data
	local profile = DataInterface:GetPlayerProfile(p)
	if not (profile) then
		warn("Currency Error: Couldn't load profile for", p)
		return
	end

	-- Check that the currency ID is valid
	local currencyInfo = Config.CURRENCY:GetCurrencyFromID(currencyID)
	if not (currencyInfo) then return end
	
	-- Check that they can afford this amount
	local canAfford = CurrencyService:CanAfford(p, currencyID, amount, true)
	if not (canAfford) then
		warn("Currency Error:", p, "can't afford to spend", amount, currencyID)
		return false
	end
	
	-- Make sure amount is positive
	amount = math.clamp(amount, 0, math.huge)

	currencyInfo.Update(profile, -amount)
	
	-- Replicate to leaderstats
	if (currencyInfo.UseLeaderstats) then
		local leaderstats = p:FindFirstChild("leaderstats")
		if (leaderstats) then
			local val = leaderstats:FindFirstChild(currencyID)
			if (val) then
				val.Value = currencyInfo.Get(profile)
			else
				warn("Currency Error: Couldn't find leaderstats value for", currencyID)
			end
		end
	end
	
	print("Took", amount, currencyID, "from", p)
	return true -- Success
end

-- // Multipliers
function CurrencyService:GetCurrencyMultiplier(p : Player, currencyID : string): number
	-- Get player data and info
	local profile = DataInterface:GetPlayerProfile(p, true)
	if not (profile) then
		return 1.0
	end

	local currencyInfo = Config.CURRENCY:GetCurrencyFromID(currencyID)
	if not currencyInfo then
		warn("No currency info found for ID:", currencyID)
		return 1.0
	end

	-- Start at base x1 multiplier
	local totalBonus : number = 0.0

	-- Friend Boost (e.g. +0.05 per friend)
	if currencyInfo.UseFriendBoost then
		for _, otherPlayer in Players:GetPlayers() do
			if p ~= otherPlayer and p:IsFriendsWith(otherPlayer.UserId) then
				totalBonus += Config.FRIEND_BOOST
			end
		end
	end

	-- Gamepasses and temporary boosts (playtime, dev products, etc.)
	if profile.Info.Multipliers then
		for _, multiplierInfo in profile.Info.Multipliers do
			if multiplierInfo.CurrencyID == currencyID then
				totalBonus += (multiplierInfo.Value - 1)
			end
		end
	end

	-- Rebirths
	if profile.Data.Stats.Rebirths and profile.Data.Stats.Rebirths > 1 then
		local rebirthMult = currencyInfo.RebirthMultiplier or 1.25
		totalBonus += (profile.Data.Stats.Rebirths - 1) * rebirthMult
	end

	-- Final multiplier is always at least 1.0
	return math.max(1.0, 1.0 + totalBonus)
end

function CurrencyService:SetMultiplier(p: Player, multiplierID: string, currencyID: string, multiplier: number, duration: number?)
	-- Get player data
	local profile = DataInterface:GetPlayerProfile(p)
	if not profile then
		warn("Currency Error: Couldn't load profile for", p)
		return false
	end

	-- Check that the currency ID is valid
	local currencyInfo = Config.CURRENCY:GetCurrencyFromID(currencyID)
	if not currencyInfo then
		warn("Currency Error: Invalid currency ID", currencyID)
		return false
	end

	-- Ensure the multipliers table exists
	profile.Info.Multipliers = profile.Info.Multipliers or {}

	local currentTime = os.time()
	local endTime = (duration and (currentTime + duration)) or nil

	-- Apply or overwrite multiplier
	profile.Info.Multipliers[multiplierID] = {
		EndTime = endTime;
		Value = multiplier;
		IsPermanent = (duration == nil);
		LastUpdate = currentTime;
		CurrencyID = currencyID;
	}

	print(`[SERVER | Currency] Set multiplier '{multiplierID}' for {p.Name} x{multiplier} for {duration or "∞"} seconds`)

	-- If temporary, remove after duration
	if duration then
		task.delay(duration, function()
			local info = profile.Info.Multipliers[multiplierID]
			if info and info.LastUpdate == currentTime then
				profile.Info.Multipliers[multiplierID] = nil
				print(`[SERVER | Currency] Removed multiplier '{multiplierID}' from {p.Name} after {duration} seconds`)
			end
		end)
	end

	return true
end

-- // Player Added
local function onPlayerAdded(p : Player)
	-- Give them leaderstats
	local leaderstats = p:FindFirstChild("leaderstats")
	if not (leaderstats) then
		leaderstats = Instance.new("Folder", p)
		leaderstats.Name = "leaderstats"
	end
	
	local profile = DataInterface:GetPlayerProfile(p, true)
    if not (profile) then
        warn("Currency Error: Couldn't load profile for", p)
        return
    end

    local statsTemplate = {}
	for currencyID, currencyInfo in Config.CURRENCY.Types do
        statsTemplate[currencyID] = 0
		if not (profile and profile.Data.Stats[currencyID]) then
			profile.Data.Stats[currencyID] = 0
		end
		if (currencyInfo.UseLeaderstats) then
			local val = Instance.new("NumberValue")
			val.Name = currencyInfo.Name
			val.Value = currencyInfo.Get(profile) or 0
			val.Parent = leaderstats
		end
	end
end

-- // Setup
local function registerReconcileSections()
	-- Register all currency types for reconciliation
	-- And multipliers
	local statsTemplate = {}
	for currencyID, currencyInfo in Config.CURRENCY.Types do
        statsTemplate[currencyID] = currencyInfo.DefaultValue or 0
	end

	DataInterface:RegisterReconcileSection("Info", "Multipliers", {})
	DataInterface:RegisterReconcileSection("Data", "Stats", statsTemplate)
end

local function initialise()
	registerReconcileSections()
	for _, p in Players:GetPlayers() do
		onPlayerAdded(p)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
end

-- Initialisation
initialise()

return CurrencyService