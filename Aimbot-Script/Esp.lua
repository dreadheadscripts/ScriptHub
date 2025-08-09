-- Esp.lua (improved FFA detection via friendly-fire heuristics)
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

-- drawing line (if supported)
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

-- Friendly-fire detection state
local friendlyFireDetected = false
local friendlyFireTimeout = 20 -- seconds to treat as FFA after detection (tweakable)
local friendlyFireExpiry = 0

-- store humanoid watchers to disconnect later
local humanoidConns = {}        -- [player] = RBXScriptConnection
local humanoidPrevHealth = {}   -- [player] = number

-- helpers to manage highlights
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

-- NEW: Attach to a player's Humanoid and listen for health drops to detect friendly fire
local function attachHumanoid(player, humanoid)
	if not humanoid or not player then return end
	humanoidPrevHealth[player] = humanoid.Health

	-- disconnect any previous connection for safety
	if humanoidConns[player] then
		pcall(function() humanoidConns[player]:Disconnect() end)
		humanoidConns[player] = nil
	end

	humanoidConns[player] = humanoid.HealthChanged:Connect(function(newHealth)
		local prev = humanoidPrevHealth[player] or newHealth
		-- only react to damage (health drop)
		if newHealth < prev then
			-- attempt to determine attacker via common server tagging patterns
			local victim = player
			local attacker = nil

			-- 1) scan for ObjectValue-like creator tags in Humanoid children
			for _,child in ipairs(humanoid:GetChildren()) do
				if child:IsA("ObjectValue") and child.Value then
					local name = child.Name:lower()
					if name:find("creator") or name:find("killer") or name:find("attacker") or name:find("last") or name:find("damager") then
						local val = child.Value
						-- if value is a Model (character), map to player
						local pl = Players:GetPlayerFromCharacter(val) or (val:IsA("Player") and val) or Players:FindFirstChild(val.Name)
						if pl then
							attacker = pl
							break
						end
					end
				end
			end

			-- 2) check common singular creator names
			if not attacker then
				local creator = humanoid:FindFirstChild("creator") or humanoid:FindFirstChild("Creator") or humanoid:FindFirstChild("creatorPlayer")
				if creator and creator.Value then
					local pl = Players:GetPlayerFromCharacter(creator.Value) or (creator.Value:IsA("Player") and creator.Value) or Players:FindFirstChild(creator.Value.Name)
					if pl then attacker = pl end
				end
			end

			-- 3) attributes fallback (some games set attributes)
			if not attacker then
				local attr = humanoid:GetAttribute("lastAttacker") or humanoid:GetAttribute("LastAttacker")
				if attr and typeof(attr) == "Instance" then
					local pl = Players:GetPlayerFromCharacter(attr) or Players:FindFirstChild(attr.Name)
					if pl then attacker = pl end
				end
			end

			-- 4) proximity + tool heuristic if no attacker found (teammate right next to victim w/ a Tool): assume possible friendly fire
			if not attacker then
				local victimHRP = victim.Character and victim.Character:FindFirstChild("HumanoidRootPart")
				if victimHRP then
					for _,other in ipairs(Players:GetPlayers()) do
						if other ~= victim and other.Team and victim.Team and other.Team == victim.Team and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
							local otherHRP = other.Character.HumanoidRootPart
							if (otherHRP.Position - victimHRP.Position).Magnitude <= 12 then
								-- check if other has a Tool in hand / character
								for _,c in ipairs(other.Character:GetChildren()) do
									if c:IsA("Tool") then
										attacker = other
										break
									end
								end
								if attacker then break end
							end
						end
					end
				end
			end

			-- If we identified an attacker and they're on the same team as victim -> mark friendly fire
			if attacker and victim.Team and attacker.Team and attacker.Team == victim.Team and attacker ~= victim then
				friendlyFireDetected = true
				friendlyFireExpiry = tick() + friendlyFireTimeout
				-- helpful debug log for you
				pcall(function()
					print(("ESP: friendly-fire detected — %s hit %s; FFA for %ds"):format(attacker.Name, victim.Name, friendlyFireTimeout))
				end)
			else
				-- else, if no attacker found, we leave it (we already ran a proximity heuristic above)
			end
		end

		humanoidPrevHealth[player] = newHealth
	end)
