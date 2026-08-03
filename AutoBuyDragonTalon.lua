--[[
    AUTO EQUIP DRAGON TALON - BLOX FRUITS
    Chức năng: Đợi game load, bay chậm an toàn đến Uzoth và trang bị lại Dragon Talon.
]]

repeat task.wait() until game:IsLoaded() -- Đợi game load xong hoàn toàn

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Config = {
    UzothCFrame = CFrame.new(5661.89, 1211.31, 864.83), -- Vị trí NPC Uzoth (Haunted Castle)
    TweenSpeed = 175 -- Tốc độ bay chậm và an toàn
}

-- 1. Bay an toàn (Safe Tween & Noclip)
local function SafeTween(targetCFrame)
    -- Chờ nhân vật xuất hiện đầy đủ sau khi game load
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    
    if not hrp then return false end
    
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    
    if dist < 10 then
        hrp.CFrame = targetCFrame
        return true
    end

    -- Khởi tạo BodyVelocity để giữ nhân vật không bị rơi
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(100000, 100000, 100000)
    bv.Parent = hrp
    
    -- Bật No-clip để xuyên tường an toàn
    local noclip = RunService.Stepped:Connect(function()
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end)

    -- Tính toán thời gian bay dựa trên khoảng cách và tốc độ
    local tweenInfo = TweenInfo.new(dist / Config.TweenSpeed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    tween.Completed:Wait()
    
    -- Dọn dẹp BodyVelocity và Noclip sau khi hạ cánh
    bv:Destroy()
    noclip:Disconnect()
    
    -- Chốt lại vị trí chính xác
    hrp.CFrame = targetCFrame
    return true
end

-- 2. Tương tác NPC để trang bị lại Dragon Talon
local function EquipDragonTalon()
    print("🚀 Đang di chuyển đến Haunted Castle (NPC Uzoth)...")
    local success = SafeTween(Config.UzothCFrame)
    
    if success then
        task.wait(1.5) -- Chờ 1.5 giây để server load map và cập nhật vị trí chắc chắn
        print("🤝 Đang tương tác với NPC để đổi võ...")
        
        -- Đợi Remote xuất hiện an toàn
        local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        local CommF = Remotes and Remotes:WaitForChild("CommF_", 5)
        
        if CommF then
            pcall(function()
                -- Lệnh tương tác NPC Uzoth
                CommF:InvokeServer("BuyDragonTalon", "Start")
                task.wait(0.5)
                CommF:InvokeServer("BuyDragonTalon", "Buy")
                task.wait(0.5)
                CommF:InvokeServer("BuyDragonTalon")
            end)
            print("✅ Hoàn tất! Đã lấy lại Dragon Talon.")
        else
            warn("❌ [LỖI]: Không tìm thấy đường truyền kết nối đến server.")
        end
    else
        warn("❌ [LỖI]: Di chuyển thất bại, nhân vật đang bị lỗi hoặc chưa Load xong.")
    end
end

-- Khởi chạy
EquipDragonTalon()
