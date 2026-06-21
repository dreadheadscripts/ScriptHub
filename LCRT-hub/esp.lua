repeat task.wait() until _G.Tabs and _G.Tabs["Combat"]

local TweenService = game:GetService("TweenService")

local tab = _G.Tabs["Combat"]

--// ESP BUTTON ONLY
local button = Instance.new("TextButton")
button.Name = "ESP_Button"
button.Size = UDim2.new(0, 400, 0, 42)
button.Position = UDim2.new(0, 20, 0, 20)
button.BackgroundColor3 = Color3.fromRGB(25, 15, 35)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBlack
button.TextSize = 15
button.Text = "🔥 ESP : OFF"
button.AutoButtonColor = false
button.Parent = tab

Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)

--// GRADIENT
local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 150)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 0, 255))
}
grad.Parent = button

--// STROKE
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 0, 150)
stroke.Thickness = 2
stroke.Transparency = 0.2
stroke.Parent = button

--// HOVER
button.MouseEnter:Connect(function()
	TweenService:Create(button, TweenInfo.new(0.15), {
		Size = UDim2.new(0, 410, 0, 46),
		TextColor3 = Color3.fromRGB(255, 255, 255)
	}):Play()

	TweenService:Create(stroke, TweenInfo.new(0.15), {
		Color = Color3.fromRGB(0, 255, 200),
		Thickness = 3
	}):Play()
end)

button.MouseLeave:Connect(function()
	TweenService:Create(button, TweenInfo.new(0.15), {
		Size = UDim2.new(0, 400, 0, 42),
		TextColor3 = Color3.fromRGB(255, 255, 255)
	}):Play()

	TweenService:Create(stroke, TweenInfo.new(0.15), {
		Color = Color3.fromRGB(255, 0, 150),
		Thickness = 2
	}):Play()
end)

--// CLICK ANIMATION ONLY, NO ESP FUNCTION
local toggled = false

button.MouseButton1Click:Connect(function()
	toggled = not toggled

	if toggled then
		button.Text = "🔥 ESP : ON"
	else
		button.Text = "🔥 ESP : OFF"
	end

	local down = TweenService:Create(button, TweenInfo.new(0.06), {
		Size = UDim2.new(0, 390, 0, 38)
	})
	down:Play()

	down.Completed:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 400, 0, 42)
		}):Play()
	end)
end)

--// FIRE PARTICLES WHILE ON
task.spawn(function()
	while button.Parent do
		if toggled then
			local flame = Instance.new("Frame")
			flame.Size = UDim2.new(0, math.random(4, 8), 0, math.random(8, 16))
			flame.Position = UDim2.new(math.random(), 0, 1, 0)
			flame.BackgroundColor3 = ({
				Color3.fromRGB(255, 60, 60),
				Color3.fromRGB(255, 0, 150),
				Color3.fromRGB(120, 0, 255)
			})[math.random(1, 3)]
			flame.BorderSizePixel = 0
			flame.Parent = button

			Instance.new("UICorner", flame).CornerRadius = UDim.new(1, 0)

			TweenService:Create(flame, TweenInfo.new(0.4), {
				Position = UDim2.new(flame.Position.X.Scale, 0, 0, 0),
				BackgroundTransparency = 1
			}):Play()

			task.delay(0.4, function()
				if flame then flame:Destroy() end
			end)
		end

		task.wait(0.05)
	end
end)
