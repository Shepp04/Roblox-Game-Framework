--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Constants
local SOUNDS_FOLDER : Folder? = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Assets"):WaitForChild("Sounds")
local DEFAULT_SOUNDS_FOLDER : Folder = script:WaitForChild("DefaultSounds")
local IS_SERVER = RunService:IsServer()
local LOCAL_PLAYER = not IS_SERVER and Players.LocalPlayer or nil

-- Assets
local ReplicatedTemp = ReplicatedStorage:FindFirstChild("ReplicatedTemp") or Instance.new("Folder")
ReplicatedTemp.Name = "ReplicatedTemp"
ReplicatedTemp.Parent = ReplicatedStorage

-- Remote creation
local function getOrCreateRemote()
	local existing = script:FindFirstChild("PlaySound")
	if existing and existing:IsA("RemoteEvent") then return existing end

	local newRemote = Instance.new("RemoteEvent")
	newRemote.Name = "PlaySound"
	newRemote.Parent = script
	return newRemote
end

-- Module
local SoundModule = {
	DefaultSounds = {},
	LoopingSoundCache = {},
	PlaySoundRemote = getOrCreateRemote(),
}

-- Helper: Clone sound from ID or object
local function cloneSound(sound)
	if typeof(sound) == "string" then
		local s = SoundModule.DefaultSounds[sound]
		if not s then
			warn("No sound found with ID:", sound)
			return nil
		end
		return s:Clone()
	elseif typeof(sound) == "Instance" and sound:IsA("Sound") then
		return sound:Clone()
	end
	return nil
end

-- Helper: Play 3D sound at CFrame or parent it to part
local function play3DSound(sound, position)
	local part = typeof(position) == "CFrame" and Instance.new("Part") or position
	if typeof(position) == "CFrame" then
		part.CFrame = position
	end

	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.Transparency = 1
	part.Name = "_SoundAnchor"
	part.Parent = workspace

	sound.RollOffMaxDistance = 150
	sound.PlayOnRemove = true
	sound.Parent = part
	part:Destroy()
end

-- Public: Play sound (one-shot)
function SoundModule:PlaySound(sound, position, playerList)
	if not sound then return end

	if IS_SERVER then
		local targetPlayers = playerList or Players:GetPlayers()

		local payload = typeof(sound) == "Instance" and sound:Clone() or sound
		if typeof(payload) == "Instance" then
			payload.Parent = ReplicatedTemp
			Debris:AddItem(payload, payload.TimeLength + 3)
		end

		for _, player in targetPlayers do
			self.PlaySoundRemote:FireClient(player, payload, position)
		end
	else
		local s = cloneSound(sound)
		if not s then return end

		if position then
			play3DSound(s, position)
		else
			s.PlayOnRemove = true
			s.Parent = workspace
			s:Destroy()
		end
	end
end

-- Public: Play looping sound (client only)
function SoundModule:PlayLoopingSound(sound, part, override, fade)
	if self.LoopingSoundCache[sound] and not override then return end

	local s = cloneSound(sound)
	if not s then return end

	s.Looped = true
	s.RollOffMaxDistance = 150
	s.Parent = part or ReplicatedTemp

	if fade then
		local vol = s.Volume
		s.Volume = 0
		s:Play()
		TweenService:Create(s, TweenInfo.new(1), { Volume = vol }):Play()
	else
		s:Play()
	end

	if self.LoopingSoundCache[sound] then
		self:StopLoopingSound(sound, false)
	end

	self.LoopingSoundCache[sound] = s
end

-- Public: Stop looping sound
function SoundModule:StopLoopingSound(sound, fade)
	local s = self.LoopingSoundCache[sound]
	if not s then return end

	self.LoopingSoundCache[sound] = nil

	if fade then
		local tween = TweenService:Create(s, TweenInfo.new(1), { Volume = 0 })
		tween:Play()
		tween.Completed:Wait()
	end

	s:Destroy()
end

-- Public: Toggle footstep audio on local player
function SoundModule:ToggleFootsteps(state)
	if IS_SERVER then return end

	local char = LOCAL_PLAYER.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local running = root and root:FindFirstChild("Running")
	if not running then return end

	if state == nil then
		state = running.Volume == 0
	end

	running.Volume = state and 0.5 or 0
end

-- Optional: Register a folder of default sounds
function SoundModule:RegisterSounds(folder)
	for _, sound in folder:GetChildren() do
		if sound:IsA("Sound") then
			self.DefaultSounds[sound.Name] = sound
		end
	end
end

-- Internal: Setup client listener
if not IS_SERVER then
	SoundModule.PlaySoundRemote.OnClientEvent:Connect(function(...)
		SoundModule:PlaySound(...)
	end)
end

local function initialise()
    -- Register default sounds
    SoundModule:RegisterSounds(DEFAULT_SOUNDS_FOLDER)

    -- Register custom sounds
    if (SOUNDS_FOLDER) then
        SoundModule:RegisterSounds(SOUNDS_FOLDER)
    else
        warn("Sounds folder not found in ReplicatedStorage.")
    end
end

-- Initialisation
initialise()

return SoundModule