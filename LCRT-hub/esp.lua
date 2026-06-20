repeat task.wait() until _G.Tabs
repeat task.wait() until _G.Tabs["Combat"]

local Players = game:GetService("Players")

local function createESP(player)
	if player == Players.LocalPlayer then return end

	local function onCharacter(char)
		local head = char:WaitForChild("Head", 5)
		if not head then return end

		-- avoid duplicates
		if head:FindFirstChild("ESP") then return end

		local esp = Instance.new("BillboardGui")
		esp.Name = "ESP"
		esp.Size = UDim2.new(0, 100, 0, 40)
		esp.AlwaysOnTop = true
		esp.Adornee = head
		esp.Parent = head

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = player.Name
		label.TextColor3 = Color3.fromRGB(0, 255, 200)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = esp
	end

	if player.Character then
		onCharacter(player.Character)
	end

	player.CharacterAdded:Connect(onCharacter)
end

for _, p in pairs(Players:GetPlayers()) do
	createESP(p)
end

Players.PlayerAdded:Connect(createESP)
