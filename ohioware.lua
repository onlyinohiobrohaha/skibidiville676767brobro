local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local lplr = Players.LocalPlayer
local mouse = lplr:GetMouse()

-- Configuration State
local Config = {
    AntiLagEnabled = false,
    MaxLatency = 200,
    MaxCompensation = 23,
    
    AntiVoidEnabled = false,
    AntiVoidMode = "Normal",
    AntiVoidY = 0,
    
    HudEnabled = false,
    Visible = true,
    TargetHudEnabled = false,

    DamageAffectsEnabled = false,
    DamageCustomMessages = true,
    DamageCustomColors = true,
    DamageFont = Font.fromName("Arial"),

    InfiniteJumpEnabled = false,
    InfiniteJumpHold = false,
    DisablerEnabled = false,

    VelocityPlusEnabled = false,
    VelocityPlusDirection = "Random",
    VelocityPlusChance = 100,
    VelocityPlusTargetOnly = false,
    KillAuraEnabled = false,
    KillAuraRange = 18,
    KillAuraAngle = 180,

    ViewmodelEnabled = false,
    ViewmodelNoBob = true,
    ViewmodelDepth = 0.8,
    ViewmodelHorizontal = 0.8,
    ViewmodelVertical = -0.2,
    ViewmodelScale = 1.0,
    ViewmodelMaterial = "Neon",
    ViewmodelColorMode = "Normal",
    ViewmodelColorHSV = {Hue = 0, Sat = 0, Val = 0},
    ViewmodelOutlineHSV = {Hue = 0, Sat = 0, Val = 0},
    ViewmodelOutlineTrans = 0.5,
    ViewmodelRotX = 0,
    ViewmodelRotY = 0,
    ViewmodelRotZ = 0
}

local Colors = {
    WindowBg = Color3.fromRGB(20, 20, 26),
    Accent = Color3.fromRGB(90, 110, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(160, 160, 170),
    SettingsBg = Color3.fromRGB(15, 15, 20),
    SliderTrack = Color3.fromRGB(40, 40, 45),
    HudText = Color3.fromRGB(255, 60, 60)
}

local Windows = {}
local AntiVoidPart = nil

-- ui shit
local UIControls = {}

-- ui framework
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PistonwareGUI"
ScreenGui.Parent = (pcall(function() return CoreGui end) and CoreGui or lplr:WaitForChild("PlayerGui"))

local function MakeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = obj.Position
        end
    end)
    obj.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

local function CreateWindow(name, posX)
    local window = Instance.new("Frame")
    window.Size = UDim2.new(0, 200, 0, 35)
    window.Position = UDim2.new(0, posX, 0, 100)
    window.BackgroundColor3 = Colors.WindowBg
    window.BorderSizePixel = 0
    window.Parent = ScreenGui
    Instance.new("UICorner", window).CornerRadius = UDim.new(0, 6)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = Colors.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = window

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 0)
    container.Position = UDim2.new(0, 0, 0, 35)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = window
    Instance.new("UIListLayout", container).SortOrder = Enum.SortOrder.LayoutOrder

    MakeDraggable(window)
    table.insert(Windows, window)
    return container
end

local function CreateModule(name, parent, toggleCallback)
    local moduleFrame = Instance.new("Frame")
    moduleFrame.Size = UDim2.new(1, 0, 0, 35)
    moduleFrame.BackgroundColor3 = Colors.WindowBg
    moduleFrame.BorderSizePixel = 0
    moduleFrame.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextColor3 = Colors.TextDark
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = moduleFrame

    local settingsPanel = Instance.new("Frame")
    settingsPanel.Size = UDim2.new(1, 0, 0, 0)
    settingsPanel.Position = UDim2.new(0, 0, 0, 35)
    settingsPanel.BackgroundColor3 = Colors.SettingsBg
    settingsPanel.ClipsDescendants = true
    settingsPanel.BorderSizePixel = 0
    settingsPanel.Parent = moduleFrame
    
    local sLayout = Instance.new("UIListLayout", settingsPanel)

    local enabled = false
    
    local moduleKey = name .. "_Enabled"
    UIControls[moduleKey] = {
        type = "Module",
        btn = btn,
        toggleCallback = toggleCallback,
        enabled = false
    }
    
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        toggleCallback(enabled)
        btn.TextColor3 = enabled and Colors.Accent or Colors.TextDark
        if UIControls[moduleKey] then
            UIControls[moduleKey].enabled = enabled
        end
    end)
    
    btn.MouseButton2Click:Connect(function()
        local isExpanded = settingsPanel.Size.Y.Offset > 0
        local targetSize = isExpanded and 0 or (sLayout.AbsoluteContentSize.Y + 5)
        
        TweenService:Create(settingsPanel, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, targetSize)}):Play()
        TweenService:Create(moduleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, targetSize + 35)}):Play()
    end)

    return settingsPanel
end

local function CreateSlider(name, min, max, default, parent, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Colors.TextDark
    label.TextSize = 11
    label.Font = "Gotham"
    label.TextXAlignment = "Left"
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 4)
    bar.Position = UDim2.new(0, 10, 0, 28)
    bar.BackgroundColor3 = Colors.SliderTrack
    bar.BorderSizePixel = 0
    bar.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Colors.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local dragging = false
    local function move()
        local percent = math.clamp((mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * percent)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        label.Text = name .. ": " .. val
        callback(val)
    end

    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then move() end end)
    
    UIControls[name] = {
        type = "Slider",
        frame = frame,
        label = label,
        fill = fill,
        bar = bar,
        min = min,
        max = max,
        callback = callback,
        currentValue = default
    }
