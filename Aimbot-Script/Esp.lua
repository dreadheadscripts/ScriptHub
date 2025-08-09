-- Esp.lua (fixed)
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

-- State
local espOn = false
local espHighlights = {}        -- [player] = Highlight
local previousClosest = nil
_G.ClosestPlayerESP = _G.ClosestPlayerESP or false

-- Drawing line (safely)
local hasDrawing, DrawingNew = pcall(function() return Drawing.new end)
local function newLine()
	if hasDrawing and DrawingNew then
		local ok, line = pcall(DrawingNew, "Line")
		if ok and line then
			line.Thickness = 2
			line.Transparency = 1
			line.Color = Color3.new(1, 1, 0)
			line.Visible = false
			return line
		end
	end
	return nil
end

_G.ClosestLine = _G.ClosestLine or newLine()

-- Utility: cleanup
local function destroyHighlightFor(player)
	local hl = espHighlights[player]
	if hl then
		pcall(function()
			if hl.Parent then hl:Destroy() end
		end)
		espHighlights[player] = nil
	end
end

local function ClearESP()
	for p,_ in pairs(espHighlights) do
		destroyHighlightFor(p)
	end
	espHighlights = {}
	previousClosest = nil
	if _G.ClosestLine then
		pcall(function() _G.ClosestLine.Visible = false end)
	end
end

-- Detect FFA: returns true when there is no team system or everyone is on same team
local function isFFA()
	-- If no one has a team assigned (all nil) -> treat as FFA
	local anyTeamAssigned = false
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Team ~= nil then
			anyTeamAssigned = true
			break
		end
	end

	if not anyTeamAssigned then
		return true
	end

	-- If everyone has the same team as LocalPlayer (or LocalPlayer has nil and everyone nil) -> FFA
	local myTeam = LocalPlayer.Team
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Team ~= myTeam then
			return false -- found different team -> not FFA
		end
	end

	-- all same team -> treat as FFA
	return true
end

local function isAlive(player)
	return player and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChild("Humanoid").Health > 0
end

local function isEnemy(player)
	if not player or player == LocalPlayer then return false end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
	if not isAlive(player) then return false end

	if isFFA() then
		return true
	end

	-- team-based
	if LocalPlayer.Team == nil or player.Team == nil then
		-- if one side has nil team -> treat as enemy only if teams differ (nil vs non-nil) --> usually consider nils as same; choose conservative: treat nil vs nil as FFA already handled
		return player.Team ~= LocalPlayer.Team
	end

	return player.Team ~= LocalPlayer.Team
end

-- Create toggle button (full width, like aimbot)
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1, 0, 0, 35)
espButton.Position = UDim2.new(0, 0, 0, 10)
espButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
espButton.TextColor3 = Color3.fromRGB(1,1,1)
espButton.Font = Enum.Font.GothamBold
espButton.TextSize = 18
espButton.Text = "ESP: Off"
espButton.Parent = playerTab
local corner = Instance.new("UICorner", espButton); corner.CornerRadius = UDim.new(0,6)

espButton.MouseButton1Click:Connect(function()
	espOn = not espOn
	espButton.Text = "ESP: " .. (espOn and "On" or "Off")
	espButton.BackgroundColor3 = espOn and Color3.fromRGB(0,180,0) or Color3.fromRGB(40,40,40)
	if not espOn then
		ClearESP()
	end
end)

-- Keep highlights up to date and handle closest highlighting & tracking line in one loop
RunService.RenderStepped:Connect(function()
	if not espOn then
		-- ensure cleaned up
		ClearESP()
		return
	end

	-- need local HRP to compute distances
	local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myHRP then
		ClearESP()
		return
	end

	-- find closest valid enemy
	local closestPlayer = nil
	local closestDist = math.huge

	-- mark seen players; we'll remove outdated highlights later
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
						-- destroy stale and recreate
						if espHighlights[player] then
							pcall(function() espHighlights[player]:Destroy() end)
						end
						local ok, hl = pcall(function()
							local h = Instance.new("Highlight")
							h.Adornee = char
							h.FillTransparency = 1
							h.OutlineTransparency = 0
							h.OutlineColor = Color3.fromRGB(255,0,0) -- default red
							h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
							h.Parent = CoreGui
							return h
						end)
						if ok and hl then
							espHighlights[player] = hl
						else
							espHighlights[player] = nil
						end
					end

					-- choose closest
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
		if not seen[p] then
			destroyHighlightFor(p)
		end
	end

	-- Manage closest highlighting
	if _G.ClosestPlayerESP then
		-- reset previous if changed
		if previousClosest and previousClosest ~= closestPlayer then
			if espHighlights[previousClosest] and espHighlights[previousClosest].Parent then
				pcall(function() espHighlights[previousClosest].OutlineColor = Color3.fromRGB(255,0,0) end)
			end
			previousClosest = nil
		end

		if closestPlayer and espHighlights[closestPlayer] then
			-- set highlight color for closest
			pcall(function() espHighlights[closestPlayer].OutlineColor = Color3.fromRGB(255,255,0) end)
			previousClosest = closestPlayer

			-- update tracking line
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
			-- no closest, hide line
			if _G.ClosestLine then pcall(function() _G.ClosestLine.Visible = false end) end
		end
	else
		-- if disabled, ensure previous reset and line hidden
		if previousClosest then
			if espHighlights[previousClosest] and espHighlights[previousClosest].Parent then
				pcall(function() espHighlights[previousClosest].OutlineColor = Color3.fromRGB(255,0,0) end)
			end
			previousClosest = nil
		end
		if _G.ClosestLine then pcall(function() _G.ClosestLine.Visible = false end) end
	end
end)

-- keep highlights cleaned when players leave or respawn
Players.PlayerRemoving:Connect(function(p)
	destroyHighlightFor(p)
	if previousClosest == p then previousClosest = nil end
end)

Players.PlayerAdded:Connect(function(p)
	-- nothing to do; loop will create highlight when valid
end)

LocalPlayer.CharacterAdded:Connect(function()
	ClearESP()
end)
