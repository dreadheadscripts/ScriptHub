--// ESP Module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local MAX_DISTANCE = 700

local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then return warn("Player tab not found in _G.Tabs") end

local espOn = false
local espHighlights = {}

-- Tracking line
local closestLine = Drawing.new("Line")
closestLine.Visible = false
closestLine.Color = Color3.new(1, 1, 0) -- Yellow
closestLine.Thickness = 1.5

-- Clear all ESP highlights
local function ClearESP()
	for player, hl in pairs(espHighlights) do
		if hl and hl.Parent then
			hl:Destroy()
		end
	end
	table.clear(espHighlights)
	closestLine.Visible = false
end

-- Button Setup
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1, 0, 0, 35)
espButton.Position = UDim2.new(0, 0, 0, 10)
espButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
espButton.TextColor3 = Color3.new(1, 1, 1)
espButton.Font = Enum.Font.GothamBold
espButton.TextSize = 18
espButton.Text = "ESP: Off"
espButton.Parent = playerTab

local corner = Instance.new("UICorner", espButton)
corner.CornerRadius = UDim.new(0, 6)

espButton.MouseButton1Click:Connect(function()
	espOn = not espOn
	espButton.Text = "ESP: " .. (espOn and "On" or "Off")
	espButton.BackgroundColor3 = espOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)
	if not espOn then ClearESP() end
end)

-- Utility: Check if player can be targeted
local function canBeDamaged(player)
	if player == LocalPlayer then return false end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
	if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
	return true
end

-- Main Render Loop
RunService.RenderStepped:Connect(function()
	if not espOn then
		ClearESP()
		return
	end

	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHRP then return end

	local closestPlayer = nil
	local closestDist = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if canBeDamaged(player) then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - myHRP.Position).Magnitude
				if dist <= MAX_DISTANCE then
					if dist < closestDist then
						closestPlayer = player
						closestDist = dist
					end

					if not espHighlights[player] or not espHighlights[player].Parent then
						if espHighlights[player] then espHighlights[player]:Destroy() end
						local hl = Instance.new("Highlight")
						hl.Adornee = char
						hl.FillTransparency = 1
						hl.OutlineTransparency = 0
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.Parent = playerTab
						espHighlights[player] = hl
					end
				else
					if espHighlights[player] then
						espHighlights[player]:Destroy()
						espHighlights[player] = nil
					end
				end
			end
		else
			if espHighlights[player] then
				espHighlights[player]:Destroy()
				espHighlights[player] = nil
			end
		end
	end

	-- Color ESP highlights
	for player, hl in pairs(espHighlights) do
		if hl and hl.Parent then
			if _G.ClosestPlayerEnabled and player == closestPlayer then
				hl.OutlineColor = Color3.new(1, 1, 0) -- Yellow
			else
				hl.OutlineColor = Color3.new(1, 0, 0) -- Red
			end
		end
	end

	-- Update tracking line
	if _G.ClosestPlayerEnabled and closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local screenPos, onScreen = Camera:WorldToViewportPoint(closestPlayer.Character.HumanoidRootPart.Position)
		local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		closestLine.From = center
		closestLine.To = Vector2.new(screenPos.X, screenPos.Y)
		closestLine.Visible = onScreen
	else
		closestLine.Visible = false
	end
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(p)
	if espHighlights[p] then
		espHighlights[p]:Destroy()
		espHighlights[p] = nil
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	ClearESP()
end)
