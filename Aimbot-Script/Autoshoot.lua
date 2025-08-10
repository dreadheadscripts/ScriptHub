--// AutoShootButton.lua
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Wait for config tab
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
autoShootButton.Text = "Auto Click: On"
autoShootButton.Parent = configTab
Instance.new("UICorner", autoShootButton).CornerRadius = UDim.new(0,6)

local function sendTouchTap()
    local viewportSize = Camera.ViewportSize
    local centerX, centerY = viewportSize.X / 2, viewportSize.Y / 2

    -- On mobile, use UserInputService:SendTouchEvent to simulate tap
    pcall(function()
        UserInputService:SendTouchEvent(Enum.UserInputType.Touch, centerX, centerY, true)
        task.wait(0.01)
        UserInputService:SendTouchEvent(Enum.UserInputType.Touch, centerX, centerY, false)
    end)
end

spawn(function()
    while true do
        if autoShootOn and _G.CurrentAimbotTarget ~= nil then
            sendTouchTap()
        end
        task.wait(shootInterval)
    end
end)

autoShootButton.MouseButton1Click:Connect(function()
    autoShootOn = not autoShootOn
    autoShootButton.Text = "Auto Click: " .. (autoShootOn and "On" or "Off")
    autoShootButton.BackgroundColor3 = autoShootOn and Color3.fromRGB(0,180,0) or Color3.fromRGB(40,40,40)
end)
