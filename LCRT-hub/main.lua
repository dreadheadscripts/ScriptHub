local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "PremiumTabUI"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

--// MAIN
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 480, 0, 360)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
main.BorderSizePixel = 0
main.Parent = gui
local gradient = Instance.new("UIGradient")
gradient.Rotation = 90 -- bottom → top

gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 30)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 30, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 40, 120))
}

gradient.Parent = main
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

--🔥 FAKE UI FIRE (WORKS IN SCREENGUI)
task.spawn(function()
	while main.Parent do
		local flame = Instance.new("Frame")
		flame.AnchorPoint = Vector2.new(0.5, 1)

		-- random width + height
		local width = math.random(6, 14)
		local height = math.random(20, 50)

		flame.Size = UDim2.new(0, width, 0, height)

		-- spawn along bottom
		flame.Position = UDim2.new(math.random(), 0, 1, 0)

		--🔥 gradient inside flame
		local grad = Instance.new("UIGradient")
		grad.Rotation = 90
		grad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), -- red
			ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 0, 255))  -- purple
		}
		grad.Parent = flame

		flame.BackgroundColor3 = Color3.new(1,1,1)
		flame.BackgroundTransparency = 0.2
		flame.BorderSizePixel = 0

		Instance.new("UICorner", flame).CornerRadius = UDim.new(1,0)

		flame.Parent = main

		--🔥 movement (FAST like you wanted)
		local rise = TweenService:Create(flame, TweenInfo.new(0.4, Enum.EasingStyle.Linear), {
			Position = UDim2.new(flame.Position.X.Scale, 0, 0.6, 0),
			BackgroundTransparency = 1
		})

		rise:Play()

		rise.Completed:Connect(function()
			flame:Destroy()
		end)

		task.wait(0.03) -- 🔥 LOWER = MORE INTENSE FIRE
	end
end)

--// REOPEN BUTTON
local reopen = Instance.new("ImageButton")
reopen.Name = "ReopenButton"
reopen.Size = UDim2.new(0,40,0,40)
reopen.Position = UDim2.new(1,-68,0,20)
reopen.AnchorPoint = Vector2.new(0.5,0.5)
reopen.Image = "rbxassetid://84147778294140"
reopen.BackgroundTransparency = 1
reopen.Visible = false
reopen.ZIndex = 999
reopen.Parent = gui

local reopenStroke = Instance.new("UIStroke")
reopenStroke.Color = Color3.fromRGB(255,0,150)
reopenStroke.Thickness = 2
reopenStroke.Parent = reopen

-- pulse
task.spawn(function()
	while reopen.Parent do
		TweenService:Create(reopen, TweenInfo.new(.6), {
			Size = UDim2.new(0,46,0,46)
		}):Play()

		task.wait(.6)

		TweenService:Create(reopen, TweenInfo.new(.6), {
			Size = UDim2.new(0,40,0,40)
		}):Play()

		task.wait(.6)
	end
end)

-- stroke pulse
task.spawn(function()
	while reopen.Parent do
		TweenService:Create(reopenStroke,TweenInfo.new(.8),{
			Thickness = 4
		}):Play()

		task.wait(.8)

		TweenService:Create(reopenStroke,TweenInfo.new(.8),{
			Thickness = 2
		}):Play()

		task.wait(.8)
	end
end)

local draggingReopen = false
local dragStart
local startPos
local startTime
local moved = false

reopen.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		draggingReopen = true
		moved = false
		dragStart = input.Position
		startPos = reopen.Position
		startTime = tick()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not draggingReopen then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement
	and input.UserInputType ~= Enum.UserInputType.Touch then return end

	local delta = input.Position - dragStart

	if math.abs(delta.X) > 10 or math.abs(delta.Y) > 10 then
		moved = true
	end

	reopen.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then

		if draggingReopen then
			draggingReopen = false

			local heldTime = tick() - startTime

			if not moved and heldTime < 0.25 then
				main.Visible = true
				reopen.Visible = false
			end
		end
	end
end)

