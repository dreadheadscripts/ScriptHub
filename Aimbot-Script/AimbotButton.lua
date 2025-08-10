--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

local combatTab = _G.Tabs and _G.Tabs.Combat
if not combatTab then
    warn("Combat tab not found! Cannot create buttons.")
    return
end

local MAX_DISTANCE = 500

--// ===== AIMBOT SECTION =====

local aimbotOn = false
local currentAimbotTarget = nil
local clicking = false

-- Aimbot toggle button
local aimbotButton = Instance.new("TextButton")
aimbotButton.Size = UDim2.new(1, 0, 0, 35)
aimbotButton.Position = UDim2.new(0, 0, 0, 10)
aimbotButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
aimbotButton.TextColor3 = Color3.new(1, 1, 1)
aimbotButton.Font = Enum.Font.GothamBold
aimbotButton.TextSize = 18
aimbotButton.Text = "Aimbot: Off"
aimbotButton.Parent = combatTab
Instance.new("UICorner", aimbotButton).CornerRadius = UDim.new(0, 6)

aimbotButton.MouseButton1Click:Connect(function()
    aimbotOn = not aimbotOn
    aimbotButton.Text = "Aimbot: " .. (aimbotOn and "On" or "Off")
    aimbotButton.BackgroundColor3 = aimbotOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)

    if not aimbotOn then
        currentAimbotTarget = nil
        aimbotLine.Visible = false
        trackingText.Text = "Tracking Nobody"
        stopClicking()
    end
end)

-- Helper functions for aimbot
local function isAlive(player)
    return player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

local function canDamageYou(player)
    if not player or player == LocalPlayer then return false end
    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team
    if myTeam == nil or theirTeam == nil then return true end
    return myTeam ~= theirTeam
end

local function hasSpawnProtection(player)
    local char = player.Character
    if not char then return false end
    return char:FindFirstChildOfClass("ForceField") ~= nil
end

local function canBeDamaged(player)
    if not player or player == LocalPlayer then return false end
    if not isAlive(player) then return false end
    if not canDamageYou(player) then return false end
    if hasSpawnProtection(player) then return false end
    return true
end

local function isVisible(position, character)
    local origin = Camera.CFrame.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local ray = workspace:Raycast(origin, (position - origin).Unit * 9999, rayParams)
    return ray and character:IsAncestorOf(ray.Instance) or not ray
end

-- Auto-click helper functions
local function safeSendClick(x, y)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
end

local function getRandomOffset()
    return math.random(-3, 3), math.random(-3, 3)
end

local clickingCoroutine = nil
local function startClicking()
    if clicking then return end
    clicking = true
    clickingCoroutine = coroutine.create(function()
        while clicking and currentAimbotTarget and isAlive(currentAimbotTarget) do
            local cx, cy = Camera.ViewportSize.X * 0.9, Camera.ViewportSize.Y / 2
            local offsetX, offsetY = getRandomOffset()
            safeSendClick(cx + offsetX, cy + offsetY)
            wait(0.01)
        end
        clicking = false
    end)
    coroutine.resume(clickingCoroutine)
end

local function stopClicking()
    clicking = false
end

-- Aimbot visual helpers
local aimbotLine = Drawing.new("Line")
aimbotLine.Color = Color3.new(0, 1, 0)
aimbotLine.Thickness = 2
aimbotLine.Visible = false

local trackingText = Instance.new("TextLabel")
trackingText.Size = UDim2.new(0, 250, 0, 25)
trackingText.Position = UDim2.new(0.5, -125, 0, 10)
trackingText.BackgroundTransparency = 1
trackingText.TextColor3 = Color3.new(0, 1, 0)
trackingText.Font = Enum.Font.GothamBold
trackingText.TextSize = 16
trackingText.Text = "Tracking Nobody"
trackingText.Parent = LocalPlayer:WaitForChild("PlayerGui")
trackingText.Visible = true

