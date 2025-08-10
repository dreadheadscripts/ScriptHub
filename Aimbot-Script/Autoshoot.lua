local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

-- Wait for config tab
local configTab
repeat
    configTab = _G.Tabs and _G.Tabs.Config
    task.wait(0.1)
until configTab

local autoShootOn = true
local shootInterval = 0.15

-- Create Auto Shoot button
local autoShootButton = Instance.new("TextButton")
autoShootButton.Size = UDim2.new(1, 0, 0, 35)
autoShootButton.Position = UDim2.new(0, 0, 0, 130)
autoShootButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
autoShootButton.TextColor3 = Color3.new(1,1,1)
autoShootButton.Font = Enum.Font.GothamBold
autoShootButton.TextSize = 18
autoShootButton.Text = "Auto Shoot: On"
autoShootButton.Parent = configTab
Instance.new("UICorner", autoShootButton).CornerRadius = UDim.new(0,6)

-- Create invisible Fire button GUI (simulate real user tap)
local fireButton = Instance.new("TextButton")
fireButton.Name = "FireButton"
fireButton.Size = UDim2.new(0, 1, 0, 1) -- tiny, invisible
fireButton.Position = UDim2.new(0.5, -0.5, 0.5, -0.5) -- center screen
fireButton.BackgroundTransparency = 1
fireButton.AutoButtonColor = false
fireButton.Visible = false
fireButton.Parent = PlayerGui

-- Function to simulate pressing the FireButton (trigger its MouseButton1Down and MouseButton1Up)
local function simulateTap()
    fireButton:CaptureFocus()
    fireButton.InputBegan:Wait() -- waits for input, but we want to simulate input, so:
    -- Instead, we fire the events directly:
    fireButton:MouseButton1Down()
    task.wait(0.02)
    fireButton:MouseButton1Up()
end

-- But Roblox GUI buttons do not have MouseButton1Down/Up methods, so better use :Activate()

local function doFire()
    fireButton:Activate()
end

-- Auto shoot loop
task.spawn(function()
    while true do
        if autoShootOn and _G.CurrentAimbotTarget then
            doFire()
            task.wait(shootInterval)
        else
            task.wait(0.1)
        end
    end
end)

autoShootButton.MouseButton1Click:Connect(function()
    autoShootOn = not autoShootOn
    autoShootButton.Text = "Auto Shoot: " .. (autoShootOn and "On" or "Off")
    autoShootButton.BackgroundColor3 = autoShootOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40,40,40)
end)
