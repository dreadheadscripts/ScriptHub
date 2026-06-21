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
main.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local b = Instance.new("Frame")
b.Size = UDim2.new(0, 200, 0, 200)
b.Position = UDim2.new(0.5, 0, 0.5, 0)
b.AnchorPoint = Vector2.new(0.5, 0.5)
b.BackgroundColor3 = Color3.fromRGB(89, 23, 198)
b.BorderSizePixel = 0
b.Parent = gui
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 20)

--// GLOW BORDER
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3.5
stroke.Color = Color3.fromRGB(120, 80, 255)
stroke.Transparency = 0.2
stroke.Parent = main

task.spawn(function()
	while main.Parent do
		TweenService:Create(stroke, TweenInfo.new(2), {
			Color = Color3.fromRGB(0, 255, 200)
		}):Play()
		task.wait(2)

		TweenService:Create(stroke, TweenInfo.new(2), {
			Color = Color3.fromRGB(120, 80, 255)
		}):Play()
		task.wait(2)
	end
end)

--// TOPBAR
local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1, 0, 0, 40)
topbar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
topbar.Parent = main
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Lucrid Premuim HUB"
title.TextColor3 = Color3.fromRGB(200, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topbar

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
close.Size = UDim2.new(0, 24, 0, 24)
close.Position = UDim2.new(1, -32, 0, 8)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = topbar
Instance.new("UICorner", close).CornerRadius = UDim.new(1, 0)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

--// TAB HOLDER
local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.new(1, 0, 0, 60)
tabHolder.Position = UDim2.new(0, 0, 0, 45)
tabHolder.BackgroundTransparency = 1
tabHolder.Parent = main

--// ARROWS (ALIGNED)
local function makeArrow(txt, xScale)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 22, 0, 30) -- SAME HEIGHT AS TAB BUTTONS

	-- 🔥 CRITICAL: match tab button Y exactly
	b.Position = UDim2.new(xScale, -10.85, 0, 2.5)

	b.Text = txt
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.BackgroundColor3 = Color3.fromRGB(40,40,60)
	b.TextColor3 = Color3.fromRGB(180,180,255)
	b.Parent = tabHolder

	Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
	return b
end

local leftArrow = makeArrow("<", 0.04)
local rightArrow = makeArrow(">", 0.96)





local defaultStyle = {}


--// TAB BAR
local tabBar = Instance.new("ScrollingFrame")
tabBar.Size = UDim2.new(1, -70, 1, 0)
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

local function setActive(btn, isActive)
	stopAnim(btn)

	if isActive then
		btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)

		-- ⚡ glow stroke
		local stroke = Instance.new("UIStroke")
		stroke.Name = "ActiveStroke"
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(0, 255, 200)
		stroke.Transparency = 0.3
		stroke.Parent = btn

		-- 🌈 rainbow text loop
		task.spawn(function()
			local hue = 0
			while activeTab and tabButtons[activeTab] == btn do
				hue += 0.01
				btn.TextColor3 = Color3.fromHSV(hue % 1, 1, 1)
				task.wait(0.03)
			end
		end)

		-- 💓 pulse animation
		local tween1 = TweenService:Create(btn, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Size = UDim2.new(0, 100, 0, 36)
		})
		tween1:Play()

		activeTweens[btn] = {tween1}

	else
	   btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	   btn.TextColor3 = Color3.fromRGB(200, 200, 200)

		local stroke = btn:FindFirstChild("ActiveStroke")
		if stroke then stroke:Destroy() end
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
btn.BackgroundColor3 = Color3.fromRGB(40,40,55)
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.TextWrapped = true
btn.TextScaled = false
btn.Text = name
btn.Parent = tabBar

Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

local textService = game:GetService("TextService")

local function updateSize()
	local maxWidth = 160
	local paddingX = 20
	local paddingY = 14

	local bounds = textService:GetTextSize(
		btn.Text,
		btn.TextSize,
		btn.Font,
		Vector2.new(maxWidth, math.huge)
	)

	btn.Size = UDim2.new(
		0,
		math.clamp(bounds.X + paddingX, 80, maxWidth),
		0,
		math.clamp(bounds.Y + paddingY, 34, 70)
	)
end

updateSize()

--// AUTO SIZE TEXT INTO BUTTON
local function fitButton()
	local textService = game:GetService("TextService")

	local maxWidth = 140 -- max tab width
	local padding = 20

	local bounds = textService:GetTextSize(
		btn.Text,
		btn.TextSize,
		btn.Font,
		Vector2.new(maxWidth, math.huge)
	)

	-- width + height based on text
	btn.Size = UDim2.new(0, math.clamp(bounds.X + padding, 80, maxWidth), 0, math.clamp(bounds.Y + 12, 34, 60))
end

fitButton()

	--// STORE BUTTON
	tabButtons[name] = btn

	--// DEFAULT STYLE SAVE
	defaultStyle[name] = {
		BackgroundColor3 = btn.BackgroundColor3,
		TextColor3 = btn.TextColor3
	}

	--// CLICK EVENT
	btn.MouseButton1Click:Connect(function()
		clickFlash(btn)
		switchTab(name)
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
createTab("mega mansion tycoon thirty 8")

--🔥 ADD THIS
_G.Tabs = {
    Combat = Tabs["Combat"],
    Player = Tabs["Player"],
    ["mega mansion tycoon thirty 8"] = Tabs["mega mansion tycoon thirty 8"]
}

task.spawn(function()
	task.wait(0.5)
	loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/LCRT-hub/esp.lua"))()
end)
