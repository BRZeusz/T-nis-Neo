  -- TenisNeo.lua
-- LocalScript único. Coloque em StarterPlayer/StarterPlayerScripts ou carregue via loadstring.
-- Versão com limpeza reforçada para evitar problemas ao reinjetar (duplica/overlap/funcionalidades sumindo).

-- ===== Aggressive cleanup of previous injections =====
local function safeDisconnect(conn)
	pcall(function()
		if conn and conn.Disconnect then conn:Disconnect() end
	end)
end
local function safeDestroy(obj)
	pcall(function()
		if obj and obj.Destroy then obj:Destroy() end
	end)
end

-- If previous internal table exists, stop its loops and destroy gui
if type(_G) == "table" and _G._TenisNeoInternal then
	local old = _G._TenisNeoInternal
	-- set flags to false to stop loops (if present)
	pcall(function() if old.autoState then old.autoState.hitRunning = false; old.autoState.serveRunning = false end end)
	-- disconnect connections
	pcall(function() safeDisconnect(old.bindingConn) end)
	pcall(function() safeDisconnect(old.toggleConn) end)
	pcall(function() safeDisconnect(old.dragConn) end)
	-- destroy GUI
	pcall(function() safeDestroy(old.screenGui) end)
	-- cleanup globals
	_G.TenisNeoConfig = nil
	_G._TenisNeoInternal = nil
end

-- Also search PlayerGui and CoreGui for any TenisNeoGui or instances with "TenisNeo" in the name
pcall(function()
	local Players = game:GetService("Players")
	local core = game:GetService("CoreGui")
	if Players.LocalPlayer then
		local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
		if pg then
			for _,child in ipairs(pg:GetChildren()) do
				if child.Name == "TenisNeoGui" or tostring(child.Name):lower():find("tenisneo") then
					safeDestroy(child)
				end
			end
		end
	end
	-- CoreGui (some executors parent to CoreGui)
	if core then
		for _,child in ipairs(core:GetChildren()) do
			if child.Name == "TenisNeoGui" or tostring(child.Name):lower():find("tenisneo") then
				safeDestroy(child)
			end
		end
	end
end)

-- ===== Services & player =====
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
if not player then player = Players:WaitForChild("LocalPlayer") end
local playerGui = player:WaitForChild("PlayerGui")

-- create fresh internal table for future cleanup
_G._TenisNeoInternal = {}
local internal = _G._TenisNeoInternal

-- ===== Config / API =====
local Config = {
	Enabled = true,
	ToggleKey = Enum.KeyCode.F,
	ToggleKeyName = "F",
	_callbacks = { Enabled = {}, ToggleKey = {}, Colors = {} },
	Colors = {
		Background = Color3.fromRGB(28, 28, 30),
		Accent = Color3.fromRGB(220, 40, 80),
		Text = Color3.fromRGB(240,240,240)
	}
}
local function notifyEnabled(v) for _,cb in ipairs(Config._callbacks.Enabled) do pcall(cb,v) end end
local function notifyToggleKey(v) for _,cb in ipairs(Config._callbacks.ToggleKey) do pcall(cb,v) end end
local function notifyColors(v) for _,cb in ipairs(Config._callbacks.Colors) do pcall(cb,v) end end

function Config:SetEnabled(value) assert(type(value)=="boolean"); self.Enabled = value; notifyEnabled(value); return true end
function Config:ToggleEnabled() self:SetEnabled(not self.Enabled) end
function Config:SetToggleKey(key)
	if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
		self.ToggleKey = key
		self.ToggleKeyName = tostring(key):match("Enum.KeyCode%.(.+)") or tostring(key)
		notifyToggleKey(self.ToggleKey)
		return true
	elseif type(key) == "string" then
		local enumKey = Enum.KeyCode[key]
		if enumKey then self.ToggleKey = enumKey; self.ToggleKeyName = key; notifyToggleKey(self.ToggleKey); return true end
		error("Nome de tecla inválido: "..tostring(key))
	else error("SetToggleKey espera Enum.KeyCode ou string") end
