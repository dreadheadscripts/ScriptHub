--// Crosshair Button + Logic (GitHub-loaded)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Make sure Config tab exists
local configTab = _G.Tabs and _G.Tabs.Config
if not configTab then return warn("Config tab not found") end

-- Crosshair state
_G.CrosshairEnabled = false
local crosshairColor = Color3.new(1, 1, 1)

-- Create Crosshair Toggle Button
local crosshairBtn = Instance.new("TextButton")
crosshairBtn.Size = UDim2.new(0, 150, 0, 40)
crosshairBtn.Position = UDim2.new(0, 10, 0, 10)
crosshairBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
crosshairBtn.TextColor3 = Color3.new(1, 1, 1)
crosshairBtn.Font = Enum.Font.GothamBold
crosshairBtn.TextSize = 18
crosshairBtn.Text = "Crosshair: Off"
crosshairBtn.Parent = configTab

local corner = Instance.new("UICorner", crosshairBtn)
corner.CornerRadius = UDim.new(0, 6)

-- Crosshair lines
local crosshairGui = Instance.new("ScreenGui")
crosshairGui.Name = "CrosshairGui"
crosshairGui.ResetOnSpawn = false
crosshairGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local size = 6
local gap = 3
local thickness = 2

local function createLine()
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = crosshairColor
    line.BorderSizePixel = 0
    line.Parent = crosshairGui
    return line
end

local lines = {
    top = createLine(),
    bottom = createLine(),
    left = createLine(),
    right = createLine(),
}

-- Setup size and anchor of lines
lines.top.Size = UDim2.new(0, thickness, 0, size)
lines.top.AnchorPoint = Vector2.new(0.5, 1)

lines.bottom.Size = UDim2.new(0, thickness, 0, size)
lines.bottom.AnchorPoint = Vector2.new(0.5, 0)

lines.left.Size = UDim2.new(0, size, 0, thickness)
lines.left.AnchorPoint = Vector2.new(1, 0.5)

lines.right.Size = UDim2.new(0, size, 0, thickness)
lines.right.AnchorPoint = Vector2.new(0, 0.5)

local function updateCrosshair()
    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2

    lines.top.Position = UDim2.new(0, cx, 0, cy - gap)
    lines.bottom.Position = UDim2.new(0, cx, 0, cy + gap)
    lines.left.Position = UDim2.new(0, cx - gap, 0, cy)
    lines.right.Position = UDim2.new(0, cx + gap, 0, cy)

    for _, line in pairs(lines) do
        line.BackgroundColor3 = crosshairColor
        line.Visible = _G.CrosshairEnabled
    end
end

-- Toggle Button Logic
crosshairBtn.MouseButton1Click:Connect(function()
    _G.CrosshairEnabled = not _G.CrosshairEnabled
    crosshairBtn.Text = "Crosshair: " .. (_G.CrosshairEnabled and "On" or "Off")
    crosshairBtn.BackgroundColor3 = _G.CrosshairEnabled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(45, 45, 55)
    updateCrosshair()
end)

-- Update crosshair every frame if enabled
RunService.RenderStepped:Connect(function()
    if _G.CrosshairEnabled then
        updateCrosshair()
    else
        for _, line in pairs(lines) do
            line.Visible = false
        end
    end
end)

-- Initially hide crosshair
updateCrosshair()
