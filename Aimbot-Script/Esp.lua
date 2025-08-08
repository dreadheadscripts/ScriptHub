-- Wait for Player tab to exist
repeat task.wait() until _G and _G.Tabs and _G.Tabs.Player

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local playerTab = _G.Tabs.Player

local MAX_DISTANCE = 700
local espEnabled = true
local espHighlights = {}
local trackingLine = nil

-- ESP Toggle Button
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1, -10, 0, 40)
espButton.Position = UDim2.new(0, 5, 0, 5)
espButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
espButton.Text = "ESP: On"
espButton.TextColor3 = Color3.new(1, 1, 1)
espButton.Font = Enum.Font.GothamBold
espButton.TextSize = 16
espButton.Parent = playerTab

espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espButton.Text = espEnabled and "ESP: On" or "ESP: Off"
    espButton.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)

    -- Clear ESP when turned off
    if not espEnabled then
        for _, hl in pairs(espHighlights) do
            if hl and hl.Parent then
                hl:Destroy()
            end
        end
        espHighlights = {}
        if trackingLine then
            trackingLine.Visible = false
        end
    end
end)

-- Helper Functions
local function isAlive(player)
    return player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

local function canBeDamaged(player)
    if not player or player == LocalPlayer then return false end
    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team
    if not myTeam or not theirTeam then return true end
    return myTeam ~= theirTeam
end

-- ESP Update Loop
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end

    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local closestEnemy = nil
    local minDist = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and canBeDamaged(player) and isAlive(player) then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myHRP.Position - hrp.Position).Magnitude
                if dist <= MAX_DISTANCE then
                    -- Get or create highlight
                    local hl = espHighlights[player]
                    if not hl or not hl.Parent then
                        if hl then hl:Destroy() end
                        hl = Instance.new("Highlight")
                        hl.Adornee = char
                        hl.FillTransparency = 1
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = playerTab
                        espHighlights[player] = hl
                    end

                    -- Color coding
                    if _G.CurrentAimbotTarget == player then
                        hl.OutlineColor = Color3.new(0, 1, 0) -- Green if being tracked
                    else
                        hl.OutlineColor = Color3.new(1, 0, 0) -- Red
                    end

                    -- Find closest enemy
                    if dist < minDist then
                        closestEnemy = player
                        minDist = dist
                    end
                else
                    if espHighlights[player] then
                        espHighlights[player]:Destroy()
                        espHighlights[player] = nil
                    end
                end
            end
        elseif espHighlights[player] then
            espHighlights[player]:Destroy()
            espHighlights[player] = nil
        end
    end

    -- Update tracking line
    if closestEnemy and closestEnemy.Character and closestEnemy.Character:FindFirstChild("HumanoidRootPart") then
        local targetHRP = closestEnemy.Character.HumanoidRootPart
        local screenPos = Camera:WorldToViewportPoint(targetHRP.Position)
        if not trackingLine then
            trackingLine = Drawing.new("Line")
            trackingLine.Thickness = 2
            trackingLine.Transparency = 1
        end
        trackingLine.Color = Color3.new(1, 1, 0)
        trackingLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        trackingLine.To = Vector2.new(screenPos.X, screenPos.Y)
        trackingLine.Visible = screenPos.Z > 0
        -- Yellow highlight for closest enemy
        local closestHL = espHighlights[closestEnemy]
        if closestHL then
            closestHL.OutlineColor = Color3.new(1, 1, 0)
        end
    else
        if trackingLine then trackingLine.Visible = false end
    end
end)
