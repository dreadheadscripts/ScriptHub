--// TP Player Module
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then return warn("Player tab not found in _G.Tabs") end

-- Main Button
local tpButton = Instance.new("TextButton")
tpButton.Size = UDim2.new(1, -10, 0, 35)
tpButton.Position = UDim2.new(0, 5, 0, 50) -- Slightly to the left, below ESP button
tpButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tpButton.TextColor3 = Color3.new(1, 1, 1)
tpButton.Font = Enum.Font.GothamBold
tpButton.TextSize = 18
tpButton.Text = "TP Player ▼"
tpButton.Parent = playerTab

Instance.new("UICorner", tpButton).CornerRadius = UDim.new(0, 6)

-- Dropdown Frame
local dropdown = Instance.new("ScrollingFrame")
dropdown.Size = UDim2.new(1, -10, 0, 120)
dropdown.Position = UDim2.new(0, 5, 0, 90)
dropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropdown.BorderSizePixel = 0
dropdown.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdown.ScrollBarThickness = 4
dropdown.Visible = false
dropdown.AutomaticCanvasSize = Enum.AutomaticSize.Y
dropdown.Parent = playerTab

Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 6)

local UIListLayout = Instance.new("UIListLayout", dropdown)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

-- Teleport function
local function teleportToPlayer(target)
	local myChar = LocalPlayer.Character
	local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local targetChar = target and target.Character
	local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

	if hrp and targetHRP then
		hrp.CFrame = targetHRP.CFrame + Vector3.new(2, 0, 0) -- Offset to avoid overlap
	end
end

-- Create a dropdown button for a player
local function createPlayerButton(p)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -10, 0, 30)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.Gotham
	button.TextSize = 16
	button.Text = p.DisplayName .. " (" .. p.Name .. ")"
	button.Parent = dropdown

	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)

	button.MouseButton1Click:Connect(function()
		teleportToPlayer(p)
		dropdown.Visible = false
		tpButton.Text = "TP Player ▼"
	end)
end

-- Refresh dropdown list
local function refreshDropdown()
	dropdown:ClearAllChildren()
	UIListLayout.Parent = dropdown -- reattach
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			createPlayerButton(p)
		end
	end
end

-- Toggle dropdown on button click
tpButton.MouseButton1Click:Connect(function()
	dropdown.Visible = not dropdown.Visible
	tpButton.Text = dropdown.Visible and "TP Player ▲" or "TP Player ▼"
	refreshDropdown()
end)

-- Update list on player changes
Players.PlayerAdded:Connect(refreshDropdown)
Players.PlayerRemoving:Connect(refreshDropdown)
