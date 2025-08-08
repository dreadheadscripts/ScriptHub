--// Closest Player Toggle (Config Tab)
local RunService = game:GetService("RunService")
local configTab = _G.Tabs and _G.Tabs.Config
if not configTab then return warn("Config tab not found!") end

-- Shared toggle state in _G
_G.ClosestPlayerESP = false

-- Create Button (Full Width)
local button = Instance.new("TextButton")
button.Size = UDim2.new(1, 0, 0, 35)
button.Position = UDim2.new(0, 0, 0, 50) -- Under crosshair button
button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.Text = "Closest Player: Off"
button.Parent = configTab

local corner = Instance.new("UICorner", button)
corner.CornerRadius = UDim.new(0, 6)

-- Button logic
button.MouseButton1Click:Connect(function()
	_G.ClosestPlayerESP = not _G.ClosestPlayerESP
	local on = _G.ClosestPlayerESP
	button.Text = "Closest Player: " .. (on and "On" or "Off")
	button.BackgroundColor3 = on and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)
end)
