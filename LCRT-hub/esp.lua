-- wait until UI is ready
repeat task.wait() until _G.LucritHub

local hub = _G.LucritHub

-- add button to Combat tab
hub.AddButton("Combat", "ESP", function()
	print("ESP Activated")

	-- your ESP code goes here
	for _, player in pairs(game.Players:GetPlayers()) do
		if player ~= game.Players.LocalPlayer then
			if player.Character and player.Character:FindFirstChild("Head") then
				
				local esp = Instance.new("BillboardGui")
				esp.Size = UDim2.new(0, 100, 0, 40)
				esp.AlwaysOnTop = true
				esp.Adornee = player.Character.Head
				esp.Parent = player.Character

				local text = Instance.new("TextLabel")
				text.Size = UDim2.new(1,0,1,0)
				text.BackgroundTransparency = 1
				text.Text = player.Name
				text.TextColor3 = Color3.fromRGB(0,255,200)
				text.Font = Enum.Font.GothamBold
				text.TextScaled = true
				text.Parent = esp
			end
		end
	end
end)