--// TOPBAR
--// TOPBAR (UPGRADED)
local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1, 0, 0, 45)
topbar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
topbar.BorderSizePixel = 0
topbar.Parent = main
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 12)

--🔥 GRADIENT BACKGROUND
local topGrad = Instance.new("UIGradient")
topGrad.Rotation = 0
topGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 20, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 30, 120)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 20, 60))
}
topGrad.Parent = topbar

--🔥 ANIMATED GRADIENT SHIFT
task.spawn(function()
	while topbar.Parent do
		TweenService:Create(topGrad, TweenInfo.new(3, Enum.EasingStyle.Linear), {
			Offset = Vector2.new(1,0)
		}):Play()
		task.wait(3)
		topGrad.Offset = Vector2.new(-1,0)
	end
end)

--🔥 GLOW LINE UNDER TOPBAR
local glowLine = Instance.new("Frame")
glowLine.Size = UDim2.new(1, 0, 0, 2)
glowLine.Position = UDim2.new(0, 0, 1, -2)
glowLine.BackgroundColor3 = Color3.fromRGB(150, 0, 255)
glowLine.BorderSizePixel = 0
glowLine.Parent = topbar

local glowGrad = Instance.new("UIGradient")
glowGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 150)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 200))
}
glowGrad.Parent = glowLine

--🔥 MOVING SHINE EFFECT
local shine = Instance.new("Frame")
shine.Size = UDim2.new(0, 80, 1, 0)
shine.BackgroundTransparency = 0.8
shine.BackgroundColor3 = Color3.new(1,1,1)
shine.BorderSizePixel = 0
shine.Parent = topbar

local shineGrad = Instance.new("UIGradient")
shineGrad.Rotation = 45
shineGrad.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0,1),
	NumberSequenceKeypoint.new(0.5,0.3),
	NumberSequenceKeypoint.new(1,1)
}
shineGrad.Parent = shine

task.spawn(function()
	while shine.Parent do
		shine.Position = UDim2.new(-0.3,0,0,0)
		local tween = TweenService:Create(shine, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {
			Position = UDim2.new(1.2,0,0,0)
		})
		tween:Play()
		task.wait(2)
	end
end)

--🔥 TITLE (UPGRADED)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Lucrid Premium HUB"
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Parent = topbar

--🔥 TITLE GRADIENT TEXT
local textGrad = Instance.new("UIGradient")
textGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 150)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 200))
}
textGrad.Parent = title

--🔥 TITLE GLOW
local titleStroke = Instance.new("UIStroke")
titleStroke.Thickness = 1.5
titleStroke.Color = Color3.fromRGB(255, 0, 150)
titleStroke.Transparency = 0.3
titleStroke.Parent = title

--🔥 SUBTLE PULSE
task.spawn(function()
	while title.Parent do
		TweenService:Create(title, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			TextTransparency = 0.1
		}):Play()
		task.wait(1)

		TweenService:Create(title, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			TextTransparency = 0
		}):Play()
		task.wait(1)
	end
end)

--// DRAG (FIXED + SMOOTH + RELIABLE)

local dragging = false
local dragStartPos
local startGuiPos
local dragInput

topbar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStartPos = input.Position
		startGuiPos = main.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

topbar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input ~= dragInput then return end

	local delta = input.Position - dragStartPos

	main.Position = UDim2.new(
		startGuiPos.X.Scale,
		startGuiPos.X.Offset + delta.X,
		startGuiPos.Y.Scale,
		startGuiPos.Y.Offset + delta.Y
	)
end)

--// CLOSE
local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 28, 0, 28)
close.Position = UDim2.new(1, -36, 0, 6)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.TextColor3 = Color3.fromRGB(255, 200, 200)
close.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
close.AutoButtonColor = false
close.Parent = topbar

Instance.new("UICorner", close).CornerRadius = UDim.new(1, 0)

--🔥 GRADIENT
local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 0, 255))
}
grad.Parent = close

--🔥 GLOW STROKE
local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 80, 80)
stroke.Transparency = 0.3
stroke.Parent = close

