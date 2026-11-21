if getgenv().VeniceToolkit then getgenv().VeniceToolkit:Destroy() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local host = (gethui and gethui()) or game:GetService("CoreGui")

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

local gui = new("ScreenGui", { Name = "VeniceToolkit", ResetOnSpawn = false, IgnoreGuiInset = true }, host)
getgenv().VeniceToolkit = gui

local win = new("Frame", {
	Size = UDim2.fromOffset(220, 244),
	Position = UDim2.new(0, 40, 0, 110),
	BackgroundColor3 = Color3.fromRGB(18, 18, 20),
	BorderSizePixel = 0,
	Active = true,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, win)
new("UIStroke", { Color = Color3.fromRGB(58, 58, 64) }, win)

local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(28, 28, 33), BorderSizePixel = 0 }, win)
new("TextLabel", {
	Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "venice.lua  ·  " .. (identifyexecutor and identifyexecutor() or "executor"),
	TextColor3 = Color3.fromRGB(190, 190, 196), TextSize = 13, Font = Enum.Font.GothamBold,
}, bar)

local dragging, dragFrom, origin
bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragFrom, origin = true, input.Position, win.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local d = input.Position - dragFrom
		win.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

local y = 36

local function toggle(label, onFlip)
	local btn = new("TextButton", {
		Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 0, y),
		BackgroundColor3 = Color3.fromRGB(31, 31, 36), BorderSizePixel = 0,
		Text = label .. ": off", TextColor3 = Color3.fromRGB(200, 200, 206),
		TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
	}, win)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, btn)
	y += 32
	local state = false
	local function set(v)
		state = v
		btn.Text = label .. ": " .. (v and "on" or "off")
		btn.TextColor3 = v and Color3.fromRGB(126, 224, 150) or Color3.fromRGB(200, 200, 206)
		onFlip(v)
	end
	btn.MouseButton1Click:Connect(function() set(not state) end)
	return set
end

local function button(label, fn)
	local b = new("TextButton", {
		Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 0, y),
		BackgroundColor3 = Color3.fromRGB(40, 40, 47), BorderSizePixel = 0,
		Text = label, TextColor3 = Color3.fromRGB(215, 215, 220),
		TextSize = 13, Font = Enum.Font.Gotham,
	}, win)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
	y += 32
	b.MouseButton1Click:Connect(fn)
	return b
end

-- fullbright: snapshot the lighting so we can put it back
local savedLight
toggle("Fullbright", function(on)
	if on then
		savedLight = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
			Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
			GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd }
		Lighting.Brightness, Lighting.ClockTime = 2, 12
		Lighting.Ambient = Color3.fromRGB(190, 190, 190)
		Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
		Lighting.GlobalShadows, Lighting.FogEnd = false, 1e6
	elseif savedLight then
		for k, v in savedLight do Lighting[k] = v end
		savedLight = nil
	end
end)

-- ESP: a Highlight per player, re-attached on respawn
local espEntries, espOn = {}, false
local function espAdd(plr)
	if plr == LP or espEntries[plr] then return end
	local entry = { conns = {} }
	espEntries[plr] = entry
	local function attach(char)
		local hl = Instance.new("Highlight")
		hl.FillColor = Color3.fromRGB(118, 170, 255)
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.45
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee, hl.Parent = char, char
		if entry.hl then entry.hl:Destroy() end
		entry.hl = hl
	end
	if plr.Character then attach(plr.Character) end
	table.insert(entry.conns, plr.CharacterAdded:Connect(attach))
end
toggle("Player ESP", function(on)
	espOn = on
	if on then
		for _, plr in Players:GetPlayers() do espAdd(plr) end
	else
		for plr, entry in espEntries do
			if entry.hl then entry.hl:Destroy() end
			for _, c in entry.conns do c:Disconnect() end
		end
		table.clear(espEntries)
	end
end)
Players.PlayerAdded:Connect(function(p) if espOn then espAdd(p) end end)
Players.PlayerRemoving:Connect(function(p)
	local e = espEntries[p]
	if e then
		if e.hl then e.hl:Destroy() end
		for _, c in e.conns do c:Disconnect() end
		espEntries[p] = nil
	end
end)

-- noclip: CanCollide is re-read every physics step, so we re-clear it every step
local noclipConn
toggle("Noclip", function(on)
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			local char = LP.Character
			if not char then return end
			for _, p in char:GetDescendants() do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end)
	else
		if noclipConn then noclipConn:Disconnect() end
		local char = LP.Character
		if char then
			for _, p in char:GetDescendants() do
				if p:IsA("BasePart") then p.CanCollide = true end
			end
		end
	end
end)

-- walkspeed: capture the real base value, reapply after every respawn
local baseSpeed, speedConn
toggle("Fast walkspeed", function(on)
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if on then
		baseSpeed = hum and hum.WalkSpeed or 16
		local function apply(c)
			local h = c:FindFirstChildOfClass("Humanoid")
			if h then h.WalkSpeed = baseSpeed * 3 end
		end
		if LP.Character then apply(LP.Character) end
		speedConn = LP.CharacterAdded:Connect(apply)
	else
		if speedConn then speedConn:Disconnect() end
		if hum and baseSpeed then hum.WalkSpeed = baseSpeed end
	end
end)

button("Teleport to nearest", function()
	local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	local best, dist
	for _, plr in Players:GetPlayers() do
		local root = plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local d = (root.Position - myRoot.Position).Magnitude
			if not dist or d < dist then best, dist = root, d end
		end
	end
	if best then LP.Character:PivotTo(best.CFrame * CFrame.new(0, 0, 3)) end
end)

button("Unload", function()
	getgenv().VeniceToolkit = nil
	gui:Destroy()
end)