end
function Config:OnEnabledChanged(cb) assert(type(cb)=="function"); table.insert(self._callbacks.Enabled, cb) end
function Config:OnToggleKeyChanged(cb) assert(type(cb)=="function"); table.insert(self._callbacks.ToggleKey, cb) end
function Config:OnColorsChanged(cb) assert(type(cb)=="function"); table.insert(self._callbacks.Colors, cb) end
function Config:DisableMenu() self:SetEnabled(false) end
function Config:SetColors(colors)
	if type(colors) ~= "table" then error("SetColors espera tabela") end
	for k,v in pairs(colors) do if self.Colors[k] ~= nil and typeof(v) == "Color3" then self.Colors[k] = v end end
	notifyColors(self.Colors)
	return true
end

-- expose API globally
_G.TenisNeoConfig = Config

-- ===== Build UI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TenisNeoGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 50
-- try playerGui parent, fallback to CoreGui
local ok, err = pcall(function() screenGui.Parent = playerGui end)
if not ok then pcall(function() screenGui.Parent = game:GetService("CoreGui") end) end
internal.screenGui = screenGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.AnchorPoint = Vector2.new(0,0)
frame.Position = UDim2.new(0.18,0,0.18,0)
frame.Size = UDim2.new(0,600,0,460)
frame.BackgroundColor3 = Config.Colors.Background
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.ClipsDescendants = true
local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,12)

local shadow = Instance.new("ImageLabel", frame)
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0,0)
shadow.Position = UDim2.new(0,-14,0,-14)
shadow.Size = UDim2.new(1,28,1,28)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://166617432"
shadow.ImageColor3 = Color3.new(0,0,0)
shadow.ImageTransparency = 0.85
shadow.ZIndex = -1

-- Top bar (draggable)
local topBar = Instance.new("Frame", frame)
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1,0,0,64)
topBar.BackgroundColor3 = Config.Colors.Background
topBar.BorderSizePixel = 0

local topAccent = Instance.new("Frame", topBar)
topAccent.Name = "TopAccent"
topAccent.Size = UDim2.new(1,0,0,6)
topAccent.Position = UDim2.new(0,0,1,-6)
topAccent.BackgroundColor3 = Config.Colors.Accent

local title = Instance.new("TextLabel", topBar)
title.Name = "Title"
title.Size = UDim2.new(0.75,-20,1,0)
title.Position = UDim2.new(0,12,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Bangers
title.TextSize = 24
title.Text = "TÊNIS NEO BY _ZEUSX77"
title.TextColor3 = Config.Colors.Text
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Name = "Close"
closeBtn.Size = UDim2.new(0,44,0,34)
closeBtn.Position = UDim2.new(1,-64,0,14)
closeBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Config.Colors.Text
local closeCorner = Instance.new("UICorner", closeBtn); closeCorner.CornerRadius = UDim.new(0,8)
closeBtn.MouseButton1Click:Connect(function() Config:DisableMenu() end)

local mainArea = Instance.new("Frame", frame)
mainArea.Name = "MainArea"
mainArea.Size = UDim2.new(1,0,1,-64)
mainArea.Position = UDim2.new(0,0,0,64)
mainArea.BackgroundTransparency = 1

-- Side tabs
local side = Instance.new("Frame", mainArea)
side.Name = "Side"
side.Size = UDim2.new(0,180,1,-24)
side.Position = UDim2.new(0,16,0,12)
side.BackgroundTransparency = 1
local sideLayout = Instance.new("UIListLayout", side); sideLayout.SortOrder = Enum.SortOrder.LayoutOrder; sideLayout.Padding = UDim.new(0,12)

-- Content (scrolling)
local content = Instance.new("ScrollingFrame", mainArea)
content.Name = "Content"
content.Position = UDim2.new(0,216,0,12)
content.Size = UDim2.new(1,-232,1,-24)
content.CanvasSize = UDim2.new(0,0,0,0)
content.ScrollBarThickness = 8
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.VerticalScrollBarInset = Enum.ScrollBarInset.Always
local contentLayout = Instance.new("UIListLayout", content)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0,10)
contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	content.CanvasSize = UDim2.new(0,0,0, contentLayout.AbsoluteContentSize.Y + 16)
end)

local function clearContent()
	for _,v in pairs(content:GetChildren()) do
		if v ~= contentLayout then safeDestroy(v) end
	end
