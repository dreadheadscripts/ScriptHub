-- Esp.lua (with instant refresh + advanced FFA detection)

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local MAX_DISTANCE = 700

local playerTab = _G.Tabs and _G.Tabs.Player
if not playerTab then
	warn("Player tab not found in _G.Tabs")
	return
end

-- state
local espOn = false
local espHighlights = {}        -- [player] = Highlight
local previousClosest = nil

-- Manual override for FFA (off by default)
_G.ForceFFA = (_G.ForceFFA == nil) and false or _G.ForceFFA
_G.ClosestPlayerESP = (_G.ClosestPlayerESP == nil) and false or _G.ClosestPlayerESP

-- Drawing line (if executor supports Drawing)
local hasDrawing, DrawingNew = pcall(function() return Drawing.new end)
if not _G.ClosestLine and hasDrawing and DrawingNew then
	local ok, line = pcall(DrawingNew, "Line")
	if ok and line then
		line.Thickness = 2
		line.Transparency = 1
		line.Color = Color3.new(1, 1, 0)
		line.Visible = false
		_G.ClosestLine = line
	end
end

-- helpers
local function destroyHighlightFor(player)
	local hl = espHighlights[player]
	if hl then
		pcall(function() if hl.Parent then hl:Destroy() end end)
		espHighlights[player] = nil
	end
end

local function ClearESP()
	for p,_ in pairs(espHighlights) do
		destroyHighlightFor(p)
	end
	espHighlights = {}
	previousClosest = nil
	if _G.ClosestLine then pcall(function() _G.ClosestLine.Visible = false end) end
end

local function isAlive(player)
	return player and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChild("Humanoid").Health > 0
end

-- advanced FFA check: treat as FFA if any teammate can damage me
local function canDamage(attacker, target)
	-- You might need to adjust this depending on the game
	if attacker.Team == target.Team then
		local attr = attacker:FindFirstChild("CanDamageTeammates")
		if attr and attr:IsA("BoolValue") and attr.Value then
			return true
		end
		return false
	end
	return true
end

local function isFFA()
	if _G.ForceFFA then return true end

	local myTeam = LocalPlayer.Team
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Team == myTeam then
			if canDamage(p, LocalPlayer) then
				return true
			end
		end
	end

	-- fallback: no teams means FFA
	local anyTeam = false
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Team then
			anyTeam = true
			break
		end
	end
	return not anyTeam
end

local function isEnemy(player)
	if player == LocalPlayer then return false end
	if not isAlive(player) then return false end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end

	if isFFA() then return true end
	return player.Team and LocalPlayer.Team and player.Team ~= LocalPlayer.Team
end

local function addESP(player)
	if player == LocalPlayer then return end

	local function refreshESP()
		if not espOn then return end
		if isEnemy(player) then
			if not espHighlights[player] or not espHighlights[player].Parent then
				destroyHighlightFor(player)
				local h = Instance.new("Highlight")
				h.Adornee = player.Character
				h.FillTransparency = 1
				h.OutlineTransparency = 0
				h.OutlineColor = Color3.fromRGB(255,0,0)
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = CoreGui
				espHighlights[player] = h
			end
		else
			destroyHighlightFor(player)
		end
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.1) -- slight delay for character load
		refreshESP()
	end)

	if player.Character then
		refreshESP()
	end
end

-- ESP button
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1, 0, 0, 35)
espButton.Position = UDim2.new(0, 0, 0, 10)
espButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
espButton.TextColor3 = Color3.new(1,1,1)
espButton.Font = Enum.Font.GothamBold
espButton.TextSize = 18
espButton.Text = "ESP: Off"
espButton.Parent = playerTab
local corner = Instance.new("UICorner", espButton); corner.CornerRadius = UDim.new(0,6)

espButton.MouseButton1Click:Connect(function()
	espOn = not espOn
	espButton.Text = "ESP: " .. (espOn and "On" or "Off")
	espButton.BackgroundColor3 = espOn and Color3.fromRGB(0,180,0) or Color3.fromRGB(40,40,40)
	if espOn then
		ClearESP()
		for _, p in ipairs(Players:GetPlayers()) do
			addESP(p)
		end
	else
		ClearESP()
	end
end)

-- Force FFA toggle
local ffaBtn = Instance.new("TextButton")
ffaBtn.Size = UDim2.new(0.48, -4, 0, 30)
ffaBtn.Position = UDim2.new(0, 0, 0, 50)
ffaBtn.BackgroundColor3 = _G.ForceFFA and Color3.fromRGB(0,180,0) or Color3.fromRGB(40,40,40)
ffaBtn.Text = "Force FFA: " .. (_G.ForceFFA and "On" or "Off")
ffaBtn.Font = Enum.Font.GothamBold
ffaBtn.TextSize = 16
ffaBtn.TextColor3 = Color3.new(1,1,1)
ffaBtn.Parent = playerTab
Instance.new("UICorner", ffaBtn).CornerRadius = UDim.new(0,6)

ffaBtn.MouseButton1Click:Connect(function()
	_G.ForceFFA = not _G.ForceFFA
	ffaBtn.Text = "Force FFA: " .. (_G.ForceFFA and "On" or "Off")
	ffaBtn.BackgroundColor3 = _G.ForceFFA and Color3.fromRGB(0,180,0) or Color3.fromRGB(40,40,40)
	if espOn then
		ClearESP()
		for _, p in ipairs(Players:GetPlayers()) do
			addESP(p)
		end
	end
end)

-- FFA mode label
local heurLabel = Instance.new("TextLabel")
heurLabel.Size = UDim2.new(0.48, -4, 0, 30)
heurLabel.Position = UDim2.new(0.52, 0, 0, 50)
heurLabel.BackgroundTransparency = 1
heurLabel.TextColor3 = Color3.new(1,1,1)
heurLabel.Font = Enum.Font.Gotham
heurLabel.TextSize = 14
heurLabel.Text = ""
heurLabel.Parent = playerTab

-- live update loop
RunService.RenderStepped:Connect(function()
	heurLabel.Text = isFFA() and "Mode: FFA" or "Mode: Teams"
end)

-- events for joins/leaves
Players.PlayerAdded:Connect(function(p)
	if espOn then
		addESP(p)
	end
end)

Players.PlayerRemoving:Connect(function(p)
	destroyHighlightFor(p)
	if previousClosest == p then previousClosest = nil end
end)

LocalPlayer.CharacterAdded:Connect(function()
	if espOn then
		ClearESP()
		for _, p in ipairs(Players:GetPlayers()) do
			addESP(p)
		end
	end
end)
