--!strict
--// Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--// Config
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local TAG_TYPE = Config.NAMETAGS.DefaultType

--// Player
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()

--// Constants
local IN_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local OUT_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local NEARBY_DISTANCE = 12

--// State
local tweens: { [BillboardGui]: { In: Tween, Out: Tween } } = {}
local lastHoveredPlayer: { Player: Player, Nametag: BillboardGui }? = nil
local lastNearbyPlayers: { { Player: Player, Nametag: BillboardGui } } = {}

--// Tween Helper
local function createTweens(gui: BillboardGui)
	local inTween = TweenService:Create(gui.Frame, IN_TWEEN_INFO, {
		GroupTransparency = 0,
		Position = UDim2.fromScale(0, 0)
	})
	local outTween = TweenService:Create(gui.Frame, OUT_TWEEN_INFO, {
		GroupTransparency = 1,
		Position = UDim2.fromScale(0, 1)
	})
	tweens[gui] = { In = inTween, Out = outTween }
	return tweens[gui]
end

local function showNametag(gui: BillboardGui)
	if TAG_TYPE == "None" then return end
	if TAG_TYPE == "Default" then return end
	if TAG_TYPE == "Modern" then
		local t = tweens[gui] or createTweens(gui)
		t.In:Play()
	end
end

local function hideNametag(gui: BillboardGui)
	if TAG_TYPE == "None" then return end
	if TAG_TYPE == "Default" then return end
	if TAG_TYPE == "Modern" then
		local t = tweens[gui] or createTweens(gui)
		t.Out:Play()
	end
end

local function initialise()
	if TAG_TYPE == "None" then return end

	-- Find the player's nametag
	local char = Player.Character or Player.CharacterAdded:Wait()
	if (char) then
		-- Hide the tag initially
		local tag = char:WaitForChild("_Nametag")
		hideNametag(tag)
	end

	if UserInputService.MouseEnabled then
		UserInputService.InputChanged:Connect(function()
			local target = Mouse.Target
			local parent = target and target.Parent
			while parent and not parent:FindFirstChild("Humanoid") and parent ~= workspace do
				parent = parent.Parent
			end

			local character = parent
			local targetPlayer = character and Players:GetPlayerFromCharacter(character)
			if targetPlayer and targetPlayer ~= Player then
				local nametag = character:FindFirstChild("_Nametag") :: BillboardGui?
				if nametag then
					if not lastHoveredPlayer or lastHoveredPlayer.Player ~= targetPlayer then
						if lastHoveredPlayer then
							hideNametag(lastHoveredPlayer.Nametag)
						end
						showNametag(nametag)
						lastHoveredPlayer = { Player = targetPlayer, Nametag = nametag }
					end
				end
			else
				if lastHoveredPlayer then
					hideNametag(lastHoveredPlayer.Nametag)
					lastHoveredPlayer = nil
				end
			end
		end)
	else
		RunService.RenderStepped:Connect(function()
			local updatedNearby = {}

			for _, otherPlayer in Players:GetPlayers() do
				if otherPlayer == Player then continue end

				local char = otherPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and Player.Character then
					local dist = Player:DistanceFromCharacter(root.Position)
					if dist < NEARBY_DISTANCE then
						local nametag = char:FindFirstChild("_Nametag") :: BillboardGui?
						if nametag then
							local alreadyVisible = false
							for _, info in lastNearbyPlayers do
								if info.Player == otherPlayer then
									alreadyVisible = true
									break
								end
							end
							if not alreadyVisible then
								showNametag(nametag)
							end
							table.insert(updatedNearby, { Player = otherPlayer, Nametag = nametag })
						end
					end
				end
			end

			for _, previous in lastNearbyPlayers do
				local stillNearby = false
				for _, current in updatedNearby do
					if current.Player == previous.Player then
						stillNearby = true
						break
					end
				end
				if not stillNearby then
					hideNametag(previous.Nametag)
				end
			end

			lastNearbyPlayers = updatedNearby
		end)
	end

	-- Hide all nametags initially
	for _, v in CollectionService:GetTagged("_Nametag") do
		if (v.Parent:FindFirstChild("Humanoid") and v:IsA("BillboardGui") and v.Name == "_Nametag") then
			hideNametag(v)
		end
	end

	CollectionService:GetInstanceAddedSignal("_Nametag"):Connect(function(v)
		if (v.Parent:FindFirstChild("Humanoid") and v:IsA("BillboardGui") and v.Name == "_Nametag") then
			hideNametag(v)
		end
	end)
end

-- Initialisation
initialise()
