--// OP Aimbot (3D tracking) - place under Combat tab
--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Settings
local MAX_DISTANCE = 500        -- maximum tracking distance (you requested 500)
local SMOOTHING = 0.25         -- 0 = snap instantly, 1 = very slow. tweak to taste
local TARGET_PREFERENCE = { "Head", "HumanoidRootPart" } -- preference order (head first)

-- Wait for combat tab to exist
local combatTab
repeat
    combatTab = _G.Tabs and _G.Tabs.Combat
    task.wait(0.1)
until combatTab

-- Ensure global aimbot target exists (ESP relies on this)
_G.CurrentAimbotTarget = _G.CurrentAimbotTarget or nil

-- Helper functions (re-usable from your aimbot if needed)
local function isAlive(player)
    return player and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChild("Humanoid").Health > 0
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
    -- check ForceField class or named nodes
    if char:FindFirstChildOfClass("ForceField") then return true end
    if char:FindFirstChild("ForceField") then return true end
    local spawnProt = char:FindFirstChild("SpawnProtection") or char:FindFirstChild("Invincible")
    if spawnProt and spawnProt.Value == true then return true end
    return false
end

local function isVisible(position, character)
    local origin = Camera.CFrame.Position
    local dir = (position - origin)
    if dir.Magnitude == 0 then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true
    local result = workspace:Raycast(origin, dir, rayParams)
    if not result then
        return true
    end
    -- If we hit a descendant of the target character, treat as visible
    local hit = result.Instance
    if hit and character and hit:IsDescendantOf(character) then
        return true
    end
    return false
end

local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not isAlive(player) then return false end
    if not player.Character then return false end

    -- Team check: who can damage you is enemy
    if not canBeDamaged(player) then return false end

    -- Invincibility behavior: if INVINCE TRACK is OFF (nil/false) then skip invincible players.
    if (_G.InvinceTrack == nil or _G.InvinceTrack == false) and hasSpawnProtection(player) then
        return false
    end

    -- successfully passed checks
    return true
end

-- find best part to aim for (head prioritized)
local function getPreferredTargetPart(char)
    if not char then return nil end
    for _, name in ipairs(TARGET_PREFERENCE) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            return p
        end
    end
    -- fallback: any BasePart
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("BasePart") then
            return obj
        end
    end
    return nil
end

-- Button creation: placed under the existing aimbot button (which is at Y = 10 in your hub)
local opButton = Instance.new("TextButton")
opButton.Size = UDim2.new(1, 0, 0, 35)
opButton.Position = UDim2.new(0, 0, 0, 55) -- under aimbot (aimbot at 10 -> this at 55)
opButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
opButton.TextColor3 = Color3.new(1, 1, 1)
opButton.Font = Enum.Font.GothamBold
opButton.TextSize = 18
opButton.Text = "OP Aimbot: Off"
opButton.Parent = combatTab
Instance.new("UICorner", opButton).CornerRadius = UDim.new(0, 6)

-- Visual tracking line (optional, uses Drawing if available)
local hasDrawing, DrawingNew = pcall(function() return Drawing.new end)
local trackLine = nil
if hasDrawing and DrawingNew then
    local ok, ln = pcall(DrawingNew, "Line")
    if ok and ln then
        ln.Color = Color3.new(0, 1, 0)
        ln.Thickness = 2
        ln.Visible = false
        trackLine = ln
    end
end

-- state
local opOn = false
local currentTarget = nil
local targetHumanoid = nil
local deathConn = nil

-- cleanup death connection
local function cleanupDeathConn()
    if deathConn then
        pcall(function() deathConn:Disconnect() end)
        deathConn = nil
        targetHumanoid = nil
    end
end

-- Toggle logic
opButton.MouseButton1Click:Connect(function()
    opOn = not opOn
    opButton.Text = "OP Aimbot: " .. (opOn and "On" or "Off")
    opButton.BackgroundColor3 = opOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)

    if not opOn then
        currentTarget = nil
        _G.CurrentAimbotTarget = nil
        cleanupDeathConn()
        if trackLine then trackLine.Visible = false end
    end
end)

-- Main update loop: find nearest enemy (3D distance) and aim at preferred part
RunService.RenderStepped:Connect(function(dt)
    if not opOn then
        if trackLine then trackLine.Visible = false end
        return
    end

    if not LocalPlayer.Character or not isAlive(LocalPlayer) then
        if trackLine then trackLine.Visible = false end
        currentTarget = nil
        _G.CurrentAimbotTarget = nil
        cleanupDeathConn()
        return
    end

    local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        if trackLine then trackLine.Visible = false end
        return
    end

    -- find closest valid enemy by 3D distance
    local bestPlayer, bestPart, bestDist = nil, nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            local char = player.Character
            if char then
                local part = getPreferredTargetPart(char)
                if part and part.Position then
                    local dist = (part.Position - myHRP.Position).Magnitude
                    if dist <= MAX_DISTANCE then
                        -- wall check: ensure there's line of sight to that part OR we still allow targeting if you want through-walls?
                        if isVisible(part.Position, char) then
                            if dist < bestDist then
                                bestDist = dist
                                bestPlayer = player
                                bestPart = part
                            end
                        end
                    end
                end
            end
        end
    end

    -- handle target change
    if currentTarget ~= bestPlayer then
        cleanupDeathConn()
        currentTarget = bestPlayer
        _G.CurrentAimbotTarget = currentTarget
        if currentTarget then
            -- try bind to their humanoid death
            local ch = currentTarget.Character
            if ch then
                targetHumanoid = ch:FindFirstChildOfClass("Humanoid")
                if targetHumanoid then
                    deathConn = targetHumanoid.Died:Connect(function()
                        -- clear on death
                        currentTarget = nil
                        _G.CurrentAimbotTarget = nil
                        cleanupDeathConn()
                        if trackLine then trackLine.Visible = false end
                    end)
                end
            end
        end
    end

    -- aim at target (smooth 3D rotation)
    if currentTarget and bestPart and bestPart.Parent then
        local targetPos = bestPart.Position
        -- new camera CFrame that looks at the target (keeps camera pos)
        local desired = CFrame.new(Camera.CFrame.Position, targetPos)
        -- smooth lerp (SMOOTHING in [0,1], lower -> faster)
        Camera.CFrame = Camera.CFrame:Lerp(desired, math.clamp(SMOOTHING, 0, 1))
        -- draw line to target center of screen
        if trackLine then
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
            trackLine.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            trackLine.To = Vector2.new(screenPos.X, screenPos.Y)
            trackLine.Visible = onScreen
        end
    else
        if trackLine then trackLine.Visible = false end
    end
end)

-- make sure _G.CurrentAimbotTarget exists for other scripts
_G.CurrentAimbotTarget = _G.CurrentAimbotTarget or nil

-- cleanup on player leaving / respawn
Players.PlayerRemoving:Connect(function(p)
    if _G.CurrentAimbotTarget == p then
        _G.CurrentAimbotTarget = nil
    end
end)
LocalPlayer.CharacterAdded:Connect(function()
    -- reset target on respawn
    currentTarget = nil
    _G.CurrentAimbotTarget = nil
    cleanupDeathConn()
    if trackLine then trackLine.Visible = false end
end)
