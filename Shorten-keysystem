-- Define your main script as a global string
_G.MainScript = [[
	local gui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
	gui.Name = "MainScriptGUI"
	local label = Instance.new("TextLabel", gui)
	label.Size = UDim2.new(0.5, 0, 0.1, 0)
	label.Position = UDim2.new(0.25, 0, 0.05, 0)
	label.Text = "✅ Main script running!"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
]]
-- Key System Config
-- Load and run the key system script after setting MainScript
loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Key/KeyConfig.lua"))()
