-- esp.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local MAX_DISTANCE = 700

-- Use shared global for text label positions
local positions = _G.ScriptManiacGUI_TextPositions or {
    trackingTextPos = UDim2.new(0.5, -125, 0, 10),
    closestTextPos = UDim2.new(0.5, -125, 0, 40),
}

-- GUI Setup
local gui = LocalPlayer:WaitForChild("PlayerGui")
local espGui = Instance.new("ScreenGui", gui)
espGui.Name = "ScriptManiacESP"
espGui.ResetOnSpawn = false

-- Draggable Text labels for ESP info
local function createDraggableText(position, color, defaultText)
    local frame = Instance.new("Frame", espGui)
    frame.Size = UDim2.new(0, 250, 0, 25)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.Active = true
    frame.Draggable = true

    local textLabel = Instance.new("TextLabel", frame)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = color
    textLabel.TextStrokeTransparency = 0.5
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 16
    textLabel.Text = defaultText or ""
    textLabel.Visible = true

    -- Save new position on drag
    frame:GetPropertyChangedSignal("Position"):Connect(function()
        positions[defaultText == "Tracking Target" and "trackingTextPos" or "closestTextPos"] = frame.Position
        _G.ScriptManiacGUI_TextPositions = positions
        pcall(function()
            writefile("ScriptManiac_Positions.json", game:GetService("HttpService"):JSONEncode(positions))
        end)
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
                        hl.Parent = espGui
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

-- Main ESP loop
RunService.RenderStepped:Connect(function()
    local currentTrackedTarget = _G.CurrentAimbotTarget or nil -- read global shared from main script
    updateESP(currentTrackedTarget)
end)
