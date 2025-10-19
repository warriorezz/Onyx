-- Arsenal Hack Menu - Fixed Hitbox Changer & Clipboard
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Config = {
    ESP = false,
    ShowNames = true,
    ShowDistance = true,
    AimbotEnabled = false,
    FOV = 50,
    ShowFOV = true,
    InfiniteAmmo = false,
    NoRecoil = false,
    RainbowWeapons = false,
    HitboxChanger = false
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
local OriginalHitboxes = {}

-- Variables for dragging
local dragging = false
local dragInput, dragStart, startPos

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
end

-- Quit function - completely remove everything
function QuitHacks()
    -- Remove GUI
    if GUI then
        GUI:Destroy()
        GUI = nil
    end
    
    -- Remove FOV Circle
    if FOVCircle then
        FOVCircle:Destroy()
        FOVCircle = nil
    end
    
    -- Remove ESP
    RemoveESP()
    
    -- Stop Rainbow Weapons
    if RainbowConnection then
        RainbowConnection:Disconnect()
        RainbowConnection = nil
    end
    
    -- Restore original hitboxes
    RestoreHitboxes()
    
    -- Reset all config
    Config.ESP = false
    Config.ShowNames = true
    Config.ShowDistance = true
    Config.AimbotEnabled = false
    Config.ShowFOV = false
    Config.InfiniteAmmo = false
    Config.NoRecoil = false
    Config.RainbowWeapons = false
    Config.HitboxChanger = false
    
    print("All hacks disabled and menu closed!")
end

-- Hitbox Changer Functions - POPRAWIONE
function ApplyHitboxChanger()
    if not Config.HitboxChanger then
        RestoreHitboxes()
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and (not player.Team or player.Team ~= LocalPlayer.Team) then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- Tylko główne części ciała które mają znaczenie dla trafień
                local hitboxParts = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}
                
                for _, partName in pairs(hitboxParts) do
                    local part = player.Character:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        -- Zapisz oryginalny rozmiar tylko raz
                        if not OriginalHitboxes[part] then
                            OriginalHitboxes[part] = {
                                Size = part.Size,
                                CanCollide = part.CanCollide
                            }
                        end
                        
                        -- Powiększ 4x tylko jeśli nie jest już powiększony
                        if part.Size == OriginalHitboxes[part].Size then
                            part.Size = part.Size * 4
                            part.CanCollide = false
                            part.Transparency = 0.7
                            part.Material = EnumMaterial.Neon
                            part.Color = Color3.fromRGB(255, 0, 255) -- Magenta kolor
                        end
                    end
                end
            end
        end
    end
end

function RestoreHitboxes()
    for part, originalData in pairs(OriginalHitboxes) do
        if part and part.Parent then
            part.Size = originalData.Size
            part.CanCollide = originalData.CanCollide
            part.Transparency = 0
            part.Material = EnumMaterial.Plastic
            part.Color = Color3.fromRGB(255, 255, 255)
        end
    end
    OriginalHitboxes = {}
end

-- Copy to clipboard function
function CopyToClipboard(text)
    local SetRBXClipboard = nil
    if setrbxclipboard then
        SetRBXClipboard = setrbxclipboard
    elseif set_clipboard then
        SetRBXClipboard = set_clipboard
    end
    
    if SetRBXClipboard then
        SetRBXClipboard(text)
        print("Link copied to clipboard: " .. text)
        return true
    else
        print("Clipboard not available. Please copy manually: " .. text)
        return false
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