end

local function CreateToggleSetting(name, parent, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. name
    btn.Font = Enum.Font.Gotham
    btn.TextColor3 = Colors.TextDark
    btn.TextSize = 11
    btn.TextXAlignment = "Left"
    btn.Parent = parent

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        btn.TextColor3 = state and Colors.Accent or Colors.TextDark
    end)
    
    UIControls[name] = {
        type = "Toggle",
        btn = btn,
        callback = callback,
        state = false
    }
end

local function CreateDropdown(name, options, default, parent, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 55)
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = false
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Colors.TextDark
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local selected = default
    local open = false

    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(1, -20, 0, 24)
    btnFrame.Position = UDim2.new(0, 10, 0, 24)
    btnFrame.BackgroundColor3 = Colors.SliderTrack
    btnFrame.BorderSizePixel = 0
    btnFrame.Parent = frame
    Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 4)

    local selectedLabel = Instance.new("TextButton")
    selectedLabel.Size = UDim2.new(1, 0, 1, 0)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = "  " .. selected .. "  ▾"
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.TextColor3 = Colors.Text
    selectedLabel.TextSize = 11
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.Parent = btnFrame

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, -20, 0, #options * 24)
    listFrame.BackgroundColor3 = Colors.SettingsBg
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 10
    listFrame.Parent = frame
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 4)
    Instance.new("UIListLayout", listFrame).SortOrder = Enum.SortOrder.LayoutOrder

    local function positionList()
        listFrame.Position = UDim2.new(0, 10, 0, 52)
    end

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 24)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = "  " .. opt
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextColor3 = opt == selected and Colors.Accent or Colors.TextDark
        optBtn.TextSize = 11
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.ZIndex = 11
        optBtn.Parent = listFrame

        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            selectedLabel.Text = "  " .. selected .. "  ▾"
            open = false
            listFrame.Visible = false
            frame.Size = UDim2.new(1, 0, 0, 55)
            callback(selected)
            for _, child in listFrame:GetChildren() do
                if child:IsA("TextButton") then
                    child.TextColor3 = child.Text == ("  " .. selected) and Colors.Accent or Colors.TextDark
                end
            end
        end)
    end

    selectedLabel.MouseButton1Click:Connect(function()
        open = not open
        positionList()
        listFrame.Visible = open
        frame.Size = UDim2.new(1, 0, 0, open and 55 + #options * 24 or 55)
    end)

    UIControls[name] = {
        type = "Dropdown",
        selectedLabel = selectedLabel,
        options = options,
        callback = callback,
        current = default,
        listFrame = listFrame,
        parentFrame = frame
    }
end

-- useless config tab that doesnt work and that no one will use
local ConfigWindow = CreateWindow("Config", 890)

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1, -20, 0, 30)
saveBtn.Position = UDim2.new(0, 10, 0, 5)
saveBtn.BackgroundColor3 = Colors.Accent
saveBtn.Text = "Save Config"
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextColor3 = Colors.Text
saveBtn.TextSize = 13
saveBtn.Parent = ConfigWindow
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(1, -20, 0, 30)
loadBtn.Position = UDim2.new(0, 10, 0, 45)
loadBtn.BackgroundColor3 = Colors.SliderTrack
loadBtn.Text = "Load Config"
loadBtn.Font = Enum.Font.GothamBold
loadBtn.TextColor3 = Colors.Text
loadBtn.TextSize = 13
loadBtn.Parent = ConfigWindow
Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)

-- uhm some ui thing
local function UpdateUIFromConfig()
    for key, ctrl in pairs(UIControls) do
        if ctrl.type == "Module" then
            local enabledState = Config[key]
            if enabledState ~= nil then
                if ctrl.enabled ~= enabledState then
                    ctrl.toggleCallback(enabledState)
                    ctrl.btn.TextColor3 = enabledState and Colors.Accent or Colors.TextDark
                    ctrl.enabled = enabledState
                end
            end
        elseif ctrl.type == "Toggle" then
            local name = ctrl.btn.Text:gsub("  ", "")
            local state = Config[name]
            if state ~= nil then
                if ctrl.state ~= state then
                    ctrl.callback(state)
                    ctrl.btn.TextColor3 = state and Colors.Accent or Colors.TextDark
                    ctrl.state = state
                end
            end
        elseif ctrl.type == "Slider" then
            local name = ctrl.label.Text:match("(.+):")
            local val = Config[name]
            if val ~= nil then
                local percent = (val - ctrl.min) / (ctrl.max - ctrl.min)
                ctrl.fill.Size = UDim2.new(percent, 0, 1, 0)
                ctrl.label.Text = name .. ": " .. val
                ctrl.callback(val)
                ctrl.currentValue = val
            end
        elseif ctrl.type == "Dropdown" then
            local name = ctrl.parentFrame:FindFirstChildWhichIsA("TextLabel").Text
            local val = Config[name]
            if val and ctrl.current ~= val then
                ctrl.callback(val)
                ctrl.selectedLabel.Text = "  " .. val .. "  ▾"
                ctrl.current = val
                for _, child in ctrl.listFrame:GetChildren() do
                    if child:IsA("TextButton") then
                        child.TextColor3 = child.Text == ("  " .. val) and Colors.Accent or Colors.TextDark
                    end
                end
            end
        end
    end
