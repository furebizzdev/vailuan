local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Criação do ScreenGui principal
local HubGui = Instance.new("ScreenGui")
HubGui.Name = "UIExploitBase"
HubGui.ResetOnSpawn = false
HubGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Tenta colocar no CoreGui (Synapse, Krnl etc usam gethui ou CoreGui), sênão coloca no PlayerGui
local hookGui = (gethui and gethui()) or game:GetService("CoreGui")
local success = pcall(function() HubGui.Parent = hookGui end)
if not success then HubGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Estados Compartilhados & Lista de Eventos (Connections) para limpar depois
local connections = {}
local speedValue = 16
local speedBoostActive = false
local antiRagdollActive = false

---------------------------------------------------------------------
-- BOTÃO FLUTUANTE (Para abrir/fechar o Menu)
---------------------------------------------------------------------
local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Parent = HubGui
OpenButton.Position = UDim2.new(0, 20, 0.5, -25)
OpenButton.Size = UDim2.new(0, 50, 0, 50)
OpenButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.Text = "Menu"
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 14
local OpenCorner = Instance.new("UICorner", OpenButton)
OpenCorner.CornerRadius = UDim.new(1, 0) -- Transforma num círculo

---------------------------------------------------------------------
-- JANELA PRINCIPAL
---------------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = HubGui
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Visible = false
local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 8)

local DropShadow = Instance.new("UIStroke", MainFrame)
DropShadow.Color = Color3.fromRGB(50, 50, 50)
DropShadow.Thickness = 1

-- Tornar a janela "arrastável"
local dragging, dragInput, dragStart, startPos
local function update(input)
	local delta = input.Position - dragStart
	MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
table.insert(connections, MainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end))
table.insert(connections, MainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end))
table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then update(input) end
end))

---------------------------------------------------------------------
-- BARRA SUPERIOR E BOTÃO DE FECHAR (X)
---------------------------------------------------------------------
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
local TopCorner = Instance.new("UICorner", TopBar)
TopCorner.CornerRadius = UDim.new(0, 8)

-- Esconder partes redondas debaixo da TopBar para ficar reta
local TopBarHider = Instance.new("Frame", TopBar)
TopBarHider.Size = UDim2.new(1, 0, 0, 8)
TopBarHider.Position = UDim2.new(0, 0, 1, -8)
TopBarHider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TopBarHider.BorderSizePixel = 0

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Sync Hub [v4]"
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

-- BOTÃO (X)
local CloseButton = Instance.new("TextButton")
CloseButton.Parent = TopBar
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16

---------------------------------------------------------------------
-- SISTEMA DE CATEGORIAS (SIDEBAR E CONTENT AREA)
---------------------------------------------------------------------
local Sidebar = Instance.new("Frame")
Sidebar.Parent = MainFrame
Sidebar.Size = UDim2.new(0, 100, 1, -30) -- Ocupa altura inteira menos os 30 da TopBar
Sidebar.Position = UDim2.new(0, 0, 0, 30)
Sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Sidebar.BorderSizePixel = 0
Sidebar.ClipsDescendants = true -- Impede que as abas "vasem" pra fora da Sidebar

local SidebarCorner = Instance.new("UICorner", Sidebar)
SidebarCorner.CornerRadius = UDim.new(0, 8)

-- Hiders pra manter o canto inferior esquerdo redondo, mas esconder o redondo de cima pra encostar na TopBar
local SidebarHiderTop = Instance.new("Frame", Sidebar)
SidebarHiderTop.Size = UDim2.new(1, 0, 0, 8)
SidebarHiderTop.Position = UDim2.new(0, 0, 0, 0)
SidebarHiderTop.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SidebarHiderTop.BorderSizePixel = 0

local SidebarHiderRight = Instance.new("Frame", Sidebar)
SidebarHiderRight.Size = UDim2.new(0, 8, 1, 0)
SidebarHiderRight.Position = UDim2.new(1, -8, 0, 0)
SidebarHiderRight.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SidebarHiderRight.BorderSizePixel = 0

local ContentArea = Instance.new("Frame")
ContentArea.Parent = MainFrame
ContentArea.Size = UDim2.new(1, -100, 1, -30)
ContentArea.Position = UDim2.new(0, 100, 0, 30)
ContentArea.BackgroundTransparency = 1

-- Container exclusivo pras abas (Para a ListLayout não bugar com os hiders decorativos)
local TabContainer = Instance.new("Frame", Sidebar)
TabContainer.Size = UDim2.new(1, 0, 1, 0)
TabContainer.BackgroundTransparency = 1

local SidebarList = Instance.new("UIListLayout", TabContainer)
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 5)
local SidebarPadding = Instance.new("UIPadding", TabContainer)
SidebarPadding.PaddingTop = UDim.new(0, 5)

