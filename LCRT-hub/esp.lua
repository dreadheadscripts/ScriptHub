-- wait until UI is ready
repeat task.wait() until _G.LucritHub

repeat task.wait() until _G.LucritHub and _G.LucritHub.AddButton

print("ESP module loaded") -- debug

_G.LucritHub.AddButton("Combat", "ESP", function()
	print("ESP CLICKED")

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
				text.TextScaled = true
				text.Parent = esp
			end
		end
	end
end)
