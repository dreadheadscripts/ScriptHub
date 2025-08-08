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

-- Create ESP toggle button (like Aimbot button style)local toggleBtn = Instance.new("TextButton")local espOn = true
-- ESP toggle state (default OFF)
local espOn = false

-- ESP Button
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1, 0, 0, 35)
espButton.Position = UDim2.new(0, 0, 0, 10)
espButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- Gray for OFF
espButton.TextColor3 = Color3.new(1, 1, 1)
espButton.Font = Enum.Font.GothamBold
espButton.TextSize = 18
espButton.Text = "ESP: Off"
espButton.Parent = _G.Tabs.Player

-- Rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = espButton

-- Toggle logic
espButton.MouseButton1Click:Connect(function()
    espOn = not espOn
    espButton.Text = "ESP: " .. (espOn and "On" or "Off")
    espButton.BackgroundColor3 = espOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(80, 80, 80)

    if not espOn then
        ClearESP()
    end
end)

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