end

-- broken save func (will be removed soon)
saveBtn.MouseButton1Click:Connect(function()
    local saveTable = {}
    for k, v in pairs(Config) do
        if type(v) ~= "function" and type(v) ~= "userdata" then
            saveTable[k] = v
        end
    end
    local json = HttpService:JSONEncode(saveTable)
    local success, err = pcall(function()
        writefile("PistonwareConfig.json", json)
    end)
    if success then
        print("Config saved successfully")
    else
        warn("Failed to save config: " .. tostring(err))
    end
end)

-- more useless broken config elements (will also be removed soon)
loadBtn.MouseButton1Click:Connect(function()
    local success, data = pcall(function()
        return readfile("PistonwareConfig.json")
    end)
    if success and data then
        local decoded = HttpService:JSONDecode(data)
        for k, v in pairs(decoded) do
            Config[k] = v
        end
        UpdateUIFromConfig()

        -- Safely update HUD visibility
        if HudFrame then
            HudFrame.Visible = Config.HudEnabled
        end
        if TargetHudFrame then
            TargetHudFrame.Visible = Config.TargetHudEnabled
        end

        -- Restart features
        if Config.DamageAffectsEnabled then
            StopDamageAffects()
            StartDamageAffects()
        else
            StopDamageAffects()
        end
        if Config.InfiniteJumpEnabled then
            StopInfiniteJump()
            StartInfiniteJump()
        else
            StopInfiniteJump()
        end
        if Config.VelocityPlusEnabled then
            StopVelocityPlus()
            StartVelocityPlus()
        else
            StopVelocityPlus()
        end
        if Config.ViewmodelEnabled then
            StopViewmodel()
            StartViewmodel()
        else
            StopViewmodel()
        end
        if Config.AntiVoidEnabled then
            UpdateAntiVoidPart()
        else
            if AntiVoidPart then AntiVoidPart:Destroy(); AntiVoidPart = nil end
        end
        print("Config loaded successfully")
    else
        warn("Failed to load config: " .. tostring(data))
    end
end)

-- antivoid stuff
local lastValidPos = Vector3.new(0, 100, 0)

task.spawn(function()
    while true do
        task.wait(0.1)
        local char = lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local ray = Ray.new(root.Position, Vector3.new(0, -500, 0))
            local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {char, AntiVoidPart})
            if hit then
                lastValidPos = root.Position
                Config.AntiVoidY = pos.Y - 20
            end

            if Config.AntiVoidEnabled and root.Position.Y < Config.AntiVoidY + 5 then
                if Config.AntiVoidMode == "Normal" then
                    root.CFrame = CFrame.new(lastValidPos + Vector3.new(0, 3, 0))
                    root.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
end)

local function UpdateAntiVoidPart()
    if AntiVoidPart then AntiVoidPart:Destroy() end
    if Config.AntiVoidEnabled then
        AntiVoidPart = Instance.new("Part")
        AntiVoidPart.Size = Vector3.new(2048, 1, 2048)
        AntiVoidPart.Position = Vector3.new(0, Config.AntiVoidY, 0)
        AntiVoidPart.Anchored = true
        AntiVoidPart.Transparency = 0.5
        AntiVoidPart.Color = Colors.Accent
        AntiVoidPart.CanCollide = (Config.AntiVoidMode == "Solid")
        AntiVoidPart.Parent = workspace
    end
end

-- ==========================================
-- DAMAGE AFFECTS LOGIC
-- ==========================================
local DamageMessages = {
    'Pow!', 'Pop!', 'Hit!', 'Smack!', 'Bang!', 'Boom!', 'Whoop!', 'Damage!',
    '-9e9!', 'Whack!', 'Crash!', 'Slam!', 'Zap!', 'Snap!', 'Thump!', 'Ouch!',
    'Crack!', 'Bam!', 'Clap!', 'Blitz!', 'Crunch!', 'Shatter!', 'Blast!',
    'Womp!', 'Thunk!', 'Rattle!', 'Kaboom!', 'Wack!', 'Bap!', 'Bomp!',
    'Sock!', 'Chop!', 'Sting!', 'Slice!', 'Swipe!', 'Punch!', 'Tonk!',
    'Bonk!', 'Jolt!', 'Spike!', 'Pierce!', 'Crush!', 'Bruise!', 'Ding!',
    'Clang!', 'Crashhh!', 'Kablam!', 'Ohioware on top!', '.gg/ohioware'
}

local DamageColors = {
    Color3.fromRGB(245, 69, 69),
    Color3.fromRGB(254, 105, 30),
    Color3.fromRGB(255, 138, 5),
    Color3.fromRGB(255, 162, 3),
    Color3.fromRGB(245, 189, 37)
}

local DamageConnection = nil

