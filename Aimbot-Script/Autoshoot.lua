--// AutoShootButton.lua
--// Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Wait for config tab to exist
local configTab
repeat
    configTab = _G.Tabs and _G.Tabs.Config
    wait(0.1)
until configTab

-- Auto Shoot variables
local autoShootOn = true  -- STARTED ON
local shootInterval = 0.1  -- seconds between shots

-- Create Auto Shoot toggle button
local autoShootButton = Instance.new("TextButton")
autoShootButton.Size = UDim2.new(1, 0, 0, 35)
autoShootButton.Position = UDim2.new(0, 0, 0, 130) -- Adjust Y if needed
autoShootButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- Green because ON
autoShootButton.TextColor3 = Color3.new(1, 1, 1)
autoShootButton.Font = Enum.Font.GothamBold
autoShootButton.TextSize = 18
autoShootButton.Text = "Auto Shoot: On"
autoShootButton.Parent = configTab
Instance.new("UICorner", autoShootButton).CornerRadius = UDim.new(0, 6)

-- Function to do mouse click at screen center
local function doMouseClickCenter()
    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2

    local vim = game:GetService("VirtualInputManager")

    if vim and vim.SendMouseButtonEvent then
        -- Works on PC
        vim:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.01)
        vim:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    else
        -- On mobile, try this — will not trigger actual tap but won't block controls
        UserInputService:SendMouseButtonEvent(centerX, centerY, 0, true)
        task.wait(0.01)
        UserInputService:SendMouseButtonEvent(centerX, centerY, 0, false)
    end
end

-- Auto shoot loop
spawn(function()
    while true do
        if autoShootOn and _G.CurrentAimbotTarget ~= nil then
            doMouseClickCenter()
        end
        task.wait(shootInterval)
    end
end)

-- Toggle button logic
autoShootButton.MouseButton1Click:Connect(function()
    autoShootOn = not autoShootOn
    autoShootButton.Text = "Auto Shoot: " .. (autoShootOn and "On" or "Off")
    autoShootButton.BackgroundColor3 = autoShootOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)
end)
