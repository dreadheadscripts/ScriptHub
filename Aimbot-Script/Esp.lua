--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Settings
local RANGE = 700

--// ESP Storage
local espDots = {}
local trackingLine = Drawing.new("Line")
trackingLine.Visible = false
trackingLine.Thickness = 2
trackingLine.Color = Color3.fromRGB(255, 255, 0)

--// Cleanup dead drawings
local function clearESP()
	for _, dot in pairs(espDots) do
		dot:Remove()
	end
	espDots = {}
end

--// Validate player
local function isValidTarget(plr)
	if plr == LocalPlayer then return false end
	if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return false end
	if not plr.Character:FindFirstChildOfClass("Humanoid") or plr.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then return false end
	if plr.Team == LocalPlayer.Team then return false end
	if (plr.Character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude > RANGE then return false end

	-- Visibility check
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
	local rayResult = workspace:Raycast(Camera.CFrame.Position, (plr.Character.HumanoidRootPart.Position - Camera.CFrame.Position).Unit * 1000, rayParams)

	if rayResult and not plr.Character:IsAncestorOf(rayResult.Instance) then
		return false
	end

	return true
end

--// Get closest visible enemy
local function getClosestVisibleEnemy()
	local closest
	local minDist = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if isValidTarget(player) then
			local pos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
			if onScreen then
				local dist = (Vector2.new(pos.X, pos.Y) - Camera.ViewportSize / 2).Magnitude
				if dist < minDist then
					minDist = dist
					closest = player
				end
			end
		end
	end

	return closest
end

--// Main ESP Loop
RunService.RenderStepped:Connect(function()
	clearESP()
	local closestEnemy = getClosestVisibleEnemy()
	local target = _G.AimbotTarget

	for _, player in ipairs(Players:GetPlayers()) do
		if isValidTarget(player) then
			local pos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
			if onScreen then
				local dot = Drawing.new("Circle")
				dot.Radius = 5
				dot.Thickness = 2
				dot.Filled = true
				dot.Position = Vector2.new(pos.X, pos.Y)

				-- Color logic
				if player == target then
					dot.Color = Color3.fromRGB(0, 255, 0) -- Green if tracked
				elseif player == closestEnemy then
					dot.Color = Color3.fromRGB(255, 255, 0) -- Yellow if closest
				else
					dot.Color = Color3.fromRGB(255, 0, 0) -- Red otherwise
				end

				dot.Visible = true
				table.insert(espDots, dot)
			end
		end
	end

	-- Tracking line logic
	if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
		local screenPos, onScreen = Camera:WorldToViewportPoint(target.Character.HumanoidRootPart.Position)
		if onScreen then
			trackingLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
			trackingLine.To = Vector2.new(screenPos.X, screenPos.Y)
			trackingLine.Color = Color3.fromRGB(0, 255, 0)
			trackingLine.Visible = true
		else
			trackingLine.Visible = false
		end
	else
		trackingLine.Visible = false
	end
end)