local function randomFrom(tbl)
    return tbl[math.random(1, #tbl)]
end

local function StartDamageAffects()
    if DamageConnection then DamageConnection:Disconnect() end
    DamageConnection = workspace.DescendantAdded:Connect(function(part)
        if part.Name == "DamageIndicatorPart" and part:IsA("BasePart") then
            for _, v in part:GetDescendants() do
                if v:IsA("TextLabel") then
                    if Config.DamageCustomMessages then
                        v.Text = randomFrom(DamageMessages)
                    end
                    if Config.DamageCustomColors then
                        v.TextColor3 = randomFrom(DamageColors)
                    end
                    v.FontFace = Config.DamageFont
                end
            end
        end
    end)
end

local function StopDamageAffects()
    if DamageConnection then
        DamageConnection:Disconnect()
        DamageConnection = nil
    end
end

-- skidded velocity logic
local vpRand = Random.new()
local vpOld = nil

local function rotateY(v, deg)
    local r = math.rad(deg)
    return Vector3.new(
        v.X * math.cos(r) - v.Z * math.sin(r),
        0,
        v.X * math.sin(r) + v.Z * math.cos(r)
    )
end
-- do velocity
local function StartVelocityPlus()
    if vpOld then return end
    vpOld = bedwars.KnockbackUtil.applyKnockback
    bedwars.KnockbackUtil.applyKnockback = function(root, mass, dir, knockback, ...)
        if vpRand:NextNumber(0, 100) > Config.VelocityPlusChance then
            return vpOld(root, mass, dir, knockback, ...)
        end
        if Config.VelocityPlusTargetOnly then
            local found = false
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= lplr and plr.Character then
                    local enemyRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                    if enemyRoot and (enemyRoot.Position - root.Position).Magnitude <= 50 then
                        found = true
                        break
                    end
                end
            end
            if not found then
                return vpOld(root, mass, dir, knockback, ...)
            end
        end
        local victimPos = root.Position
        local awayVec = Vector3.new(victimPos.X - dir.X, 0, victimPos.Z - dir.Z)
        if awayVec.Magnitude < 0.001 then
            return vpOld(root, mass, dir, knockback, ...)
        end
        awayVec = awayVec.Unit
        local chosen = Config.VelocityPlusDirection
        if chosen == "Random" then
            chosen = ({"Left", "Right", "Pull"})[vpRand:NextInteger(1, 3)]
        end
        local desiredAway
        if chosen == "Left" then
            desiredAway = rotateY(awayVec, 90)
        elseif chosen == "Right" then
            desiredAway = rotateY(awayVec, -90)
        elseif chosen == "Pull" then
            desiredAway = -awayVec
        else
            desiredAway = awayVec
        end
        local fakeAttacker = Vector3.new(
            victimPos.X - desiredAway.X * 100,
            dir.Y,
            victimPos.Z - desiredAway.Z * 100
        )
        return vpOld(root, mass, fakeAttacker, knockback, ...)
    end
end

local function StopVelocityPlus()
    if vpOld then
        bedwars.KnockbackUtil.applyKnockback = vpOld
        vpOld = nil
    end
end

--inf jump stuff
local ijConnection = nil
local ijHeldConnection = nil
local ijHeld = false

local function StartInfiniteJump()
    ijConnection = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Space and not UserInputService:GetFocusedTextBox() then
            ijHeld = true
            local char = lplr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if Config.InfiniteJumpHold then
                    task.spawn(function()
                        repeat
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                            task.wait()
                        until not ijHeld or not Config.InfiniteJumpEnabled or not Config.InfiniteJumpHold or UserInputService:GetFocusedTextBox()
                    end)
                else
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
    ijHeldConnection = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Space then
            ijHeld = false
        end
    end)
end

local function StopInfiniteJump()
    ijHeld = false
    if ijConnection then ijConnection:Disconnect(); ijConnection = nil end
    if ijHeldConnection then ijHeldConnection:Disconnect(); ijHeldConnection = nil end
end
-- disabler stuff
local krystalOldMomentum = nil

local function StartKrystalDisabler()
    if krystalOldMomentum then return end
    
    local controller = bedwars and bedwars.GlacialSkaterController
   

    krystalOldMomentum = controller.updateMomentum
    
    -- Hook the function
    controller.updateMomentum = function(self)
        self.momentum = 9e9
        self.lastMomentumReport = 9e9
        
        pcall(function()
            bedwars.Client:Get('MomentumUpdate'):SendToServer({
                momentumValue = 9e9
            })
        end)
        
        return krystalOldMomentum(self) -- call original if needed
    end

    -- Initial boost
    pcall(function()
        controller:updateMomentum(9e9)
    end)
    
    --print("✅ Krystal Disabler enabled")
end

local function StopKrystalDisabler()
    local controller = bedwars and bedwars.GlacialSkaterController
    if controller and krystalOldMomentum then
        controller.updateMomentum = krystalOldMomentum
        krystalOldMomentum = nil
        --print("❌ Krystal Disabler disabled")
    end
end

local kaConnection = nil
local kaLastSwing = 0

local function StartKillaura()
    if kaConnection then return end
    
    kaConnection = RunService.Heartbeat:Connect(function()
        if not Config.KillauraEnabled then return end
        local char = lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not bedwars or not bedwars.SwordController then return end
        
        -- Basic checks
        if tick() - kaLastSwing < 0.1 then return end
        if bedwars.AppController and bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then return end
        
        local sword = bedwars.getInventory and bedwars.getInventory(lplr).hand or nil
        if not sword or not sword.tool then return end
        
        local meta = bedwars.ItemMeta[sword.tool.Name]
        if not meta or not meta.sword then return end
        
        -- Find best target
        local bestTarget, bestDist = nil, Config.KillauraRange + 4
        for _, plr in Players:GetPlayers() do
            if plr ~= lplr and plr.Character then
                local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    local dist = (tRoot.Position - root.Position).Magnitude
                    if dist < bestDist then
                        -- Simple angle check
                        local dir = (tRoot.Position - root.Position).Unit
                        local facing = root.CFrame.LookVector
                        local angle = math.acos(facing:Dot(dir))
                        if math.deg(angle) <= Config.KillauraAngle / 2 then
                            bestTarget = plr.Character
                            bestDist = dist
                        end
                    end
                end
            end
        end
        
        if bestTarget then
            local tRoot = bestTarget:FindFirstChild("HumanoidRootPart")
            if tRoot and (tRoot.Position - root.Position).Magnitude <= Config.KillauraRange + 4 then
                local dir = (tRoot.Position - root.Position).Unit
                local pos = root.Position + dir * math.max((tRoot.Position - root.Position).Magnitude - 14.4, 0)
                
                pcall(function()
                    bedwars.Client:Get('SwordHit'):SendToServer({
                        weapon = sword.tool,
                        chargedAttack = {chargeRatio = 0},
                        entityInstance = bestTarget,
                        validate = {
                            raycast = {},
                            targetPosition = {value = tRoot.Position},
                            selfPosition = {value = pos},
                        },
                    })
                end)
                
                kaLastSwing = tick()
                -- Play swing effect if possible
                pcall(function()
                    bedwars.SwordController:playSwordEffect(meta, false)
                end)
            end
        end
    end)
end

local function StopKillaura()
    if kaConnection then
        kaConnection:Disconnect()
        kaConnection = nil
    end
end
-- ==========================================
-- VIEWMODEL LOGIC
-- ==========================================
local vmOldAnim = nil
local vmOldC1 = nil
local vmCustomHighlights = {}
local vmBaseSizes = {}
local vmRenderConnection = nil

local function vmGetCtrl()
    return lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]