-- Gerenciador de Categorias
local Tabs = {}
local function CreateTab(name)
	local TabButton = Instance.new("TextButton")
	TabButton.Parent = TabContainer
	TabButton.Size = UDim2.new(1, 0, 0, 30)
	TabButton.BackgroundTransparency = 1
	TabButton.Text = name
	TabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	TabButton.Font = Enum.Font.GothamSemibold
	TabButton.TextSize = 14
	
	local TabContent = Instance.new("ScrollingFrame")
	TabContent.Parent = ContentArea
	TabContent.Size = UDim2.new(1, 0, 1, 0)
	TabContent.BackgroundTransparency = 1
	TabContent.Visible = false
	TabContent.ScrollBarThickness = 4
	TabContent.BorderSizePixel = 0
	
	local ContentList = Instance.new("UIListLayout", TabContent)
	ContentList.SortOrder = Enum.SortOrder.LayoutOrder
	ContentList.Padding = UDim.new(0, 10)
	local Padding = Instance.new("UIPadding", TabContent)
	Padding.PaddingTop = UDim.new(0, 10)
	Padding.PaddingLeft = UDim.new(0, 10)
	Padding.PaddingRight = UDim.new(0, 10)
	Padding.PaddingBottom = UDim.new(0, 10)
	
	Tabs[name] = {Button = TabButton, Content = TabContent}
	
	table.insert(connections, TabButton.MouseButton1Click:Connect(function()
		for tName, tab in pairs(Tabs) do
			if tName == name then
				tab.Content.Visible = true
				tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				tab.Content.Visible = false
				tab.Button.TextColor3 = Color3.fromRGB(150, 150, 150)
			end
		end
	end))
	
	return TabContent
end

local PlayerTab = CreateTab("Jogador")
local FarmTab = CreateTab("Farm/Loja")
local MiscTab = CreateTab("Outros")

-- Deixar a primeira aba ativa
Tabs["Jogador"].Content.Visible = true
Tabs["Jogador"].Button.TextColor3 = Color3.fromRGB(255, 255, 255)

---------------------------------------------------------------------
-- CONTEÚDO PLACEHOLDER ABA "OUTROS"
---------------------------------------------------------------------
local MiscLabel = Instance.new("TextLabel", MiscTab)
MiscLabel.Size = UDim2.new(1, 0, 0, 30)
MiscLabel.BackgroundTransparency = 1
MiscLabel.Text = "Mais extras serão adicionados aqui..."
MiscLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
MiscLabel.Font = Enum.Font.Gotham
MiscLabel.TextSize = 14
MiscLabel.TextXAlignment = Enum.TextXAlignment.Center

---------------------------------------------------------------------
-- FUNÇÕES: BARRA DE VELOCIDADE (SLIDER) E TOGGLE
---------------------------------------------------------------------

-- Função para Criar Toggle UI
local function CreateToggle(parent, title, callback)
	local Frame = Instance.new("Frame", parent)
	Frame.Size = UDim2.new(1, 0, 0, 35)
	Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	local Corner = Instance.new("UICorner", Frame)
	Corner.CornerRadius = UDim.new(0, 6)

	local Label = Instance.new("TextLabel", Frame)
	Label.Size = UDim2.new(1, -60, 1, 0)
	Label.Position = UDim2.new(0, 10, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = title
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Font = Enum.Font.GothamSemibold
	Label.TextSize = 14

	local Btn = Instance.new("TextButton", Frame)
	Btn.Size = UDim2.new(0, 40, 0, 20)
	Btn.Position = UDim2.new(1, -50, 0.5, -10)
	Btn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
	Btn.Text = ""
	local BtnCorner = Instance.new("UICorner", Btn)
	BtnCorner.CornerRadius = UDim.new(1, 0)

	local Circle = Instance.new("Frame", Btn)
	Circle.Size = UDim2.new(0, 16, 0, 16)
	Circle.Position = UDim2.new(0, 2, 0.5, -8)
	Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	local CircleCorner = Instance.new("UICorner", Circle)
	CircleCorner.CornerRadius = UDim.new(1, 0)

	local toggled = false
	table.insert(connections, Btn.MouseButton1Click:Connect(function()
		toggled = not toggled
		if toggled then
			TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 150, 50)}):Play()
			TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
		else
			TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 50, 50)}):Play()
			TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
		end
		callback(toggled)
	end))
end