end

-- bind existing players and future players
local function bindPlayer(player)
	-- cleanup on removal
	player.AncestryChanged:Connect(function(_, parent)
		if not parent then
			-- player removed from game
			if humanoidConns[player] then pcall(function() humanoidConns[player]:Disconnect() end) end
			humanoidConns[player] = nil
			humanoidPrevHealth[player] = nil
		end
	end)

	player.CharacterAdded:Connect(function(char)
		-- small delay to let humanoid populate
		task.wait(0.05)
		local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
		if humanoid then
			attachHumanoid(player, humanoid)
		end
	end)

	-- if character already exists, attach now
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		attachHumanoid(player, player.Character:FindFirstChildOfClass("Humanoid"))
	end
end

for _,p in ipairs(Players:GetPlayers()) do
	bindPlayer(p)
end
Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(function(p)
	-- cleanup
	if humanoidConns[p] then pcall(function() humanoidConns[p]:Disconnect() end) end
	humanoidConns[p] = nil
	humanoidPrevHealth[p] = nil
	destroyHighlightFor(p)
	if previousClosest == p then previousClosest = nil end
end)

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
	-- resetting highlights so the UI immediately reflects mode change
	if espOn then
		ClearESP()
	end
end)

-- small label on right showing current auto-FFA heuristic result
local heurLabel = Instance.new("TextLabel")
heurLabel.Size = UDim2.new(0.48, -4, 0, 30)
heurLabel.Position = UDim2.new(0.52, 0, 0, 50)
heurLabel.BackgroundTransparency = 1
heurLabel.TextColor3 = Color3.new(1,1,1)
heurLabel.Font = Enum.Font.Gotham
heurLabel.TextSize = 14
heurLabel.Text = "" -- updated live
heurLabel.Parent = playerTab

-- helper: isFFA now includes friendly-fire detection
local function isFFA()
	-- manual override
	if _G.ForceFFA then return true end

	-- if we recently detected friendly fire, treat as FFA
	if friendlyFireDetected and tick() < friendlyFireExpiry then
		return true
	elseif friendlyFireDetected and tick() >= friendlyFireExpiry then
		-- expiry passed -> clear flag
		friendlyFireDetected = false
	end

	-- existing heuristics below
	local anyTeamAssigned = false
	for _,p in ipairs(Players:GetPlayers()) do
		if p.Team ~= nil then
			anyTeamAssigned = true
			break
		end
	end
	if not anyTeamAssigned then
		return true
	end

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

-- Hard-refresh helper to rebuild broken highlights if something changed
task.spawn(function()
	while true do
		if espOn then
			for p, hl in pairs(espHighlights) do
				local char = p.Character
				if not hl or not hl.Parent or not char or hl.Adornee ~= char then
					destroyHighlightFor(p)
				end
			end
		end
		task.wait(0.5)
	end
end)

-- main update loop (single loop to handle highlights + closest)
RunService.RenderStepped:Connect(function()
	heurLabel.Text = isFFA() and "Mode: FFA" or "Mode: Teams"

	if not espOn then
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
		if player ~= LocalPlayer and isAlive(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			-- treat as enemy depending on isFFA / teams
			local function isEnemyLocal(p)
				if p == LocalPlayer then return false end
				if not isAlive(p) then return false end
				if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then return false end

				if isFFA() then
					return true
				end

				if LocalPlayer.Team == nil or p.Team == nil then
					return false
				end

				return p.Team ~= LocalPlayer.Team
			end

			if isEnemyLocal(player) then
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local dist = (hrp.Position - myHRP.Position).Magnitude
					if dist <= MAX_DISTANCE then
						seen[player] = true
						-- create or ensure highlight
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
						else
							-- Force-update adornee & default color to avoid stale visuals
							pcall(function()
								espHighlights[player].Adornee = char
								if not (_G.ClosestPlayerESP and player == closestPlayer) then
									espHighlights[player].OutlineColor = Color3.fromRGB(255, 0, 0)
								end
							end)
						end

						if dist < closestDist then
							closestDist = dist
							closestPlayer = player
						end
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

-- clean up highlights on player removal handled above

LocalPlayer.CharacterAdded:Connect(function()
	ClearESP()
end)