end

local function vmApplyOffsets()
    local ctrl = pcall(vmGetCtrl) and vmGetCtrl() or nil
    if not ctrl then return end
    ctrl:SetAttribute("ConstantManager_DEPTH_OFFSET", -Config.ViewmodelDepth)
    ctrl:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", Config.ViewmodelHorizontal)
    ctrl:SetAttribute("ConstantManager_VERTICAL_OFFSET", Config.ViewmodelVertical)
end

local function vmClearOffsets()
    local ok, ctrl = pcall(vmGetCtrl)
    if not ok or not ctrl then return end
    ctrl:SetAttribute("ConstantManager_DEPTH_OFFSET", 0)
    ctrl:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", 0)
    ctrl:SetAttribute("ConstantManager_VERTICAL_OFFSET", 0)
end

local function vmApplyHighlight(part)
    local hl = Instance.new("Highlight")
    local c = Config.ViewmodelColorHSV
    local o = Config.ViewmodelOutlineHSV
    hl.FillColor = Color3.fromHSV(c.Hue, c.Sat, c.Val)
    hl.FillTransparency = math.clamp(Config.ViewmodelOutlineTrans + 0.2, 0, 1)
    hl.OutlineColor = Color3.fromHSV(o.Hue, o.Sat, o.Val)
    hl.OutlineTransparency = Config.ViewmodelOutlineTrans
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = part
    table.insert(vmCustomHighlights, hl)
end

local function vmApplyMaterial(part)
    local matName = Config.ViewmodelMaterial
    if Enum.Material[matName] then part.Material = Enum.Material[matName] end
    local c = Config.ViewmodelColorHSV
    part.Color = Color3.fromHSV(c.Hue, c.Sat, c.Val)
    local scale = Config.ViewmodelScale
    if not vmBaseSizes[part] then
        vmBaseSizes[part] = (part:IsA("MeshPart") and part.Size)
            or (part:FindFirstChildOfClass("SpecialMesh") and part:FindFirstChildOfClass("SpecialMesh").Scale)
            or Vector3.new(1, 1, 1)
    end
    if part:IsA("MeshPart") then
        part.Size = vmBaseSizes[part] * scale
        part.TextureID = ""
    else
        local mesh = part:FindFirstChildOfClass("SpecialMesh")
        if mesh then mesh.Scale = vmBaseSizes[part] * scale; mesh.TextureId = "" end
    end
end

local function vmMain()
    local viewmodel = game:GetService("Workspace").CurrentCamera:FindFirstChild("Viewmodel")
    if not viewmodel then return end
    if viewmodel:FindFirstChild("RightHand") and viewmodel.RightHand:FindFirstChild("RightWrist") and vmOldC1 then
        local rot = CFrame.Angles(
            math.rad(Config.ViewmodelRotX),
            math.rad(Config.ViewmodelRotY),
            math.rad(Config.ViewmodelRotZ)
        )
        viewmodel.RightHand.RightWrist.C1 = vmOldC1 * rot
    end
    for _, hl in vmCustomHighlights do pcall(function() hl:Destroy() end) end
    table.clear(vmCustomHighlights)
    for _, part in viewmodel:GetDescendants() do
        if part:IsA("BasePart") then
            vmApplyMaterial(part)
            if Config.ViewmodelColorMode == "Normal" or Config.ViewmodelColorMode == "Mixed" then
                vmApplyHighlight(part)
            end
        end
    end
end

