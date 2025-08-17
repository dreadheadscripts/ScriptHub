--// Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local userId = tostring(LocalPlayer.UserId)

--// Generate or load persistent deviceId tied to the device
local sessionFile = "device_sessionId.txt"
local deviceId
if isfile(sessionFile) then
	deviceId = readfile(sessionFile)
else
	deviceId = HttpService:GenerateGUID(false)
	writefile(sessionFile, deviceId)
end
local sessionId = deviceId -- sessionId now tied only to device, shared by all users on that device

--// Config
local keyFileName = "keySystemKey.txt"
local FIRESTORE_BASE = "https://firestore.googleapis.com/v1/projects/smh-keysystem/databases/(default)/documents/keys/"
local HEARTBEAT_INTERVAL = 2
local STALE_THRESHOLD = 15 * 1000 -- milliseconds
local MainScript = [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/dreadheadscripts/ScriptHub/refs/heads/main/Aimbot-Script/Base-Gui.lua
"))()
]]

--// Utilities
local function safeReadFile(name)
	local ok, content = pcall(function() return readfile(name) end)
	return ok and content or nil
end

local function safeWriteFile(name, content)
	pcall(function() writefile(name, content) end)
end

local function notify(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 3
		})
	end)
end

local function httpRequestWithRetry(reqArgs)
	local retries = 2
	for attempt = 1, retries do
		local ok, res = pcall(function()
			return HttpService:RequestAsync(reqArgs)
		end)
		if ok and res and res.Success then
			return res
		else
			warn("[KeySystem Debug] HTTP request failed:", (res and res.StatusCode) or "nil", (res and res.StatusMessage) or "no msg")
			task.wait(0.5)
		end
	end
	return nil
end

local function fetchKeyDoc(key)
	local url = FIRESTORE_BASE .. key
	warn("[KeySystem Debug] GET →", url)
	local response = httpRequestWithRetry({
		Url = url,
		Method = "GET",
		Headers = { ["Content-Type"] = "application/json" }
	})
	if not response then return nil, "network" end
	local ok, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
	if not ok or not data or not data.fields then return nil, "parse" end
	return data, nil
end

local function patchKeyFields(key, fieldsTable)
	local updateMask = table.concat((function()
		local out = {}
		for field, _ in pairs(fieldsTable) do table.insert(out, field) end
		return out
	end)(), "&updateMask.fieldPaths=")
	local url = FIRESTORE_BASE .. key .. "?updateMask.fieldPaths=" .. updateMask
	local body = { fields = fieldsTable }
	local response = httpRequestWithRetry({
		Url = url,
		Method = "PATCH",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode(body)
	})
	return response and response.Success
end

local function claimKey(key, sessionId, userId)
	return patchKeyFields(key, {
		sessionId = { stringValue = sessionId },
		userId = { stringValue = tostring(userId) },
		inUse = { booleanValue = true },
		lastPing = { integerValue = tostring(os.time() * 1000) }
	})
end

local function clearKeyBinding(key)
	return patchKeyFields(key, {
		sessionId = { stringValue = "" },
		userId = { stringValue = "" },
		inUse = { booleanValue = false },
		lastPing = { integerValue = "0" }
	})
end

local function updateLastPing(key, sessionId, userId)
	local timestamp = tostring(os.time() * 1000)
	local success = patchKeyFields(key, {
		lastPing = { integerValue = timestamp },
		userId = { stringValue = tostring(userId) }
	})
	if not success then
		warn("[KeySystem Debug] Failed to update heartbeat. Checking for key swap.")
		local doc, err = fetchKeyDoc(key)
		if doc and doc.fields and doc.fields.sessionId and doc.fields.sessionId.stringValue ~= sessionId then
			LocalPlayer:Kick("Key has been swapped")
		end
	end
	return success
end

local function validateKey(key, sessionId, userId)
	local doc, err = fetchKeyDoc(key)
	if not doc then return false, "invalid" end
	local fields = doc.fields

	if not (fields.valid and fields.valid.booleanValue) then return false, "invalid" end
	local expires = tonumber(fields.expiresAt and fields.expiresAt.integerValue)
	if not expires or expires <= os.time() * 1000 then return false, "expired" end

	local docSession = fields.sessionId and fields.sessionId.stringValue or ""
	local docLastPing = tonumber(fields.lastPing and fields.lastPing.integerValue) or 0

	if docSession == sessionId then
		updateLastPing(key, sessionId, userId)
		return true
	end

	if docSession == "" then
		return claimKey(key, sessionId, userId), "claimed"
	end

	if (os.time() * 1000 - docLastPing) >= STALE_THRESHOLD then
		if clearKeyBinding(key) and claimKey(key, sessionId, userId) then
			return true
		end
		return false, "takeover_failed"
	end

	return false, "session_mismatch"