end

-- tab buttons
local tabButtons = {}
local function createTabButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,0,0,44)
	btn.BackgroundColor3 = Color3.fromRGB(34,34,36)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Bangers
	btn.TextSize = 16
	btn.Text = text
	btn.TextColor3 = Config.Colors.Text
	btn.AutoButtonColor = false
	btn.Parent = side
	local uic = Instance.new("UICorner", btn); uic.CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(0,0,0); stroke.Thickness = 1; stroke.Transparency = 0.75
	table.insert(tabButtons, btn)
	return btn
end

local autoBtn = createTabButton("AUTO")
local settingsBtn = createTabButton("SETTINGS")

-- UIRefs and binding management
local UIRefs = { lblKey = nil, changeKeyBtn = nil, bindingActive = false }
local bindingConn = nil
local function stopBinding()
	if bindingConn then safeDisconnect(bindingConn) end
	bindingConn = nil
	UIRefs.bindingActive = false
	if UIRefs.changeKeyBtn then UIRefs.changeKeyBtn.Text = "Mudar tecla" end
	internal.bindingConn = nil
end
local function startBinding(lblKey, changeKeyBtn, info)
	if UIRefs.bindingActive then return end
	UIRefs.bindingActive = true
	changeKeyBtn.Text = "Pressione a tecla..."
	info.Text = "Pressione a tecla desejada. Esc para cancelar."
	bindingConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then info.Text = "Cancelado."; stopBinding(); return end
			local ok, err = pcall(function() Config:SetToggleKey(input.KeyCode) end)
			if not ok then info.Text = "Erro ao definir tecla: " .. tostring(err); stopBinding(); return end
			lblKey.Text = "Tecla para abrir/fechar: " .. Config.ToggleKeyName
			info.Text = "Tecla alterada para: " .. Config.ToggleKeyName
			stopBinding()
		end
	end)
	internal.bindingConn = bindingConn
end

local function selectTab(activeBtn)
	for _,b in pairs(tabButtons) do b.BackgroundColor3 = Color3.fromRGB(34,34,36) end
	activeBtn.BackgroundColor3 = Config.Colors.Background:Lerp(Config.Colors.Accent, 0.06)
end

-- AUTO behavior
local autoState = { hitRunning=false, serveRunning=false, serveRotate=0, servePower=100 }
internal.autoState = autoState

local function startAutoHit()
	if autoState.hitRunning then return end
	autoState.hitRunning = true
	task.spawn(function()
		while autoState.hitRunning and screenGui.Parent do
			if not game:IsLoaded() then game.Loaded:Wait() end
			local args = {{ CamPos = Vector3.new(0,0,0), HitPos = Vector3.new(0,0,0), HitBallType = 0, ClientTick = 0, CamDir = Vector3.new(0,0,0), AttackMoveSpeed = Vector3.new(0,0,0)}}
			pcall(function()
				local remotes = ReplicatedStorage:FindFirstChild("Remotes")
				if remotes then
					local hitRf = remotes:FindFirstChild("HitBallRF")
					if hitRf and hitRf.InvokeServer then hitRf:InvokeServer(unpack(args)) end
				end
			end)
			task.wait()
		end
	end)
end
local function stopAutoHit() autoState.hitRunning = false end

local function startAutoServe()
	if autoState.serveRunning then return end
	autoState.serveRunning = true
	task.spawn(function()
		while autoState.serveRunning and screenGui.Parent do
			if not game:IsLoaded() then game.Loaded:Wait() end
			local args = {{ RotateType = autoState.serveRotate, Power = autoState.servePower }}
			pcall(function()
				local remotes = ReplicatedStorage:FindFirstChild("Remotes")
				if remotes then
					local serveRf = remotes:FindFirstChild("ServeRF")
					if serveRf and serveRf.InvokeServer then serveRf:InvokeServer(unpack(args)) end
				end
			end)
			task.wait()
		end
	end)
end
local function stopAutoServe() autoState.serveRunning = false end

