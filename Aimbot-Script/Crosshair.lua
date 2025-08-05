--// Crosshair Customizable UI for Config Tab

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local configTab = _G.Tabs and _G.Tabs.Config
if not configTab then return warn("Config tab not found") end

-- State
local crosshairOn = true
local crosshairColor = Color3.fromRGB(255, 255, 255)
local crosshairSize = 6
local crosshairGap = 4
local lineThickness = 2

-- Clear configTab to prepare UI
for _, child in pairs(configTab:GetChildren()) do
	if not child:IsA("UIListLayout") then
		child:Destroy()
	end
end

-- ScrollFrame setup
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.CanvasSize = UDim2.new(0, 0, 2, 0) -- Make scrollable vertically
scrollFrame.ScrollBarThickness = 8
scrollFrame.BackgroundTransparency = 1
scrollFrame.Parent = configTab

local uiLayout = Instance.new("UIListLayout")
uiLayout.Padding = UDim.new(0, 10)
uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiLayout.Parent = scrollFrame

-- Helper to create labels
local function createLabel(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 24)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1,1,1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = scrollFrame
	return label
end

-- Helper to create sliders
local function createSlider(name, min, max, default)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -20, 0, 50)
	container.BackgroundTransparency = 1
	container.Parent = scrollFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.3, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1,1,1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = name
	label.Parent = container

	local slider = Instance.new("TextBox")
	slider.Size = UDim2.new(0.6, 0, 0.6, 0)
	slider.Position = UDim2.new(0.35, 0, 0.2, 0)
	slider.Text = tostring(default)
	slider.TextColor3 = Color3.new(1,1,1)
	slider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	slider.ClearTextOnFocus = false
	slider.Font = Enum.Font.Gotham
	slider.TextSize = 16
	slider.Parent = container

	local corner = Instance.new("UICorner", slider)
	corner.CornerRadius = UDim.new(0, 6)

	return slider
end

-- Create toggle button for crosshair On/Off
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 150, 0, 40)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 18
toggleBtn.Text = "Crosshair: On"
toggleBtn.Parent = scrollFrame

local corner = Instance.new("UICorner", toggleBtn)
corner.CornerRadius = UDim.new(0, 6)

toggleBtn.MouseButton1Click:Connect(function()
	crosshairOn = not crosshairOn
	toggleBtn.Text = crosshairOn and "Crosshair: On" or "Crosshair: Off"
	toggleBtn.BackgroundColor3 = crosshairOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(80, 80, 80)
end)

-- Color inputs (R, G, B)
createLabel("Crosshair Color (RGB)")

local rInput = createSlider("R", 0, 255, 255)
local gInput = createSlider("G", 0, 255, 255)
local bInput = createSlider("B", 0, 255, 255)

-- Size, Gap, Thickness inputs
createLabel("Crosshair Size")
local sizeInput = createSlider("Size", 1, 30, crosshairSize)

createLabel("Crosshair Gap")
local gapInput = createSlider("Gap", 0, 30, crosshairGap)

createLabel("Line Thickness")
local thicknessInput = createSlider("Thickness", 1, 10, lineThickness)

-- Clamp helper
local function clamp(n, min, max)
	return math.min(math.max(n, min), max)
end

-- Update function for crosshair UI lines
local function updateCrosshair()
	local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2

	for _, line in pairs(lines) do
		line.BackgroundColor3 = crosshairColor
		line.Visible = crosshairOn
	end

	lines.top.Position = UDim2.new(0, cx, 0, cy - crosshairGap)
	lines.top.Size = UDim2.new(0, lineThickness, 0, crosshairSize)

	lines.bottom.Position = UDim2.new(0, cx, 0, cy + crosshairGap)
	lines.bottom.Size = UDim2.new(0, lineThickness, 0, crosshairSize)

	lines.left.Position = UDim2.new(0, cx - crosshairGap, 0, cy)
	lines.left.Size = UDim2.new(0, crosshairSize, 0, lineThickness)

	lines.right.Position = UDim2.new(0, cx + crosshairGap, 0, cy)
	lines.right.Size = UDim2.new(0, crosshairSize, 0, lineThickness)
end

-- Create crosshair lines (if not already)
local crosshairGui = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("CrosshairGui")
if not crosshairGui then
	crosshairGui = Instance.new("ScreenGui")
	crosshairGui.Name = "CrosshairGui"
	crosshairGui.ResetOnSpawn = false
	crosshairGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local lines = {}
for _, partName in pairs({"top", "bottom", "left", "right"}) do
	if not crosshairGui:FindFirstChild(partName) then
		local line = Instance.new("Frame")
		line.Name = partName
		line.BorderSizePixel = 0
		line.Parent = crosshairGui
		lines[partName] = line
	else
		lines[partName] = crosshairGui[partName]
	end
	lines[partName].BackgroundColor3 = crosshairColor
	lines[partName].Visible = crosshairOn
end

-- Update crosshair every frame
RunService.RenderStepped:Connect(function()
	-- Update color and clamp values from inputs
	crosshairColor = Color3.fromRGB(
		clamp(tonumber(rInput.Text) or 255, 0, 255),
		clamp(tonumber(gInput.Text) or 255, 0, 255),
		clamp(tonumber(bInput.Text) or 255, 0, 255)
	)
	crosshairSize = clamp(tonumber(sizeInput.Text) or 6, 1, 30)
	crosshairGap = clamp(tonumber(gapInput.Text) or 4, 0, 30)
	lineThickness = clamp(tonumber(thicknessInput.Text) or 2, 1, 10)

	updateCrosshair()
end)