-- Função para Criar Slider UI
local function CreateSlider(parent, title, min, max, default, callback)
	local Frame = Instance.new("Frame", parent)
	Frame.Size = UDim2.new(1, 0, 0, 45)
	Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	local Corner = Instance.new("UICorner", Frame)
	Corner.CornerRadius = UDim.new(0, 6)

	local Label = Instance.new("TextLabel", Frame)
	Label.Size = UDim2.new(1, -20, 0, 20)
	Label.Position = UDim2.new(0, 10, 0, 5)
	Label.BackgroundTransparency = 1
	Label.Text = title .. ": " .. default
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Font = Enum.Font.GothamSemibold
	Label.TextSize = 13

	local Bg = Instance.new("Frame", Frame)
	Bg.Size = UDim2.new(1, -20, 0, 6)
	Bg.Position = UDim2.new(0, 10, 0, 30)
	Bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	local BgCorner = Instance.new("UICorner", Bg)
	BgCorner.CornerRadius = UDim.new(1, 0)

	local progressRatio = (default - min) / (max - min)
	local Progress = Instance.new("Frame", Bg)
	Progress.Size = UDim2.new(progressRatio, 0, 1, 0)
	Progress.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
	Progress.BorderSizePixel = 0
	local ProgCorner = Instance.new("UICorner", Progress)
	ProgCorner.CornerRadius = UDim.new(1, 0)

	local Btn = Instance.new("TextButton", Bg)
	Btn.Size = UDim2.new(1, 0, 1, 10)
	Btn.Position = UDim2.new(0, 0, 0, -5)
	Btn.BackgroundTransparency = 1
	Btn.Text = ""

	local draggingSlider = false
	table.insert(connections, Btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = true
		end
	end))
	table.insert(connections, Btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = false
		end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local mouseX = input.Position.X
			local sliderX = Bg.AbsolutePosition.X
			local sliderWidth = Bg.AbsoluteSize.X
			local percent = math.clamp((mouseX - sliderX) / sliderWidth, 0, 1)
			
			local val = math.floor(min + (percent * (max - min)))
			Progress.Size = UDim2.new(percent, 0, 1, 0)
			Label.Text = title .. ": " .. val
			callback(val)
		end
	end))
end

-- Adicionando Slider de Velocidade
CreateSlider(PlayerTab, "Velocidade de Caminhada (WalkSpeed)", 16, 250, 16, function(value)
	speedValue = value
	if speedBoostActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.WalkSpeed = speedValue
	end
end)

-- Adicionando Toggle de Velocidade
CreateToggle(PlayerTab, "Ativar Boost de Velocidade", function(state)
	speedBoostActive = state
	if speedBoostActive then
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.WalkSpeed = speedValue
		end
	else
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.WalkSpeed = 16 -- Volta ao normal
		end
	end
end)

-- Adicionando Toggle de Anti Ragdoll
CreateToggle(PlayerTab, "Anti Ragdoll", function(state)
	antiRagdollActive = state
	if not state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
	end
end)

-- Loop para forçar estados e atributos (Velocidade e Anti Ragdoll)
table.insert(connections, RunService.RenderStepped:Connect(function()
	if LocalPlayer.Character then
		local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
		
		if speedBoostActive and humanoid then
			humanoid.WalkSpeed = speedValue
		end

		if antiRagdollActive and humanoid then
			pcall(function()
				-- Bloqueia o Estado e força a levantar
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll or humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
				
				-- Combate o script ragdoll_controller bloqueando a desativação da Root do LowerTorso
				local lowerTorso = LocalPlayer.Character:FindFirstChild("LowerTorso")
				if lowerTorso then
					local root = lowerTorso:FindFirstChild("Root")
					if root and root.Enabled == false then
						root.Enabled = true
						workspace.CurrentCamera.CameraSubject = humanoid
					end
				end
			end)
		end
	end
end))

---------------------------------------------------------------------
-- FUNÇÕES: DROPDOWN
---------------------------------------------------------------------
local function CreateDropdown(parent, title, options, callback)
	local Frame = Instance.new("Frame", parent)
	Frame.Size = UDim2.new(1, 0, 0, 40) 
	Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	Frame.ZIndex = 1
	local Corner = Instance.new("UICorner", Frame)
	Corner.CornerRadius = UDim.new(0, 6)

	local Btn = Instance.new("TextButton", Frame)
	Btn.Size = UDim2.new(1, 0, 1, 0)
	Btn.BackgroundTransparency = 1
	Btn.Text = title .. " [Selecionar]"
	Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	Btn.Font = Enum.Font.GothamSemibold
	Btn.TextSize = 13
	Btn.TextXAlignment = Enum.TextXAlignment.Left
	Btn.ZIndex = 2
	
	local UIPad = Instance.new("UIPadding", Btn)
	UIPad.PaddingLeft = UDim.new(0, 10)

	local DropList = Instance.new("ScrollingFrame", parent) -- Colocado no parent pra sobrepor
	DropList.Size = UDim2.new(1, 0, 0, 120)
	DropList.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	DropList.ScrollBarThickness = 2
	DropList.Visible = false
	DropList.ZIndex = 5
	local DropCorner = Instance.new("UICorner", DropList)
	DropCorner.CornerRadius = UDim.new(0, 6)
	
	local ListLayout = Instance.new("UIListLayout", DropList)
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local isOpen = false
	table.insert(connections, Btn.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			-- Posiciona a droplist exatamente debaixo do botão
			DropList.Position = UDim2.new(
				Frame.Position.X.Scale, Frame.Position.X.Offset,
				Frame.Position.Y.Scale, Frame.Position.Y.Offset + 45
			)
			DropList.Visible = true
		else
			DropList.Visible = false
		end
	end))

	local function AddOption(optName)
		local OptBtn = Instance.new("TextButton", DropList)
		OptBtn.Size = UDim2.new(1, 0, 0, 25)
		OptBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		OptBtn.Text = optName
		OptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		OptBtn.Font = Enum.Font.Gotham
		OptBtn.TextSize = 12
		OptBtn.ZIndex = 6

		table.insert(connections, OptBtn.MouseButton1Click:Connect(function()
			Btn.Text = title .. " [" .. optName .. "]"
			isOpen = false
			DropList.Visible = false
			callback(optName)
		end))
	end

	for _, opt in ipairs(options) do AddOption(opt) end