-- UI builders
local function showAuto()
	selectTab(autoBtn)
	clearContent()
	-- Title
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Parent = content
	titleLbl.Size = UDim2.new(1,-20,0,30)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = Enum.Font.Bangers
	titleLbl.TextSize = 20
	titleLbl.TextColor3 = Config.Colors.Text
	titleLbl.Text = "AUTO"
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.LayoutOrder = 1

	-- Auto Hit row
	local hitRow = Instance.new("Frame", content)
	hitRow.Size = UDim2.new(1,-20,0,64); hitRow.BackgroundTransparency = 1; hitRow.LayoutOrder = 2
	local hitLbl = Instance.new("TextLabel", hitRow)
	hitLbl.Size = UDim2.new(0.6,0,1,0); hitLbl.BackgroundTransparency = 1; hitLbl.Font = Enum.Font.Gotham; hitLbl.TextSize = 14
	hitLbl.TextColor3 = Config.Colors.Text; hitLbl.Text = "Auto Hit (usa script fornecido)"; hitLbl.TextXAlignment = Enum.TextXAlignment.Left
	local hitToggle = Instance.new("TextButton", hitRow)
	hitToggle.Size = UDim2.new(0,140,0,36); hitToggle.Position = UDim2.new(0.65,0,0.5,-18)
	hitToggle.BackgroundColor3 = Color3.fromRGB(40,40,44); hitToggle.Font = Enum.Font.GothamBold; hitToggle.TextSize = 14
	hitToggle.TextColor3 = Config.Colors.Text; hitToggle.Text = "LIGAR"; hitToggle.AutoButtonColor = false
	local hitCorner = Instance.new("UICorner", hitToggle); hitCorner.CornerRadius = UDim.new(0,6)
	hitToggle.MouseButton1Click:Connect(function()
		if not autoState.hitRunning then startAutoHit(); hitToggle.Text = "DESLIGAR"; hitToggle.BackgroundColor3 = Config.Colors.Accent
		else stopAutoHit(); hitToggle.Text = "LIGAR"; hitToggle.BackgroundColor3 = Color3.fromRGB(40,40,44) end
	end)

	-- Auto Serve row
	local serveRow = Instance.new("Frame", content)
	serveRow.Size = UDim2.new(1,-20,0,120); serveRow.BackgroundTransparency = 1; serveRow.LayoutOrder = 3
	local serveLbl = Instance.new("TextLabel", serveRow)
	serveLbl.Size = UDim2.new(0.6,0,0,24); serveLbl.BackgroundTransparency = 1; serveLbl.Font = Enum.Font.Gotham; serveLbl.TextSize = 14
	serveLbl.TextColor3 = Config.Colors.Text; serveLbl.Text = "Auto Serve (ajustável)"; serveLbl.TextXAlignment = Enum.TextXAlignment.Left

	local rotateLbl = Instance.new("TextLabel", serveRow)
	rotateLbl.Size = UDim2.new(0,120,0,20); rotateLbl.Position = UDim2.new(0,0,0,34); rotateLbl.BackgroundTransparency = 1
	rotateLbl.Font = Enum.Font.Gotham; rotateLbl.TextSize = 12; rotateLbl.TextColor3 = Config.Colors.Text
	rotateLbl.Text = "RotateType: "..tostring(autoState.serveRotate)

	local rotateBtn = Instance.new("TextButton", serveRow)
	rotateBtn.Size = UDim2.new(0,84,0,28); rotateBtn.Position = UDim2.new(0,130,0,32)
	rotateBtn.BackgroundColor3 = Color3.fromRGB(40,40,44); rotateBtn.Text = "Trocar"; rotateBtn.Font = Enum.Font.Gotham; rotateBtn.TextSize = 12
	rotateBtn.TextColor3 = Config.Colors.Text; local rCorner = Instance.new("UICorner", rotateBtn); rCorner.CornerRadius = UDim.new(0,6)
	rotateBtn.MouseButton1Click:Connect(function() autoState.serveRotate = (autoState.serveRotate + 1) % 4; rotateLbl.Text = "RotateType: "..tostring(autoState.serveRotate) end)

	local powerLbl = Instance.new("TextLabel", serveRow)
	powerLbl.Size = UDim2.new(0,120,0,20); powerLbl.Position = UDim2.new(0,0,0,68); powerLbl.BackgroundTransparency = 1
	powerLbl.Font = Enum.Font.Gotham; powerLbl.TextSize = 12; powerLbl.TextColor3 = Config.Colors.Text
	powerLbl.Text = "Power: "..tostring(autoState.servePower)

	local powerMinus = Instance.new("TextButton", serveRow)
	powerMinus.Size = UDim2.new(0,36,0,28); powerMinus.Position = UDim2.new(0,130,0,64); powerMinus.BackgroundColor3 = Color3.fromRGB(40,40,44)
	powerMinus.Font = Enum.Font.GothamBold; powerMinus.Text = "-"; powerMinus.TextSize = 16; powerMinus.TextColor3 = Config.Colors.Text
	local pmc = Instance.new("UICorner", powerMinus); pmc.CornerRadius = UDim.new(0,6)
	local powerPlus = Instance.new("TextButton", serveRow)
	powerPlus.Size = UDim2.new(0,36,0,28); powerPlus.Position = UDim2.new(0,176,0,64); powerPlus.BackgroundColor3 = Color3.fromRGB(40,40,44)
	powerPlus.Font = Enum.Font.GothamBold; powerPlus.Text = "+"; powerPlus.TextSize = 16; powerPlus.TextColor3 = Config.Colors.Text
	local ppc = Instance.new("UICorner", powerPlus); ppc.CornerRadius = UDim.new(0,6)
	powerMinus.MouseButton1Click:Connect(function() autoState.servePower = math.clamp(autoState.servePower - 5, 0, 100); powerLbl.Text = "Power: "..tostring(autoState.servePower) end)
	powerPlus.MouseButton1Click:Connect(function() autoState.servePower = math.clamp(autoState.servePower + 5, 0, 100); powerLbl.Text = "Power: "..tostring(autoState.servePower) end)

	local serveToggle = Instance.new("TextButton", serveRow)
	serveToggle.Size = UDim2.new(0,140,0,36); serveToggle.Position = UDim2.new(0.65,0,0.5,-18)
	serveToggle.BackgroundColor3 = Color3.fromRGB(40,40,44); serveToggle.Font = Enum.Font.GothamBold; serveToggle.TextSize = 14
	serveToggle.TextColor3 = Config.Colors.Text; serveToggle.Text = "LIGAR"; serveToggle.AutoButtonColor = false
	local serveCorner = Instance.new("UICorner", serveToggle); serveCorner.CornerRadius = UDim.new(0,6)
	serveToggle.MouseButton1Click:Connect(function()
		if not autoState.serveRunning then startAutoServe(); serveToggle.Text = "DESLIGAR"; serveToggle.BackgroundColor3 = Config.Colors.Accent
		else stopAutoServe(); serveToggle.Text = "LIGAR"; serveToggle.BackgroundColor3 = Color3.fromRGB(40,40,44) end
	end)
