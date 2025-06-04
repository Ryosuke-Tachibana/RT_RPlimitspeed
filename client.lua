local isSpeedLimitUIOpen = false
local isSpeedLimited = false
local currentSpeedLimit = 50.0
local speedLimit = 0.0
local isInVehicle = false 
local notificationType = "okok" --'ox''qb''gta''okok'

local currentLanguage = GetConvar('RPlimitspeed_locale', 'jp') 


local locale = RPlimitspeedLocale[currentLanguage] or {} 


if not RPlimitspeedLocale[currentLanguage] then
    print(string.format('^1[RPlimitspeed]^0 Error: Translations not found for locale: %s. Using default (jp) or empty.', currentLanguage))
    locale = RPlimitspeedLocale['jp'] or {} 
end


local function getLocalizedText(key)
    return locale[key] or "TRANSLATION_MISSING" 
end

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
            AddTextComponentString(getLocalizedText("speed_limit_setting"))
            DrawText(x + 0.01, y + 0.01)

            SetTextScale(0.5, 0.5)
            SetTextEntry("STRING")
            AddTextComponentString(string.format("%.1f km/h", currentSpeedLimit))
            DrawText(x + 0.01, y + 0.03)

            SetTextScale(0.3, 0.3)
            SetTextEntry("STRING")
            AddTextComponentString(getLocalizedText("change_speed"))
            DrawText(x + 0.01, y + 0.07)
        end
    end
end)


RegisterCommand('setlimitspeed', function()
    isSpeedLimitUIOpen = not isSpeedLimitUIOpen
    
    if not isSpeedLimitUIOpen and isSpeedLimited then
        sendNotification(notificationType, string.format(getLocalizedText("speed_limit_set"), speedLimit), 3000)
    elseif not isSpeedLimitUIOpen and not isSpeedLimited and speedLimit > 0 then
        sendNotification(notificationType, getLocalizedText("speed_limit_disabled"), 3000)
    elseif not isSpeedLimitUIOpen then
        
    end
end, false)

RegisterCommand('setnotify', function(source, args)
    if #args == 1 then
        local type = string.lower(args[1])
        if type == "okok" or type == "ox" or type == "qb" or type == "gta" then
            notificationType = type
            sendNotification("gta", string.format(getLocalizedText("notification_type_set"), type), 2000)
        else
            sendNotification("gta", getLocalizedText("invalid_notification_type"), 3000)
        end
    else
        sendNotification("gta", getLocalizedText("usage_setnotify"), 3000)
    end
end, false)

RegisterCommand('setlang', function(source, args)
    if #args == 1 then
        local lang = string.lower(args[1])
        if lang == "jp" or lang == "en" then
            
            
            currentLanguage = lang
            locale = RPlimitspeedLocale[currentLanguage] or {}
            if not RPlimitspeedLocale[currentLanguage] then
                print(string.format('^1[RPlimitspeed]^0 Warning: Translations not found for switched locale: %s.', currentLanguage))
                locale = RPlimitspeedLocale['jp'] or {} 
            end
            sendNotification("gta", string.format(getLocalizedText("language_set"), lang), 2000)
        else
            sendNotification("gta", getLocalizedText("invalid_language"), 3000)
        end
    else
        sendNotification("gta", getLocalizedText("usage_setlang"), 3000)
    end
end, false)


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
                isSpeedLimitUIOpen = false 
                sendNotification(notificationType, string.format(getLocalizedText("speed_limit_set"), speedLimit), 3000)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            isSpeedLimitUIOpen = false
        end
    end
end)

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
        else
            -- 車から降りたら速度制限を解除
            if isSpeedLimited then
                isSpeedLimited = false
                speedLimit = 0.0
                sendNotification(notificationType, getLocalizedText("speed_limit_disabled"), 3000)
            end
        end
    end
end)
