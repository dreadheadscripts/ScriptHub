-- Wait for _G.Tabs and Player tab frame
repeat task.wait() until _G and _G.Tabs and _G.Tabs.Player
local playerTabFrame = _G.Tabs.Player

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local MAX_DISTANCE = 700

-- Use saved positions or defaults (relative to Player tab frame)
local positions = _G.ScriptManiacGUI_TextPositions or {
    trackingTextPos = UDim2.new(0.5, -125, 0, 10),
    closestTextPos = UDim2.new(0.5, -125, 0, 40),
}

-- Helper to create draggable text labels inside Player tab frame
local function createDraggableText(position, color, defaultText)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 25)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.Active = true
    frame.Selectable = true
    frame.Draggable = true
    frame.Parent = playerTabFrame

    local textLabel = Instance.new("TextLabel", frame)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = color
    textLabel.TextStrokeTransparency = 0.5
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 16
    textLabel.Text = defaultText or ""
    textLabel.Visible = true

    -- Update global positions when dragged
    frame:GetPropertyChangedSignal("Position"):Connect(function()
        if defaultText == "Tracking Target" then
            positions.trackingTextPos = frame.Position
        elseif defaultText == "Closest Enemy" then
            positions.closestTextPos = frame.Position
        end
        _G.ScriptManiacGUI_TextPositions = positions
    end)

    return textLabel
end

local trackingText = createDraggableText(positions.trackingTextPos, Color3.new(0, 1, 0), "Tracking Target")
local closestText = createDraggableText(positions.closestTextPos, Color3.new(1, 1, 0), "Closest Enemy")

local espHighlights = {}
local lineToClosest = nil

local function clearAllESP()
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then
            hl:Destroy()
        end
    end
    espHighlights = {}
    if lineToClosest then
        lineToClosest.Visible = false
        lineToClosest:Remove()
        lineToClosest = nil
    end
end

local function isAlive(player)
    return player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

local function canBeDamaged(player)
    if not player or player == LocalPlayer then return false end
    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team
    if not myTeam or not theirTeam then return true end
    return myTeam ~= theirTeam
end

local function updateESP(currentTrackedTarget)
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        clearAllESP()
        trackingText.Text = "Tracking Target: None"
        closestText.Text = "Closest Enemy: None"
        return
    end

    local closestEnemy, minDist = nil, math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and canBeDamaged(player) and isAlive(player) then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myHRP.Position - hrp.Position).Magnitude
                if dist <= MAX_DISTANCE then
                    local hl = espHighlights[player]
                    if not hl or not hl.Parent then
                        if hl then hl:Destroy() end
                        hl = Instance.new("Highlight")
                        hl.Adornee = char
                        hl.FillTransparency = 1
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = playerTabFrame -- put Highlight parent here or workspace if needed
                        espHighlights[player] = hl
                    end

                    if player == currentTrackedTarget then
                        hl.OutlineColor = Color3.new(0, 1, 0) -- Green tracked
                    else
                        hl.OutlineColor = Color3.new(1, 0, 0) -- Red others
                    end

                    if dist < minDist then
                        closestEnemy = player
                        minDist = dist
                    end
                elseif espHighlights[player] then
                    espHighlights[player]:Destroy()
                    espHighlights[player] = nil
                end
            end
        elseif espHighlights[player] then
            espHighlights[player]:Destroy()
            espHighlights[player] = nil
        end
    end

    -- Closest enemy info and line
    if closestEnemy then
        closestText.Text = "Closest Enemy: " .. closestEnemy.Name .. " (" .. math.floor(minDist) .. " studs)"
        local hrp = closestEnemy.Character and closestEnemy.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local screenPos = Camera:WorldToViewportPoint(hrp.Position)
            if not lineToClosest then
                local Drawing = require(game:GetService("ReplicatedStorage"):WaitForChild("Drawing") or {}) -- fallback; you should have Drawing lib loaded
                lineToClosest = Drawing.new("Line")
                lineToClosest.Thickness = 1.5
                lineToClosest.Color = Color3.new(1, 1, 0)
                lineToClosest.Transparency = 1
            end
            lineToClosest.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            lineToClosest.To = Vector2.new(screenPos.X, screenPos.Y)
            lineToClosest.Visible = screenPos.Z > 0
        end
    else
        closestText.Text = "Closest Enemy: None"
        if lineToClosest then
            lineToClosest.Visible = false
        end
    end

    trackingText.Text = "Tracking Target: " .. (currentTrackedTarget and currentTrackedTarget.Name or "None")
end

RunService.RenderStepped:Connect(function()
    local currentTrackedTarget = _G.CurrentAimbotTarget or nil
    updateESP(currentTrackedTarget)
end)