end

-- SETTINGS UI builder (Discord at top)
local function showSettings()
	selectTab(settingsBtn)
	clearContent()

	local titleLbl = Instance.new("TextLabel", content)
	titleLbl.Size = UDim2.new(1,-20,0,30); titleLbl.BackgroundTransparency = 1; titleLbl.Font = Enum.Font.Bangers
	titleLbl.TextSize = 20; titleLbl.TextColor3 = Config.Colors.Text; titleLbl.Text = "SETTINGS"; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.LayoutOrder = 1

	-- Discord frame
	local discordFrame = Instance.new("Frame", content)
	discordFrame.Size = UDim2.new(1,-20,0,100); discordFrame.BackgroundTransparency = 1; discordFrame.LayoutOrder = 2
	local dTitle = Instance.new("TextLabel", discordFrame)
	dTitle.Size = UDim2.new(1,0,0,20); dTitle.BackgroundTransparency = 1; dTitle.Font = Enum.Font.GothamBold; dTitle.TextSize = 14
	dTitle.TextColor3 = Config.Colors.Text; dTitle.Text = "DISCORD"; dTitle.TextXAlignment = Enum.TextXAlignment.Left

	local invite = "https://discord.gg/x77community"
	local helpMessage = "Caso venha ter bugs no script basta apertar na função ABRIR DISCORD X77 COMMUNITY"

	local openDiscordBtn = Instance.new("TextButton", discordFrame)
	openDiscordBtn.Size = UDim2.new(0,340,0,34); openDiscordBtn.Position = UDim2.new(0,0,0,28)
	openDiscordBtn.BackgroundColor3 = Config.Colors.Accent; openDiscordBtn.Font = Enum.Font.GothamBold; openDiscordBtn.TextSize = 14
	openDiscordBtn.TextColor3 = Color3.fromRGB(255,255,255); openDiscordBtn.Text = "ABRIR DISCORD X77 COMMUNITY"
	local oc = Instance.new("UICorner", openDiscordBtn); oc.CornerRadius = UDim.new(0,6)
	openDiscordBtn.MouseButton1Click:Connect(function()
		local ok = pcall(function() GuiService:OpenBrowserWindow(invite) end)
		if not ok then
			local ok2 = false
			pcall(function() setclipboard(invite); ok2 = true end)
			if ok2 then
				local msg = Instance.new("TextLabel", discordFrame); msg.Size = UDim2.new(1,0,0,18); msg.Position = UDim2.new(0,0,0,66)
				msg.BackgroundTransparency = 1; msg.Font = Enum.Font.Gotham; msg.TextSize = 12; msg.TextColor3 = Color3.fromRGB(200,200,200)
				msg.Text = "Invite copiado para a área de transferência. Cole no navegador."
				game.Debris:AddItem(msg, 4)
			else
				local msg = Instance.new("TextLabel", discordFrame); msg.Size = UDim2.new(1,0,0,18); msg.Position = UDim2.new(0,0,0,66)
				msg.BackgroundTransparency = 1; msg.Font = Enum.Font.Gotham; msg.TextSize = 12; msg.TextColor3 = Color3.fromRGB(200,200,200)
				msg.Text = "Não foi possível abrir navegador nem copiar. Link: "..invite
				game.Debris:AddItem(msg, 6)
			end
		end
	end)

	local copyInviteBtn = Instance.new("TextButton", discordFrame)
	copyInviteBtn.Size = UDim2.new(0,140,0,28); copyInviteBtn.Position = UDim2.new(0,350,0,28)
	copyInviteBtn.BackgroundColor3 = Color3.fromRGB(40,40,44); copyInviteBtn.Font = Enum.Font.Gotham; copyInviteBtn.TextSize = 12
	copyInviteBtn.TextColor3 = Config.Colors.Text; copyInviteBtn.Text = "Copiar invite"
	local cic = Instance.new("UICorner", copyInviteBtn); cic.CornerRadius = UDim.new(0,6)
	copyInviteBtn.MouseButton1Click:Connect(function()
		local ok = false
		pcall(function() setclipboard(invite); ok = true end)
		if ok then
			local msg = Instance.new("TextLabel", discordFrame); msg.Size = UDim2.new(1,0,0,18); msg.Position = UDim2.new(0,0,0,66)
			msg.BackgroundTransparency = 1; msg.Font = Enum.Font.Gotham; msg.TextSize = 12; msg.TextColor3 = Color3.fromRGB(200,200,200)
			msg.Text = "Invite copiado para a área de transferência."
			game.Debris:AddItem(msg, 3)
		else
			local msg = Instance.new("TextLabel", discordFrame); msg.Size = UDim2.new(1,0,0,18); msg.Position = UDim2.new(0,0,0,66)
			msg.BackgroundTransparency = 1; msg.Font = Enum.Font.Gotham; msg.TextSize = 12; msg.TextColor3 = Color3.fromRGB(200,200,200)
			msg.Text = "Não foi possível copiar. Link: "..invite
			game.Debris:AddItem(msg, 4)
		end
	end)

	local copyMsgBtn = Instance.new("TextButton", discordFrame)
	copyMsgBtn.Size = UDim2.new(0,200,0,28); copyMsgBtn.Position = UDim2.new(0,500,0,28)
	copyMsgBtn.BackgroundColor3 = Color3.fromRGB(40,40,44); copyMsgBtn.Font = Enum.Font.Gotham; copyMsgBtn.TextSize = 12
	copyMsgBtn.TextColor3 = Config.Colors.Text; copyMsgBtn.Text = "Copiar mensagem de ajuda"
	local cmc = Instance.new("UICorner", copyMsgBtn); cmc.CornerRadius = UDim.new(0,6)
	copyMsgBtn.MouseButton1Click:Connect(function()
		local ok = false
		pcall(function() setclipboard(helpMessage); ok = true end)
		if ok then
			local msg = Instance.new("TextLabel", discordFrame); msg.Size = UDim2.new(1,0,0,18); msg.Position = UDim2.new(0,0,0,66)
			msg.BackgroundTransparency = 1; msg.Font = Enum.Font.Gotham; msg.TextSize = 12; msg.TextColor3 = Color3.fromRGB(200,200,200)
			msg.Text = "Mensagem copiada para área de transferência."
			game.Debris:AddItem(msg, 3)
		else
			local msg = Instance.new("TextLabel", discordFrame); msg.Size = UDim2.new(1,0,0,18); msg.Position = UDim2.new(0,0,0,66)
			msg.BackgroundTransparency = 1; msg.Font = Enum.Font.Gotham; msg.TextSize = 12; msg.TextColor3 = Color3.fromRGB(200,200,200)
			msg.Text = "Não foi possível copiar automaticamente. Texto: "..helpMessage
			game.Debris:AddItem(msg, 5)
		end
	end)

	-- Key info
	local lblKey = Instance.new("TextLabel", content)
	lblKey.Size = UDim2.new(1,-20,0,22); lblKey.BackgroundTransparency = 1; lblKey.Font = Enum.Font.Gotham
	lblKey.TextSize = 14; lblKey.TextColor3 = Config.Colors.Text; lblKey.Text = "Tecla para abrir/fechar: "..Config.ToggleKeyName
	lblKey.LayoutOrder = 3; lblKey.TextXAlignment = Enum.TextXAlignment.Left

	local changeKeyBtn = Instance.new("TextButton", content)
	changeKeyBtn.Size = UDim2.new(0,140,0,34); changeKeyBtn.BackgroundColor3 = Color3.fromRGB(40,40,44)
	changeKeyBtn.Font = Enum.Font.GothamBold; changeKeyBtn.TextSize = 14; changeKeyBtn.TextColor3 = Config.Colors.Text
	changeKeyBtn.Text = "Mudar tecla"; changeKeyBtn.LayoutOrder = 4
	local ck = Instance.new("UICorner", changeKeyBtn); ck.CornerRadius = UDim.new(0,6)

	local info = Instance.new("TextLabel", content)
	info.Size = UDim2.new(1,-20,0,46); info.BackgroundTransparency = 1; info.Font = Enum.Font.Gotham
	info.TextSize = 12; info.TextColor3 = Color3.fromRGB(180,180,180); info.TextWrapped = true
	info.Text = "Clique em 'Mudar tecla' e pressione a nova tecla desejada. Esc cancela."; info.LayoutOrder = 5

	-- Color swatches omitted here for brevity (kept same logic as earlier scripts)
	-- Buttons row: disable & destroy
	local btnRow = Instance.new("Frame", content); btnRow.Size = UDim2.new(1,-20,0,44); btnRow.BackgroundTransparency = 1; btnRow.LayoutOrder = 9
	local disableBtn = Instance.new("TextButton", btnRow); disableBtn.Size = UDim2.new(0,220,1,0); disableBtn.BackgroundColor3 = Color3.fromRGB(70,18,18)
	disableBtn.Font = Enum.Font.GothamBold; disableBtn.Text = "Desativar menu"; local dcorner = Instance.new("UICorner", disableBtn); dcorner.CornerRadius = UDim.new(0,6)
	disableBtn.MouseButton1Click:Connect(function() Config:DisableMenu() end)
	local destroyBtn = Instance.new("TextButton", btnRow); destroyBtn.Size = UDim2.new(0,260,1,0); destroyBtn.Position = UDim2.new(0,230,0,0)
	destroyBtn.BackgroundColor3 = Color3.fromRGB(40,40,44); destroyBtn.Font = Enum.Font.GothamBold; destroyBtn.Text = "Destruir menu (desejetar)"
	local dc = Instance.new("UICorner", destroyBtn); dc.CornerRadius = UDim.new(0,6)
	destroyBtn.MouseButton1Click:Connect(function()
		-- stop all
		pcall(function() autoState.hitRunning = false; autoState.serveRunning = false end)
		-- stop bindings
		stopBinding()
		-- disconnect toggle
		pcall(function() if internal.toggleConn then internal.toggleConn:Disconnect(); internal.toggleConn = nil end end)
		_G.TenisNeoConfig = nil
		safeDestroy(screenGui)
		_G._TenisNeoInternal = nil
	end)

	UIRefs.lblKey = lblKey
	UIRefs.changeKeyBtn = changeKeyBtn
	changeKeyBtn.MouseButton1Click:Connect(function()
		if UIRefs.bindingActive then return end
		startBinding(lblKey, changeKeyBtn, info)
	end)
