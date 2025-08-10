--// AutoShootButton.lua
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Wait for Config tab
local configTab
repeat
    configTab = _G.Tabs and _G.Tabs.Config
    task.wait(0.1)
until configTab

local autoShootOn = true
local shootInterval = 0.1

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

-- Function to simulate a tap at center of screen
local function simulateTapCenter()
    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2

    -- Send touch tap (began + ended)
    UserInputService:SendTouchEvent(Enum.UserInputState.Begin, Vector2.new(centerX, centerY), 0)
    task.wait(0.01)
    UserInputService:SendTouchEvent(Enum.UserInputState.End, Vector2.new(centerX, centerY), 0)
end

spawn(function()
    while true do
        if autoShootOn and _G.CurrentAimbotTarget ~= nil then
            simulateTapCenter()
        end
        task.wait(shootInterval)
    end
end)

autoShootButton.MouseButton1Click:Connect(function()
    autoShootOn = not autoShootOn
    autoShootButton.Text = "Auto Shoot: " .. (autoShootOn and "On" or "Off")
    autoShootButton.BackgroundColor3 = autoShootOn and Color3.fromRGB(0,180,0) or Color3.fromRGB(40,40,40)
end)