--// MINIMIZE BUTTON
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.new(0, 28, 0, 28)
minimize.Position = UDim2.new(1, -68, 0, 6)
minimize.Text = "-"
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 18
minimize.TextColor3 = Color3.fromRGB(255,255,255)
minimize.BackgroundColor3 = Color3.fromRGB(35,20,45)
minimize.AutoButtonColor = false
minimize.Parent = topbar

Instance.new("UICorner", minimize).CornerRadius = UDim.new(1,0)

local minGrad = Instance.new("UIGradient")
minGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,150)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120,0,255))
}
minGrad.Parent = minimize

--🔥 PULSE (like arrows)
task.spawn(function()
	while close.Parent do
		TweenService:Create(close, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = UDim2.new(0, 32, 0, 32)
		}):Play()
		task.wait(0.6)

		TweenService:Create(close, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = UDim2.new(0, 28, 0, 28)
		}):Play()
		task.wait(0.6)
	end
end)

--🔥 HOVER (bright + aggressive)
close.MouseEnter:Connect(function()
	TweenService:Create(close, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(90, 20, 20),
		TextColor3 = Color3.fromRGB(255,255,255)
	}):Play()

	TweenService:Create(stroke, TweenInfo.new(0.15), {
		Color = Color3.fromRGB(255, 0, 0),
		Transparency = 0
	}):Play()
end)

close.MouseLeave:Connect(function()
	TweenService:Create(close, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(35, 20, 25),
		TextColor3 = Color3.fromRGB(255, 200, 200)
	}):Play()

	TweenService:Create(stroke, TweenInfo.new(0.15), {
		Color = Color3.fromRGB(255, 80, 80),
		Transparency = 0.3
	}):Play()
end)

--🔥 CLICK IMPACT (HARD + CLEAN)
close.MouseButton1Click:Connect(function()
	local down = TweenService:Create(close, TweenInfo.new(0.06), {
		Size = UDim2.new(0, 24, 0, 24)
	})
	down:Play()

	down.Completed:Connect(function()
		TweenService:Create(close, TweenInfo.new(0.08, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 34, 0, 34)
		}):Play()
	end)

	--🔥 DESTROY AFTER ANIMATION
	task.delay(0.08, function()
		gui:Destroy()
	end)
end)

--// TAB HOLDER
local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.new(1, 0, 0, 60)
tabHolder.Position = UDim2.new(0, 0, 0, 45)
tabHolder.BackgroundTransparency = 1
tabHolder.Parent = main

--// ARROWS (ALIGNED)
local function makeArrow(txt, xScale)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0, 50, 1, 0)
	holder.Position = UDim2.new(xScale, -20, -.2, 2)
	holder.BackgroundTransparency = 1
	holder.Parent = tabHolder

	-- glowing back plate
	local glow = Instance.new("Frame")
	glow.Size = UDim2.new(0, 35, 0, 35)
	glow.Position = UDim2.new(0.43, 0, 0.5, 0)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundColor3 = Color3.fromRGB(255, 0, 170)
	glow.BackgroundTransparency = 0.6
	glow.BorderSizePixel = 0
	glow.Parent = holder
	Instance.new("UICorner", glow).CornerRadius = UDim.new(1,0)

	local glowGrad = Instance.new("UIGradient")
	glowGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 200))
	}
	glowGrad.Parent = glow

	-- button
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 28, 0, 28)
	b.Position = UDim2.new(0.44, 0, 0.5, 0)
	b.AnchorPoint = Vector2.new(0.5, 0.5)

	b.Text = txt
	b.Font = Enum.Font.GothamBlack
	b.TextSize = 18
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.BackgroundColor3 = Color3.fromRGB(25, 15, 35)
	b.AutoButtonColor = false
	b.Parent = holder

	Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(0, 255, 200)
	stroke.Transparency = 0.2
	stroke.Parent = b

	-- pulse animation (FIXED INSIDE FUNCTION)
	task.spawn(function()
		while b.Parent do
			TweenService:Create(glow, TweenInfo.new(0.6), {
				BackgroundTransparency = 0.2,
				Size = UDim2.new(0, 30, 0, 30)
			}):Play()

			task.wait(0.6)

			TweenService:Create(glow, TweenInfo.new(0.6), {
				BackgroundTransparency = 0.6,
				Size = UDim2.new(0, 35, 0, 35)
			}):Play()

			task.wait(0.6)
		end
	end)

	-- hover
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(60, 20, 90)
		}):Play()
	end)

	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(25, 15, 35)
		}):Play()
	end)

	return b
