--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Loading screen code stored as a string variable
local LoadingScreenCode = [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/Loading-Screen.lua"))()
]]

-- Execute the loading screen
local success, err = pcall(function()
    loadstring(LoadingScreenCode)()
end)

if not success then
    warn("Failed to load loading screen:", err)
end

-- Wait for the loading screen GUI to appear
local loadingGui = nil
local timeout = 10
local timer = 0
while timer < timeout do
    loadingGui = PlayerGui:FindFirstChild("LoadingScreen")
    if loadingGui then
        print("✅ Found LoadingScreen GUI")
        break
    end
    task.wait(0.5)
    timer = timer + 0.5
end

if not loadingGui then
    warn("❌ LoadingScreen GUI never appeared, skipping wait.")
end

-- Wait for loading screen to finish (destroyed)
if loadingGui then
    print("Waiting for LoadingScreen to finish...")
    while loadingGui.Parent do
        task.wait(0.5)
    end
    print("✅ LoadingScreen GUI destroyed, proceeding.")
end

-- Now create the main Script Maniac Hub GUI

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ScriptManiacHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

--// Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 300)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Selectable = true
mainFrame.Draggable = false
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 10)

--// Main Frame Drag
do
	local dragging, dragInput, dragStart, startPos

	mainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	mainFrame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--// Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Script Maniac Hub"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

--// Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner", closeButton)
closeCorner.CornerRadius = UDim.new(0, 6)

--// Open Button (Circular + Image) centered on screen
local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0, 60, 0, 60)
openButton.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center screen
openButton.AnchorPoint = Vector2.new(0.5, 0.5)
openButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
openButton.Text = ""
openButton.Visible = false
openButton.Parent = gui

local openCorner = Instance.new("UICorner", openButton)
openCorner.CornerRadius = UDim.new(1, 0) -- Circle shape

-- Image on open button
local icon = Instance.new("ImageLabel")
icon.Size = UDim2.new(1, -12, 1, -12)
icon.Position = UDim2.new(0, 6, 0, 6)
icon.BackgroundTransparency = 1
icon.Image = "rbxassetid://107886940086071"
icon.Parent = openButton

--// Open Button Drag + Click Fix (Mobile + PC)
do
	local dragging = false
	local dragStart, dragInput, startPos
	local wasDragging = false

	openButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = openButton.Position
			wasDragging = false

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					task.delay(0.05, function()
						wasDragging = false
					end)
				end
			end)
		end
	end)

	openButton.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			if math.abs(delta.X) > 2 or math.abs(delta.Y) > 2 then
				wasDragging = true
			end
			openButton.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	openButton.MouseButton1Click:Connect(function()
		if wasDragging then return end
		mainFrame.Visible = true
		openButton.Visible = false
	end)
end

--// Tab Buttons Frame
local tabButtons = Instance.new("Frame")
tabButtons.Size = UDim2.new(1, 0, 0, 35)
tabButtons.Position = UDim2.new(0, 0, 0, 40)
tabButtons.BackgroundTransparency = 1
tabButtons.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabButtons

--// Tab Content Area
local tabContent = Instance.new("Frame")
tabContent.Size = UDim2.new(1, -20, 1, -80)
tabContent.Position = UDim2.new(0, 10, 0, 80)
tabContent.BackgroundTransparency = 1
tabContent.Parent = mainFrame

--// Tabs Setup
local tabs = {
	Combat = Instance.new("Frame"),
	Player = Instance.new("Frame"),
	Config = Instance.new("Frame")
}

for name, frame in pairs(tabs) do
	frame.Name = name .. "Tab"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = tabContent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "More buttons on 08/30/2025"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 18
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = frame
end

-- Expose tabs globally so external scripts can access them
_G.Tabs = tabs

--// Tab Switch Logic
local function switchTo(tabName)
	for name, frame in pairs(tabs) do
		frame.Visible = (name == tabName)
	end

	for _, button in ipairs(tabButtons:GetChildren()) do
		if button:IsA("TextButton") then
			button.BackgroundColor3 = (button.Name == tabName .. "Button")
				and Color3.fromRGB(120, 120, 120)
				or Color3.fromRGB(45, 45, 55)
		end
	end
end

--// Create Tab Buttons
for name in pairs(tabs) do
	local button = Instance.new("TextButton")
	button.Name = name .. "Button"
	button.Size = UDim2.new(0, 130, 1, 0)
	button.Text = name
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.AutoButtonColor = true
	button.Parent = tabButtons

	local corner = Instance.new("UICorner", button)
	corner.CornerRadius = UDim.new(0, 6)

	button.MouseButton1Click:Connect(function()
		switchTo(name)
	end)
end

-- Show first tab by default
switchTo("Combat")

-- Close button logic
closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	openButton.Visible = true
end)

-- Load the external scripts AFTER _G.Tabs exists so they can add UI in the right tab
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/AimbotButton.lua"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/Crosshair.lua"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/Esp.lua"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/ClosestPlayer.lua"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/tpplayer.lua"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/Invincetrack.lua"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/Autoshoot.lua"))() end)
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/opaimbot.lua"))() end)
