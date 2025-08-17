--// AimbotButton.lua
--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local MAX_DISTANCE = 500 -- max distance to target

-- Wait for combat tab to exist
local combatTab
repeat
    combatTab = _G.Tabs and _G.Tabs.Combat
    wait(0.1)
until combatTab

-- Initialize global tracking variable
_G.CurrentAimbotTarget = nil

-- Helper functions
local function isAlive(player)
    return player and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0
end

local function canBeDamaged(player)
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

local function isVisible(position, character)
    local origin = Camera.CFrame.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true
    local ray = workspace:Raycast(origin, (position - origin).Unit * 9999, rayParams)
    return ray and character:IsAncestorOf(ray.Instance) or not ray
end

local function isEnemy(player)
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    if not canBeDamaged(player) then return false end

    if not _G.InvinceTrack then
        if hasSpawnProtection(player) then
            return false
        end
    end

    return true
end

local function hasLineOfSight(fromPos, toPos, ignoreList)
    local direction = (toPos - fromPos)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = ignoreList or {}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true
    local raycastResult = workspace:Raycast(fromPos, direction, rayParams)
    if raycastResult then
        local hitPart = raycastResult.Instance
        if hitPart and hitPart:IsDescendantOf(Players:GetPlayerFromCharacter(hitPart.Parent) and hitPart.Parent or nil) then
            return true
        end
        return false
    end
    return true
end

-- Aimbot variables
local aimbotOn = false
local currentAimbotTarget = nil
local currentTargetHumanoid = nil
local deathConn = nil

-- Create Aimbot toggle button
local aimbotButton = Instance.new("TextButton")
aimbotButton.Size = UDim2.new(1, 0, 0, 35)
aimbotButton.Position = UDim2.new(0, 0, 0, 10)
aimbotButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
aimbotButton.TextColor3 = Color3.new(1, 1, 1)
aimbotButton.Font = Enum.Font.GothamBold
aimbotButton.TextSize = 18
aimbotButton.Text = "Op Aimbot: Off"
aimbotButton.Parent = combatTab
Instance.new("UICorner", aimbotButton).CornerRadius = UDim.new(0, 6)

-- Aimbot visuals (tracking line)
local hasDrawing, DrawingNew = pcall(function() return Drawing.new end)
local aimbotLine = nil
if hasDrawing and DrawingNew then
    local ok, line = pcall(DrawingNew, "Line")
    if ok and line then
        line.Color = Color3.new(0, 1, 0)
        line.Thickness = 2
        line.Visible = false
        aimbotLine = line
    end
end

-- Cleanup function for aimbot target death connection
local function cleanupDeathConnection()
    if deathConn then
        deathConn:Disconnect()
        deathConn = nil
        currentTargetHumanoid = nil
    end
end

-- Toggle logic
aimbotButton.MouseButton1Click:Connect(function()
    aimbotOn = not aimbotOn
    aimbotButton.Text = "Op Aimbot: " .. (aimbotOn and "On" or "Off")
    aimbotButton.BackgroundColor3 = aimbotOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)

    if not aimbotOn then
        currentAimbotTarget = nil
        _G.CurrentAimbotTarget = nil
        cleanupDeathConnection()
        if aimbotLine then aimbotLine.Visible = false end
    end
end)

-- Calculate angular distance between camera and target
local function getAngularDistance(worldPos)
    local camPos = Camera.CFrame.Position
    local camLook = Camera.CFrame.LookVector
    local dir = (worldPos - camPos).Unit
    local angle = math.acos(math.clamp(camLook:Dot(dir), -1, 1))
    return math.deg(angle)
end

-- Main aimbot loop
RunService.RenderStepped:Connect(function()
    if not aimbotOn then
        if aimbotLine then aimbotLine.Visible = false end
        currentAimbotTarget = nil
        _G.CurrentAimbotTarget = nil
        cleanupDeathConnection()
        return
    end

    if not LocalPlayer.Character or not isAlive(LocalPlayer) then
        if aimbotLine then aimbotLine.Visible = false end
        currentAimbotTarget = nil
        _G.CurrentAimbotTarget = nil
        cleanupDeathConnection()
        return
    end

    local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        if aimbotLine then aimbotLine.Visible = false end
        currentAimbotTarget = nil
        _G.CurrentAimbotTarget = nil
        cleanupDeathConnection()
        return
    end

    local closestPlayer, closestPart
    local bestVal = math.huge -- start infinite for 3D tracking

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            if isVisible(part.Position, char) and hasLineOfSight(Camera.CFrame.Position, part.Position, {LocalPlayer.Character, char}) then
                                local dist = (part.Position - myHRP.Position).Magnitude
                                if dist < bestVal and dist <= MAX_DISTANCE then
                                    closestPlayer = player
                                    closestPart = part
                                    bestVal = dist
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Handle target change
    if currentAimbotTarget ~= closestPlayer then
        cleanupDeathConnection()
        currentAimbotTarget = closestPlayer
        _G.CurrentAimbotTarget = currentAimbotTarget

        if currentAimbotTarget then
            local char = currentAimbotTarget.Character
            if char then
                currentTargetHumanoid = char:FindFirstChildOfClass("Humanoid")
                if currentTargetHumanoid then
                    deathConn = currentTargetHumanoid.Died:Connect(function()
                        currentAimbotTarget = nil
                        _G.CurrentAimbotTarget = nil
                        cleanupDeathConnection()
                        if aimbotLine then aimbotLine.Visible = false end
                    end)
                end
            end
        end
    end

    -- Lock camera
    if currentAimbotTarget and closestPart then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestPart.Position)
        if aimbotLine then
            local screenPos = Camera:WorldToViewportPoint(closestPart.Position)
            aimbotLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            aimbotLine.To = Vector2.new(screenPos.X, screenPos.Y)
            aimbotLine.Visible = screenPos.Z > 0
        end
    else
        if aimbotLine then aimbotLine.Visible = false end
    end
end)