end

local leftArrow = makeArrow("<", 0.04)
local rightArrow = makeArrow(">", 0.96)





local defaultStyle = {}


--// TAB BAR
local tabBar = Instance.new("ScrollingFrame")
tabBar.Size = UDim2.new(1, -80, 1, 0)
tabBar.AnchorPoint = Vector2.new(0.5, 0.5)
tabBar.Position = UDim2.new(0.5, 0, 0.5, 0)
tabBar.BackgroundTransparency = 1
tabBar.ScrollBarThickness = 0
tabBar.ScrollingDirection = Enum.ScrollingDirection.X
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
tabBar.Parent = tabHolder

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 6)
layout.Parent = tabBar

--// CONTENT
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -110)
content.Position = UDim2.new(0, 10, 0, 105)
content.BackgroundTransparency = 1
content.Parent = main

--// SYSTEM
local Tabs = {}
local activeTab
local tabButtons = {}

local function clearEffects(btn)
	-- remove old glow if exists
	local stroke = btn:FindFirstChild("ActiveStroke")
	if stroke then stroke:Destroy() end

	local grad = btn:FindFirstChild("ActiveGradient")
	if grad then grad:Destroy() end
end

local activeTweens = {}

local function stopAnim(btn)
	if activeTweens[btn] then
		for _, t in ipairs(activeTweens[btn]) do
			pcall(function() t:Cancel() end)
		end
	end
	activeTweens[btn] = nil
end

local function clearActiveEffects(btn)
	for _, v in pairs(btn:GetChildren()) do
		if v.Name == "ActiveStroke" or v.Name == "ActiveGradient" or v.Name == "TabFire" or v.Name == "Confetti" then
			v:Destroy()
		end
	end
end

local function setActive(btn, isActive)
	clearActiveEffects(btn)

	if isActive then
		-- active effects
	else
		-- inactive effects
	end
end

	-- active background
	local grad = Instance.new("UIGradient")
	grad.Name = "ActiveGradient"
	grad.Rotation = 90
	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,40,40)), -- red
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,0,120)), -- pink
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120,0,255)) -- purple
	}
	grad.Parent = btn

	-- text gradient
	local textGrad = Instance.new("UIGradient")
	textGrad.Name = "TextGradient"
	textGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,60,60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,180))
	}
	textGrad.Parent = btn

	-- glow
	local stroke = Instance.new("UIStroke")
	stroke.Name = "ActiveStroke"
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255,50,50)
	stroke.Parent = btn

   local function clearActiveEffects(btn)
	for _, v in ipairs(btn:GetChildren()) do
		if v.Name == "ActiveStroke"
		or v.Name == "ActiveGradient"
		or v.Name == "TextGradient"
		or v.Name == "TabFire" then
			v:Destroy()
		end
	end
end