end

-- Connect tabs
autoBtn.MouseButton1Click:Connect(function() pcall(showAuto) end)
settingsBtn.MouseButton1Click:Connect(function() pcall(showSettings) end)
pcall(showAuto)

-- Toggle key binding
local toggleConn = nil
local function bindToggleKey(key)
	if toggleConn then safeDisconnect(toggleConn) end
	toggleConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key then
			Config:ToggleEnabled()
		end
	end)
	internal.toggleConn = toggleConn
end
bindToggleKey(Config.ToggleKey)
Config:OnToggleKeyChanged(function(k) bindToggleKey(k); if UIRefs.lblKey and UIRefs.lblKey.Parent then UIRefs.lblKey.Text = "Tecla para abrir/fechar: "..Config.ToggleKeyName end end)

-- Apply colors helper
local function applyColors(colors)
	frame.BackgroundColor3 = colors.Background
	topBar.BackgroundColor3 = colors.Background
	topAccent.BackgroundColor3 = colors.Accent
	title.TextColor3 = colors.Text
	closeBtn.TextColor3 = colors.Text
	for _,b in ipairs(tabButtons) do b.TextColor3 = colors.Text end
	for _,v in ipairs(content:GetChildren()) do
		if v:IsA("TextLabel") then v.TextColor3 = colors.Text
		elseif v:IsA("TextButton") and v.Text ~= "" then v.TextColor3 = colors.Text end
	end
