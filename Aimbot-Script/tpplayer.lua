local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then return warn("Player tab not found in _G.Tabs") end

local selectedPlayer = nil

-- Dropdown menu (right side)
local dropdown = Instance.new("TextButton")
dropdown.Size = UDim2.new(0.55, 0, 0, 35)
dropdown.Position = UDim2.new(0.45, 0, 0, 50)
dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropdown.TextColor3 = Color3.new(1, 1, 1)
dropdown.Font = Enum.Font.Gotham
dropdown.TextSize = 16
dropdown.Text = "Select Player"
dropdown.Parent = playerTab

local corner1 = Instance.new("UICorner", dropdown)
corner1.CornerRadius = UDim.new(0, 6)

local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(1, 0, 4, 0)
playerListFrame.Position = UDim2.new(0, 0, 1, 0)
playerListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
playerListFrame.BorderSizePixel = 0
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.Visible = false
playerListFrame.ScrollBarThickness = 4
playerListFrame.Parent = dropdown

local function updateDropdown()
	playerListFrame:ClearAllChildren()
	local y = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local option = Instance.new("TextButton")
			option.Size = UDim2.new(1, 0, 0, 25)
			option.Position = UDim2.new(0, 0, 0, y)
			option.BackgroundColor3 = Color3.fromRGB(28, 129, 50)
			option.TextColor3 = Color3.new(1, 1, 1)
			option.Font = Enum.Font.Gotham
			option.TextSize = 14
			option.Text = player.Name
			option.Parent = playerListFrame

			local uiCorner = Instance.new("UICorner", option)
			uiCorner.CornerRadius = UDim.new(0, 4)

			option.MouseButton1Click:Connect(function()
				selectedPlayer = player
				dropdown.Text = "Selected: " .. player.Name
				playerListFrame.Visible = false
			end)

			y += 25
		end
	end
	playerListFrame.CanvasSize = UDim2.new(0, 0, 0, y)
end

dropdown.MouseButton1Click:Connect(function()
	playerListFrame.Visible = not playerListFrame.Visible
	updateDropdown()
end)

Players.PlayerAdded:Connect(updateDropdown)
Players.PlayerRemoving:Connect(function(p)
	if selectedPlayer == p then
		selectedPlayer = nil
		dropdown.Text = "Select Player"
	end
	updateDropdown()
end)

-- TP Button (left side)
local tpButton = Instance.new("TextButton")
tpButton.Size = UDim2.new(0.45, -5, 0, 35)
tpButton.Position = UDim2.new(0, 0, 0, 50)
tpButton.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
tpButton.TextColor3 = Color3.new(1, 1, 1)
tpButton.Font = Enum.Font.GothamBold
tpButton.TextSize = 18
tpButton.Text = "TP To"
tpButton.Parent = playerTab

local corner2 = Instance.new("UICorner", tpButton)
corner2.CornerRadius = UDim.new(0, 6)

tpButton.MouseButton1Click:Connect(function()
	if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local myChar = LocalPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if myHRP then
			myHRP.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
		end
	end
end)
