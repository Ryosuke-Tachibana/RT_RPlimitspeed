local isSpeedLimitUIOpen = false
local isSpeedLimited = false
local currentSpeedLimit = 50.0
local speedLimit = 0.0
local isInVehicle = false
local notificationType = "okok" --'ox''qb''gta''okok'


local function sendNotification(type, message, duration)
    if type == "okok" and exports.okokNotify then
        exports.okokNotify:Alert('info', message, duration)
    elseif type == "ox" and exports.ox_lib then
        exports.ox_lib:Notify({ type = 'info', description = message, duration = duration })
    elseif type == "qb" and exports['qb-core'] then
        QBCore.Functions.Notify(message, 'info', duration / 1000)
    elseif type == "gta" then
        SetNotificationTextEntry("STRING")
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

-- UIの描画
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isSpeedLimitUIOpen then
            local x = 0.01
            local y = 0.05
            local width = 0.2
            local height = 0.1
            local backgroundColor = { r = 0, g = 0, b = 0, a = 200 }
            local textColor = { r = 255, g = 255, b = 255, a = 255 }

            DrawRect(x + width / 2, y + height / 2, width, height, backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)
            SetTextProportional(0)
            SetTextScale(0.4, 0.4)
            SetTextColour(textColor.r, textColor.g, textColor.b, textColor.a)
            SetTextEntry("STRING")
            AddTextComponentString("速度制限設定")
            DrawText(x + 0.01, y + 0.01)

            SetTextScale(0.5, 0.5)
            SetTextEntry("STRING")
            AddTextComponentString(string.format("%.1f km/h", currentSpeedLimit))
            DrawText(x + 0.01, y + 0.03)

            SetTextScale(0.3, 0.3)
            SetTextEntry("STRING")
            AddTextComponentString("↑/↓: 変更  Enter: 決定")
            DrawText(x + 0.01, y + 0.07)
        end
    end
end)

-- UIの表示/非表示と速度制限のオン/オフを切り替えるコマンド
RegisterCommand('setlimitspeed', function()
    isSpeedLimitUIOpen = not isSpeedLimitUIOpen
    -- UIが開いている状態では速度制限をオンにしない。決定を押した時のみオンにする。
    if not isSpeedLimitUIOpen and isSpeedLimited then
        sendNotification(notificationType, string.format('速度制限を %.1f km/h に設定しました。', speedLimit), 3000)
    elseif not isSpeedLimitUIOpen and not isSpeedLimited and speedLimit > 0 then
        sendNotification(notificationType, '速度制限を無効にしました。', 3000)
    elseif not isSpeedLimitUIOpen then
        -- UIを閉じただけで、特に速度制限の状態は変わらない場合
    end
end, false)

-- 通知タイプを設定するコマンド
RegisterCommand('setnotify', function(source, args)
    if #args == 1 then
        local type = string.lower(args[1])
        if type == "okok" or type == "ox" or type == "qb" or type == "gta" then
            notificationType = type
            sendNotification("gta", string.format('通知タイプを "%s" に設定しました。', type), 2000)
        else
            sendNotification("gta", '無効な通知タイプです。使用可能なタイプ: okok, ox, qb, gta', 3000)
        end
    else
        sendNotification("gta", '使用方法: /setnotify [okok/ox/qb/gta]', 3000)
    end
end, false)

-- UIが開いている間の入力処理と速度制限値の確定
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isSpeedLimitUIOpen then
            if IsControlJustPressed(0, 172) then -- INPUT_UP
                currentSpeedLimit = currentSpeedLimit + 5.0
            elseif IsControlJustPressed(0, 173) then -- INPUT_DOWN
                currentSpeedLimit = math.max(0.0, currentSpeedLimit - 5.0)
            elseif IsControlJustPressed(0, 18) then -- INPUT_ENTER
                speedLimit = currentSpeedLimit
                isSpeedLimited = true
                isSpeedLimitUIOpen = false -- UIを閉じる
                sendNotification(notificationType, string.format('速度制限を %.1f km/h に設定しました。', speedLimit), 3000)
            end
        end
    end
end)

-- 車両に乗っているかの状態を監視し、降りたらUIを閉じる
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            isSpeedLimitUIOpen = false
        end
    end
end)

-- 速度監視と制御
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if isSpeedLimited then
                local currentVehicleSpeedVector = GetEntitySpeedVector(vehicle)
                local currentVehicleSpeed = math.sqrt(currentVehicleSpeedVector.x^2 + currentVehicleSpeedVector.y^2 + currentVehicleSpeedVector.z^2) * 3.6
                if currentVehicleSpeed > speedLimit then
                    SetEntityMaxSpeed(vehicle, speedLimit / 3.6)
                else
                    SetEntityMaxSpeed(vehicle, 1000.0)
                end
            else
                SetEntityMaxSpeed(vehicle, 1000.0)
            end
        end
    end
end)