-- Aimbot main loop
RunService.RenderStepped:Connect(function()
    if not aimbotOn then
        aimbotLine.Visible = false
        trackingText.Text = "Tracking Nobody"
        stopClicking()
        currentAimbotTarget = nil
        return
    end

    if not LocalPlayer.Character or not isAlive(LocalPlayer) then
        aimbotLine.Visible = false
        trackingText.Text = "Tracking Nobody"
        stopClicking()
        currentAimbotTarget = nil
        return
    end

    local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        stopClicking()
        return
    end

    local closestPlayer, closestPart, bestVal = nil, nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and canBeDamaged(player) then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local distToPlayer = (hrp.Position - myHRP.Position).Magnitude
                if distToPlayer <= MAX_DISTANCE then
                    local head = char:FindFirstChild("Head")
                    if head and isVisible(head.Position, char) then
                        local screenPos = Camera:WorldToViewportPoint(head.Position)
                        local fov = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                        if fov < bestVal then
                            closestPlayer = player
                            closestPart = head
                            bestVal = fov
                        end
                    end
                end
            end
        end
    end

    currentAimbotTarget = closestPlayer

    if currentAimbotTarget and closestPart then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestPart.Position)
        local screenPos = Camera:WorldToViewportPoint(closestPart.Position)
        aimbotLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        aimbotLine.To = Vector2.new(screenPos.X, screenPos.Y)
        aimbotLine.Visible = screenPos.Z > 0
        trackingText.Text = "Tracking: " .. currentAimbotTarget.Name .. " (" .. math.floor((closestPart.Position - myHRP.Position).Magnitude) .. " studs)"
        startClicking()
    else
        aimbotLine.Visible = false
        trackingText.Text = "Tracking Nobody"
        stopClicking()
    end
end)

--// ===== KILL AURA SECTION =====

local killAuraOn = false
local killAuraTarget = nil
local killAuraClicking = false

-- Kill Aura toggle button
local killAuraButton = Instance.new("TextButton")
killAuraButton.Size = UDim2.new(1, 0, 0, 35)
killAuraButton.Position = UDim2.new(0, 0, 0, 50)
killAuraButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
killAuraButton.TextColor3 = Color3.new(1, 1, 1)
killAuraButton.Font = Enum.Font.GothamBold
killAuraButton.TextSize = 18
killAuraButton.Text = "Kill Aura: Off"
killAuraButton.Parent = combatTab
Instance.new("UICorner", killAuraButton).CornerRadius = UDim.new(0, 6)

killAuraButton.MouseButton1Click:Connect(function()
    killAuraOn = not killAuraOn
    killAuraButton.Text = "Kill Aura: " .. (killAuraOn and "On" or "Off")
    killAuraButton.BackgroundColor3 = killAuraOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)

    if not killAuraOn then
        killAuraTarget = nil
        killAuraLine.Visible = false
        killAuraStopClicking()
    end
end)

-- Kill Aura helper functions
local function isValidKillAuraTarget(player)
    if not player or player == LocalPlayer then return false end
    if not isAlive(player) then return false end
    if not canDamageYou(player) then return false end
    if hasSpawnProtection(player) then return false end
    return true
end

local killAuraLine = Drawing.new("Line")
killAuraLine.Color = Color3.new(1, 0, 0)
killAuraLine.Thickness = 2
killAuraLine.Visible = false

local killAuraClickCoroutine = nil
local function killAuraStartClicking()
    if killAuraClicking then return end
    killAuraClicking = true
    killAuraClickCoroutine = coroutine.create(function()
        while killAuraClicking and killAuraTarget and isAlive(killAuraTarget) do
            local cx, cy = Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.9
            local offsetX, offsetY = getRandomOffset()
            safeSendClick(cx + offsetX, cy + offsetY)
            wait(0.02)
        end
        killAuraClicking = false
    end)
    coroutine.resume(killAuraClickCoroutine)
end

local function killAuraStopClicking()
    killAuraClicking = false
end

-- Kill Aura main loop
RunService.RenderStepped:Connect(function()
    if not killAuraOn then
        killAuraLine.Visible = false
        killAuraStopClicking()
        killAuraTarget = nil
        return
    end

    if not LocalPlayer.Character or not isAlive(LocalPlayer) then
        killAuraLine.Visible = false
        killAuraStopClicking()
        killAuraTarget = nil
        return
    end

    local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        killAuraStopClicking()
        return
    end

    local closestPlayer, closestPart, bestDist = nil, nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if isValidKillAuraTarget(player) then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist <= MAX_DISTANCE then
                    if dist < bestDist then
                        closestPlayer = player
                        closestPart = hrp
                        bestDist = dist
                    end
                end
            end
        end
    end

    killAuraTarget = closestPlayer

    if killAuraTarget and closestPart then
        killAuraLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local screenPos, onScreen = Camera:WorldToViewportPoint(closestPart.Position)
        killAuraLine.To = Vector2.new(screenPos.X, screenPos.Y)
        killAuraLine.Visible = onScreen
        killAuraStartClicking()
    else
        killAuraLine.Visible = false
        killAuraStopClicking()
    end
