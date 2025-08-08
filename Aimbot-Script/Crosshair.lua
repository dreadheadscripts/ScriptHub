--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Ensure Config tab exists
local configTab = _G.Tabs and _G.Tabs.Config
if not configTab then return warn("Config tab not found!") end

--// Crosshair Settings
local crosshairColor = Color3.new(1, 1, 1) -- White
local crosshairSize = 6
local crosshairGap = 2
local crosshairThickness = 1
local crosshairOn = true -- ✅ Starts ON

--// Drawing Crosshair
local crosshair = {
	top = Drawing.new("Line"),
	bottom = Drawing.new("Line"),
	left = Drawing.new("Line"),
	right = Drawing.new("Line")
}

for _, line in pairs(crosshair) do
	line.Color = crosshairColor
	line.Thickness = crosshairThickness
	line.Transparency = 1
	line.Visible = crosshairOn
end

--// Create Toggle Button in Config Tab (Full Width)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 0, 35) -- Full width like aimbot button
toggleBtn.Position = UDim2.new(0, 0, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- Green when ON
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 18
toggleBtn.Text = "Crosshair: On"
toggleBtn.Parent = configTab

local corner = Instance.new("UICorner", toggleBtn)
corner.CornerRadius = UDim.new(0, 6)

--// Toggle Handler
toggleBtn.MouseButton1Click:Connect(function()
	crosshairOn = not crosshairOn
	toggleBtn.Text = crosshairOn and "Crosshair: On" or "Crosshair: Off"
	toggleBtn.BackgroundColor3 = crosshairOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)

	for _, line in pairs(crosshair) do
		line.Visible = crosshairOn
	end
end)

--// Constant Refresher
RunService.RenderStepped:Connect(function()
	local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2

	crosshair.top.From = Vector2.new(cx, cy - crosshairGap - crosshairSize)
	crosshair.top.To = Vector2.new(cx, cy - crosshairGap)

	crosshair.bottom.From = Vector2.new(cx, cy + crosshairGap)
	crosshair.bottom.To = Vector2.new(cx, cy + crosshairGap + crosshairSize)

	crosshair.left.From = Vector2.new(cx - crosshairGap - crosshairSize, cy)
	crosshair.left.To = Vector2.new(cx - crosshairGap, cy)

	crosshair.right.From = Vector2.new(cx + crosshairGap, cy)
	crosshair.right.To = Vector2.new(cx + crosshairGap + crosshairSize, cy)

	for _, line in pairs(crosshair) do
		line.Visible = crosshairOn
	end
end)