end
Config:OnColorsChanged(function(c) applyColors(c) end)
applyColors(Config.Colors)

-- visibility
Config:OnEnabledChanged(function(v) frame.Visible = v end)
frame.Visible = Config.Enabled

-- Draggable logic (store conn)
local dragging = false
local dragOffset = Vector2.new(0,0)
local dragConn = RunService.RenderStepped:Connect(function()
	if not dragging then return end
	local mouse = UserInputService:GetMouseLocation()
	local newX = mouse.X - dragOffset.X
	local newY = mouse.Y - dragOffset.Y
	local width = frame.AbsoluteSize.X; local height = frame.AbsoluteSize.Y
	local screenW = workspace.CurrentCamera.ViewportSize.X; local screenH = workspace.CurrentCamera.ViewportSize.Y
	if newX < 0 then newX = 0 end
	if newY < 0 then newY = 0 end
	if newX + width > screenW then newX = screenW - width end
	if newY + height > screenH then newY = screenH - height end
	frame.Position = UDim2.new(0, newX, 0, newY)
end)
internal.dragConn = dragConn

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		local mouse = UserInputService:GetMouseLocation()
		local absPos = frame.AbsolutePosition
		dragOffset = mouse - absPos
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)
topBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Save refs for future cleanup
internal.bindingConn = bindingConn
internal.toggleConn = toggleConn
internal.dragConn = dragConn
internal.screenGui = screenGui

-- Cleanup handler when GUI destroyed
screenGui.Destroying:Connect(function()
	stopBinding()
	pcall(function() if internal.toggleConn then internal.toggleConn:Disconnect() end end)
	pcall(function() if internal.dragConn then internal.dragConn:Disconnect() end end)
	_G.TenisNeoConfig = nil
	_G._TenisNeoInternal = nil
end)

print("[TenisNeo] UI carregada. ToggleKey:", Config.ToggleKeyName)
