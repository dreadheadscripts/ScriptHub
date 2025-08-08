-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Constants
local MAX_DISTANCE = 500

-- Position memory for GUI dragging (optional, you can remove if unused)
getfenv()._G.ScriptManiacGUI_TextPositions = getfenv()._G.ScriptManiacGUI_TextPositions or {
    mainFramePos = UDim2.new(0, 20, 0.3, 0)
}

-- Toggles
local espOn = false

-- Store ESP Highlights per player
local espHighlights = {}

-- GUI Setup
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "ScriptManiacGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 70)
frame.Position = _G.ScriptManiacGUI_TextPositions.mainFramePos
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame)

frame:GetPropertyChangedSignal("Position"):Connect(function()
    _G.ScriptManiacGUI_TextPositions.mainFramePos = frame.Position
    pcall(function()
        writefile("ScriptManiac_Positions.json", HttpService:JSONEncode(_G.ScriptManiacGUI_TextPositions))
    end)
end)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 20)
title.Text = "Script Maniac ESP"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local function createButton(name, yPos, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 180, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = name .. ": Off"
    Instance.new("UICorner", btn)

    btn.MouseButton1Click:Connect(function()
        callback()
    end)

    return btn
end

-- ESP Toggle Button styled like Aimbot button
local espButton = createButton("ESP", 25, function()
    espOn = not espOn
    if espOn then
        espButton.Text = "ESP: On"
        espButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    else
        espButton.Text = "ESP: Off"
        espButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        -- Remove all highlights
        for player, highlight in pairs(espHighlights) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
        espHighlights = {}
    end
end)

-- Function to check if player is a valid enemy for ESP
local function canBeDamaged(player)
    if player == LocalPlayer then return false end
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team
    if myTeam and theirTeam and myTeam == theirTeam then return false end
    return true
end

-- ESP Update Loop
RunService.RenderStepped:Connect(function()
    if not espOn then return end

    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    for _, player in pairs(Players:GetPlayers()) do
        if canBeDamaged(player) then
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - myHRP.Position).Magnitude <= MAX_DISTANCE then
                    if not espHighlights[player] or not espHighlights[player].Parent then
                        -- Create new highlight
                        local hl = Instance.new("Highlight")
                        hl.Adornee = char
                        hl.FillTransparency = 1
                        hl.OutlineTransparency = 0
                        hl.OutlineColor = Color3.fromRGB(255, 0, 0) -- Red outline
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = gui
                        espHighlights[player] = hl
                    end
                else
                    -- Remove highlight if too far or no hrp
                    if espHighlights[player] then
                        espHighlights[player]:Destroy()
                        espHighlights[player] = nil
                    end
                end
            else
                -- Remove highlight if no character
                if espHighlights[player] then
                    espHighlights[player]:Destroy()
                    espHighlights[player] = nil
                end
            end
        else
            -- Remove highlight if can't be damaged (team or dead)
            if espHighlights[player] then
                espHighlights[player]:Destroy()
                espHighlights[player] = nil
            end
        end
    end
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
end)

-- Cleanup on character removal (respawn)
Players.PlayerAdded:Connect(function(player)
    player.CharacterRemoving:Connect(function()
        if espHighlights[player] then
            espHighlights[player]:Destroy()
            espHighlights[player] = nil
        end
    end)
end)
