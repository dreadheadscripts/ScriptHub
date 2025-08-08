-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Constants
local Range = 700

-- Reference to Player tab (adjust this if needed)
local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then
    warn("Player tab not found!")
    return
end

-- Create ESP toggle button (same size & position as Aimbot button)
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0, 180, 0, 30)
espButton.Position = UDim2.new(0, 10, 0, 65)
espButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
espButton.TextColor3 = Color3.new(1, 1, 1)
espButton.Font = Enum.Font.GothamBold
espButton.TextSize = 14
espButton.Text = "ESP: On"
espButton.Name = "EspButton"
espButton.Parent = playerTab
Instance.new("UICorner", espButton)

local espOn = true
espButton.MouseButton1Click:Connect(function()
    espOn = not espOn
    espButton.Text = "ESP: " .. (espOn and "On" or "Off")
    espButton.BackgroundColor3 = espOn and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(80, 80, 80)
end)

-- Table to hold outlines keyed by player
local outlines = {}

local function createOutline()
    local outline = {}
    for _, lineName in ipairs({"Top", "Bottom", "Left", "Right"}) do
        local line = Drawing.new("Line")
        line.Color = Color3.new(1, 0, 0) -- default red
        line.Thickness = 2
        line.Visible = false
        outline[lineName] = line
    end
    return outline
end

local function removeOutline(outline)
    for _, line in pairs(outline) do
        line:Remove()
    end
end

-- Add outlines for all players except local
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        outlines[player] = createOutline()
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        outlines[player] = createOutline()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if outlines[player] then
        removeOutline(outlines[player])
        outlines[player] = nil
    end
end)

-- Helper: get screen points for bounding box corners
local function getBoundingBoxPoints(character)
    local parts = {}
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    if #parts == 0 then return nil end

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, part in pairs(parts) do
        local corners = {
            part.CFrame * Vector3.new(-part.Size.X/2, part.Size.Y/2, -part.Size.Z/2),
            part.CFrame * Vector3.new(part.Size.X/2, part.Size.Y/2, -part.Size.Z/2),
            part.CFrame * Vector3.new(-part.Size.X/2, -part.Size.Y/2, -part.Size.Z/2),
            part.CFrame * Vector3.new(part.Size.X/2, -part.Size.Y/2, -part.Size.Z/2),
            part.CFrame * Vector3.new(-part.Size.X/2, part.Size.Y/2, part.Size.Z/2),
            part.CFrame * Vector3.new(part.Size.X/2, part.Size.Y/2, part.Size.Z/2),
            part.CFrame * Vector3.new(-part.Size.X/2, -part.Size.Y/2, part.Size.Z/2),
            part.CFrame * Vector3.new(part.Size.X/2, -part.Size.Y/2, part.Size.Z/2),
        }

        for _, corner in pairs(corners) do
            local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
            if onScreen and screenPos.Z > 0 then
                minX = math.min(minX, screenPos.X)
                maxX = math.max(maxX, screenPos.X)
                minY = math.min(minY, screenPos.Y)
                maxY = math.max(maxY, screenPos.Y)
            end
        end
    end

    if minX == math.huge then return nil end

    return {
        minX = minX,
        maxX = maxX,
        minY = minY,
        maxY = maxY
    }
end

-- Main loop to update outlines
RunService.RenderStepped:Connect(function()
    if not espOn then
        -- Hide all outlines if ESP off
        for _, outline in pairs(outlines) do
            for _, line in pairs(outline) do
                line.Visible = false
            end
        end
        return
    end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local closestPlayer, closestDist = nil, math.huge

    -- Find closest enemy player within range and different team
    for player, outline in pairs(outlines) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local human = char and char:FindFirstChildOfClass("Humanoid")

        if player ~= LocalPlayer and hrp and human and human.Health > 0 and player.Team ~= LocalPlayer.Team then
            local dist = (hrp.Position - myHRP.Position).Magnitude
            if dist <= Range and dist < closestDist then
                closestPlayer = player
                closestDist = dist
            end
        end
    end

    -- Update outlines
    for player, outline in pairs(outlines) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local human = char and char:FindFirstChildOfClass("Humanoid")

        if player ~= LocalPlayer and hrp and human and human.Health > 0 and player.Team ~= LocalPlayer.Team then
            local dist = (hrp.Position - myHRP.Position).Magnitude
            if dist <= Range then
                local box = getBoundingBoxPoints(char)
                if box then
                    -- Draw box with 4 lines
                    outline.Top.From = Vector2.new(box.minX, box.minY)
                    outline.Top.To = Vector2.new(box.maxX, box.minY)

                    outline.Bottom.From = Vector2.new(box.minX, box.maxY)
                    outline.Bottom.To = Vector2.new(box.maxX, box.maxY)

                    outline.Left.From = Vector2.new(box.minX, box.minY)
                    outline.Left.To = Vector2.new(box.minX, box.maxY)

                    outline.Right.From = Vector2.new(box.maxX, box.minY)
                    outline.Right.To = Vector2.new(box.maxX, box.maxY)

                    -- Color based on tracking and closest
                    local isTracked = (_G.CurrentAimbotTarget == player)
                    if isTracked then
                        for _, line in pairs(outline) do
                            line.Color = Color3.fromRGB(0, 255, 0) -- Green
                        end
                    elseif player == closestPlayer then
                        for _, line in pairs(outline) do
                            line.Color = Color3.fromRGB(255, 255, 0) -- Yellow
                        end
                    else
                        for _, line in pairs(outline) do
                            line.Color = Color3.fromRGB(255, 0, 0) -- Red
                        end
                    end

                    for _, line in pairs(outline) do
                        line.Visible = true
                    end
                else
                    for _, line in pairs(outline) do
                        line.Visible = false
                    end
                end
            else
                for _, line in pairs(outline) do
                    line.Visible = false
                end
            end
        else
            for _, line in pairs(outline) do
                line.Visible = false
            end
        end
    end
end)
