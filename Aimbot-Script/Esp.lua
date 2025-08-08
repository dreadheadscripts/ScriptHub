-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local MAX_DISTANCE = 700

-- Reference to Player tab where button will go
local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then
    warn("Player tab not found in _G.Tabs")
    return
end

-- ESP state
local espOn = false
local espHighlights = {}

-- Function to clear all ESP highlights
local function ClearESP()
    for player, hl in pairs(espHighlights) do
        if hl and hl.Parent then
            hl:Destroy()
        end
        espHighlights[player] = nil
    end
end

-- Create ESP toggle button (like Aimbot button style)
local espButton = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 0, 35) -- Full width like aimbot button
toggleBtn.Position = UDim2.new(0, 0, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- Green when ON
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 18
espButton.Text = "Esp: Off"
espButton.Parent = playerTab

local corner = Instance.new("UICorner", espButton)
corner.CornerRadius = UDim.new(0, 6)

-- Helper to check if player is enemy & alive
local function canBeDamaged(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    -- Team check (if teams exist)
    if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
        return false
    end
    -- Spawn protection check
    if char:FindFirstChildOfClass("ForceField") then
        return false
    end
    return true
end

-- Function to update ESP highlights each frame
RunService.RenderStepped:Connect(function()
    if not espOn then
        ClearESP()
        return
    end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    -- Find closest enemy to highlight (for outline color logic if you want)
    local closestPlayer = nil
    local closestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if canBeDamaged(player) then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist <= MAX_DISTANCE then
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = player
                    end

                    -- Create Highlight if doesn't exist
                    if not espHighlights[player] or not espHighlights[player].Parent then
                        if espHighlights[player] then
                            espHighlights[player]:Destroy()
                        end
                        local hl = Instance.new("Highlight")
                        hl.Adornee = char
                        hl.FillTransparency = 1 -- no fill
                        hl.OutlineTransparency = 0
                        hl.OutlineColor = Color3.new(1, 0, 0) -- Red outline for all
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = playerTab -- Parent inside Player tab GUI (or gui)
                        espHighlights[player] = hl
                    end
                else
                    -- If player is too far, remove highlight if exists
                    if espHighlights[player] then
                        espHighlights[player]:Destroy()
                        espHighlights[player] = nil
                    end
                end
            end
        else
            -- Not valid target, remove highlight
            if espHighlights[player] then
                espHighlights[player]:Destroy()
                espHighlights[player] = nil
            end
        end
    end
end)

-- Toggle ESP on/off on button click
espButton.MouseButton1Click:Connect(function()
    espOn = not espOn
    espButton.Text = "Esp: " .. (espOn and "On" or "Off")
    espButton.BackgroundColor3 = espOn and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(80, 80, 80)

    if not espOn then
        ClearESP()
    end
end)

-- Cleanup ESP on player respawn
Players.PlayerRemoving:Connect(function(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    ClearESP()
end)
