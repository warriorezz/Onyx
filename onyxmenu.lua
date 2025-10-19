-- Arsenal Hack Menu - Fixed Version
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Config = {
    ESP = false,
    AimbotEnabled = false,
    FOV = 50,
    ShowFOV = true,
    InfiniteAmmo = false,
    NoRecoil = false,
    RainbowWeapons = false
}

local ESPHandles = {}
local AimbotTarget = nil
local RightMouseDown = false
local FOVCircle = nil
local RainbowConnection = nil
local MenuVisible = true
local GUI = nil
local MainFrame = nil
local CurrentTab = "Player"

-- Śledzenie prawego przycisku myszy
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightMouseDown = true
    end
    
    -- Toggle menu na klawisz K
    if input.KeyCode == Enum.KeyCode.K then
        ToggleMenu()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightMouseDown = false
        AimbotTarget = nil
    end
end)

-- Toggle menu function
function ToggleMenu()
    if not GUI then
        CreateGUI()
        return
    end
    
    MenuVisible = not MenuVisible
    GUI.Enabled = MenuVisible
    
    if MenuVisible then
        UserInputService.MouseIconEnabled = true
    else
        UserInputService.MouseIconEnabled = true
    end
end

-- FOV Circle na środku celownika
function CreateFOVCircle()
    if FOVCircle then
        FOVCircle:Destroy()
        FOVCircle = nil
    end
    
    if not Config.ShowFOV or not Config.AimbotEnabled then return end
    
    local circleGui = Instance.new("ScreenGui")
    circleGui.Name = "FOVCircle"
    circleGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    circleGui.ResetOnSpawn = false
    circleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local outerCircle = Instance.new("Frame")
    outerCircle.Size = UDim2.new(0, Config.FOV * 4, 0, Config.FOV * 4)
    outerCircle.Position = UDim2.new(0.5, -Config.FOV * 2, 0.5, -Config.FOV * 2)
    outerCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    outerCircle.BackgroundTransparency = 0.8
    outerCircle.BorderSizePixel = 0
    outerCircle.Parent = circleGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = outerCircle
    
    FOVCircle = circleGui
end

function UpdateFOVCircle()
    if Config.ShowFOV and Config.AimbotEnabled then
        if not FOVCircle then
            CreateFOVCircle()
        else
            local frame = FOVCircle:FindFirstChildOfClass("Frame")
            if frame then
                frame.Size = UDim2.new(0, Config.FOV * 4, 0, Config.FOV * 4)
                frame.Position = UDim2.new(0.5, -Config.FOV * 2, 0.5, -Config.FOV * 2)
                
                if RightMouseDown and AimbotTarget then
                    frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    frame.BackgroundTransparency = 0.7
                else
                    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    frame.BackgroundTransparency = 0.8
                end
            end
        end
    elseif FOVCircle then
        FOVCircle:Destroy()
        FOVCircle = nil
    end
end

-- Funkcje broni
function WeaponHacks()
    if Config.InfiniteAmmo and LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                for _, v in pairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") and (string.lower(v.Name):find("ammo") or string.lower(v.Name):find("clip")) then
                        v.Value = 999
                    end
                end
            end
        end
    end
    
    if Config.NoRecoil and LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                for _, v in pairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") and (string.lower(v.Name):find("recoil") or string.lower(v.Name):find("shake")) then
                        v.Value = 0
                    end
                end
            end
        end
    end
end

