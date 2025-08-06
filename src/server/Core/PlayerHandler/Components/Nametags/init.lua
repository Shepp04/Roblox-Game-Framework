--!strict
-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- // Config
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- // Component
local Component = {}

-- // Private
local function setText(tag: BillboardGui, tagType: string, p: Player)
	local tagData = Config.NAMETAGS.Types[tagType]
	if not tagData then
		warn("Invalid Nametag Type: " .. tostring(tagType))
		return
	end

	tag.Frame.PlayerName.TextLabel.Text = tagData.PlayerNamePrefix .. p.Name .. tagData.PlayerNameSuffix
end

-- // Public
function Component:Update(p: Player): boolean
	-- Get character and important parts
	local char = p.Character
	if not char then return false end

	local human = char:FindFirstChild("Humanoid") :: Humanoid?
	local head = char:FindFirstChild("Head") :: Part?
	local root = char:FindFirstChild("HumanoidRootPart") :: Part?

	if not (human and head and root) then
		warn(`[NametagComponent] {p.Name} missing Humanoid, Head, or Root`)
		return false
	end

	-- Apply tag type
	local tagType = Config.NAMETAGS.DefaultType or "Default"
	if tagType == "None" then return false end

	local tagData = Config.NAMETAGS.Types[tagType]
	if not tagData then
		warn("Invalid Nametag Type: " .. tostring(tagType))
		return false
	end

	-- Turn off default display name
	human.NameDisplayDistance = 0

	-- Check if tag already exists
	local tag = char:FindFirstChild("_Nametag") :: BillboardGui?
	if not tag then
		tag = tagData.Gui:Clone()
		tag.Name = "_Nametag"

		-- Assign Adornee safely
		local success, err = pcall(function()
			tag.Adornee = head
		end)
		if not success then
			warn("Failed to assign Adornee for nametag:", err)
		end

		tag.Parent = char

		-- Assign a tag
		CollectionService:AddTag(tag, "_Nametag")
	end

	-- Attach animation script once
	local playerGui = p:FindFirstChild("PlayerGui")
	if playerGui and not playerGui:FindFirstChild("NametagAnimation") then
		local scriptClone = script.NametagAnimation:Clone()
		scriptClone.Name = "NametagAnimation"
		scriptClone.Parent = playerGui
	end

	setText(tag, tagType, p)

	return true
end

return Component