local function setActive(btn, isActive)
	clearActiveEffects(btn)

	if isActive then

		btn.BackgroundColor3 = Color3.fromRGB(25,15,35)
		btn.TextColor3 = Color3.new(1,1,1)

		local grad = Instance.new("UIGradient")
		grad.Name = "ActiveGradient"
		grad.Rotation = 90
		grad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,50,50)),
			ColorSequenceKeypoint.new(.5, Color3.fromRGB(255,0,150)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(120,0,255))
		}
		grad.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Name = "ActiveStroke"
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(255,60,120)
		stroke.Parent = btn

		task.spawn(function()
			while activeTab and tabButtons[activeTab] == btn and btn.Parent do

				local flame = Instance.new("Frame")
				flame.Name = "TabFire"

				flame.Size = UDim2.new(
					0,
					math.random(4,8),
					0,
					math.random(8,16)
				)

				flame.Position = UDim2.new(
					math.random(),
					0,
					1,
					0
				)

				flame.BackgroundColor3 = ({
					Color3.fromRGB(255,50,50),
					Color3.fromRGB(255,0,150),
					Color3.fromRGB(120,0,255)
				})[math.random(1,3)]

				flame.BorderSizePixel = 0
				flame.Parent = btn

				Instance.new("UICorner", flame).CornerRadius = UDim.new(1,0)

				TweenService:Create(
					flame,
					TweenInfo.new(.4),
					{
						Position = UDim2.new(
							flame.Position.X.Scale,
							0,
							0,
							0
						),
						BackgroundTransparency = 1
					}
				):Play()

				task.delay(.4,function()
					if flame then
						flame:Destroy()
					end
				end)

				task.wait(.05)
			end
		end)

	else

		btn.BackgroundColor3 = Color3.fromRGB(25,15,35)
		btn.TextColor3 = Color3.fromRGB(220,220,255)

	end
end

local function clickFlash(btn)
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1,0,1,0)
	flash.BackgroundColor3 = Color3.fromRGB(255,255,255)
	flash.BackgroundTransparency = 0.7
	flash.Parent = btn

	local tween = TweenService:Create(flash, TweenInfo.new(0.3), {
		BackgroundTransparency = 1
	})
	tween:Play()

	tween.Completed:Connect(function()
		flash:Destroy()
	end)
end

local function updateAllTabs()
	for name, btn in pairs(tabButtons) do
		setActive(btn, name == activeTab)
	end
end
local function switchTab(name)
	if activeTab == name then return end

	for _, frame in pairs(Tabs) do
		frame.Visible = false
	end

	activeTab = name

	if Tabs[name] then
		Tabs[name].Visible = true
	end

	for n, btn in pairs(tabButtons) do
		setActive(btn, n == name)
	end
end

local function createTab(name)
	local page = Instance.new("Frame")
	page.Size = UDim2.new(1,0,1,0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = content
	Tabs[name] = page

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,0,1,0)
	label.BackgroundTransparency = 1
	label.Text = name .. " TAB"
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.TextColor3 = Color3.fromRGB(200,200,200)
	label.Parent = page

--// TAB BUTTON (AUTO FIT + WRAP + AUTO HEIGHT)
local btn = Instance.new("TextButton")
btn.AutoButtonColor = false
btn.BackgroundColor3 = Color3.fromRGB(25, 15, 35)
btn.TextColor3 = Color3.fromRGB(220, 220, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.TextWrapped = true
btn.Text = name
btn.Parent = tabBar

Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

--🔥 GRADIENT (MOVING FIRE LOOK)
local grad = Instance.new("UIGradient")
grad.Name = "FireGradient"
grad.Rotation = 90
grad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 150)),   -- pink
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 0, 255)), -- purple
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 200))    -- cyan

}
grad.Offset = Vector2.new(0,1)
grad.Parent = btn

--🔥 GLOW STROKE
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = Color3.fromRGB(180, 0, 255)
stroke.Transparency = .5
stroke.Parent = btn

--🔥 SIZE FIT
local textService = game:GetService("TextService")
local function fitButton()
	local maxWidth = 140
	local bounds = textService:GetTextSize(
		btn.Text,
		btn.TextSize,
		btn.Font,
		Vector2.new(maxWidth, math.huge)
	)

	btn.Size = UDim2.new(
		0,
		math.clamp(bounds.X + 20, 80, maxWidth),
		0,
		math.clamp(bounds.Y + 12, 34, 60)
	)
end

fitButton()

--🔥 STORE ORIGINAL SIZE FIRST (IMPORTANT: DO THIS BEFORE EVENTS)
local originalSize = btn.Size

--🔥 ARROW-STYLE PULSE (same as arrows)
task.spawn(function()
	while btn.Parent do
		TweenService:Create(btn, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = originalSize + UDim2.new(0,4,0,4)
		}):Play()
		task.wait(0.6)

		TweenService:Create(btn, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = originalSize + UDim2.new(0,4,0,10)
		}):Play()
		task.wait(0.6)
	end
