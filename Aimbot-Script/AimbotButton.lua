--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

--// Tabs
local CombatTab = _G.Tabs and _G.Tabs.Combat
if not CombatTab then return warn("❌ Combat tab not found") end

--// Config
local RANGE = 700
local FOV = 300

--// State
local aimbotEnabled = false
local killAuraEnabled = false
local currentTarget = nil
local trackingLine = Drawing.new("Line")
trackingLine.Visible = false
trackingLine.Thickness = 2

--// ESP Integration (for dot coloring)
_G.AimbotTarget = nil

--// Create Button
local function createToggleButton(name, defaultOn, parent, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 35)
	button.BackgroundColor3 = defaultOn and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(40, 40, 40)
	button.Text = name .. ": " .. (defaultOn and "On" or "Off")
	button.TextColor3 = Color3.new(1,1,1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.Parent = parent

	local corner = Instance.new("UICorner", button)
	corner.CornerRadius = UDim.new(0, 6)

	local toggled = defaultOn
	button.MouseButton1Click:Connect(function()
		toggled = not toggled
		button.Text = name .. ": " .. (toggled and "On" or "Off")
		button.BackgroundColor3 = toggled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(40, 40, 40)
		callback(toggled)
	end)

	callback(defaultOn)

	return button
end

--// Get Closest Valid Enemy
local function getClosestEnemy()
	local closest = nil
	local shortestDist = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if player.Team == LocalPlayer.Team then continue end

			local hrp = player.Character.HumanoidRootPart
			local screenPoint, onScreen = Camera:WorldToViewportPoint(hrp.Position)
			if not onScreen then continue end
			if (Camera.CFrame.Position - hrp.Position).Magnitude > RANGE then continue end

			local fovDist = (Vector2.new(screenPoint.X, screenPoint.Y) - Camera.ViewportSize / 2).Magnitude
			if fovDist > FOV then continue end

			local ray = Ray.new(Camera.CFrame.Position, (hrp.Position - Camera.CFrame.Position).Unit * 1000)
			local hitPart, hitPos = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character}, false, true)
			if not hitPart or not player.Character:IsAncestorOf(hitPart) then continue end

			if fovDist < shortestDist then
				shortestDist = fovDist
				closest = player
			end
		end
	end

	return closest
end

--// Aimbot + KillAura Loop
RunService.RenderStepped:Connect(function()
	if not aimbotEnabled and not killAuraEnabled then
		currentTarget = nil
		trackingLine.Visible = false
		_G.AimbotTarget = nil
		return
	end

	local target = getClosestEnemy()
	if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
		currentTarget = target
		local hrp = target.Character.HumanoidRootPart
		local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

		-- Aimbot
		if aimbotEnabled then
			local direction = (hrp.Position - Camera.CFrame.Position).Unit
			local newLookVector = CFrame.new(Camera.CFrame.Position, hrp.Position)
			Camera.CFrame = Camera.CFrame:Lerp(newLookVector, 0.12)
		end

		-- Kill Aura
		if killAuraEnabled then
			local head = target.Character:FindFirstChild("Head")
			if head then
				pcall(function()
					VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
					VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
				end)
			end
		end

		-- Tracking line
		trackingLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		trackingLine.To = Vector2.new(screenPos.X, screenPos.Y)
		trackingLine.Color = Color3.fromRGB(0, 255, 0)
		trackingLine.Visible = true

		-- ESP sync
		_G.AimbotTarget = target

	else
		currentTarget = nil
		trackingLine.Visible = false
		_G.AimbotTarget = nil
	end
end)

--// Create Buttons
createToggleButton("Aimbot", false, CombatTab, function(state)
	aimbotEnabled = state
end)

createToggleButton("Kill Aura", false, CombatTab, function(state)
	killAuraEnabled = state
end)
