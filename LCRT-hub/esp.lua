repeat task.wait() until _G.Tabs and _G.Tabs["Combat"]

local TweenService = game:GetService("TweenService")
local tab = _G.Tabs["Combat"]

--// LOADING ANIMATION
local loading = Instance.new("TextLabel")
loading.Name = "ESP_Loading"
loading.Size = UDim2.new(0, 400, 0, 42)
loading.Position = UDim2.new(0, 20, 0, 20)
loading.BackgroundTransparency = 1
loading.Text = "Loading ESP"
loading.TextColor3 = Color3.fromRGB(255,255,255)
loading.Font = Enum.Font.GothamBlack
loading.TextSize = 16
loading.Parent = tab

local loadingStroke = Instance.new("UIStroke")
loadingStroke.Color = Color3.fromRGB(255,0,150)
loadingStroke.Thickness = 2
loadingStroke.Parent = loading

local loadingGrad = Instance.new("UIGradient")
loadingGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255,50,50)),
	ColorSequenceKeypoint.new(.5, Color3.fromRGB(255,0,150)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120,0,255))
}
loadingGrad.Parent = loading

for i = 1, 18 do
	local dots = string.rep(".", (i % 3) + 1)
	loading.Text = "Loading ESP" .. dots
	task.wait(0.12)
end

loading:Destroy()

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

local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
	ColorSequenceKeypoint.new(.5, Color3.fromRGB(255, 0, 150)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 0, 255))
}
grad.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 0, 150)
stroke.Thickness = 2
stroke.Transparency = 0.2
stroke.Parent = button

local toggled = false

button.MouseEnter:Connect(function()
	TweenService:Create(button, TweenInfo.new(.15), {
		Size = UDim2.new(0, 410, 0, 46)
	}):Play()

	TweenService:Create(stroke, TweenInfo.new(.15), {
		Color = Color3.fromRGB(0, 255, 200),
		Thickness = 3
	}):Play()
end)

button.MouseLeave:Connect(function()
	TweenService:Create(button, TweenInfo.new(.15), {
		Size = UDim2.new(0, 400, 0, 42)
	}):Play()

	TweenService:Create(stroke, TweenInfo.new(.15), {
		Color = Color3.fromRGB(255, 0, 150),
		Thickness = 2
	}):Play()
end)

button.MouseButton1Click:Connect(function()
	toggled = not toggled

	button.Text = toggled and "🔥 ESP : ON" or "🔥 ESP : OFF"

	local down = TweenService:Create(button, TweenInfo.new(.06), {
		Size = UDim2.new(0, 390, 0, 38)
	})
	down:Play()

	down.Completed:Connect(function()
		TweenService:Create(button, TweenInfo.new(.1, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 400, 0, 42)
		}):Play()
	end)
end)

--// FIRE PARTICLES WHILE ON
task.spawn(function()
	while button.Parent do
		if toggled then
			local flame = Instance.new("Frame")
			flame.Size = UDim2.new(0, math.random(4,8), 0, math.random(8,16))
			flame.Position = UDim2.new(math.random(), 0, 1, 0)
			flame.BackgroundColor3 = ({
				Color3.fromRGB(255,60,60),
				Color3.fromRGB(255,0,150),
				Color3.fromRGB(120,0,255)
			})[math.random(1,3)]
			flame.BorderSizePixel = 0
			flame.Parent = button

			Instance.new("UICorner", flame).CornerRadius = UDim.new(1,0)

			TweenService:Create(flame, TweenInfo.new(.4), {
				Position = UDim2.new(flame.Position.X.Scale,0,0,0),
				BackgroundTransparency = 1
			}):Play()

			task.delay(.4, function()
				if flame then flame:Destroy() end
			end)
		end

		task.wait(.05)
	end
end)