-- Rainbow Weapons
function RainbowWeapons()
    if Config.RainbowWeapons then
        if not RainbowConnection then
            RainbowConnection = RunService.Heartbeat:Connect(function()
                if LocalPlayer.Character then
                    local hue = tick() % 1
                    local color = Color3.fromHSV(hue, 1, 1)
                    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
                        if tool:IsA("Tool") then
                            for _, part in pairs(tool:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.Color = color
                                    part.Material = EnumMaterial.Neon
                                end
                            end
                        end
                    end
                end
            end)
        end
    else
        if RainbowConnection then
            RainbowConnection:Disconnect()
            RainbowConnection = nil
        end
    end
end

-- Prostsze wykrywanie wrogów przed sobą
function GetClosestEnemyInFront()
    if not LocalPlayer.Character then return nil end
    
    local camera = workspace.CurrentCamera
    local cameraPos = camera.CFrame.Position
    local cameraLook = camera.CFrame.LookVector
    
    local closest = nil
    local closestAngle = math.rad(Config.FOV / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and (not player.Team or player.Team ~= LocalPlayer.Team) then
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            
            if head and humanoid and humanoid.Health > 0 then
                local headPos = head.Position
                local toHead = (headPos - cameraPos).Unit
                
                local dotProduct = cameraLook:Dot(toHead)
                local angle = math.acos(math.clamp(dotProduct, -1, 1))
                
                local distance = (headPos - cameraPos).Magnitude
                
                if angle <= closestAngle and distance < 100 then
                    closestAngle = angle
                    closest = player
                end
            end
        end
    end
    
    return closest
end

-- Aimbot aktywowany prawym przyciskiem
function RightClickAimbot()
    if not Config.AimbotEnabled or not LocalPlayer.Character then 
        AimbotTarget = nil
        UpdateFOVCircle()
        return 
    end
    
    if not RightMouseDown then
        AimbotTarget = nil
        UpdateFOVCircle()
        return
    end
    
    local closest = GetClosestEnemyInFront()
    if not closest then 
        AimbotTarget = nil
        UpdateFOVCircle()
        return 
    end
    
    AimbotTarget = closest
    
    local targetHead = closest.Character:FindFirstChild("Head")
    local camera = workspace.CurrentCamera
    
    if targetHead and camera then
        camera.CFrame = CFrame.new(camera.CFrame.Position, targetHead.Position)
    end
    
    UpdateFOVCircle()
end

-- Triggerbot - auto strzał tylko gdy celujemy
function Triggerbot()
    if not Config.AimbotEnabled or not LocalPlayer.Character or not RightMouseDown then return end
    
    local target = AimbotTarget or GetClosestEnemyInFront()
    if target and target.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        end
    end
end

-- Simple ESP
function CreateSimpleESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and (not player.Team or player.Team ~= LocalPlayer.Team) then
            if not ESPHandles[player] then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ESP"
                highlight.Adornee = player.Character
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.7
                highlight.Parent = player.Character
                ESPHandles[player] = highlight
            end
        end
    end
end

function RemoveESP()
    for player, highlight in pairs(ESPHandles) do
        if highlight then
            highlight:Destroy()
        end
    end
    ESPHandles = {}
end

-- GUI Creation
function CreateGUI()
    GUI = Instance.new("ScreenGui")
    GUI.Name = "MainHackGUI"
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    GUI.ResetOnSpawn = false
    GUI.Enabled = true

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 300, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
    MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
    MainFrame.Parent = GUI

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar

    -- Title Text
    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(0.6, 0, 1, 0)
    TitleText.Position = UDim2.new(0, 10, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "ARSENAL HACK MENU"
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.TextSize = 16
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Font = Enum.Font.GothamBold
    TitleText.Parent = TitleBar

    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 70, 0, 25)
    CloseButton.Position = UDim2.new(1, -75, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.Text = "CLOSE (K)"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 11
    CloseButton.Font = Enum.Font.Gotham
    CloseButton.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseButton

    CloseButton.MouseButton1Click:Connect(function()
        ToggleMenu()
    end)

    -- Tabs Container
    local TabsContainer = Instance.new("Frame")
    TabsContainer.Size = UDim2.new(1, -20, 0, 30)
    TabsContainer.Position = UDim2.new(0, 10, 0, 45)
    TabsContainer.BackgroundTransparency = 1
    TabsContainer.Name = "TabsContainer"
    TabsContainer.Parent = MainFrame

    -- Tab Buttons
    local PlayerTab = CreateTabButton("PLAYER", UDim2.new(0, 0, 0, 0))
    local WeaponTab = CreateTabButton("WEAPON", UDim2.new(0.33, 0, 0, 0))
    local ESPTab = CreateTabButton("ESP", UDim2.new(0.66, 0, 0, 0))

    PlayerTab.Parent = TabsContainer
    WeaponTab.Parent = TabsContainer
    ESPTab.Parent = TabsContainer

    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -20, 1, -90)
    ContentArea.Position = UDim2.new(0, 10, 0, 85)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Name = "ContentArea"
    ContentArea.Parent = MainFrame

    -- Create tab contents
    CreatePlayerContent(ContentArea)
    CreateWeaponContent(ContentArea)
    CreateESPContent(ContentArea)

    -- Start with Player tab
    SwitchToTab("PLAYER")
end

function CreateTabButton(text, position)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.32, 0, 1, 0)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 11
    button.Font = Enum.Font.Gotham
    button.Name = text
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        SwitchToTab(text)
    end)
    
    return button
end

