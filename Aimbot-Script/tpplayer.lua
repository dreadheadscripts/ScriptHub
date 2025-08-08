--// Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then return warn("Player tab not found in _G.Tabs") end

--// Button + Dropdown Container
local container = Instance.new("Frame")
container.Size = UDim2.new(1, 0, 0, 90)
container.Position = UDim2.new(0, 0, 0, 50)
container.BackgroundTransparency = 1
container.Parent = playerTab

--// TP Player Button (aligned to the left)
local tpButton = Instance.new("TextButton")
tpButton.Size = UDim2.new(0.45, 0, 0, 35)
tpButton.Position = UDim2.new(0, 0, 0, 0)
tpButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tpButton.TextColor3 = Color3.new(1, 1, 1)
tpButton.Font = Enum.Font.GothamBold
tpButton.TextSize = 16
tpButton.Text = "TP Closest"
tpButton.Parent = container

local corner = Instance.new("UICorner", tpButton)
corner.CornerRadius = UDim.new(0, 6)

--// Dropdown Button
local dropdownButton = Instance.new("TextButton")
dropdownButton.Size = UDim2.new(0.5, 0, 0, 35)
dropdownButton.Position = UDim2.new(0.5, 0, 0, 0)
dropdownButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropdownButton.TextColor3 = Color3.new(1, 1, 1)
dropdownButton.Font = Enum.Font.GothamBold
dropdownButton.TextSize = 16
dropdownButton.Text = "TP To Player ▼"
dropdownButton.Parent = container

local dropdownCorner = Instance.new("UICorner", dropdownButton)
dropdownCorner.CornerRadius = UDim.new(0, 6)

--// Dropdown Frame
local dropdownFrame = Instance.new("ScrollingFrame")
dropdownFrame.Size = UDim2.new(1, 0, 0, 50)
dropdownFrame.Position = UDim2.new(0, 0, 0, 40)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropdownFrame.Visible = false
dropdownFrame.ScrollBarThickness = 4
dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdownFrame.Parent = container

local dropdownUICorner = Instance.new("UICorner", dropdownFrame)
dropdownUICorner.CornerRadius = UDim.new(0, 6)

local UIListLayout = Instance.new("UIListLayout", dropdownFrame)
UIListLayout.Padding = UDim.new(0, 2)

--// Teleport to Closest Player
local function canBeDamaged(player)
	if player == LocalPlayer then return false end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
	if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
	return true
end

tpButton.MouseButton1Click:Connect(function()
	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHRP then return end

	local closestPlayer, closestDist = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if canBeDamaged(player) then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			local dist = (hrp.Position - myHRP.Position).Magnitude
			if dist < closestDist then
				closestDist = dist
				closestPlayer = player
			end
		end
	end

	if closestPlayer then
		myHRP.CFrame = closestPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
	end
end)

--// Create dropdown items
local function updateDropdown()
	dropdownFrame:ClearAllChildren()
	UIListLayout.Parent = dropdownFrame
	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -4, 0, 25)
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.Gotham
		button.TextSize = 14
		button.Text = player.Name
		button.Parent = dropdownFrame

		local btnCorner = Instance.new("UICorner", button)
		btnCorner.CornerRadius = UDim.new(0, 4)

		button.MouseButton1Click:Connect(function()
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if myHRP then
					myHRP.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
				end
			end
			dropdownFrame.Visible = false
		end)

		count += 1
	end

	dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, count * 27)
end

dropdownButton.MouseButton1Click:Connect(function()
	updateDropdown()
	dropdownFrame.Visible = not dropdownFrame.Visible
end)

--// Auto-update dropdown on player join/leave
Players.PlayerAdded:Connect(updateDropdown)
Players.PlayerRemoving:Connect(updateDropdown)
