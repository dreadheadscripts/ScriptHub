local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

--// AutoShootButton.lua
--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Wait for Config tab to exist
local configTab
repeat
    configTab = _G.Tabs and _G.Tabs.Config
    task.wait(0.1)
until configTab

-- Auto Shoot variables
local autoShootOn = true  -- Starts ON
local shootInterval = 0.1 -- Seconds between shots

-- Create Auto Shoot toggle button
local autoShootButton = Instance.new("TextButton")
autoShootButton.Size = UDim2.new(1, 0, 0, 35)
autoShootButton.Position = UDim2.new(0, 0, 0, 130) -- Adjust Y if needed
autoShootButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- Green = ON
autoShootButton.TextColor3 = Color3.new(1, 1, 1)
autoShootButton.Font = Enum.Font.GothamBold
autoShootButton.TextSize = 18
autoShootButton.Text = "Auto Shoot: On"
autoShootButton.Parent = configTab
Instance.new("UICorner", autoShootButton).CornerRadius = UDim.new(0, 6)

-- Function to trigger shooting by activating the tool
local function doAutoShoot()
    local character = LocalPlayer.Character
    if not character then return end

    -- Find the tool equipped
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        -- Activate tool to shoot
        tool:Activate()
    end
end

-- Auto shoot loop
spawn(function()
    while true do
        if autoShootOn and _G.CurrentAimbotTarget ~= nil then
            doAutoShoot()
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
