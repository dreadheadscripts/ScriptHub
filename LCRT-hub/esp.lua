repeat task.wait() until _G.Tabs and _G.Tabs["Combat"]

local Players = game:GetService("Players")

local enabled = false
local espFolder = Instance.new("Folder")
espFolder.Name = "ESP_FOLDER"
espFolder.Parent = workspace

--// create ESP
local function addESP(player)
	if player == Players.LocalPlayer then return end

	local function onChar(char)
		if not enabled then return end

		local head = char:FindFirstChild("Head")
		if not head then return end

		if head:FindFirstChild("ESP") then return end

		local esp = Instance.new("BillboardGui")
		esp.Name = "ESP"
		esp.Size = UDim2.new(0, 200, 0, 200)
		esp.AlwaysOnTop = true
		esp.Adornee = head
		esp.Parent = head

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1,0,1,0)
		txt.BackgroundTransparency = 1
		txt.Text = player.Name
		txt.TextColor3 = Color3.fromRGB(0,255,200)
		txt.TextScaled = true
		txt.Font = Enum.Font.GothamBold
		txt.Parent = esp
	end

	player.CharacterAdded:Connect(onChar)
	if player.Character then
		onChar(player.Character)
	end
end

--// apply to all players
for _, p in ipairs(Players:GetPlayers()) do
	addESP(p)
end

Players.PlayerAdded:Connect(addESP)

--// cleanup function
local function clearESP()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("Head") then
			local esp = p.Character.Head:FindFirstChild("ESP")
			if esp then esp:Destroy() end
		end
	end
end

--// UI BUTTON (auto injected into your Combat tab)
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 400, 0, 40)
button.BackgroundColor3 = Color3.fromRGB(40,40,55)
button.TextColor3 = Color3.fromRGB(255,255,255)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Text = "ESP: OFF"

Instance.new("UICorner", button)

button.MouseButton1Click:Connect(function()
	enabled = not enabled

	if enabled then
		button.Text = "ESP: ON"
		-- refresh ESP
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				local head = p.Character:FindFirstChild("Head")
				if head and not head:FindFirstChild("ESP") then
					addESP(p)
				end
			end
		end
	else
		button.Text = "ESP: OFF"
		clearESP()
	end
end)

--// inject into your hub tab
button.Parent = _G.Tabs["Combat"]
