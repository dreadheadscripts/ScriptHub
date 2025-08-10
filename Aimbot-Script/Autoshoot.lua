--// AutoShootButton.lua
--// Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Debug function to print with tag
local function debugPrint(...)
    print("[AutoShoot DEBUG]:", ...)
end

-- Wait for config tab (with timeout and debug)
local configTab
local maxWait = 10
local waited = 0
repeat
    configTab = _G.Tabs and _G.Tabs.Config
    if not configTab then
        task.wait(0.1)
        waited = waited + 0.1
    end
until configTab or waited >= maxWait
if not configTab then
    debugPrint("Failed to find Config tab in time, stopping script.")
    return
end

-- Auto Shoot variables
local autoShootOn = true  -- STARTED ON
local shootInterval = 0.1  -- seconds between shots
local refreshInterval = 60 -- seconds before script auto refreshes

-- Create Auto Shoot toggle button
local autoShootButton = Instance.new("TextButton")
autoShootButton.Size = UDim2.new(1, 0, 0, 35)
autoShootButton.Position = UDim2.new(0, 0, 0, 130) -- adjust Y if needed
autoShootButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- green because ON
autoShootButton.TextColor3 = Color3.new(1, 1, 1)
autoShootButton.Font = Enum.Font.GothamBold
autoShootButton.TextSize = 18
autoShootButton.Text = "Auto Shoot: On"
autoShootButton.Parent = configTab
Instance.new("UICorner", autoShootButton).CornerRadius = UDim.new(0, 6)

-- Bypass placeholder:
-- If you know any anti-cheat globals, disable or reset them here
-- e.g. _G.AntiCheatEnabled = false
debugPrint("Bypass hooks (if any) should be placed here.")

-- Function to tap directly in center of screen on mobile
local function doTouchTapCenter()
    local centerPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    UserInputService:TouchTap(centerPos.X, centerPos.Y)
    debugPrint("TouchTap at center:", centerPos.X, centerPos.Y)
end

-- Function to click mouse center on PC fallback
local function doMouseClickCenter()
    local vim = game:GetService("VirtualInputManager")
    if vim and vim.SendMouseButtonEvent then
        local centerX = Camera.ViewportSize.X / 2
        local centerY = Camera.ViewportSize.Y / 2
        -- Mouse button down
        vim:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.01)
        -- Mouse button up
        vim:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
        debugPrint("Mouse click at center:", centerX, centerY)
    else
        -- fallback clicks at 0,0 (may not be accurate)
        UserInputService:SendMouseButtonEvent(0, 0, 0, true)
        UserInputService:SendMouseButtonEvent(0, 0, 0, false)
        debugPrint("Fallback mouse click at (0,0)")
    end
end

-- Auto shoot loop with debug and bypass refresh logic
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

        -- Refresh (reload) the script every refreshInterval seconds to bypass detection
        if elapsed >= refreshInterval then
            debugPrint("Refreshing AutoShootButton.lua script to bypass detection...")
            elapsed = 0
            -- Reload script by fetching from your GitHub repo (adjust URL to your script location)
            local success, err = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Aimbot-Script/AutoShootButton.lua"))()
            end)
            if not success then
                debugPrint("Failed to reload AutoShootButton.lua:", err)
            else
                debugPrint("Reloaded AutoShootButton.lua successfully.")
            end
            -- Stop current loop to avoid duplicates after reload
            break
        end
    end
end)

-- Toggle button logic with debug
autoShootButton.MouseButton1Click:Connect(function()
    autoShootOn = not autoShootOn
    autoShootButton.Text = "Auto Shoot: " .. (autoShootOn and "On" or "Off")
    autoShootButton.BackgroundColor3 = autoShootOn and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)
    debugPrint("Auto Shoot toggled", autoShootOn and "ON" or "OFF")
end)

debugPrint("AutoShootButton.lua script loaded and running.")