end)

--🔥 HOVER
btn.MouseEnter:Connect(function()
	TweenService:Create(btn, TweenInfo.new(0.15), {
		Size = originalSize + UDim2.new(0,4,0,4),
		BackgroundColor3 = Color3.fromRGB(45, 20, 70),
		TextColor3 = Color3.fromRGB(255,255,255)
	}):Play()

	TweenService:Create(stroke, TweenInfo.new(0.15), {
		Color = Color3.fromRGB(0, 255, 200),
		Transparency = 0
	}):Play()
end)

btn.MouseLeave:Connect(function()
	TweenService:Create(btn, TweenInfo.new(0.15), {
		Size = originalSize,
		BackgroundColor3 = Color3.fromRGB(25, 15, 35),
		TextColor3 = Color3.fromRGB(220,220,255)
	}):Play()

	TweenService:Create(stroke, TweenInfo.new(0.15), {
		Color = Color3.fromRGB(180, 0, 255),
		Transparency = 0.4
	}):Play()
end)

	--// STORE BUTTON
	tabButtons[name] = btn

	--// DEFAULT STYLE SAVE
	defaultStyle[name] = {
		BackgroundColor3 = btn.BackgroundColor3,
		TextColor3 = btn.TextColor3
	}

    --//click
    btn.MouseButton1Click:Connect(function()
	-- stop pulse so it doesn’t fight animation
	stopAnim(btn)

	local down = TweenService:Create(btn, TweenInfo.new(0.06), {
		Size = originalSize - UDim2.new(0,8,0,8)
	})
	down:Play()

	down.Completed:Connect(function()
		local up = TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Back), {
			Size = originalSize + UDim2.new(0,4,0,4)
		})
		up:Play()

		up.Completed:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.05), {
				Size = originalSize
			}):Play()
		end)
	end)

	-- 🔥 delay tab switch so animation shows
	task.delay(0.08, function()
		clickFlash(btn)
		switchTab(name)
	end)
end)

	--// FIRST TAB AUTO SELECT
	if not activeTab then
		switchTab(name)
	end

	return btn
end


--// SCROLL
local target = 0
task.spawn(function()
	while task.wait() do
		tabBar.CanvasPosition = Vector2.new(
			tabBar.CanvasPosition.X + (target - tabBar.CanvasPosition.X) * 0.15,
			0
		)
	end
end)

leftArrow.MouseButton1Click:Connect(function()
	target = math.max(0, target - 120)
end)

rightArrow.MouseButton1Click:Connect(function()
	target += 120
end)

tabBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		target = math.max(0, target - input.Position.Z * 60)
	end
end)

--// SPARKLES (FLOATING)
task.spawn(function()
	while main.Parent do
		local s = Instance.new("Frame")
		s.Size = UDim2.new(0,3,0,3)
		s.Position = UDim2.new(math.random(),0,math.random(),0)
		s.BackgroundColor3 = Color3.fromHSV(math.random(),1,1)
		s.Parent = main
		Instance.new("UICorner", s).CornerRadius = UDim.new(1,0)

		TweenService:Create(s, TweenInfo.new(1.2), {
			Position = UDim2.new(math.random(),0,math.random(),0),
			BackgroundTransparency = 1
		}):Play()

		task.delay(1.2,function() s:Destroy() end)
		task.wait(0.1)
	end
end)

--// TABS
--// TABS
createTab("Combat")
createTab("Player")
createTab("goon")
createTab("balll")
createTab("comp")
createTab("rugrat")
createTab("nutss")

_G.Tabs = {
Combat = Tabs["Combat"],
Player = Tabs["Player"]
}

task.spawn(function()
loadstring(game("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/LCRT-hub/esp.lua"))()
end)

-- minimize button
minimize.MouseButton1Click:Connect(function()
	local pos = minimize.AbsolutePosition
	reopen.Position = UDim2.new(0, pos.X, 0, pos.Y)

	main.Visible = false
	reopen.Visible = true
end)

