-- Esp.lua (with Force FFA toggle & improved handling)
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

-- Improved FFA detection:
-- 1) If _G.ForceFFA == true -> FFA
-- 2) If no team values assigned at all (everyone.Team == nil) -> FFA
-- 3) If everyone (except you) is on the same team as you -> FFA
-- NOTE: This is a heuristic; some games use server-only friendly-fire toggles that can't be read client-side.
local function isFFA()
	if _G.ForceFFA then return true end

	-- check if any player has a non-nil team assigned
	local anyTeamAssigned = false
	for _,p in ipairs(Players:GetPlayers()) do
		if p.Team ~= nil then
			anyTeamAssigned = true
			break
		end
	end
	if not anyTeamAssigned then
		-- no teams in use -> treat as FFA
		return true
	end

	-- if everyone else is on same team as local player => FFA
	local myTeam = LocalPlayer.Team
	local totalOthers = 0
	local sameTeamCount = 0
	for _,p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			totalOthers = totalOthers + 1
			if p.Team == myTeam then
				sameTeamCount = sameTeamCount + 1
			end
		end
	end

	if totalOthers > 0 and sameTeamCount == totalOthers then
		return true
	end

	return false
end

-- enemy test (no wall checks here per your request)
local function isEnemy(player)
	if player == LocalPlayer then return false end
	if not isAlive(player) then return false end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end

	if isFFA() then
		return true
	end

	-- normal team-based check
	if LocalPlayer.Team == nil or player.Team == nil then
		-- conservative: if teams undefined, treat as non-enemy unless isFFA() true
		return false
	end

	return player.Team ~= LocalPlayer.Team
end

-- ESP button (full width, like Aimbot)
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
	if not espOn then ClearESP() end
end)

-- Force FFA toggle button right under ESP button
local ffaBtn = Instance.new("TextButton")
ffaBtn.Size = UDim2.new(0.48, -4, 0, 30) -- left half under esp
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
	-- resetting highlights is useful so the UI immediately reflects mode change
	if espOn then
		ClearESP()
	end
end)

-- (Optional) small label on right showing current auto-FFA heuristic result
local heurLabel = Instance.new("TextLabel")
heurLabel.Size = UDim2.new(0.48, -4, 0, 30)
heurLabel.Position = UDim2.new(0.52, 0, 0, 50)
heurLabel.BackgroundTransparency = 1
heurLabel.TextColor3 = Color3.new(1,1,1)
heurLabel.Font = Enum.Font.Gotham
heurLabel.TextSize = 14
heurLabel.Text = "" -- updated live
heurLabel.Parent = playerTab

-- main update loop (single loop to handle highlights + closest)
RunService.RenderStepped:Connect(function()
	heurLabel.Text = isFFA() and "Mode: FFA" or "Mode: Teams"

	if not espOn then
		-- ensure cleaned up
		-- (don't ClearESP every tick to avoid GC thrash; only if not already empty)
		if next(espHighlights) then ClearESP() end
		return
	end

	local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myHRP then
		if next(espHighlights) then ClearESP() end
		return
	end

	-- find closest valid enemy
	local closestPlayer = nil
	local closestDist = math.huge
	local seen = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if isEnemy(player) then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - myHRP.Position).Magnitude
				if dist <= MAX_DISTANCE then
					seen[player] = true
					-- create highlight if missing
					if not espHighlights[player] or not espHighlights[player].Parent then
						if espHighlights[player] then pcall(function() espHighlights[player]:Destroy() end) end
						local ok, hl = pcall(function()
							local h = Instance.new("Highlight")
							h.Adornee = char
							h.FillTransparency = 1
							h.OutlineTransparency = 0
							h.OutlineColor = Color3.fromRGB(255,0,0)
							h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
							h.Parent = CoreGui
							return h
						end)
						if ok and hl then espHighlights[player] = hl end
					end

					if dist < closestDist then
						closestDist = dist
						closestPlayer = player
					end
				end
			end
		end
	end

	-- remove highlights for players no longer valid/seen
	for p,_ in pairs(espHighlights) do
		if not seen[p] then destroyHighlightFor(p) end
	end

	-- Handle closest-player coloring + tracking line
	if _G.ClosestPlayerESP and closestPlayer and espHighlights[closestPlayer] then
		-- reset previous if changed
		if previousClosest and previousClosest ~= closestPlayer then
			if espHighlights[previousClosest] and espHighlights[previousClosest].Parent then
				pcall(function() espHighlights[previousClosest].OutlineColor = Color3.fromRGB(255,0,0) end)
			end
		end

		-- color closest yellow
		pcall(function() espHighlights[closestPlayer].OutlineColor = Color3.fromRGB(255,255,0) end)
		previousClosest = closestPlayer

		-- update line
		if _G.ClosestLine then
			local hrp = closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
				local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
				_G.ClosestLine.From = center
				_G.ClosestLine.To = Vector2.new(screenPos.X, screenPos.Y)
				_G.ClosestLine.Visible = onScreen
			else
				_G.ClosestLine.Visible = false
			end
		end
	else
		-- not enabled or no closest -> ensure line hidden and reset previous highlight
		if previousClosest then
			if espHighlights[previousClosest] and espHighlights[previousClosest].Parent then
				pcall(function() espHighlights[previousClosest].OutlineColor = Color3.fromRGB(255,0,0) end)
			end
			previousClosest = nil
		end
		if _G.ClosestLine then pcall(function() _G.ClosestLine.Visible = false end) end
	end
end)

-- cleanup on player events
Players.PlayerRemoving:Connect(function(p)
	destroyHighlightFor(p)
	if previousClosest == p then previousClosest = nil end
end)

LocalPlayer.CharacterAdded:Connect(function()
	ClearESP()
end)