local function StartViewmodel()
    pcall(vmApplyOffsets)
    local vm = game:GetService("Workspace").CurrentCamera:FindFirstChild("Viewmodel")
    vmOldC1 = (vm and vm:FindFirstChild("RightHand") and vm.RightHand:FindFirstChild("RightWrist") and vm.RightHand.RightWrist.C1) or CFrame.identity
    if Config.ViewmodelNoBob then
        vmOldAnim = bedwars.ViewmodelController.playAnimation
        bedwars.ViewmodelController.playAnimation = function(self, animtype, ...)
            if bedwars.AnimationType and animtype == bedwars.AnimationType.FP_WALK then return end
            return vmOldAnim(self, animtype, ...)
        end
    end
    vmRenderConnection = RunService.PostSimulation:Connect(vmMain)
end

local function StopViewmodel()
    if vmOldAnim then bedwars.ViewmodelController.playAnimation = vmOldAnim; vmOldAnim = nil end
    local vm = game:GetService("Workspace").CurrentCamera:FindFirstChild("Viewmodel")
    if vm and vm:FindFirstChild("RightHand") and vm.RightHand:FindFirstChild("RightWrist") and vmOldC1 then
        vm.RightHand.RightWrist.C1 = vmOldC1
    end
    pcall(vmClearOffsets)
    table.clear(vmBaseSizes)
    for _, hl in vmCustomHighlights do pcall(function() hl:Destroy() end) end
    table.clear(vmCustomHighlights)
    if vmRenderConnection then vmRenderConnection:Disconnect(); vmRenderConnection = nil end
end

-- broken target hud that i will fix next upd 
local TargetHudFrame = Instance.new("Frame")
TargetHudFrame.Size = UDim2.new(0, 180, 0, 110)
TargetHudFrame.Position = UDim2.new(0.5, -90, 0.5, -160)
TargetHudFrame.BackgroundColor3 = Colors.WindowBg
TargetHudFrame.BorderSizePixel = 0
TargetHudFrame.Visible = false
TargetHudFrame.Parent = ScreenGui
Instance.new("UICorner", TargetHudFrame).CornerRadius = UDim.new(0, 6)

local thStroke = Instance.new("UIStroke", TargetHudFrame)
thStroke.Color = Colors.Accent
thStroke.Transparency = 0.7
thStroke.Thickness = 1

local thTitle = Instance.new("TextLabel")
thTitle.Size = UDim2.new(1, 0, 0, 24)
thTitle.Position = UDim2.new(0, 0, 0, 0)
thTitle.BackgroundTransparency = 1
thTitle.Text = "Target HUD"
thTitle.TextColor3 = Colors.TextDark
thTitle.Font = Enum.Font.GothamBold
thTitle.TextSize = 11
thTitle.Parent = TargetHudFrame

MakeDraggable(TargetHudFrame)
table.insert(Windows, TargetHudFrame)

local thDiv = Instance.new("Frame")
thDiv.Size = UDim2.new(1, -20, 0, 1)
thDiv.Position = UDim2.new(0, 10, 0, 24)
thDiv.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
thDiv.BorderSizePixel = 0
thDiv.Parent = TargetHudFrame

local thName = Instance.new("TextLabel")
thName.Size = UDim2.new(1, -20, 0, 18)
thName.Position = UDim2.new(0, 10, 0, 30)
thName.BackgroundTransparency = 1
thName.Text = "No Target"
thName.TextColor3 = Colors.Text
thName.Font = Enum.Font.GothamBold
thName.TextSize = 13
thName.TextXAlignment = Enum.TextXAlignment.Center
thName.Parent = TargetHudFrame

local function MakeHealthBar(yPos, bgColor)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -20, 0, 7)
    bg.Position = UDim2.new(0, 10, 0, yPos)
    bg.BackgroundColor3 = Colors.SliderTrack
    bg.BorderSizePixel = 0
    bg.Parent = TargetHudFrame
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = bgColor
    fill.BorderSizePixel = 0
    fill.Parent = bg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    return fill
end

local thTheirLabel = Instance.new("TextLabel")
thTheirLabel.Size = UDim2.new(1, -20, 0, 14)
thTheirLabel.Position = UDim2.new(0, 10, 0, 51)
thTheirLabel.BackgroundTransparency = 1
thTheirLabel.Text = "Enemy  0 / 0"
thTheirLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
thTheirLabel.Font = Enum.Font.Gotham
thTheirLabel.TextSize = 10
thTheirLabel.TextXAlignment = Enum.TextXAlignment.Left
thTheirLabel.Parent = TargetHudFrame

local thTheirBar = MakeHealthBar(65, Color3.fromRGB(220, 60, 60))

local thMyLabel = Instance.new("TextLabel")
thMyLabel.Size = UDim2.new(1, -20, 0, 14)
thMyLabel.Position = UDim2.new(0, 10, 0, 74)
thMyLabel.BackgroundTransparency = 1
thMyLabel.Text = "You  0 / 0"
thMyLabel.TextColor3 = Colors.Accent
thMyLabel.Font = Enum.Font.Gotham
thMyLabel.TextSize = 10
thMyLabel.TextXAlignment = Enum.TextXAlignment.Left
thMyLabel.Parent = TargetHudFrame

local thMyBar = MakeHealthBar(88, Colors.Accent)

local thStatus = Instance.new("TextLabel")
thStatus.Size = UDim2.new(1, -20, 0, 14)
thStatus.Position = UDim2.new(0, 10, 0, 93)
thStatus.BackgroundTransparency = 1
thStatus.Text = ""
thStatus.Font = Enum.Font.GothamBold
thStatus.TextSize = 11
thStatus.TextXAlignment = Enum.TextXAlignment.Center
thStatus.Parent = TargetHudFrame

