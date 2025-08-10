--// AimbotButton.lua [ loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/AimbotButton.lua"))() ]
--// Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

--// Globals
local aimbotOn = false
local killAuraOn = false
_G.InvinceTrack = true -- default: ignore invincible players

--// Helper functions
local function isAlive(player)
	if not player.Character then return false end
	local hum = player.Character:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function isPlayerInvincible(char)
	if not char then return false end
	if char:FindFirstChildOfClass("ForceField") then return true end
	if char:FindFirstChild("ForceField") then return true end
	local spawnProt = char:FindFirstChild("SpawnProtection") or char:FindFirstChild("Invincible")
	return spawnProt and spawnProt.Value == true
end

local function canDamageTarget(player)
	-- Check if LocalPlayer can damage target based on team or other game logic
	if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
		return false -- same team
	end
	-- Add more custom checks here if the game has special damage rules
	return true
end

local function isEnemy(player)
	if player == LocalPlayer then return false end
	if not isAlive(player) then return false end
	if not player.Character:FindFirstChild("HumanoidRootPart") then return false end

	-- Invincible filter
	if _G.InvinceTrack and isPlayerInvincible(player.Character) then
		return false
	end

	-- Team/damage check
	return canDamageTarget(player)
end

local function getClosestEnemy()
	local closest, dist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if isEnemy(plr) then
			local root = plr.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local magnitude = (root.Position - Camera.CFrame.Position).Magnitude
				if magnitude < dist then
					dist = magnitude
					closest = plr
				end
			end
		end
	end
	return closest
end

--// Aimbot logic
RunService.RenderStepped:Connect(function()
	if aimbotOn then
		local target = getClosestEnemy()
		if target and target.Character:FindFirstChild("Head") then
			local headPos = target.Character.Head.Position
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, headPos)
		end
	end
end)

--// Kill Aura logic
RunService.RenderStepped:Connect(function()
	if killAuraOn then
		local target = getClosestEnemy()
		if target and target.Character:FindFirstChild("HumanoidRootPart") then
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
		end
	end
end)

--// Combat tab buttons
local combatTab = script.Parent -- change if needed to the actual Combat tab reference

-- Aimbot Section
local aimbotButton = Instance.new("TextButton")
aimbotButton.Size = UDim2.new(1, 0, 0, 35)
aimbotButton.Position = UDim2.new(0, 0, 0, 10)
aimbotButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
aimbotButton.TextColor3 = Color3.new(1,1,1)
aimbotButton.Font = Enum.Font.GothamBold
aimbotButton.TextSize = 18
aimbotButton.Text = "Aimbot: Off"
aimbotButton.Parent = combatTab
Instance.new("UICorner", aimbotButton).CornerRadius = UDim.new(0,6)

aimbotButton.MouseButton1Click:Connect(function()
	aimbotOn = not aimbotOn
	aimbotButton.Text = "Aimbot: " .. (aimbotOn and "On" or "Off")
	aimbotButton.BackgroundColor3 = aimbotOn and Color3.fromRGB(0,180,0) or Color3.fromRGB(40,40,40)
end)

-- Kill Aura Section
local killAuraButton = Instance.new("TextButton")
killAuraButton.Size = UDim2.new(1, 0, 0, 35)
killAuraButton.Position = UDim2.new(0, 0, 0, 50)
killAuraButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
killAuraButton.TextColor3 = Color3.new(1,1,1)
killAuraButton.Font = Enum.Font.GothamBold
killAuraButton.TextSize = 18
killAuraButton.Text = "Kill Aura: Off"
killAuraButton.Parent = combatTab
Instance.new("UICorner", killAuraButton).CornerRadius = UDim.new(0,6)

killAuraButton.MouseButton1Click:Connect(function()
	killAuraOn = not killAuraOn
	killAuraButton.Text = "Kill Aura: " .. (killAuraOn and "On" or "Off")
	killAuraButton.BackgroundColor3 = killAuraOn and Color3.fromRGB(0,180,0) or Color3.fromRGB(40,40,40)
end)
