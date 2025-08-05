return function(parentFrame)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Camera = workspace.CurrentCamera

    -- Default state
    local crosshairOn = true
    local crosshairColor = Color3.fromRGB(255, 255, 255)

    -- Create toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 180, 0, 30)
    toggleBtn.Position = UDim2.new(0, 10, 0, 10)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.Text = "Crosshair: On"
    toggleBtn.Parent = parentFrame
    Instance.new("UICorner", toggleBtn)

    -- Create sliders for R, G, B (using TextBoxes for input)
    local function createSlider(name, yPos, default)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 50, 0, 20)
        label.Position = UDim2.new(0, 10, 0, yPos)
        label.BackgroundTransparency = 1
        label.Text = name .. ":"
        label.TextColor3 = Color3.new(1,1,1)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = parentFrame

        local inputBox = Instance.new("TextBox")
        inputBox.Size = UDim2.new(0, 120, 0, 20)
        inputBox.Position = UDim2.new(0, 60, 0, yPos)
        inputBox.Text = tostring(default)
        inputBox.TextColor3 = Color3.new(1,1,1)
        inputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        inputBox.ClearTextOnFocus = false
        inputBox.Font = Enum.Font.Gotham
        inputBox.TextSize = 14
        inputBox.Parent = parentFrame
        Instance.new("UICorner", inputBox)

        return inputBox
    end

    local rInput = createSlider("R", 50, 255)
    local gInput = createSlider("G", 80, 255)
    local bInput = createSlider("B", 110, 255)

    local function clamp(n, min, max)
        if n < min then return min end
        if n > max then return max end
        return n
    end

    -- Crosshair UI Setup
    local crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = "CrosshairGui"
    crosshairGui.ResetOnSpawn = false
    crosshairGui.Parent = PlayerGui

    local crosshairSize = 6
    local crosshairGap = 2
    local lineThickness = 2

    -- Create 4 crosshair lines as Frames
    local lines = {}

    -- Top line
    lines.top = Instance.new("Frame")
    lines.top.AnchorPoint = Vector2.new(0.5, 1)
    lines.top.Size = UDim2.new(0, lineThickness, 0, crosshairSize)
    lines.top.BackgroundColor3 = crosshairColor
    lines.top.BorderSizePixel = 0
    lines.top.Parent = crosshairGui

    -- Bottom line
    lines.bottom = Instance.new("Frame")
    lines.bottom.AnchorPoint = Vector2.new(0.5, 0)
    lines.bottom.Size = UDim2.new(0, lineThickness, 0, crosshairSize)
    lines.bottom.BackgroundColor3 = crosshairColor
    lines.bottom.BorderSizePixel = 0
    lines.bottom.Parent = crosshairGui

    -- Left line
    lines.left = Instance.new("Frame")
    lines.left.AnchorPoint = Vector2.new(1, 0.5)
    lines.left.Size = UDim2.new(0, crosshairSize, 0, lineThickness)
    lines.left.BackgroundColor3 = crosshairColor
    lines.left.BorderSizePixel = 0
    lines.left.Parent = crosshairGui

    -- Right line
    lines.right = Instance.new("Frame")
    lines.right.AnchorPoint = Vector2.new(0, 0.5)
    lines.right.Size = UDim2.new(0, crosshairSize, 0, lineThickness)
    lines.right.BackgroundColor3 = crosshairColor
    lines.right.BorderSizePixel = 0
    lines.right.Parent = crosshairGui

    local function updateCrosshair()
        local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2

        lines.top.Position = UDim2.new(0, cx, 0, cy - crosshairGap)
        lines.bottom.Position = UDim2.new(0, cx, 0, cy + crosshairGap)
        lines.left.Position = UDim2.new(0, cx - crosshairGap, 0, cy)
        lines.right.Position = UDim2.new(0, cx + crosshairGap, 0, cy)

        for _, line in pairs(lines) do
            line.BackgroundColor3 = crosshairColor
            line.Visible = crosshairOn
        end
    end

    -- Toggle button functionality
    toggleBtn.MouseButton1Click:Connect(function()
        crosshairOn = not crosshairOn
        toggleBtn.Text = "Crosshair: " .. (crosshairOn and "On" or "Off")
        toggleBtn.BackgroundColor3 = crosshairOn and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(80, 80, 80)
        updateCrosshair()
    end)

    -- Update color on inputs change
    local function updateColor()
        local r = clamp(tonumber(rInput.Text) or 255, 0, 255)
        local g = clamp(tonumber(gInput.Text) or 255, 0, 255)
        local b = clamp(tonumber(bInput.Text) or 255, 0, 255)
        crosshairColor = Color3.fromRGB(r, g, b)
        updateCrosshair()
    end

    rInput.FocusLost:Connect(updateColor)
    gInput.FocusLost:Connect(updateColor)
    bInput.FocusLost:Connect(updateColor)

    -- Constant update every frame
    RunService.RenderStepped:Connect(function()
        updateCrosshair()
    end)

    -- Initial draw
    updateCrosshair()
end
