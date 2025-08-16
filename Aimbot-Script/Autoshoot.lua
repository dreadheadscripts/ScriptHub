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

-- Auto Shoot variables
local autoShootOn = true  -- started ON
local shootInterval = 0.1  -- seconds between shots

-- Track if finger is currently touching the screen (mobile)
local isTouching = false

UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
    if not gameProcessed then
        isTouching = true
    end
end)

UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
    if not gameProcessed then
        isTouching = false
    end
end)

-- Create Auto Shoot toggle button
local autoShootButton = Instance.new("TextButton")
autoShootButton.Size = UDim2.new(1, 0, 0, 50) -- taller to fit note
autoShootButton.Position = UDim2.new(0, 0, 0, 130)
autoShootButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- green ON
autoShootButton.TextColor3 = Color3.new(1, 1, 1)
autoShootButton.Font = Enum.Font.GothamBold
autoShootButton.TextSize = 16
autoShootButton.TextWrapped = true
autoShootButton.Text = "Auto Shoot: On\n(works better on PC)"
autoShootButton.Parent = configTab
Instance.new("UICorner", autoShootButton).CornerRadius = UDim.new(0, 6)

-- Function to simulate mouse click at center of screen
local function doMouseClickCenter()
    local vim = game:GetService("VirtualInputManager")
    if vim and vim.SendMouseButtonEvent then
        local centerX = Camera.ViewportSize.X / 2
        local centerY = Camera.ViewportSize.Y / 2
        vim:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.01)
        vim:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    else
        -- fallback for PC or unknown devices
        UserInputService:SendMouseButtonEvent(0, 0, 0, true)
        UserInputService:SendMouseButtonEvent(0, 0, 0, false)
    end
end

-- Auto shoot loop
task.spawn(function()
    while true do
        if autoShootOn and _G.CurrentAimbotTarget and not isTouching then
            doMouseClickCenter()
        end
        task.wait(shootInterval)
    end
end)

-- Toggle button logic
autoShootButton.MouseButton1Click:Connect(function()
    autoShootOn = not autoShootOn
    autoShootButton.Text = "Auto Shoot: " .. (autoShootOn and "On" or "Off") .. "\n(works better on PC)"
    autoShootButton.BackgroundColor3 = autoShootOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)
end)
