--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera

--// Variables
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

local CombatTab = _G.Tabs and _G.Tabs.Combat
if not CombatTab then return end

-- Settings
local RANGE = 700
local FOV = math.rad(90)

-- State
local aimbotEnabled = true
local killAuraEnabled = true
local currentTarget = nil

--// UI Button Creator
local function createToggleButton(name, defaultOn, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 40) -- full width
	button.BackgroundColor3 = defaultOn and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.Text = name .. ": " .. (defaultOn and "On" or "Off")
	button.Parent = CombatTab

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local state = defaultOn
	button.MouseButton1Click:Connect(function()
		state = not state
		button.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)
		button.Text = name .. ": " .. (state and "On" or "Off")
		callback(state)
	end)

	return button
end

--// Get Closest Target
local function getClosestTarget()
	local closest, minDist = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Team ~= LocalPlayer.Team then
			local hrp = player.Character.HumanoidRootPart
			local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
			local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
			if onScreen and distance <= RANGE then
				local dir = (hrp.Position - Camera.CFrame.Position).Unit
				local dot = dir:Dot(Camera.CFrame.LookVector)
				local angle = math.acos(dot)
				if angle <= FOV then
					if distance < minDist then
						closest = player
						minDist = distance
					end
				end
			end
		end
	end
	return closest
end

--// Aimbot Logic
RunService.RenderStepped:Connect(function()
	if not aimbotEnabled then return end

	currentTarget = getClosestTarget()
	if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
		local targetPos = currentTarget.Character.HumanoidRootPart.Position
		local cameraPos = Camera.CFrame.Position
		local dir = (targetPos - cameraPos).Unit
		local newCFrame = CFrame.new(cameraPos, cameraPos + dir)
		Camera.CFrame = newCFrame
	end
end)

--// Kill Aura Logic
RunService.Heartbeat:Connect(function()
	if not killAuraEnabled then return end

	local target = getClosestTarget()
	if target and target.Character then
		for _, part in ipairs(target.Character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
				break
			end
		end
	end
end)

--// UI Buttons
createToggleButton("Aimbot", true, function(state)
	aimbotEnabled = state
end)

createToggleButton("Kill Aura", true, function(state)
	killAuraEnabled = state
end)