end

---------------------------------------------------------------------
-- ABA FARM/LOJA (Auto Buy Brainrots)
---------------------------------------------------------------------

-- Para o Dropdown, nós varremos ReplicatedStorage e Workspace.
-- Se mostrar "Aguardando itens do Mapa", é porque eles não spawnam no "Workspace.Brainrots".
local brainrotList = {}
pcall(function()
	-- Tenta primeiro os Models que já estão soltos no mapa (Workspace)
	if workspace:FindFirstChild("Brainrots") then
		for _, item in ipairs(workspace.Brainrots:GetChildren()) do
			table.insert(brainrotList, item.Name)
		end
	end
	
	-- Se não achou na pasta "Brainrots" do Workspace, puxa a lista pelos arquivos originais na Replicated
	if #brainrotList == 0 then
		local repStore = game:GetService("ReplicatedStorage")
		if repStore:FindFirstChild("Brainrots") then
			for _, item in ipairs(repStore.Brainrots:GetChildren()) do
				table.insert(brainrotList, item.Name)
			end
		end
	end
end)
if #brainrotList == 0 then brainrotList = {"ItemNaoEncontrado"} end -- Fallback

local selectedItemToBuy = nil
CreateDropdown(FarmTab, "Item (Brainrot)", brainrotList, function(selected)
    selectedItemToBuy = selected
end)

local autoBuyActive = false
CreateToggle(FarmTab, "Auto Comprar Brainrot", function(state)
	autoBuyActive = state
end)

-- Função auxiliar para notificar na tela do Roblox
local function Notify(title, text)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 3
		})
	end)
end

-- Função auxiliar para notificar na tela do Roblox
local function Notify(title, text)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 3
		})
	end)
end

-- Loop de Auto Farm (Via Remote "Bridge")
-- Como "Item não encontrado no Mapa" provou que o item NÃO É um objeto físico no chão, vamos voltar a bombardear o Remote!
local purchaseDelay = 0.5 -- Tempo entre cada tentativa de compra (para não tomar kick de spam)
task.spawn(function()
	while task.wait(purchaseDelay) do
		if autoBuyActive and selectedItemToBuy then
			pcall(function()
				local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
				
				if remotes then
					local bridge = remotes:FindFirstChild("Bridge")
					if bridge and bridge:IsA("RemoteEvent") then
						-- Usando a estrutura de argumentos que o Spy pegou
						-- [1] = "Path", [2] = "Brainrots", [3] = "Purchase", [4] = NOME DO ITEM (que pegamos do ReplicatedStorage)
						local args = {
							[1] = "Path",
							[2] = "Brainrots",
							[3] = "Purchase",
							[4] = selectedItemToBuy 
						}
						
						-- Dispara a compra!
						bridge:FireServer(unpack(args))
					end
				end
			end)
		end
	end
end)

---------------------------------------------------------------------
-- BOTÕES DE CONTROLE GERAIS
---------------------------------------------------------------------

-- Botão Flutuante Mostrar/Ocultar
table.insert(connections, OpenButton.MouseButton1Click:Connect(function()
	MainFrame.Visible = not MainFrame.Visible
end))

-- Botão X de Fechamento (Encerramento do Script)
table.insert(connections, CloseButton.MouseButton1Click:Connect(function()
	-- Desativa a velocidade e restaura a física do ragdoll primeiro
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.WalkSpeed = 16
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
	end
	
	-- Desconecta todos os loops e eventos para não sobrar rastros (memory leak)
	for _, conn in ipairs(connections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	
	-- Deleta a interface visual
	HubGui:Destroy()
end))
