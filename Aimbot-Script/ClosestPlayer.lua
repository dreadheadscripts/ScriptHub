--// Closest Player Toggle (Config Tab)
local RunService = game:GetService("RunService")
local configTab = _G.Tabs and _G.Tabs.Config
if not configTab then return warn("Config tab not found!") end

-- Shared toggle state in _G
_G.ClosestPlayerESP = false

-- Create Button (Full Width)
local button = Instance.new("TextButton")
button.Size = UDim2.new(1, 0, 0, 35)
button.Position = UDim2.new(0, 0, 0, 50) -- Under crosshair button
button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.Text = "Closest Player: Off"
button.Parent = configTab

local corner = Instance.new("UICorner", button)
corner.CornerRadius = UDim.new(0, 6)

-- Button logic
button.MouseButton1Click:Connect(function()
	_G.ClosestPlayerESP = not _G.ClosestPlayerESP
	local on = _G.ClosestPlayerESP
	button.Text = "Closest Player: " .. (on and "On" or "Off")
	button.BackgroundColor3 = on and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(40, 40, 40)
end)

local previousClosest = nil -- store previous closest player

local function resetHighlight(player)
    local hl = espHighlights[player]
    if hl and hl.Parent then
        hl.OutlineColor = Color3.new(1, 0, 0) -- reset to red
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    ClosestPlayerEnabled = not ClosestPlayerEnabled
    toggleBtn.Text = ClosestPlayerEnabled and "Closest Player: On" or "Closest Player: Off"
    toggleBtn.BackgroundColor3 = ClosestPlayerEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(40, 40, 40)

    if not ClosestPlayerEnabled and previousClosest then
        resetHighlight(previousClosest)
        previousClosest = nil
        -- Also remove the line tracking if any
        if trackingLine then
            trackingLine.Visible = false
            trackingLine = nil
        end
    end
end)

-- In your RenderStepped update, after finding closest player:
if ClosestPlayerEnabled then
    if previousClosest and previousClosest ~= closestPlayer then
        resetHighlight(previousClosest)
    end

    previousClosest = closestPlayer
    -- set yellow outline
    if closestPlayer and espHighlights[closestPlayer] then
        espHighlights[closestPlayer].OutlineColor = Color3.fromRGB(255, 255, 0) -- yellow
    end

    -- update tracking line code here...
else
    -- When off, no line and no yellow highlight
    if previousClosest then
        resetHighlight(previousClosest)
        previousClosest = nil
    end
end
