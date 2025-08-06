--!strict
-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- // Packages
local Remotes = require('../Remotes')
local Debounce = require('../Debounce')

-- // Remotes
local DropCurrencyRemote = Remotes:GetRemote("RemoteEvent", "DropCurrency")

-- // Config
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local CollectableCurrency = {}

local player = Players.LocalPlayer

-- // Assets
local ValueGui = script:WaitForChild("ValueGui")
ValueGui.Enabled = false

-- // Constants
local maxCollectables = 10

function CollectableCurrency:DropCurrency(currencyID : string, value : number)
	-- Check that the value is not <= 0
	if (value <= 0) then return end

	-- Divide this value into different currency drops of this type
	local currencyInfo = Config.CURRENCY:GetCurrencyFromID(currencyID)
	local list = currencyInfo and currencyInfo.Collectables
	if not (list) then warn("No collectables for currency:", currencyID) return end

	table.sort(list, function(a, b)
		return a.Value > b.Value
	end)

	-- Create a value billboard gui
	local gui = ValueGui:Clone()
	gui.Enabled = true
	gui.Adornee = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	gui:SetAttribute("Value", 0)

	local frame = gui.Currencies:FindFirstChild(currencyID)
	if not (frame) then
		frame = gui.Currencies.Default
	end

	for _, v in gui.Currencies:GetChildren() do
		if v:IsA("Frame") then
			v.Visible = v == frame
		end
	end

	frame.Button.Amount.Text = "0"
	gui.Parent = workspace:FindFirstChild("Temp") or workspace

	if (currencyID == "XP") then
		maxCollectables = 5
		gui.Enabled = false
	end

	local amountRemaining = value
	local drops = {}
	while (amountRemaining > 0 and #drops < maxCollectables) do
		local selectedCollectable = list[#list] -- Default
		for i = 1, #list do
			if (amountRemaining > list[i].Value) then
				selectedCollectable = list[i]
				break
			end
		end
		table.insert(drops, selectedCollectable)
		amountRemaining -= selectedCollectable.Value
		task.wait()
	end

	-- Haptic Service
	-- hapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 1)

	-- Drop the drops
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")
	for i, v in drops do
		local model = v.Model:Clone()
		model:PivotTo(root.CFrame * CFrame.new(math.random(-10, 10), 0, math.random(-10, 10)))
		
		if not (model.PrimaryPart) then
			warn("The collectable currency model", model, "needs a primary part!")
			continue
		end
		
		for _, v in model:GetDescendants() do
			if v:IsA("BasePart") then
				v.CollisionGroup = "Collectables"
			end
		end

		model.Parent = workspace:FindFirstChild("Temp") or workspace

		local clone = v.Sound:Clone()
		clone.Parent = model
		clone:Play()

		Debris:AddItem(model, 2.5)
		Debris:AddItem(clone, 2)
		task.wait(((1 - (i / #drops)) ^ 2) * .3)

		if not (currencyID == "XP") then
			task.delay(0.2, function()
				local tween = TweenService:Create(
					model.PrimaryPart, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
					{CFrame = root.CFrame, Size = Vector3.new(0, 0, 0), Transparency = 1}
				)
				tween:Play()

				local billboardGui = model:FindFirstChildOfClass("BillboardGui")
					or model.PrimaryPart:FindFirstChildOfClass("BillboardGui")
				if (billboardGui) then
					billboardGui.Enabled = true
					TweenService:Create(
						billboardGui,
						TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
						{Size = UDim2.fromScale(0.01, 0.01), Enabled = false}
					):Play()
				end
                
				local newValue = value * (i / #drops)
				local text = Config.CURRENCY:GetCurrencyText(currencyID, newValue)
				if (text) then
					frame.Button.Amount.Text = "+" .. text
				end
			end)
		else
			local billboardGui = model:FindFirstChildOfClass("BillboardGui")
				or model.PrimaryPart:FindFirstChildOfClass("BillboardGui")
			if (billboardGui) then
				billboardGui.Enabled = false
			end
		end
	end

	-- hapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0)	

	-- Fade out the GUI
	task.wait(2.0)
	for i = 0, 1, 0.05 do
		gui.Currencies.GroupTransparency = i
		task.wait()
	end
	gui:Destroy()
end

DropCurrencyRemote.OnClientEvent:Connect(function(...)
	CollectableCurrency:DropCurrency(...)
end)

return CollectableCurrency