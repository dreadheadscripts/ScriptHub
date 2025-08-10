-- Define your main script as a global string
_G.MainScript = [[
	loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/refs/heads/main/Aimbot-Script/Base-Gui.lua"))()
]]
-- Key System Config
-- Load and run the key system script after setting MainScript
loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/main/Key/KeyConfig.lua"))()
