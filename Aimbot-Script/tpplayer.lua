--// TP Player Module
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Make sure _G.Tabs.Player is valid
local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then return warn("Player tab not found in _G.Tabs") end

-- Container frame for button + dropdown (below ESP at Y = 90)
local container = Instance.new("Frame")
container.Size = UDim2.new(1, -10, 0, 35)
container.Position = UDim2.new(0, 5, 0, 90)
container.BackgroundTransparency = 1
container.Parent = playerTab

-- Selected player holder
local selectedPlayer = nil

-- TP Button (left side)
local tpButton = Instance.new("TextButton")
tpButton.Size = UDim2.new(0.48, -2, 1, 0)
tpButton.Position = UDim2.new(0, 0, 0, 0)
tpButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tpButton.TextColor3 = Color3.new(1, 1, 1)
tpButton.Font = Enum.Font.GothamBold
tpButton.TextSize = 16
tpButton.Text = "TP Player"
tpButton.Parent = container

Instance.new("UICorner", tpButton).CornerRadius = UDim.new(0, 6)

-- Dropdown (right side)
local dropdown = Instance.new("ScrollingFrame")
dropdown.Size = UDim2.new(0.48, -2, 3, 0)
dropdown.Position = UDim2.new(0.52, 2, 1.1, 0)
dropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropdown.BorderSizePixel = 0
dropdown.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdown.ScrollBarThickness = 4
dropdown.AutomaticCanvasSize = Enum.AutomaticSize.Y
dropdown.Visible = false
dropdown.Parent = container

Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 6)

local UIListLayout = Instance.new("UIListLayout", dropdown)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

-- Teleport logic
local function teleportToPlayer(p)
	local myChar = LocalPlayer.Character
	local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local targetChar = p and p.Character
	local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

	if hrp and targetHRP then
		hrp.CFrame = targetHRP.CFrame + Vector3.new(2, 0, 0)
	end
end

-- Dropdown player button creation
local function createPlayerButton(p)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -10, 0, 30)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.Gotham
	button.TextSize = 15
	button.Text = p.DisplayName .. " (" .. p.Name .. ")"
	button.Parent = dropdown

	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)

	button.MouseButton1Click:Connect(function()
		selectedPlayer = p
		dropdown.Visible = false
		tpButton.Text = "TP: " .. p.DisplayName
	end)
end

-- Refresh dropdown list
local function refreshDropdown()
	dropdown:ClearAllChildren()
	UIListLayout.Parent = dropdown
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			createPlayerButton(p)
		end
	end
end

-- Button click
tpButton.MouseButton1Click:Connect(function()
	if selectedPlayer then
		teleportToPlayer(selectedPlayer)
	else
		dropdown.Visible = not dropdown.Visible
		if dropdown.Visible then
			refreshDropdown()
		end
	end
end)

-- Auto-refresh on join/leave
Players.PlayerAdded:Connect(function()
	if dropdown.Visible then
		refreshDropdown()
	end
end)

Players.PlayerRemoving:Connect(function()
	if dropdown.Visible then
		refreshDropdown()
	end
	if selectedPlayer and not Players:FindFirstChild(selectedPlayer.Name) then
		selectedPlayer = nil
		tpButton.Text = "TP Player"
	end
end)