function CreatePlayerContent(parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Name = "PLAYERTab"
    frame.Visible = false
    frame.Parent = parent

    -- Aimbot Toggle
    local aimbotButton = CreateToggleButton("AIMBOT PRO", UDim2.new(0, 0, 0, 0), "AimbotEnabled")
    aimbotButton.Parent = frame

    -- FOV Toggle
    local fovButton = CreateToggleButton("SHOW FOV CIRCLE", UDim2.new(0, 0, 0, 40), "ShowFOV")
    fovButton.Parent = frame

    -- FOV Slider
    local FOVText = Instance.new("TextLabel")
    FOVText.Size = UDim2.new(1, 0, 0, 25)
    FOVText.Position = UDim2.new(0, 0, 0, 80)
    FOVText.BackgroundTransparency = 1
    FOVText.Text = "FOV: " .. Config.FOV
    FOVText.TextColor3 = Color3.fromRGB(255, 255, 255)
    FOVText.TextSize = 12
    FOVText.Parent = frame

    local FOVSlider = Instance.new("TextButton")
    FOVSlider.Size = UDim2.new(1, 0, 0, 30)
    FOVSlider.Position = UDim2.new(0, 0, 0, 105)
    FOVSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    FOVSlider.Text = "CHANGE FOV (50/100/150)"
    FOVSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
    FOVSlider.TextSize = 11
    FOVSlider.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = FOVSlider

    FOVSlider.MouseButton1Click:Connect(function()
        if Config.FOV == 50 then
            Config.FOV = 100
        elseif Config.FOV == 100 then
            Config.FOV = 150
        else
            Config.FOV = 50
        end
        FOVText.Text = "FOV: " .. Config.FOV
        UpdateFOVCircle()
    end)

    local Info = Instance.new("TextLabel")
    Info.Size = UDim2.new(1, 0, 0, 80)
    Info.Position = UDim2.new(0, 0, 0, 145)
    Info.BackgroundTransparency = 1
    Info.Text = "• Aimbot: Right Mouse Button\n• FOV: Circle shows aim range\n• Green = Locked on target"
    Info.TextColor3 = Color3.fromRGB(180, 180, 100)
    Info.TextSize = 10
    Info.TextWrapped = true
    Info.Parent = frame
end

function CreateWeaponContent(parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Name = "WEAPONTab"
    frame.Visible = false
    frame.Parent = parent

    local ammoButton = CreateToggleButton("INFINITE AMMO", UDim2.new(0, 0, 0, 0), "InfiniteAmmo")
    ammoButton.Parent = frame

    local recoilButton = CreateToggleButton("NO RECOIL", UDim2.new(0, 0, 0, 40), "NoRecoil")
    recoilButton.Parent = frame

    local rainbowButton = CreateToggleButton("RAINBOW WEAPONS", UDim2.new(0, 0, 0, 80), "RainbowWeapons")
    rainbowButton.Parent = frame

    local Info = Instance.new("TextLabel")
    Info.Size = UDim2.new(1, 0, 0, 100)
    Info.Position = UDim2.new(0, 0, 0, 125)
    Info.BackgroundTransparency = 1
    Info.Text = "• Infinite Ammo: Never run out\n• No Recoil: Perfect accuracy\n• Rainbow: Color changing weapons"
    Info.TextColor3 = Color3.fromRGB(180, 180, 100)
    Info.TextSize = 10
    Info.TextWrapped = true
    Info.Parent = frame
end

function CreateESPContent(parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Name = "ESPTab"
    frame.Visible = false
    frame.Parent = parent

    local espButton = CreateToggleButton("ENABLE ESP", UDim2.new(0, 0, 0, 0), "ESP")
    espButton.Parent = frame

    local Info = Instance.new("TextLabel")
    Info.Size = UDim2.new(1, 0, 0, 120)
    Info.Position = UDim2.new(0, 0, 0, 40)
    Info.BackgroundTransparency = 1
    Info.Text = "• ESP: Highlights enemies in red\n• Works automatically\n• Only shows enemy team\n• Updates in real-time"
    Info.TextColor3 = Color3.fromRGB(180, 180, 100)
    Info.TextSize = 10
    Info.TextWrapped = true
    Info.Parent = frame
end

function CreateToggleButton(text, position, configKey)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 35)
    button.Position = position
    button.BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(60, 60, 60)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    button.Font = Enum.Font.Gotham
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        button.BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(60, 60, 60)
        
        if configKey == "ESP" then
            if Config.ESP then
                CreateSimpleESP()
            else
                RemoveESP()
            end
        elseif configKey == "AimbotEnabled" or configKey == "ShowFOV" then
            UpdateFOVCircle()
        elseif configKey == "RainbowWeapons" then
            RainbowWeapons()
        end
    end)
    
    return button
end

function SwitchToTab(tabName)
    CurrentTab = tabName
    
    -- Hide all tabs
    local contentArea = MainFrame:FindFirstChild("ContentArea")
    if contentArea then
        for _, tab in pairs(contentArea:GetChildren()) do
            if tab:IsA("Frame") then
                tab.Visible = (tab.Name == tabName .. "Tab")
            end
        end
    end
    
    -- Update tab buttons
    local tabsContainer = MainFrame:FindFirstChild("TabsContainer")
    if tabsContainer then
        for _, button in pairs(tabsContainer:GetChildren()) do
            if button:IsA("TextButton") then
                button.BackgroundColor3 = (button.Name == tabName) and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(50, 50, 50)
            end
        end
    end
end

-- Main Loop
RunService.Heartbeat:Connect(function()
    RightClickAimbot()
    Triggerbot()
    WeaponHacks()
    
    if Config.ESP then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and (not player.Team or player.Team ~= LocalPlayer.Team) then
                if not ESPHandles[player] or not ESPHandles[player].Parent then
                    CreateSimpleESP()
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPHandles[player] then
        ESPHandles[player]:Destroy()
        ESPHandles[player] = nil
    end
end)

-- Initial setup - CREATE MENU IMMEDIATELY
CreateGUI()
UpdateFOVCircle()

print("Arsenal Hack Menu v5 Loaded!")
print("Menu is now visible!")
print("Press K to hide/show the menu")
