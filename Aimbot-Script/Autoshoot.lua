--// AutoShootButton.lua
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function debugPrint(...)
    print("[AutoShoot DEBUG]:", ...)
end

local configTab
repeat
    configTab = _G.Tabs and _G.Tabs.Config
    task.wait(0.1)
until configTab

local autoShootOn = true
local shootInterval = 0.1
local refreshInterval = 60

local autoShootButton = Instance.new("TextButton")
autoShootButton.Size = UDim2.new(1, 0, 0, 35)
autoShootButton.Position = UDim2.new(0, 0, 0, 130)
autoShootButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
autoShootButton.TextColor3 = Color3.new(1, 1, 1)
autoShootButton.Font = Enum.Font.GothamBold
autoShootButton.TextSize = 18
autoShootButton.Text = "Auto Shoot: On"
autoShootButton.Parent = configTab
Instance.new("UICorner", autoShootButton).CornerRadius = UDim.new(0, 6)

-- Simulate touch tap at center for mobile
local function doTouchTapCenter()
    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2

    -- Touch began
    UserInputService:SendTouchEvent(Enum.UserInputState.Begin, 0, Vector2.new(centerX, centerY), 0)
    task.wait(0.05)
    -- Touch ended
    UserInputService:SendTouchEvent(Enum.UserInputState.End, 0, Vector2.new(centerX, centerY), 0)

    debugPrint("Sent TouchTap at center:", centerX, centerY)
end

-- Mouse click fallback for PC
local function doMouseClickCenter()
    local vim = game:GetService("VirtualInputManager")
    if vim and vim.SendMouseButtonEvent then
        local centerX = Camera.ViewportSize.X / 2
        local centerY = Camera.ViewportSize.Y / 2
        vim:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.01)
        vim:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
        debugPrint("Sent MouseClick at center:", centerX, centerY)
    else
        UserInputService:SendMouseButtonEvent(0, 0, 0, true)
        UserInputService:SendMouseButtonEvent(0, 0, 0, false)
        debugPrint("Fallback MouseClick at (0,0)")
    end
end

spawn(function()
    local elapsed = 0
    while true do
        if autoShootOn and _G.CurrentAimbotTarget then
            if UserInputService.TouchEnabled then
                doTouchTapCenter()
            else
                doMouseClickCenter()
            end
        end
        task.wait(shootInterval)
        elapsed = elapsed + shootInterval
        if elapsed >= refreshInterval then
            debugPrint("Refreshing AutoShootButton.lua script...")
            elapsed = 0
            local success, err = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/AutoShootButton.lua"))()
            end)
            if not success then
                debugPrint("Failed to reload AutoShootButton.lua:", err)
            else
                debugPrint("Reloaded AutoShootButton.lua successfully.")
            end
            break
        end
    end
end)

autoShootButton.MouseButton1Click:Connect(function()
    autoShootOn = not autoShootOn
    autoShootButton.Text = "Auto Shoot: " .. (autoShootOn and "On" or "Off")
    autoShootButton.BackgroundColor3 = autoShootOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)
    debugPrint("Auto Shoot toggled", autoShootOn and "ON" or "OFF")
end)

debugPrint("AutoShootButton.lua script loaded and running.")
