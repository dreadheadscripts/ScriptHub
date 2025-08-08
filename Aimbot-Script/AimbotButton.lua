--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

--// Config
local AIMBOT_FOV = 300
local AIMBOT_RANGE = 700

--// Tabs
local CombatTab = _G.Tabs and _G.Tabs.Combat

--// GUI Toggle Button
local aimbotButton = Instance.new("TextButton")
aimbotButton.Size = UDim2.new(1, -20, 0, 35)
aimbotButton.Position = UDim2.new(0, 10, 0, 10)
aimbotButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
aimbotButton.TextColor3 = Color3.new(1, 1, 1)
aimbotButton.Font = Enum.Font.GothamBold
aimbotButton.TextSize = 16
aimbotButton.Text = "Aimbot: Off"
aimbotButton.Parent = CombatTab

local corner = Instance.new("UICorner", aimbotButton)
corner.CornerRadius = UDim.new(0, 6)

--// Aimbot State
local aimbotEnabled = false
local currentTarget = nil
local trackingLine = Drawing.new("Line")
trackingLine.Thickness = 2
trackingLine.Color = Color3.fromRGB(0, 255, 0)
trackingLine.Visible = false

--// Wall Check Function
local function hasLineOfSight(targetPart)
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
	local result = workspace:Raycast(origin, direction, rayParams)
	return not result
end

--// Get Closest Enemy
local function getClosestEnemy()
	local closest = nil
	local shortestDistance = AIMBOT_RANGE

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = player.Character.HumanoidRootPart
			local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
			local distance = (Camera.CFrame.Position - hrp.Position).Magnitude

			local sameTeam = player.Team == LocalPlayer.Team
			local visible = hasLineOfSight(hrp)

			if onScreen and distance < shortestDistance and not sameTeam and visible then
				shortestDistance = distance
				closest = player
			end
		end
	end

	return closest
end

--// Update ESP (assumes Esp.lua uses _G.ESP_DOTS)
local function updateEspColors()
	if not _G.ESP_DOTS then return end

	for player, dot in pairs(_G.ESP_DOTS) do
		if player == currentTarget then
			dot.Color = Color3.fromRGB(0, 255, 0) -- green
		else
			dot.Color = Color3.fromRGB(255, 0, 0) -- red
		end
	end
end

--// Aimbot Logic
RunService.RenderStepped:Connect(function()
	if not aimbotEnabled then
		trackingLine.Visible = false
		currentTarget = nil
		return
	end

	local target = getClosestEnemy()
	currentTarget = target

	if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = target.Character.HumanoidRootPart
		local screenPos = Camera:WorldToViewportPoint(hrp.Position)

		-- Tracking line
		trackingLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		trackingLine.To = Vector2.new(screenPos.X, screenPos.Y)
		trackingLine.Visible = true

		-- Smooth aim
		local targetPos = CFrame.lookAt(Camera.CFrame.Position, hrp.Position)
		Camera.CFrame = Camera.CFrame:Lerp(targetPos, 0.15)

		updateEspColors()
	else
		trackingLine.Visible = false
		currentTarget = nil
	end
end)

--// Toggle Behavior
aimbotButton.MouseButton1Click:Connect(function()
	aimbotEnabled = not aimbotEnabled
	aimbotButton.Text = "Aimbot: " .. (aimbotEnabled and "On" or "Off")
	aimbotButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)
	if not aimbotEnabled then
		trackingLine.Visible = false
		currentTarget = nil
	end
end)
