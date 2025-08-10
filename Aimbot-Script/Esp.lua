-- Esp.lua (with FFA detection, Invince Track support, and Aimbot target highlight)
--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local MAX_DISTANCE = 700

local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then
    warn("Player tab not found in _G.Tabs")
    return
end

-- state
local espOn = false
local espHighlights = {}        -- [player] = Highlight
local previousClosest = nil

_G.ClosestPlayerESP = (_G.ClosestPlayerESP == nil) and false or _G.ClosestPlayerESP

-- Default InvinceTrack OFF if nil
if _G.InvinceTrack == nil then
    _G.InvinceTrack = false
end

-- Drawing line (if executor supports Drawing)
local hasDrawing, DrawingNew = pcall(function() return Drawing.new end)
if not _G.ClosestLine and hasDrawing and DrawingNew then
    local ok, line = pcall(DrawingNew, "Line")
    if ok and line then
        line.Thickness = 2
        line.Transparency = 1
        line.Color = Color3.new(1, 1, 0)
        line.Visible = false
        _G.ClosestLine = line
    end
end

-- helpers
local function destroyHighlightFor(player)
    local hl = espHighlights[player]
    if hl then
        pcall(function() if hl.Parent then hl:Destroy() end end)
        espHighlights[player] = nil
    end
end

local function ClearESP()
    for p,_ in pairs(espHighlights) do
        destroyHighlightFor(p)
    end
    espHighlights = {}
    previousClosest = nil
    if _G.ClosestLine then pcall(function() _G.ClosestLine.Visible = false end) end
end

local function isAlive(player)
    return player and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChild("Humanoid").Health > 0
end

-- Invincibility check function
local function isPlayerInvincible(char)
    if not char then return false end
    if char:FindFirstChildOfClass("ForceField") then return true end
    if char:FindFirstChild("ForceField") then return true end
    local spawnProt = char:FindFirstChild("SpawnProtection") or char:FindFirstChild("Invincible")
    if spawnProt and spawnProt.Value == true then
        return true
    end
    return false
end

-- Improved FFA detection:
local function isFFA()
    local anyTeamAssigned = false
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Team ~= nil then
            anyTeamAssigned = true
            break
        end
    end
    if not anyTeamAssigned then
        return true
    end

    local myTeam = LocalPlayer.Team
    local totalOthers = 0
    local sameTeamCount = 0
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            totalOthers = totalOthers + 1
            if p.Team == myTeam then
                sameTeamCount = sameTeamCount + 1
            end
        end
    end

    if totalOthers > 0 and sameTeamCount == totalOthers then
        return true
    end

    return false
end

local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not isAlive(player) then return false end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end

    if _G.InvinceTrack and isPlayerInvincible(player.Character) then
        return false
    end

    if isFFA() then
        return true
    end

    if LocalPlayer.Team == nil or player.Team == nil then
        return false
    end

    return player.Team ~= LocalPlayer.Team
end

-- ESP button (full width, like Aimbot)
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1, 0, 0, 35)
espButton.Position = UDim2.new(0, 0, 0, 10)
espButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
espButton.TextColor3 = Color3.new(1,1,1)
espButton.Font = Enum.Font.GothamBold
espButton.TextSize = 18
espButton.Text = "ESP: Off"
espButton.Parent = playerTab
Instance.new("UICorner", espButton).CornerRadius = UDim.new(0,6)

espButton.MouseButton1Click:Connect(function()
    espOn = not espOn
    espButton.Text = "ESP: " .. (espOn and "On" or "Off")
    espButton.BackgroundColor3 = espOn and Color3.fromRGB(0,180,0) or Color3.fromRGB(40,40,40)
    if not espOn then ClearESP() end
end)

-- main update loop (handles highlights and closest)
RunService.RenderStepped:Connect(function()
    if not espOn then
        if next(espHighlights) then ClearESP() end
        return
    end

    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        if next(espHighlights) then ClearESP() end
        return
    end

    local closestPlayer = nil
    local closestDist = math.huge
    local seen = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist <= MAX_DISTANCE then
                    seen[player] = true
                    if not espHighlights[player] or not espHighlights[player].Parent then
                        if espHighlights[player] then pcall(function() espHighlights[player]:Destroy() end) end
                        local ok, hl = pcall(function()
                            local h = Instance.new("Highlight")
                            h.Adornee = char
                            h.FillTransparency = 1
                            h.OutlineTransparency = 0
                            h.OutlineColor = Color3.fromRGB(255,0,0)
                            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            h.Parent = CoreGui
                            return h
                        end)
                        if ok and hl then espHighlights[player] = hl end
                    end

                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = player
                    end
                end
            end
        end
    end

    for p,_ in pairs(espHighlights) do
        if not seen[p] then destroyHighlightFor(p) end
    end

    local currentAimbotTarget = _G.CurrentAimbotTarget

    for player, highlight in pairs(espHighlights) do
        if highlight and highlight.Parent then
            if player == currentAimbotTarget then
                highlight.OutlineColor = Color3.fromRGB(0, 255, 0) -- Green for aimbot target
            else
                if player == closestPlayer and _G.ClosestPlayerESP and currentAimbotTarget == nil then
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 0) -- Yellow for closest player only if no aimbot target
                else
                    highlight.OutlineColor = Color3.fromRGB(255, 0, 0) -- Red default
                end
            end
        end
    end

    if _G.ClosestPlayerESP and closestPlayer and espHighlights[closestPlayer] and currentAimbotTarget == nil then
        if previousClosest and previousClosest ~= closestPlayer then
            if espHighlights[previousClosest] and espHighlights[previousClosest].Parent then
                pcall(function() espHighlights[previousClosest].OutlineColor = Color3.fromRGB(255,0,0) end)
            end
        end
        pcall(function() espHighlights[closestPlayer].OutlineColor = Color3.fromRGB(255,255,0) end)
        previousClosest = closestPlayer

        if _G.ClosestLine then
            local hrp = closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                _G.ClosestLine.From = center
                _G.ClosestLine.To = Vector2.new(screenPos.X, screenPos.Y)
                _G.ClosestLine.Visible = onScreen
            else
                _G.ClosestLine.Visible = false
            end
        end
    else
        if previousClosest then
            if espHighlights[previousClosest] and espHighlights[previousClosest].Parent then
                pcall(function() espHighlights[previousClosest].OutlineColor = Color3.fromRGB(255,0,0) end)
            end
            previousClosest = nil
        end
        if _G.ClosestLine then pcall(function() _G.ClosestLine.Visible = false end) end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    destroyHighlightFor(p)
    if previousClosest == p then previousClosest = nil end
end)

LocalPlayer.CharacterAdded:Connect(function()
    ClearESP()
end)
