--// AimbotButton.lua [ loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/AimbotButton.lua"))() ]
--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Wait for combat tab to exist
local combatTab
repeat
    combatTab = _G.Tabs and _G.Tabs.Combat
    wait(0.1)
until combatTab

local MAX_DISTANCE = 500

-- ===== AIMBOT SECTION =====

local aimbotOn = false
local currentAimbotTarget = nil
local currentAimbotPart = nil

-- Create Aimbot toggle button
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

-- Aimbot visuals
local aimbotLine = Drawing.new("Line")
aimbotLine.Color = Color3.new(0, 1, 0)
aimbotLine.Thickness = 2
aimbotLine.Visible = false

-- Wall check function
local function hasLineOfSight(fromPos, toPos, ignoreList)
    local ray = Ray.new(fromPos, (toPos - fromPos))
    local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList or {})
    return hitPart == nil or hitPart:IsDescendantOf(Players:GetPlayerFromCharacter(hitPart.Parent) and hitPart.Parent or nil)
end

-- Aimbot toggle logic
aimbotButton.MouseButton1Click:Connect(function()
    aimbotOn = not aimbotOn
    aimbotButton.Text = "Aimbot: " .. (aimbotOn and "On" or "Off")
    aimbotButton.BackgroundColor3 = aimbotOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)

    if not aimbotOn then
        currentAimbotTarget = nil
        currentAimbotPart = nil
        aimbotLine.Visible = false
    end
end)

-- Aimbot main loop
RunService.RenderStepped:Connect(function()
    if not aimbotOn then
        aimbotLine.Visible = false
        currentAimbotTarget = nil
        currentAimbotPart = nil
        return
    end

    if not LocalPlayer.Character or not isAlive(LocalPlayer) then
        aimbotLine.Visible = false
        currentAimbotTarget = nil
        currentAimbotPart = nil
        return
    end

    local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local closestPlayer, closestPart, bestVal = nil, nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer 
        and player.Team ~= LocalPlayer.Team -- Team check
        and canBeDamaged(player) then

            local char = player.Character
            if char then
                local distToPlayer = (char:GetPivot().Position - myHRP.Position).Magnitude
                if distToPlayer <= MAX_DISTANCE then

                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen 
                            and isVisible(part.Position, char)
                            and hasLineOfSight(Camera.CFrame.Position, part.Position, {LocalPlayer.Character}) then

                                local fov = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                                if fov < bestVal then
                                    bestVal = fov
                                    closestPlayer = player
                                    closestPart = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    currentAimbotTarget = closestPlayer
    currentAimbotPart = closestPart

    if currentAimbotTarget and currentAimbotPart then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, currentAimbotPart.Position)
        local screenPos = Camera:WorldToViewportPoint(currentAimbotPart.Position)
        aimbotLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        aimbotLine.To = Vector2.new(screenPos.X, screenPos.Y)
        aimbotLine.Visible = screenPos.Z > 0
    else
        aimbotLine.Visible = false
    end
end)
-- ===== KILL AURA SECTION =====

local killAuraOn = false
local killAuraTarget = nil
local killAuraClicking = false

-- Create Kill Aura toggle button
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

-- Kill Aura helpers
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

-- Kill Aura toggle logic
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
                if dist <= MAX_DISTANCE and dist < bestDist then
                    closestPlayer = player
                    closestPart = hrp
                    bestDist = dist
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
end)
