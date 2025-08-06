--!strict

local Debounce = {}

--[[
	USAGE:
	if not Debounce:Try("key", 1) then return end
	Debounce:Reset("key")
	if Debounce:IsActive("key") then ...
]]

function Debounce:Try(key: string, delay: number, callback: (() -> ())?): boolean
	if self[key] then return false end

	self[key] = true
	task.delay(delay, function()
		self[key] = nil
		if callback then callback() end
	end)

	return true
end

function Debounce:IsActive(key: string): boolean
	return self[key] == true
end

function Debounce:Reset(key: string)
	self[key] = nil
end

function Debounce:ClearAll()
	for k in pairs(self) do
		self[k] = nil
	end
end

return Debounce