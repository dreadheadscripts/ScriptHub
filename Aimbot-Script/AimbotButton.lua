--// Aimbot Button + Logic (GitHub-loaded)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Make sure Combat tab exists
local combatTab = _G.Tabs and _G.Tabs.Combat
if not combatTab then return warn("Combat tab not found") end

-- Aimbot state
_G.AimbotEnabled = false

-- Settings
local TARGET_PART = "Head"
local FOV_RADIUS = 300
local AUTO_CLICK_INTERVAL = 0.1
local lastClick = 0

-- Create Aimbot Toggle Button
local aimbotBtn = Instance.new("TextButton")
aimbotBtn.Size = UDim2.new(0, 150, 0, 40)
aimbotBtn.Position = UDim2.new(0, 10, 0, 10)
aimbotBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
aimbotBtn.TextColor3 = Color3.new(1, 1, 1)
aimbotBtn.Font = Enum.Font.GothamBold
aimbotBtn.TextSize = 18
aimbotBtn.Text = "Aimbot: Off"
aimbotBtn.Parent = combatTab

local corner = Instance.new("UICorner", aimbotBtn)
corner.CornerRadius = UDim.new(0, 6)

-- Toggle handler
aimbotBtn.MouseButton1Click:Connect(function()
	_G.AimbotEnabled = not _G.AimbotEnabled
	aimbotBtn.Text = _G.AimbotEnabled and "Aimbot: On" or "Aimbot: Off"
	aimbotBtn.BackgroundColor3 = _G.AimbotEnabled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(45, 45, 55)
end)

-- Helper: Check visibility and distance
local function isValidTarget(player)
	if player == LocalPlayer or not player.Character then return false end

	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local targetPart = player.Character:FindFirstChild(TARGET_PART)

	if not hrp or not humanoid or not targetPart then return false end
	if humanoid.Health <= 0 then return false end

	-- Invincibility or spawn protection check
	if player:FindFirstChild("Spawned") or player:FindFirstChild("Invincible") then return false end

	-- Wall check using raycast
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin).Unit * 500
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
	local result = workspace:Raycast(origin, direction, raycastParams)

	if result and result.Instance and not targetPart:IsDescendantOf(result.Instance.Parent) then
		return false -- Hit a wall
	end

	return true
end

-- Helper: Find best target
local function getClosestTarget()
	local closest, minDist = nil, FOV_RADIUS

	for _, plr in pairs(Players:GetPlayers()) do
		if isValidTarget(plr) then
			local part = plr.Character and plr.Character:FindFirstChild(TARGET_PART)
			if part then
				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
					if dist < minDist then
						closest = part
						minDist = dist
					end
				end
			end
		end
	end

	return closest
end

-- Helper: Smooth aim
local function aimAt(part)
	local camCF = Camera.CFrame
	local targetPos = part.Position
	local direction = (targetPos - camCF.Position).Unit
	local goal = CFrame.new(camCF.Position, camCF.Position + direction)

	-- Smooth rotation
	Camera.CFrame = camCF:Lerp(goal, 0.15)
end

-- Simulate mobile click
local function autoClick()
	if tick() - lastClick < AUTO_CLICK_INTERVAL then return end
	lastClick = tick()

	local virtualInput = game:GetService("VirtualInputManager")
	virtualInput:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 0)
	virtualInput:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 0)
end

-- Aimbot loop
RunService.RenderStepped:Connect(function()
	if not _G.AimbotEnabled then return end

	local target = getClosestTarget()
	if target then
		aimAt(target)
		autoClick()
	end
end)
