--[[
    AUTO BUY DRAGON TALON - Blox Fruits
    Version: 3.3 Ultra Stable (Anti-Kick Pro)
    Cải tiến: Lag Compensation, State Management, Stealth BV
]]

repeat task.wait() until game:IsLoaded()

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

local plr = Players.LocalPlayer

-- Cấu hình
local Config = {
    Enabled = true,
    TweenSpeed = 300,
    TargetTP = CFrame.new(5661.89014, 1211.31909, 864.836731, .811413169, -1.36805838e-08, -0.584473014, 4.75227395e-08,
        1, 4.25682458e-08, .584473014, -6.23161966e-08, .811413169),
    RetryDelay = 5,
    MaxRetries = 10,
    RandomDelayMin = 0.5,
    RandomDelayMax = 1.0,
    FlightAltitude = 15 -- Độ cao bù thêm khi bay
}

-- Biến UI
local StatusText

-- // 1. TẠO PART ĐIỀU KHIỂN //
local ControlPart = Instance.new("Part")
ControlPart.Name = "DragonTalon_ProControl"
ControlPart.Size = Vector3.new(1, 1, 1)
ControlPart.Anchored = true
ControlPart.CanCollide = false
ControlPart.Transparency = 1
ControlPart.Parent = workspace

-- Dọn dẹp part cũ
for _, v in pairs(workspace:GetChildren()) do
    if v.Name == ControlPart.Name and v ~= ControlPart then
        v:Destroy()
    end
end

-- // 2. LOGIC ANTI-KICK & NO-CLIP PRO //
task.spawn(function()
    while task.wait() do
        pcall(function()
            local char = plr.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end

            local hrp = char.HumanoidRootPart
            local hum = char:FindFirstChildOfClass("Humanoid")

            if Config.Enabled and (ControlPart.Position - hrp.Position).Magnitude < 1500 then
                -- LAG COMPENSATION: Phát hiện lệch vị trí quá xa
                if (hrp.Position - ControlPart.Position).Magnitude > 200 then
                    ControlPart.CFrame = hrp.CFrame
                else
                    hrp.CFrame = ControlPart.CFrame
                end

                -- STEALTH BODYVELOCITY: Lực vật lý vừa đủ (100k)
                if not hrp:FindFirstChild("BodyClip") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "BodyClip"
                    bv.Velocity = Vector3.new(0, 0, 0)
                    bv.MaxForce = Vector3.new(100000, 100000, 100000)
                    bv.Parent = hrp
                end

                -- STATE MANAGEMENT: Vô hiệu hóa physics check mặc định
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                end

                -- NO-CLIP
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            else
                -- Cleanup khi dừng
                if hrp:FindFirstChild("BodyClip") then
                    hrp.BodyClip:Destroy()
                end
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end)
    end
end)

-- Anti-AFK
local AntiAFK = plr.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- Delay ngẫu nhiên
local function randomWait()
    task.wait(math.random(Config.RandomDelayMin * 100, Config.RandomDelayMax * 100) / 100)
end

-- Cập nhật Status
local function updateStatus(text, color)
    if StatusText then
        StatusText.Text = text
        StatusText.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    end
end

-- Kiểm tra Dragon Talon
local function hasDragonTalon()
    local backpack = plr:FindFirstChild("Backpack")
    local char = plr.Character
    local function check(p) return p and p:FindFirstChild("Dragon Talon") end
    return check(backpack) or check(char)
end

-- Chọn Team
local function autoSelectTeam()
    if not plr.Team then
        updateStatus("⏳ Chọn team...", Color3.fromRGB(255, 200, 100))
        pcall(function()
            local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
            if remotes then
                remotes.CommF_:InvokeServer("SetTeam", getgenv().Team or "Pirates")
            end
        end)
        task.wait(2)
    end
    return plr.Team ~= nil
end