RunService.RenderStepped:Connect(function()
    if not Config.TargetHudEnabled then return end

    local target = nil
    local hit = mouse.Target
    if hit then
        local char = hit:FindFirstAncestorWhichIsA("Model")
        if char then
            local plr = Players:GetPlayerFromCharacter(char)
            if plr and plr ~= lplr then target = plr end
        end
    end

    if not target then
        local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then
            local closest, closestDist = nil, 30
            for _, plr in Players:GetPlayers() do
                if plr ~= lplr and plr.Character then
                    local theirRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                    if theirRoot then
                        local dist = (theirRoot.Position - myRoot.Position).Magnitude
                        if dist < closestDist then
                            closest = plr
                            closestDist = dist
                        end
                    end
                end
            end
            target = closest
        end
    end

    if target and target.Character then
        local theirHum = target.Character:FindFirstChildOfClass("Humanoid")
        local myHum = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid")

        if theirHum and myHum then
            local theirHP = math.floor(theirHum.Health)
            local theirMax = math.floor(theirHum.MaxHealth)
            local myHP = math.floor(myHum.Health)
            local myMax = math.floor(myHum.MaxHealth)

            thName.Text = target.DisplayName
            thName.TextColor3 = Colors.Text

            thTheirLabel.Text = "Enemy  " .. theirHP .. " / " .. theirMax
            thTheirBar.Size = UDim2.new(math.clamp(theirHP / math.max(theirMax, 1), 0, 1), 0, 1, 0)

            thMyLabel.Text = "You  " .. myHP .. " / " .. myMax
            thMyBar.Size = UDim2.new(math.clamp(myHP / math.max(myMax, 1), 0, 1), 0, 1, 0)

            if myHP > theirHP then
                thStatus.Text = "WINNING"
                thStatus.TextColor3 = Color3.fromRGB(80, 220, 100)
            elseif myHP < theirHP then
                thStatus.Text = "LOSING"
                thStatus.TextColor3 = Color3.fromRGB(255, 70, 70)
            else
                thStatus.Text = "EVEN"
                thStatus.TextColor3 = Colors.TextDark
            end
        end
    else
        thName.Text = "No Target"
        thName.TextColor3 = Colors.TextDark
        thTheirLabel.Text = "Enemy  — / —"
        thTheirBar.Size = UDim2.new(0, 0, 1, 0)
        thMyLabel.Text = "You  — / —"
        thMyBar.Size = UDim2.new(0, 0, 1, 0)
        thStatus.Text = ""
        local myHum = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid")
        if myHum then
            local myHP = math.floor(myHum.Health)
            local myMax = math.floor(myHum.MaxHealth)
            thMyLabel.Text = "You  " .. myHP .. " / " .. myMax
            thMyBar.Size = UDim2.new(math.clamp(myHP / math.max(myMax, 1), 0, 1), 0, 1, 0)
        end
    end
end)

-- ==========================================
-- HUD FEATURE
-- ==========================================
local HudFrame = Instance.new("Frame")
HudFrame.Size = UDim2.new(0, 220, 0, 80)
HudFrame.Position = UDim2.new(0, 20, 1, -100)
HudFrame.BackgroundTransparency = 1
HudFrame.Visible = false
HudFrame.Parent = ScreenGui

local HudList = Instance.new("UIListLayout", HudFrame)
HudList.VerticalAlignment = Enum.VerticalAlignment.Bottom

