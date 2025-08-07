--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local MAX_DISTANCE = 700 -- ESP tracking range

--// Ensure Player tab exists
local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then return warn("Player tab not found!") end

--// Globals
local espOn = true -- Starts ON
local espDots = {}
local lineToClosest = nil

--// Create ESP Toggle Button (same style as Crosshair button, below it)
local espToggleBtn = Instance.new("TextButton")
espToggleBtn.Size = UDim2.new(0, 160, 0, 40)
espToggleBtn.Position = UDim2.new(0, 10, 0, 60) -- below crosshair button (which is at Y=10)
espToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
espToggleBtn.TextColor3 = Color3.new(1, 1, 1)
espToggleBtn.Font = Enum.Font.GothamBold
espToggleBtn.TextSize = 18
espToggleBtn.Text = "ESP: On"
espToggleBtn.Parent = playerTab

local espCorner = Instance.new("UICorner", espToggleBtn)
espCorner.CornerRadius = UDim.new(0, 6)

espToggleBtn.MouseButton1Click:Connect(function()
    espOn = not espOn
    espToggleBtn.Text = espOn and "ESP: On" or "ESP: Off"
    espToggleBtn.BackgroundColor3 = espOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(50, 50, 60)

    -- Enable/disable all highlights
    for _, hl in pairs(espDots) do
        if hl and hl:IsA("Highlight") then
            hl.Enabled = espOn
        end
    end

    if lineToClosest then
        lineToClosest.Visible = espOn
    end
end)

--// Helper functions
local function canBeDamaged(player)
    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team
    if not myTeam or not theirTeam then return true end
    return myTeam ~= theirTeam
end

local function isValidTarget(player)
    if player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    if not char:FindFirstChild("HumanoidRootPart") then return false end
    if not canBeDamaged(player) then return false end
    return true
end

--// Clear all ESP highlights and tracking line
local function clearESP()
    for _, hl in pairs(espDots) do
        if hl and hl.Parent then
            hl:Destroy()
        end
    end
    espDots = {}

    if lineToClosest then
        lineToClosest.Visible = false
        lineToClosest:Remove()
        lineToClosest = nil
    end
end

--// Main update loop
RunService.RenderStepped:Connect(function()
    if not espOn then
        clearESP()
        return
    end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        clearESP()
        return
    end

    local closestEnemy = nil
    local minDist = math.huge

    -- Clean up invalid highlights
    for player, hl in pairs(espDots) do
        if not isValidTarget(player) then
            hl:Destroy()
            espDots[player] = nil
        end
    end

    -- Iterate all players to update highlights
    for _, player in pairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myHRP.Position - hrp.Position).Magnitude
                if dist <= MAX_DISTANCE then
                    local hl = espDots[player]
                    if not hl or not hl.Parent then
                        if hl then hl:Destroy() end
                        hl = Instance.new("Highlight")
                        hl.FillTransparency = 1
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Adornee = char
                        hl.Parent = game:GetService("CoreGui")
                        espDots[player] = hl
                    end

                    -- Color Logic:
                    -- Green if player is currentAimbotTarget or currentKillAuraTarget
                    -- Yellow if closest enemy
                    -- Red otherwise

                    local isTracked = false
                    if _G.currentAimbotTarget == player or _G.currentKillAuraTarget == player then
                        isTracked = true
                    end

                    if player == closestEnemy then
                        hl.OutlineColor = Color3.fromRGB(255, 255, 0) -- yellow
                    elseif isTracked then
                        hl.OutlineColor = Color3.fromRGB(0, 255, 0) -- green
                    else
                        hl.OutlineColor = Color3.fromRGB(255, 0, 0) -- red
                    end

                    if dist < minDist then
                        closestEnemy = player
                        minDist = dist
                    end
                else
                    -- Out of range, destroy highlight if exists
                    if espDots[player] then
                        espDots[player]:Destroy()
                        espDots[player] = nil
                    end
                end
            end
        else
            -- Invalid target, destroy highlight if exists
            if espDots[player] then
                espDots[player]:Destroy()
                espDots[player] = nil
            end
        end
    end

    -- Update tracking line and text for closest enemy
    if closestEnemy then
        local hrp = closestEnemy.Character and closestEnemy.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if not lineToClosest then
                lineToClosest = Drawing.new("Line")
                lineToClosest.Thickness = 1.5
                lineToClosest.Color = Color3.fromRGB(255, 255, 0)
                lineToClosest.Transparency = 1
            end
            lineToClosest.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            lineToClosest.To = Vector2.new(screenPos.X, screenPos.Y)
            lineToClosest.Visible = espOn and onScreen
        end
    else
        if lineToClosest then
            lineToClosest.Visible = false
        end
    end
end)
