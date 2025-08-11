--!strict
local CurrencyConfig : { Types: { [string]: Currency } } = { Types = {} }

-- // Type Defs
export type Currency = {
	Name : string,
	Symbol : string,
    DefaultValue : number?,
	RebirthMultiplier : number,
	UseLeaderstats : boolean,
	UseFriendBoost : boolean,
	Collectables : {
		{
			Name : string,
			Value : number,
			Model : Model,
			Sound : Sound,
		}
	},
	Get : ({}) -> number,
	Update : ({}, number) -> nil
}

-- // Assets
local CurrencyModels = script:WaitForChild("Models")
local CurrencySounds = script:WaitForChild("Sounds")

-- // Configuration
CurrencyConfig.Types = {
	Cash = {
        Name = "Cash",
        Symbol = "₵",
        DefaultValue = 50,
        UseFriendBoost = true,
        RebirthMultiplier = 1.25,
        UseLeaderstats = true,
        Collectables = {
            [1] = {
                Name = "Coin",
                Value = 1,
                Model = CurrencyModels:WaitForChild("Coin"),
                Sound = CurrencySounds:WaitForChild("CoinPickup"),
            },
        },
        Get = function(profile : any): number
            return profile.Data.Stats.Cash or 0
        end,
        Update = function(profile : any, amount : number)
            profile.Data.Stats.Cash += amount
        end,
	},
	Rebirths = {
        Name = "Rebirths",
        Symbol = "♻️",
        DefaultValue = 1,
        UseFriendBoost = true,
        RebirthMultiplier = 1.25,
        UseLeaderstats = true,
        Collectables = {
            [1] = {
                Name = "Rebirth",
                Value = 1,
                Model = CurrencyModels:WaitForChild("Coin"),
                Sound = CurrencySounds:WaitForChild("CoinPickup"),
            },
        },
        Get = function(profile : any): number
            return profile.Data.Stats.Rebirths or 0
        end,
        Update = function(profile : any, amount: number)
            profile.Data.Stats.Rebirths += amount
        end,
	},
}

-- // Public API
function CurrencyConfig:GetCurrencyFromID(currencyID : string): Currency?
    if not (currencyID and CurrencyConfig.Types[currencyID]) then return nil end
    return CurrencyConfig.Types[currencyID]
end

function CurrencyConfig:GetCurrencyText(currencyID : string, amount : number): string
    if not (currencyID and amount) then return "" end
    
    local text = tostring(amount)

    -- Check if this stat has its own currency type
    local currencyInfo = self:GetCurrencyFromID(currencyID)
    if (currencyInfo) then
        local symbol = currencyInfo.Symbol
        local name = currencyInfo.Name

        if (symbol) then
            text = string.format("%s%s", symbol, text)
        else
            text = string.format("%s %s", text, name)
        end
    end

    return text
end

return CurrencyConfig