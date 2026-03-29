local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- Wait for config tab
local configTab
repeat
    configTab = _G.Tabs and _G.Tabs.Config
    task.wait(0.1)
until configTab

-- SETTINGS
local autoShootOn = true
local shootInterval = 0.08 -- faster & smoother
local maxDistance = 12 -- only shoot if close

local isTouching = false

-- Mobile touch detection
UserInputService.TouchStarted:Connect(function(_, gp)
    if not gp then
        isTouching = true
    end
end)

UserInputService.TouchEnded:Connect(function(_, gp)
    if not gp then
        isTouching = false
    end
end)

-- GUI BUTTON
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, 0, 0, 50)
btn.Position = UDim2.new(0, 0, 0, 130)
btn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
btn.TextColor3 = Color3.new(1,1,1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.TextWrapped = true
btn.Text = "Auto Shoot: ON\n(PC recommended)"
btn.Parent = configTab

Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

-- CLICK FUNCTION
local function click()
    local x = Camera.ViewportSize.X / 2
    local y = Camera.ViewportSize.Y / 2

    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

-- MAIN LOOP
task.spawn(function()
    while true do
        if autoShootOn and not isTouching then
            local target = _G.CurrentAimbotTarget
            local myChar = LocalPlayer.Character

            if target and target.Character and myChar then
                local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                local mHRP = myChar:FindFirstChild("HumanoidRootPart")
                local humanoid = target.Character:FindFirstChild("Humanoid")

                if tHRP and mHRP and humanoid and humanoid.Health > 0 then
                    local dist = (tHRP.Position - mHRP.Position).Magnitude

                    if dist <= maxDistance then
                        click()
                    end
                end
            end
        end

        task.wait(shootInterval)
    end
end)

-- TOGGLE BUTTON
btn.MouseButton1Click:Connect(function()
    autoShootOn = not autoShootOn

    btn.Text = "Auto Shoot: " .. (autoShootOn and "ON" or "OFF") .. "\n(PC recommended)"
    btn.BackgroundColor3 = autoShootOn and Color3.fromRGB(0,180,0) or Color3.fromRGB(40,40,40)
end)