-- Enhanced ESP with Names and Distance - POPRAWIONE (bez powiększania głowy)
function CreateESP(player)
    if not player.Character then return end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Remove old ESP if exists
    if ESPHandles[player] then
        if ESPHandles[player].Highlight then
            ESPHandles[player].Highlight:Destroy()
        end
        if ESPHandles[player].Billboard then
            ESPHandles[player].Billboard:Destroy()
        end
    end

    -- Create Highlight (NIE modyfikuje rozmiarów części!)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    -- Create Billboard for Name and Distance
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.Adornee = humanoidRootPart
    billboard.AlwaysOnTop = true
    billboard.Parent = humanoidRootPart

    -- Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 14
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Visible = Config.ShowNames
    nameLabel.Parent = billboard

    -- Distance Label
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextSize = 12
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Visible = Config.ShowDistance
    distanceLabel.Parent = billboard

    -- Distance update connection
    local distanceConnection = RunService.Heartbeat:Connect(function()
        if character and character.Parent and LocalPlayer.Character then
            local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if localRoot and humanoidRootPart then
                local distance = (humanoidRootPart.Position - localRoot.Position).Magnitude
                local distanceInSteps = math.floor(distance / 3) -- Convert studs to steps (approx)
                distanceLabel.Text = distanceInSteps .. " steps"
                
                -- Update visibility based on distance and settings
                if distance > 200 then
                    billboard.Enabled = false
                    highlight.Enabled = false
                else
                    billboard.Enabled = Config.ShowNames or Config.ShowDistance
                    highlight.Enabled = true
                    
                    -- Update label visibility
                    nameLabel.Visible = Config.ShowNames
                    distanceLabel.Visible = Config.ShowDistance
                end
            end
        else
            distanceConnection:Disconnect()
        end
    end)

    ESPHandles[player] = {
        Highlight = highlight,
        Billboard = billboard,
        NameLabel = nameLabel,
        DistanceLabel = distanceLabel,
        Connection = distanceConnection
    }
end

function UpdateAllESP()
    -- Update existing ESP
    for player, espData in pairs(ESPHandles) do
        if espData.NameLabel then
            espData.NameLabel.Visible = Config.ShowNames
        end
        if espData.DistanceLabel then
            espData.DistanceLabel.Visible = Config.ShowDistance
        end
        if espData.Billboard then
            espData.Billboard.Enabled = Config.ShowNames or Config.ShowDistance
        end
    end
end

function CreateSimpleESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and (not player.Team or player.Team ~= LocalPlayer.Team) then
            CreateESP(player)
        end
    end
end

function RemoveESP()
    for player, espData in pairs(ESPHandles) do
        if espData.Highlight then
            espData.Highlight:Destroy()
        end
        if espData.Billboard then
            espData.Billboard:Destroy()
        end
        if espData.Connection then
            espData.Connection:Disconnect()
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
    MainFrame.Size = UDim2.new(0, 350, 0, 450)
    MainFrame.Position = UDim2.new(0, 50, 0, 50)
    MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
    MainFrame.Parent = GUI

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    -- Title Bar - draggable area
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
    TitleText.Size = UDim2.new(0.5, 0, 1, 0)
    TitleText.Position = UDim2.new(0, 10, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "ARSENAL HACK MENU"
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.TextSize = 14
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Font = Enum.Font.GothamBold
    TitleText.Parent = TitleBar

    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 60, 0, 25)
    CloseButton.Position = UDim2.new(1, -65, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    CloseButton.Text = "HIDE (K)"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 10
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

    -- Tab Buttons - 4 kategorie
    local PlayerTab = CreateTabButton("PLAYER", UDim2.new(0, 0, 0, 0))
    local WeaponTab = CreateTabButton("WEAPON", UDim2.new(0.25, 0, 0, 0))
    local ESPTab = CreateTabButton("ESP", UDim2.new(0.5, 0, 0, 0))
    local MiscTab = CreateTabButton("MISC", UDim2.new(0.75, 0, 0, 0))

    PlayerTab.Parent = TabsContainer
    WeaponTab.Parent = TabsContainer
    ESPTab.Parent = TabsContainer
    MiscTab.Parent = TabsContainer

    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -20, 1, -120)
    ContentArea.Position = UDim2.new(0, 10, 0, 85)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Name = "ContentArea"
    ContentArea.Parent = MainFrame

    -- Create tab contents
    CreatePlayerContent(ContentArea)
    CreateWeaponContent(ContentArea)
    CreateESPContent(ContentArea)
    CreateMiscContent(ContentArea)

    -- Quit Button at bottom
    local QuitButton = Instance.new("TextButton")
    QuitButton.Size = UDim2.new(1, -20, 0, 35)
    QuitButton.Position = UDim2.new(0, 10, 1, -45)
    QuitButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    QuitButton.Text = "QUIT - DISABLE ALL HACKS"
    QuitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    QuitButton.TextSize = 12
    QuitButton.Font = Enum.Font.GothamBold
    QuitButton.Parent = MainFrame

    local QuitCorner = Instance.new("UICorner")
    QuitCorner.CornerRadius = UDim.new(0, 6)
    QuitCorner.Parent = QuitButton

    QuitButton.MouseButton1Click:Connect(function()
        QuitHacks()
    end)

    -- Start with Player tab
    SwitchToTab("PLAYER")
    
    -- Setup dragging
    SetupDragging(TitleBar)
