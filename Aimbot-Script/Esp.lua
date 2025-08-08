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
local closestLine = Drawing.new("Line")
closestLine.Visible = false
closestLine.Color = Color3.new(1, 1, 0) -- Yellow
closestLine.Thickness = 1.5

-- Cleanup function
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

-- Detect FFA
local function isFFA()
    local myTeam = LocalPlayer.Team
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= myTeam then
            return false -- Found someone on a different team, so it's not FFA
        end
    end
    return true -- Everyone's on the same team (FFA or no teams)
end

-- Check if enemy
local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end

    if isFFA() then
        return true -- FFA mode: everyone except you is an enemy
    else
        return player.Team ~= LocalPlayer.Team
    end
end

-- Function to determine if a player is a valid enemy
local function canBeDamaged(player)
	if player == LocalPlayer then return false end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
	if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
	return true
end

-- ESP Update Loop
RunService.RenderStepped:Connect(function()
	if not espOn then ClearESP() return end

	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHRP then return end

	local closest, closestDist = nil, math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if canBeDamaged(player) then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - myHRP.Position).Magnitude
				if dist <= MAX_DISTANCE then
					if dist < closestDist then
						closest = player
						closestDist = dist
					end

					if not espHighlights[player] or not espHighlights[player].Parent then
						if espHighlights[player] then espHighlights[player]:Destroy() end
						local hl = Instance.new("Highlight")
						hl.Adornee = char
						hl.FillTransparency = 1
						hl.OutlineTransparency = 0
						hl.OutlineColor = Color3.new(1, 0, 0) -- Default red
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

	-- Apply yellow highlight and tracking line if closest player toggle is enabled
	if _G.ClosestPlayerESP and closest and espHighlights[closest] then
		for player, hl in pairs(espHighlights) do
			if hl then
				hl.OutlineColor = (player == closest) and Color3.new(1, 1, 0) or Color3.new(1, 0, 0)
			end
		end

		local char = closest.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local screenPos, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
			if onScreen then
				local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
				closestLine.From = center
				closestLine.To = Vector2.new(screenPos.X, screenPos.Y)
				closestLine.Visible = true
			else
				closestLine.Visible = false
			end
		end
	else
		closestLine.Visible = false
	end
end)

local previousClosestPlayer = nil

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
						closestDist = dist
						closestPlayer = player
					end

					-- Create or update highlight
					if not espHighlights[player] or not espHighlights[player].Parent then
						if espHighlights[player] then
							espHighlights[player]:Destroy()
						end
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

	-- Handle closest player coloring
	for player, hl in pairs(espHighlights) do
		if hl and hl.Parent then
			if _G.ClosestPlayerEnabled and player == closestPlayer then
				hl.OutlineColor = Color3.new(1, 1, 0) -- Yellow
			else
				hl.OutlineColor = Color3.new(1, 0, 0) -- Red
			end
		end
	end

	-- Optional: yellow tracking line (if enabled)
	if _G.ClosestPlayerEnabled then
		if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = closestPlayer.Character.HumanoidRootPart
			if not _G.ClosestLine then
				local line = Drawing.new("Line")
				line.Color = Color3.new(1, 1, 0)
				line.Thickness = 2
				line.Transparency = 1
				line.ZIndex = 2
				line.Visible = true
				_G.ClosestLine = line
			end

			local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
			local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
			_G.ClosestLine.From = center
			_G.ClosestLine.To = Vector2.new(screenPos.X, screenPos.Y)
			_G.ClosestLine.Visible = onScreen
		end
	else
		-- Remove the yellow line if toggled off
		if _G.ClosestLine then
			_G.ClosestLine.Visible = false
			_G.ClosestLine:Remove()
			_G.ClosestLine = nil
		end
	end
end)

-- Cleanup on player removal
Players.PlayerRemoving:Connect(function(p)
	if espHighlights[p] then
		espHighlights[p]:Destroy()
		espHighlights[p] = nil
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	ClearESP()
end)