local function CreateHudLine(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Colors.HudText
    label.Text = text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.RichText = true
    label.Parent = HudFrame
    return label
end

local Watermark = CreateHudLine('OhioWare <font color="rgb(150, 150, 150)">0.1</font>')
local PingLabel = CreateHudLine("Ping: 0ms")

RunService.RenderStepped:Connect(function()
    if Config.HudEnabled then
        local ping = math.floor(lplr:GetNetworkPing() * 1000)
        PingLabel.Text = "Ping: " .. ping .. "ms" --seriously fuck this game
        
    end
end)

--finally make menu
local MovementWindow = CreateWindow("Movement", 50)
local WorldWindow = CreateWindow("World", 260)
local RenderWindow = CreateWindow("Render", 470)
local CombatWindow = CreateWindow("Combat", 680)

-- Modules
CreateModule("HUD", RenderWindow, function(s)
    Config.HudEnabled = s
    if HudFrame then HudFrame.Visible = s end
end)

local dmgSettings = CreateModule("Damage Effects", RenderWindow, function(s)
    Config.DamageAffectsEnabled = s
    if s then
        StartDamageAffects()
    else
        StopDamageAffects()
    end
end)

local dmgMsgBtn = Instance.new("TextButton")
dmgMsgBtn.Size = UDim2.new(1, 0, 0, 30)
dmgMsgBtn.BackgroundTransparency = 1
dmgMsgBtn.Text = "  Custom Messages"
dmgMsgBtn.Font = Enum.Font.Gotham
dmgMsgBtn.TextColor3 = Colors.Accent
dmgMsgBtn.TextSize = 11
dmgMsgBtn.TextXAlignment = Enum.TextXAlignment.Left
dmgMsgBtn.Parent = dmgSettings

dmgMsgBtn.MouseButton1Click:Connect(function()
    Config.DamageCustomMessages = not Config.DamageCustomMessages
    dmgMsgBtn.TextColor3 = Config.DamageCustomMessages and Colors.Accent or Colors.TextDark
end)

local dmgColorBtn = Instance.new("TextButton")
dmgColorBtn.Size = UDim2.new(1, 0, 0, 30)
dmgColorBtn.BackgroundTransparency = 1
dmgColorBtn.Text = "  Custom Colors"
dmgColorBtn.Font = Enum.Font.Gotham
dmgColorBtn.TextColor3 = Colors.Accent
dmgColorBtn.TextSize = 11
dmgColorBtn.TextXAlignment = Enum.TextXAlignment.Left
dmgColorBtn.Parent = dmgSettings

dmgColorBtn.MouseButton1Click:Connect(function()
    Config.DamageCustomColors = not Config.DamageCustomColors
    dmgColorBtn.TextColor3 = Config.DamageCustomColors and Colors.Accent or Colors.TextDark
end)

local vmSettings = CreateModule("Viewmodel", RenderWindow, function(s)
    Config.ViewmodelEnabled = s
    if s then StartViewmodel() else StopViewmodel() end
end)

CreateToggleSetting("No Bobbing", vmSettings, function(s)
    Config.ViewmodelNoBob = s
    if Config.ViewmodelEnabled then StopViewmodel(); StartViewmodel() end
end)

CreateSlider("Depth", 0, 20, 8, vmSettings, function(v)
    Config.ViewmodelDepth = v / 10
    if Config.ViewmodelEnabled then pcall(vmApplyOffsets) end
end)

CreateSlider("Horizontal", 0, 20, 8, vmSettings, function(v)
    Config.ViewmodelHorizontal = v / 10
    if Config.ViewmodelEnabled then pcall(vmApplyOffsets) end
end)

CreateSlider("Vertical", 0, 20, 0, vmSettings, function(v)
    Config.ViewmodelVertical = (v / 10) - 0.2
    if Config.ViewmodelEnabled then pcall(vmApplyOffsets) end
end)

CreateSlider("Sword Scale", 1, 10, 10, vmSettings, function(v)
    Config.ViewmodelScale = v / 10
end)

CreateSlider("Rotation X", 0, 360, 0, vmSettings, function(v)
    Config.ViewmodelRotX = v
end)

CreateSlider("Rotation Y", 0, 360, 0, vmSettings, function(v)
    Config.ViewmodelRotY = v
end)

CreateSlider("Rotation Z", 0, 360, 0, vmSettings, function(v)
    Config.ViewmodelRotZ = v
end)

CreateDropdown("Material", {"Neon", "Plastic", "ForceField"}, "Neon", vmSettings, function(v)
    Config.ViewmodelMaterial = v
end)

CreateDropdown("Color Mode", {"Normal", "Classic", "Mixed"}, "Normal", vmSettings, function(v)
    Config.ViewmodelColorMode = v
end)

local ijSettings = CreateModule("Infinite Jump", MovementWindow, function(s)
    Config.InfiniteJumpEnabled = s
    if s then StartInfiniteJump() else StopInfiniteJump() end
end)

CreateToggleSetting("Hold to Jump", ijSettings, function(s)
    Config.InfiniteJumpHold = s
end)

local avSettings = CreateModule("Anti Void", MovementWindow, function(s)
    Config.AntiVoidEnabled = s
    UpdateAntiVoidPart()
end)

CreateToggleSetting("Solid Mode", avSettings, function(s)
    Config.AntiVoidMode = s and "Solid" or "Normal"
    UpdateAntiVoidPart()
end)

local lagSettings = CreateModule("Anti Lagback", WorldWindow, function(s)
    Config.AntiLagEnabled = s
end)

CreateSlider("Max Latency", 0, 1000, 200, lagSettings, function(v) Config.MaxLatency = v end)
CreateSlider("Compensation", 0, 50, 23, lagSettings, function(v) Config.MaxCompensation = v end)

local vpSettings = CreateModule("Velocity Plus", CombatWindow, function(s)
    Config.VelocityPlusEnabled = s
    if s then StartVelocityPlus() else StopVelocityPlus() end
end)

CreateDropdown("Direction", {"Left", "Right", "Pull", "Random"}, "Random", vpSettings, function(v)
    Config.VelocityPlusDirection = v
end)

CreateSlider("Chance", 0, 100, 100, vpSettings, function(v)
    Config.VelocityPlusChance = v
end)

CreateToggleSetting("Only When Targeting", vpSettings, function(s)
    Config.VelocityPlusTargetOnly = s
end)

local kaSettings = CreateModule("Killaura", CombatWindow, function(s)
    Config.KillauraEnabled = s
    if s then
        StartKillaura()
    else
        StopKillaura()
    end
end)

CreateSlider("Range", 0, 25, 18, kaSettings, function(v)
    Config.KillauraRange = v
end)

CreateSlider("Max Angle", 0, 360, 180, kaSettings, function(v)
    Config.KillauraAngle = v
end)

local krystalModule = CreateModule("Krystal Disabler", CombatWindow, function(s)  -- or MovementWindow
    Config.KrystalDisablerEnabled = s
    if s then
        StartKrystalDisabler()
    else
        StopKrystalDisabler()
    end
end)

-- Keybind (P) with safety check
UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.P then
        Config.Visible = not Config.Visible
        for _, win in pairs(Windows) do
            if win and win:IsA("Frame") then
                win.Visible = Config.Visible
            end
        end
    end
end)