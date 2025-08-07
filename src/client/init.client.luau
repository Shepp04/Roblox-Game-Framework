--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("Hello world, from client!")
print("[Requiring UI Library]")

local Packages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("Main")

local menus = mainGui:WaitForChild("Menus")
local menu1 = menus:WaitForChild("Menu1")

local button = menu1:WaitForChild("Frame"):WaitForChild("ExpandingButton")
local closeButton = menu1.Frame:WaitForChild("CloseButton")

button.Select.MouseButton1Click:Connect(function()
    if not (Packages.Debounce:Try("BUTTON_1_CLICK", 0.75)) then return end

    -- Show a message to the server
    Packages.UI.Messages:LocalMessage(
        "Hello from the client!",
        "Success",
        Color3.fromRGB(0, 255, 0),
        5
    )

    local soundID = math.random(1, 2) == 1 and "UIClick01" or "UISuccess01"
    Packages.Sounds:PlaySound(soundID)
end)

closeButton.Select.MouseButton1Click:Connect(function()
    Packages.UI:CloseMenu(menu1, true, true)
    Packages.Sounds:PlaySound("UIClick02")
end)

Packages.UI:OpenMenu(menu1, true, true, 90)