-- invincetrack.lua
local configTab = _G.ConfigTab
if not configTab then
    warn("Config tab not found for Invince Track button")
    return
end

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, 0, 0, 35) -- full width, 35px height
button.Position = UDim2.new(0, 0, 0, 90) -- below Closest Player button
button.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- off state
button.Text = "Invince Track: Off"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 20
button.Parent = configTab

_G.InvinceTrackEnabled = false

button.MouseButton1Click:Connect(function()
    _G.InvinceTrackEnabled = not _G.InvinceTrackEnabled
    if _G.InvinceTrackEnabled then
        button.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- green on
        button.Text = "Invince Track: On"
    else
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- off color
        button.Text = "Invince Track: Off"
    end
end)
