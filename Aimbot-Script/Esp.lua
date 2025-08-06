--// ESP SCRIPT (Player Tab)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- Make sure Player tab exists
local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then return warn("Player tab not found") end

-- Globals
_G.ESPEnabled = true
local highlights = {}
local closestLabel = nil
local trackingLine = nil
local previousClosest = nil

-- ESP Button
local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(0, 150, 0, 40)
espBtn.Position = UDim2.new(0, 10, 0, 60)
espBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- green = on
espBtn.TextColor3 = Color3.new(1, 1, 1)
espBtn.Font = Enum.Font.GothamBold
espBtn.TextSize = 18
espBtn.Text = "ESP: On"
espBtn.Parent = playerTab

local corner = Instance.new("UICorner", espBtn)
corner.CornerRadius = UDim.new(0, 6)

espBtn.MouseButton1Click:Connect(function()
	_G.ESPEnabled = not _G.ESPEnabled
	espBtn.Text = _G.ESPEnabled and "ESP: On" or "ESP: Off"
	espBtn.BackgroundColor3 = _G.ESPEnabled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(45, 45, 55)

	if not _G.ESPEnabled then
		for _, h in pairs(highlights) do
			if h and h.Parent then h:Destroy() end
		end
		highlights = {}
		if closestLabel then closestLabel.Visible = false end
		if trackingLine then
			trackingLine:Destroy()
			trackingLine = nil
		end
		previousClosest = nil
	end
end)

-- Closest Label
closestLabel = Instance.new("TextLabel")
closestLabel.Size = UDim2.new(0, 200, 0, 25)
closestLabel.Position = UDim2.new(0.5, -100, 0.8, 0)
closestLabel.AnchorPoint = Vector2.new(0.5, 0)
closestLabel.BackgroundTransparency = 1
closestLabel.TextColor3 = Color3.new(1, 1, 1)
closestLabel.TextStrokeTransparency = 0
closestLabel.Font = Enum.Font.GothamBold
closestLabel.TextSize = 20
closestLabel.Text = ""
closestLabel.Visible = true
closestLabel.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Helper functions
local function isAlive(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0
end

local function hasSpawnProtection(player)
	return player.Character and player.Character:FindFirstChildOfClass("ForceField") ~= nil
end

local function canDamageYou(player)
	local myTeam = LocalPlayer.Team
	local theirTeam = player.Team
	if not myTeam or not theirTeam then return true end
	return myTeam ~= theirTeam
end

local function isValidTarget(player)
	if player == LocalPlayer then return false end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
	if not canDamageYou(player) then return false end
	-- ESP should appear on enemies even if dead or spawn protected
	return true
end

local function isVisible(part)
	local origin = Camera.CFrame.Position
	local direction = (part.Position - origin).Unit * 500
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
	local result = workspace:Raycast(origin, direction, raycastParams)
	return not result or (result.Instance and result.Instance:IsDescendantOf(part.Parent))
end

-- Refresh ESP highlight for player
local function refreshPlayerHighlight(player)
	if highlights[player] then
		highlights[player]:Destroy()
		highlights[player] = nil
	end

	if not isValidTarget(player) then return end

	local char = player.Character
	if not char then return end

	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = Color3.fromRGB(255, 0, 0) -- red default
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = char
	highlight.Parent = game:GetService("CoreGui")

	highlights[player] = highlight
end

-- Draw or update tracking line to closest player
local function updateTrackingLine(target)
	if trackingLine then
		trackingLine:Destroy()
		trackingLine = nil
	end
	if not target or not target.Character then return end
	local hrp = target.Character:FindFirstChild("HumanoidRootPart")
	local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not localHRP then return end

	local line = Drawing and Drawing.new and Drawing.new("Line") or nil
	if not line then return end
	trackingLine = line
	line.Color = Color3.fromRGB(255, 255, 0)
	line.Thickness = 2
	line.Transparency = 1

	-- Update line position every frame
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not _G.ESPEnabled or not target.Character or not localHRP.Parent then
			line:Remove()
			conn:Disconnect()
			trackingLine = nil
			return
		end
		local vectorFrom = Camera:WorldToViewportPoint(localHRP.Position)
		local vectorTo = Camera:WorldToViewportPoint(hrp.Position)
		line.From = Vector2.new(vectorFrom.X, vectorFrom.Y)
		line.To = Vector2.new(vectorTo.X, vectorTo.Y)
	end)
end

-- Update ESP and closest tracking
local function updateESP()
	if not _G.ESPEnabled then return end
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

	local closestDist = math.huge
	local closestPlayer = nil

	for _, player in pairs(Players:GetPlayers()) do
		if isValidTarget(player) then
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp and isVisible(hrp) then
				local dist = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestPlayer = player
				end
			end
		end
	end

	-- Only update highlights if the closest player changed
	if closestPlayer ~= previousClosest then
		for plr, hl in pairs(highlights) do
			if not isValidTarget(plr) then
				hl:Destroy()
				highlights[plr] = nil
			else
				if plr == closestPlayer then
					hl.OutlineColor = Color3.fromRGB(255, 255, 0) -- yellow for closest
				else
					hl.OutlineColor = Color3.fromRGB(255, 0, 0) -- red for others
				end
			end
		end

		updateTrackingLine(closestPlayer)

		previousClosest = closestPlayer
	end

	if closestPlayer then
		closestLabel.Text = "Closest: " .. closestPlayer.Name .. " [" .. math.floor(closestDist) .. "m]"
		closestLabel.Visible = true
	else
		closestLabel.Visible = false
		if trackingLine then
			trackingLine:Destroy()
			trackingLine = nil
		end
		previousClosest = nil
	end
end

-- Main Render Loop
RunService.RenderStepped:Connect(function()
	if _G.ESPEnabled then
		pcall(updateESP)
	end
end)

-- Constant Refreshers
local function trackPlayer(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		if _G.ESPEnabled then refreshPlayerHighlight(player) end
	end)

	player.CharacterRemoving:Connect(function()
		if highlights[player] then
			highlights[player]:Destroy()
			highlights[player] = nil
		end
	end)

	if player.Character then
		task.delay(1, function()
			if _G.ESPEnabled then refreshPlayerHighlight(player) end
		end)
	end
end

-- When player joins
Players.PlayerAdded:Connect(trackPlayer)

-- Existing players
for _, player in pairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		trackPlayer(player)
	end
end