end

local function closeMainGui()
	local gui = PlayerGui:FindFirstChild("MainScriptGUI")
	if gui then gui:Destroy() end
end

local function reopenKeyGUI()
	closeMainGui()
	safeWriteFile(keyFileName, "")
	showKeyGUI()
end

local function monitorKey(key)
	while true do
		task.wait(HEARTBEAT_INTERVAL)
		local valid, reason = validateKey(key, sessionId, userId)
		if not valid then
			warn("[KeySystem Debug] Key invalid or swapped, reopening GUI.")
			notify("Session Ended", "Key swapped or expired.")
			reopenKeyGUI()
			break
		end
	end
end

--// Show Key GUI
function showKeyGUI()
	local existing = PlayerGui:FindFirstChild("KeySystemGUI")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui", PlayerGui)
	gui.Name = "KeySystemGUI"
	gui.ResetOnSpawn = false

	local frame = Instance.new("Frame", gui)
	frame.Size = UDim2.new(0, 360, 0, 380)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 12)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(220, 220, 220)
	title.Text = "Enter Your Access Key"

	local desc = Instance.new("TextLabel", frame)
	desc.Size = UDim2.new(1, -40, 0, 40)
	desc.Position = UDim2.new(0, 20, 0, 50)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 15
	desc.TextColor3 = Color3.fromRGB(180, 180, 180)
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Text = "Paste your key below. If you don't have one, join our Discord or get a direct key link."

	local bottomLabel = Instance.new("TextLabel", frame)
	bottomLabel.Size = UDim2.new(1, 0, 0, 24)
	bottomLabel.Position = UDim2.new(0, 0, 0, 90)
	bottomLabel.BackgroundTransparency = 1
	bottomLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	bottomLabel.Font = Enum.Font.GothamBold
	bottomLabel.TextSize = 16
	bottomLabel.Text = "Script Maniac Hub"

	local input = Instance.new("TextBox", frame)
	input.Size = UDim2.new(1, -40, 0, 40)
	input.Position = UDim2.new(0, 20, 0, 115)
	input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	input.TextColor3 = Color3.fromRGB(230, 230, 230)
	input.Font = Enum.Font.Gotham
	input.TextSize = 18
	input.PlaceholderText = "Paste your key here..."
	input.Text = ""
	input.ClearTextOnFocus = false
	Instance.new("UICorner", input).CornerRadius = UDim.new(0, 8)

	local submit = Instance.new("TextButton", frame)
	submit.Size = UDim2.new(1, -40, 0, 45)
	submit.Position = UDim2.new(0, 20, 0, 165)
	submit.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
	submit.Text = "Submit"
	submit.Font = Enum.Font.GothamSemibold
	submit.TextSize = 20
	submit.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 8)

	local buttonsFrame = Instance.new("Frame", frame)
	buttonsFrame.Size = UDim2.new(1, -40, 0, 130)
	buttonsFrame.Position = UDim2.new(0, 20, 0, 220)
	buttonsFrame.BackgroundTransparency = 1

	local discord = Instance.new("TextButton", buttonsFrame)
	discord.Size = UDim2.new(1, 0, 0, 40)
	discord.Position = UDim2.new(0, 0, 0, 0)
	discord.BackgroundColor3 = Color3.fromRGB(70, 100, 180)
	discord.Text = "Join Discord for Key"
	discord.Font = Enum.Font.GothamSemibold
	discord.TextSize = 18
	discord.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", discord).CornerRadius = UDim.new(0, 8)

	local directKey = Instance.new("TextButton", buttonsFrame)
	directKey.Size = UDim2.new(1, 0, 0, 40)
	directKey.Position = UDim2.new(0, 0, 0, 50)
	directKey.BackgroundColor3 = Color3.fromRGB(90, 130, 170)
	directKey.Text = "Get Key Direct Link"
	directKey.Font = Enum.Font.GothamSemibold
	directKey.TextSize = 18
	directKey.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", directKey).CornerRadius = UDim.new(0, 8)

	local closeBtn = Instance.new("TextButton", frame)
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 20
	closeBtn.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	discord.MouseButton1Click:Connect(function()
		setclipboard("https://discord.gg/8hYTmpTC")
		notify("Copied", "Discord invite link copied to clipboard.")
	end)

	directKey.MouseButton1Click:Connect(function()
		setclipboard("https://dreadheadscripts.github.io/Key/")
		notify("Copied", "Key direct link copied to clipboard.")
	end)

	submit.MouseButton1Click:Connect(function()
		local key = input.Text:match("^%s*(.-)%s*$")
		if key == "" then
			notify("Error", "Please enter a key.")
			return
		end

		submit.Text = "Checking..."
		submit.Active = false
		submit.BackgroundColor3 = Color3.fromRGB(160, 160, 60)

		task.spawn(function()
			local ok, reason = validateKey(key, sessionId, LocalPlayer.UserId)
			if ok then
				safeWriteFile(keyFileName, key)
				gui:Destroy()
				notify("Key Valid", "Access granted. Loading...")
				loadstring(MainScript)()

				task.spawn(function()
					while true do
						task.wait(HEARTBEAT_INTERVAL)
						updateLastPing(key, sessionId, userId)
					end
				end)

				task.spawn(function()
					monitorKey(key)
				end)
			else
				if reason == "session_mismatch" then
					local doc = fetchKeyDoc(key)
					local boundTo = doc and doc.fields and doc.fields.userId and doc.fields.userId.stringValue or "another user"
					local confirmGui = Instance.new("ScreenGui", PlayerGui)
					confirmGui.Name = "ConfirmUnlinkGUI"
					confirmGui.ResetOnSpawn = false

					local box = Instance.new("Frame", confirmGui)
					box.Size = UDim2.new(0, 320, 0, 170)
					box.Position = UDim2.new(0.5, -160, 0.45, 0)
					box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
					box.Active = true
					box.Draggable = true
					Instance.new("UICorner", box)

					local message = Instance.new("TextLabel", box)
					message.Size = UDim2.new(1, -20, 0, 60)
					message.Position = UDim2.new(0, 10, 0, 15)
					message.TextWrapped = true
					message.Text = "This key is already linked to:\n" .. boundTo .. "\n\nDo you want to unlink it?"
					message.Font = Enum.Font.Gotham
					message.TextSize = 16
					message.TextColor3 = Color3.new(1, 1, 1)
					message.BackgroundTransparency = 1

					local yes = Instance.new("TextButton", box)
					yes.Size = UDim2.new(0.4, 0, 0, 30)
					yes.Position = UDim2.new(0.05, 0, 1, -45)
					yes.Text = "Unlink"
					yes.Font = Enum.Font.GothamBold
					yes.TextSize = 14
					yes.TextColor3 = Color3.new(1, 1, 1)
					yes.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
					Instance.new("UICorner", yes)

					local no = Instance.new("TextButton", box)
					no.Size = UDim2.new(0.4, 0, 0, 30)
					no.Position = UDim2.new(0.55, 0, 1, -45)
					no.Text = "Cancel"
					no.Font = Enum.Font.GothamBold
					no.TextSize = 14
					no.TextColor3 = Color3.new(1, 1, 1)
					no.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
					Instance.new("UICorner", no)

					yes.MouseButton1Click:Connect(function()
						confirmGui:Destroy()
						if clearKeyBinding(key) and claimKey(key, sessionId, LocalPlayer.UserId) then
							safeWriteFile(keyFileName, key)
							gui:Destroy()
							notify("Claimed", "Key re-linked to your session.")
							loadstring(MainScript)()

							task.spawn(function()
								while true do
									task.wait(HEARTBEAT_INTERVAL)
									updateLastPing(key, sessionId, userId)
								end
							end)

							task.spawn(function()
								monitorKey(key)
							end)
						else
							notify("Error", "Failed to re-link key.")
							submit.Text = "Try Again"
							submit.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
							task.wait(1.8)
							submit.Text = "Submit"
							submit.Active = true
						end
					end)

					no.MouseButton1Click:Connect(function()
						confirmGui:Destroy()
						submit.Text = "Submit"
						submit.Active = true
					end)
				else
					notify("Invalid", "Invalid, Key Expired or Invalid")
					submit.Text = "Try Again"
					submit.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
					task.wait(1.8)
					submit.Text = "Submit"
					submit.Active = true
				end
			end
		end)
	end)
end

--// Entry Point Logic
local function tryCachedKey()
	local key = safeReadFile(keyFileName)
	if not key or key == "" then return false end

	local ok, reason = validateKey(key, sessionId, LocalPlayer.UserId)
	if ok then
		notify("Key Valid", "Access granted. Loading...")
		loadstring(MainScript)()
		task.spawn(function()
			while true do
				task.wait(HEARTBEAT_INTERVAL)
				updateLastPing(key, sessionId, userId)
			end
		end)
		task.spawn(function()
			monitorKey(key)
		end)
		return true
	else
		if reason == "expired" or reason == "invalid" or reason == "session_mismatch" then
			safeWriteFile(keyFileName, "")
			showKeyGUI()
		end
		return false
	end
end

--// Start script
if not tryCachedKey() then
	showKeyGUI()
end
