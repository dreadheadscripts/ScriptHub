-- invincetrack.lua
local configTab = _G.Tabs and _G.Tabs.Config
if not configTab then
    warn("Config tab not found! Can't create InvinceTrack button.")
else
    _G.InvinceTrack = false -- default OFF

    local invBtn = Instance.new("TextButton")
    invBtn.Size = UDim2.new(1, 0, 0, 35)        -- full-width like other buttons
    invBtn.Position = UDim2.new(0, 0, 0, 90)    -- place under Closest Player (closest at y=50)
    invBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    invBtn.TextColor3 = Color3.fromRGB(1, 1, 1)
    invBtn.Font = Enum.Font.GothamBold
    invBtn.TextSize = 18
    invBtn.Text = "Invince Track: Off"
    invBtn.Parent = configTab

    local corner = Instance.new("UICorner", invBtn)
    corner.CornerRadius = UDim.new(0, 6)

    invBtn.MouseButton1Click:Connect(function()
        _G.InvinceTrack = not _G.InvinceTrack
        invBtn.Text = "Invince Track: " .. (_G.InvinceTrack and "On" or "Off")
        invBtn.BackgroundColor3 = _G.InvinceTrack and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)
        -- you can add any extra behavior here if needed
    end)
end