end

-- Dragging functionality
function SetupDragging(dragFrame)
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function CreateTabButton(text, position)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.24, 0, 1, 0)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 10
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

    -- Hitbox Changer Toggle
    local hitboxButton = CreateToggleButton("HITBOX CHANGER", UDim2.new(0, 0, 0, 80), "HitboxChanger")
    hitboxButton.Parent = frame

    -- FOV Slider
    local FOVText = Instance.new("TextLabel")
    FOVText.Size = UDim2.new(1, 0, 0, 25)
    FOVText.Position = UDim2.new(0, 0, 0, 120)
    FOVText.BackgroundTransparency = 1
    FOVText.Text = "FOV: " .. Config.FOV
    FOVText.TextColor3 = Color3.fromRGB(255, 255, 255)
    FOVText.TextSize = 12
    FOVText.Parent = frame

    local FOVSlider = Instance.new("TextButton")
    FOVSlider.Size = UDim2.new(1, 0, 0, 30)
    FOVSlider.Position = UDim2.new(0, 0, 0, 145)
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
    Info.Position = UDim2.new(0, 0, 0, 185)
    Info.BackgroundTransparency = 1
    Info.Text = "• Aimbot: Right Mouse Button\n• FOV: Circle shows aim range\n• Hitbox: 4x larger hitboxes\n• Makes enemies easier to hit"
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
    Info.Size = UDim2.new(1, 0, 0, 80)
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

    -- ESP Toggle
    local espButton = CreateToggleButton("ENABLE ESP", UDim2.new(0, 0, 0, 0), "ESP")
    espButton.Parent = frame

    -- Show Names Toggle
    local namesButton = CreateToggleButton("SHOW NAMES", UDim2.new(0, 0, 0, 40), "ShowNames")
    namesButton.Parent = frame

    -- Show Distance Toggle
    local distanceButton = CreateToggleButton("SHOW DISTANCE", UDim2.new(0, 0, 0, 80), "ShowDistance")
    distanceButton.Parent = frame

    local Info = Instance.new("TextLabel")
    Info.Size = UDim2.new(1, 0, 0, 100)
    Info.Position = UDim2.new(0, 0, 0, 125)
    Info.BackgroundTransparency = 1
    Info.Text = "• ESP: Highlights enemies in red\n• Names: Shows player names\n• Distance: Shows distance in steps\n• Works up to 200 steps away"
    Info.TextColor3 = Color3.fromRGB(180, 180, 100)
    Info.TextSize = 10
    Info.TextWrapped = true
    Info.Parent = frame
end

function CreateMiscContent(parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Name = "MISCTab"
    frame.Visible = false
    frame.Parent = parent

    -- Discord Button
    local discordButton = Instance.new("TextButton")
    discordButton.Size = UDim2.new(1, 0, 0, 80)
    discordButton.Position = UDim2.new(0, 0, 0, 0)
    discordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- Discord color
    discordButton.Text = "Join Discord Server\n\nJoin the Onyx Discord server"
    discordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordButton.TextSize = 12
    discordButton.TextWrapped = true
    discordButton.Font = Enum.Font.GothamBold
    discordButton.Parent = frame

    local discordCorner = Instance.new("UICorner")
    discordCorner.CornerRadius = UDim.new(0, 8)
    discordCorner.Parent = discordButton

    discordButton.MouseButton1Click:Connect(function()
        local discordLink = "https://discord.gg/MWqRMDZnnF"
        if CopyToClipboard(discordLink) then
            -- Pokaz potwierdzenie
            local originalText = discordButton.Text
            discordButton.Text = "LINK COPIED!\nPaste in browser"
            discordButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            
            wait(2)
            
            discordButton.Text = originalText
            discordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        end
    end)

    local Info = Instance.new("TextLabel")
    Info.Size = UDim2.new(1, 0, 0, 120)
    Info.Position = UDim2.new(0, 0, 0, 90)
    Info.BackgroundTransparency = 1
    Info.Text = "• Join our Discord community!\n• Get support and updates\n• Share your experience\n• Report bugs and issues\n• Connect with other users"
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
        button.BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(60, 60, 