-- Bay an toàn (Tween thông qua Control Part)
local function safeTween(targetCF)
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end

    local hrp = char.HumanoidRootPart
    ControlPart.CFrame = hrp.CFrame
    task.wait(0.1)

    -- Bay cao hơn mục tiêu một chút để tránh vật cản
    local flyCF = targetCF * CFrame.new(0, Config.FlightAltitude, 0)
    local distance = (ControlPart.Position - flyCF.Position).Magnitude

    if distance < 10 then
        ControlPart.CFrame = targetCF
        return true
    end

    local speed = Config.TweenSpeed
    if distance < 300 then speed = 200 end

    local tween = TweenService:Create(ControlPart, TweenInfo.new(distance / speed, Enum.EasingStyle.Linear),
        { CFrame = flyCF })
    tween:Play()

    repeat
        task.wait()
    until (tween.PlaybackState == Enum.PlaybackState.Completed) or not Config.Enabled

    if Config.Enabled then
        -- Hạ cánh xuống vị trí chính xác
        ControlPart.CFrame = targetCF
        task.wait(0.3)
        return true
    end

    tween:Cancel()
    return false
end

-- Mua võ
local function buyDragonTalon()
    local commF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
    if not commF then return false end

    for i = 1, Config.MaxRetries do
        pcall(function()
            commF:InvokeServer("BuyDragonTalon", "Start")
            task.wait(0.5)
            commF:InvokeServer("BuyDragonTalon")
        end)

        task.wait(1.5)
        if hasDragonTalon() then return true end
        updateStatus("❌ Thử lại " .. i, Color3.fromRGB(255, 100, 100))
    end
    return false
end

-- Vòng lặp chính
local function mainLoop()
    task.spawn(function()
        if not autoSelectTeam() then return end

        while task.wait(0.5) do
            if not Config.Enabled then break end

            if hasDragonTalon() then
                updateStatus("✅ Hoàn thành!", Color3.fromRGB(100, 255, 100))
                Config.Enabled = false
                break
            end

            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local dist = (char.HumanoidRootPart.Position - Config.TargetTP.Position).Magnitude

                if dist > 25 then
                    updateStatus("🚀 Đang bay (" .. math.floor(dist) .. "m)", Color3.fromRGB(100, 200, 255))
                    safeTween(Config.TargetTP)
                else
                    updateStatus("💰 Đang mua...", Color3.fromRGB(255, 255, 100))
                    if buyDragonTalon() then
                        updateStatus("✅ Thành công!", Color3.fromRGB(100, 255, 100))
                        task.wait(5)
                    end
                end
            else
                task.wait(2)
            end
        end
    end)
end

-- UI
local function createUI()
    pcall(function() if CoreGui:FindFirstChild("DragonTalonUI") then CoreGui.DragonTalonUI:Destroy() end end)
    local gui = Instance.new("ScreenGui", CoreGui); gui.Name = "DragonTalonUI"
    local main = Instance.new("Frame", gui)
    main.Size = UDim2.new(0, 200, 0, 100); main.Position = UDim2.new(0.5, -100, 0.1, 0); main.BackgroundColor3 = Color3
    .fromRGB(25, 25, 35)
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 30); title.Text = "🐉 Dragon Talon v3.3 Pro"; title.TextColor3 = Color3.fromRGB(255,
        255, 255); title.Font = Enum.Font.GothamBold; title.BackgroundColor3 = Color3.fromRGB(50, 80, 255)
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

    StatusText = Instance.new("TextLabel", main)
    StatusText.Size = UDim2.new(1, 0, 0, 30); StatusText.Position = UDim2.new(0, 0, 0, 35); StatusText.Text =
    "🚀 Khởi động..."; StatusText.TextColor3 = Color3.fromRGB(100, 255, 100); StatusText.BackgroundTransparency = 1; StatusText.Font =
    Enum.Font.Gotham

    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(0.9, 0, 0, 25); btn.Position = UDim2.new(0.05, 0, 0, 70); btn.Text = "DỪNG SCRIPT"; btn.BackgroundColor3 =
    Color3.fromRGB(255, 50, 50); btn.TextColor3 = Color3.new(1, 1, 1); btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    btn.MouseButton1Click:Connect(function()
        Config.Enabled = not Config.Enabled
        btn.Text = Config.Enabled and "DỪNG SCRIPT" or "CHẠY SCRIPT"
        btn.BackgroundColor3 = Config.Enabled and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 200, 50)
        if Config.Enabled then mainLoop() end
    end)
end

createUI()
mainLoop()

-- Cleanup
plr.CharacterRemoving:Connect(function()
    pcall(function() if AntiAFK then AntiAFK:Disconnect() end end)
end)
