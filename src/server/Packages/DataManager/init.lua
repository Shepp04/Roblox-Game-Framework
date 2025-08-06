--!strict
-- Uses ProfileStore and ReplicatedData to save data and enable server/client communication

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Packages
local ProfileStore = require(script:WaitForChild("ProfileStore"))

local SharedPackages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"))
local ReplicatedData = SharedPackages.ReplicatedData

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

--// Templates
local PROFILE_TEMPLATE = Config.PROFILE_TEMPLATE
local INFO_TEMPLATE = Config.INFO_TEMPLATE

--// ProfileStore Setup
local PlayerStore = ProfileStore.New("PlayerStore", PROFILE_TEMPLATE)
local Profiles: { [Player]: Config.PlayerProfile } = {}

--// Module
local DataManager = {}

-- Deep clone utility
local function deepClone(original)
	local copy = {}
	for k, v in pairs(original) do
		if typeof(v) == "table" then
			copy[k] = deepClone(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function deepReconcile(target: {}, template: {})
	for k, v in pairs(template) do
		if typeof(v) == "table" and typeof(target[k]) == "table" then
			deepReconcile(target[k], v)
		elseif target[k] == nil then
			target[k] = v
		end
	end
end

--// Private: Called when a profile is loaded
local function onProfileLoad(player: Player, profile: Config.PlayerProfile)
	-- Initialise Info
	profile.Info = deepClone(INFO_TEMPLATE)

	-- Extra temporary values
	profile.Info.JoinTime = os.time()
	profile.Info.ClaimedGifts = {}

	-- Analytics
	profile.Data.Analytics.TotalLogins += 1

	-- Save join time locally for playtime calc
	profile.Info.JoinTime = os.time()

	-- Replicate to client
	ReplicatedData:SetData("PlayerData", profile.Data, { player })
	ReplicatedData:SetData("PlayerInfo", profile.Info, { player })
	ReplicatedData:SetData("Stats", profile.Data.Stats, { player })
end

--// Public API

function DataManager:GetPlayerProfile(player: Player, yield: boolean?): Config.PlayerProfile?
	if Profiles[player] then return Profiles[player] end

	if yield then
		repeat task.wait(0.1)
		until not player.Parent or Profiles[player]
	end

	return Profiles[player]
end

function DataManager:GetPlayerData(player: Player, yield: boolean?): {}?
	local profile = self:GetPlayerProfile(player, yield)
	return profile and profile.Data or nil
end

function DataManager:ResetData(player: Player): boolean
	local profile = self:GetPlayerProfile(player)
	if not profile then return false end

	profile.Data = {}
	profile:Reconcile()
	onProfileLoad(player, profile)

	profile.Data.Stats.Cash = 99999999 -- dev override
	warn("Reset data for", player)
	return true
end

--// Modular Support: Reconcile a new section into existing data
function DataManager:ReconcileProfileSection(player: Player, sectionType: "Info" | "Data", sectionName: string, template: {}): boolean
	local profile = self:GetPlayerProfile(player)
	if not profile then return false end

	if sectionType == "Info" then
		profile.Info[sectionName] = profile.Info[sectionName] or {}
		deepReconcile(profile.Info[sectionName], template)
		ReplicatedData:SetData("PlayerInfo", profile.Info, { player })

	elseif sectionType == "Data" then
		profile.Data[sectionName] = profile.Data[sectionName] or {}
		deepReconcile(profile.Data[sectionName], template)
		ReplicatedData:SetData("PlayerData", profile.Data, { player })
	end

	return true
end

--// Events

function DataManager:LoadPlayerProfile(player: Player): Config.PlayerProfile?
	local profile = PlayerStore:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return not player:IsDescendantOf(Players)
		end,
	})

	if not profile then
		player:Kick("Profile load failed. Please rejoin.")
		return nil
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("Profile session ended. Please rejoin.")
	end)

	if player:IsDescendantOf(Players) then
		onProfileLoad(player, profile)
		Profiles[player] = profile
		return profile
	else
		profile:EndSession()
	end

	return nil
end

function DataManager:ReleasePlayerProfile(player: Player)
	local profile = Profiles[player]
	if profile then
		profile.Data.Analytics.LastLeaveTime = os.time()
		profile:EndSession()
	end
end

return DataManager