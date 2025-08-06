--!strict
local UI = {}

-- // Paths
UI.Messages = require(script.Messages)

-- // Services
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- // Assets
local MenuBlur = Instance.new("BlurEffect")
MenuBlur.Name = "MenuBlur"
MenuBlur.Size = 0
MenuBlur.Parent = Lighting
MenuBlur.Enabled = false

-- // Constants
UI.DefaultProperties = {
    BlurSize = 10,
    FOV = 70,
    TweenDuration = 0.2,
}

-- // Utils
function UI:ToggleFOV(state : boolean, fov : number?)
    if (not fov) then
        fov = UI.DefaultProperties.FOV
    end
    if (state) then
        TweenService:Create(
            game.Workspace.CurrentCamera,
            TweenInfo.new(UI.DefaultProperties.TweenDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {FieldOfView = fov}
        ):Play()
    else
        TweenService:Create(
            game.Workspace.CurrentCamera,
            TweenInfo.new(UI.DefaultProperties.TweenDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {FieldOfView = UI.DefaultProperties.FOV}
        ):Play()
    end
end

function UI:ToggleBlur(state : boolean)
    if (MenuBlur.Enabled == state) then return end
    MenuBlur.Enabled = state
    if (state) then
        MenuBlur.Size = 0
        MenuBlur.Enabled = true
        TweenService:Create(
            MenuBlur,
            TweenInfo.new(UI.DefaultProperties.TweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UI.DefaultProperties.BlurSize}
        ):Play()
    else
        TweenService:Create(
            MenuBlur,
            TweenInfo.new(UI.DefaultProperties.TweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = 0}
        ):Play()
        task.delay(UI.DefaultProperties.TweenDuration, function()
            if (MenuBlur.Size == 0) then
                MenuBlur.Enabled = false
            end
        end)
    end
end

function UI:CloseMenu(menu : CanvasGroup | Frame, affectBlur : boolean?, affectFOV : boolean?)
    if not (menu:IsA("Frame") or menu:IsA("CanvasGroup")) then
        return
    end

    if (not menu.Visible) then
        return
    end
    if not (menu.Visible) then
        return
    end
    TweenService:Create(
        menu,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 1, 0)}
    ):Play()
    task.delay(0.5, function()
        if (menu.Position.Y.Scale == 1) then
            menu.Visible = false
        end
    end)

    if (not affectBlur or affectBlur == true) then
        UI:ToggleBlur(false)
    end

    if (not affectFOV or affectFOV == true) then
        UI:ToggleFOV(false)
    end
end

function UI:OpenMenu(menu : CanvasGroup | Frame, closeOthers : boolean, affectBlur : boolean, fov : number?)
    if not (menu:IsA("Frame") or menu:IsA("CanvasGroup")) then
        return
    end
    if (menu.Visible) then
        return
    end

    if closeOthers then
        for _, v in CollectionService:GetTagged("Menu") do
            if not (v:IsA("Frame") or v:IsA("CanvasGroup")) then
                continue
            end
            if (v == menu) then
                continue
            end
            UI:CloseMenu(v, false)
        end
    end

    menu.Visible = true
    TweenService:Create(
        menu,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    ):Play()

    if (affectBlur == true) then
        UI:ToggleBlur(true)
    end

    if (fov) then
        UI:ToggleFOV(true, fov)
    end
end

function UI:CloseMenus()
    for _, v in CollectionService:GetTagged("Menu") do
        if not (v:IsA("Frame") or v:IsA("CanvasGroup")) then
            continue
        end
        UI:ToggleMenu(v, false, false)
    end
end

-- // Require UI Components (Client Only)
if (RunService:IsClient()) then
    local Components = {}
    for _, m in script:WaitForChild("Components"):GetChildren() do
        if (m:IsA("ModuleScript")) then
            task.spawn(function()
                Components[m.Name] = require(m)
            end)
        end
    end
end

return UI