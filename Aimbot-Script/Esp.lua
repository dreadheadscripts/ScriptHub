--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Tabs reference
local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then return warn("Player tab missing") end

--// Globals
_G.ESPEnabled = true
_G.TargetTracking = nil -- Set by aimbot/kill aura
local highlights = {}
local closestEnemy = nil
local tracerLine = nil

--// ESP Toggle Button
local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(0, 150, 0, 40)
espBtn.Position = UDim2.new(0, 10, 0, 60)
espBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
espBtn.Text = "ESP: On"
espBtn.TextColor3 = Color3.new(1, 1, 1)
espBtn.Font = Enum.Font.GothamBold
espBtn.TextSize = 18
espBtn.Parent = playerTab

Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 6)

espBtn.MouseButton1Click:Connect(function()
	_G.ESPEnabled = not _G.ESPEnabled
	espBtn.Text = _G.ESPEnabled and "ESP: On" or "ESP: Off"
	espBtn.BackgroundColor3 = _G.ESPEnabled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(45, 45, 55)

	if not _G.ESPEnabled then
		for _, h in pairs(highlights) do if h then h:Destroy() end end
		highlights = {}
		if tracerLine then tracerLine:Remove() tracerLine = nil end
	end
end)

--// Utilities
local function isEnemy(player)
	if player == LocalPlayer then return false end
	if not player.Team or not LocalPlayer.Team then return true end
	return player.Team ~= LocalPlayer.Team
end

local function isAlive(player)
	local human = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return human and human.Health > 0
end

local function hasSpawnProtection(player)
	return player.Character and player.Character:FindFirstChild("ForceField")
end

local function getRoot(player)
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function createHighlight(player)
	local hl = Instance.new("Highlight")
	hl.Name = "ESP_Highlight"
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.OutlineColor = Color3.fromRGB(255, 0, 0)
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = player.Character
	hl.Parent = game:GetService("CoreGui")
	return hl
end

local function updateESP()
	if not _G.ESPEnabled then return end
	local myHRP = getRoot(LocalPlayer)
	if not myHRP then return end

	local closestDist = math.huge
	local closestPlr = nil

	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = getRoot(plr)
		if hrp and isEnemy(plr) and not hasSpawnProtection(plr) then
			local dist = (myHRP.Position - hrp.Position).Magnitude
			if dist < closestDist then
				closestDist = dist
				closestPlr = plr
			end

			if not highlights[plr] then
				highlights[plr] = createHighlight(plr)
			end

			local tracking = (_G.TargetTracking == plr)
			local color = Color3.fromRGB(255, 0, 0)
			if plr == closestPlr then
				color = Color3.fromRGB(255, 255, 0) -- Yellow if closest
			elseif tracking then
				color = Color3.fromRGB(0, 255, 0) -- Green if tracking
			end

			highlights[plr].OutlineColor = color
		else
			if highlights[plr] then
				highlights[plr]:Destroy()
				highlights[plr] = nil
			end
		end
	end

	-- Tracking line
	if tracerLine then tracerLine:Remove() tracerLine = nil end
	if closestPlr and _G.ESPEnabled then
		local enemyHRP = getRoot(closestPlr)
		if enemyHRP then
			tracerLine = Drawing.new("Line")
			tracerLine.Visible = true
			tracerLine.From = Camera.ViewportSize / 2
			local screenPos, onScreen = Camera:WorldToViewportPoint(enemyHRP.Position)
			if onScreen then
				tracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
				tracerLine.Color = Color3.fromRGB(255, 255, 0)
				tracerLine.Thickness = 2
			else
				tracerLine.Visible = false
			end
		end
	end
end

--// Constant Updater
RunService.RenderStepped:Connect(function()
	pcall(updateESP)
end)

--// Refresh when players join/respawn
local function watchPlayer(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		if _G.ESPEnabled then
			if highlights[player] then highlights[player]:Destroy() end
			highlights[player] = createHighlight(player)
		end
	end)

	player.CharacterRemoving:Connect(function()
		if highlights[player] then
			highlights[player]:Destroy()
			highlights[player] = nil
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then watchPlayer(player) end
end

Players.PlayerAdded:Connect(watchPlayer)
