QBCore = exports['qb-core']:GetCoreObject()


-- Configuration
Config = Config or {}
Config.ImpoundInterval = 3600 -- 1 Hour (in seconds)
Config.CountdownTime = 100 -- Countdown time before impound (in seconds)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    Wait(2000)
    local vehicles = GetAllVehicles()
    local impounded = 0
    for _, vehicle in ipairs(vehicles) do
        local plate = GetVehicleNumberPlateText(vehicle)
        local driver = GetPedInVehicleSeat(vehicle, -1)
        if plate and plate ~= "" and driver == 0 then
            local result = MySQL.Sync.execute(
                'UPDATE player_vehicles SET state = 2, garage = ?, depotprice = ? WHERE plate = ? AND state = 0',
                {Config.StorageType or "insuransi", Config.DepotPrice, plate}
            )
            if result > 0 then
                DeleteEntity(vehicle)
                impounded = impounded + 1
            end
        end
    end
end)

-- Event untuk server restart - impound semua kendaraan yang state = 0 (di dunia)
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    if not Config.RestartMessage then
        print("[ERROR] Config.RestartMessage tidak ditemukan! Pastikan config.lua termuat dengan benar.")
        return
    end
    
    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent('chat:clear', playerId)
        TriggerClientEvent('chat:addMessage', playerId, {
            template = '<div class="chat-message emergency">[EMERGENCY] 🚨 {0}</div>',
            args = { Config.RestartMessage }
        })
    end
    
    local result = MySQL.Sync.execute(
        'UPDATE player_vehicles SET state = 2, garage = ?, depotprice = ? WHERE state = 0',
        {Config.StorageType or "insuransi", Config.DepotPrice or 120}
    )
    
    if result > 0 then
        for _, playerId in ipairs(GetPlayers()) do
            TriggerClientEvent('chat:clear', playerId)
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 0, 0},
                multiline = true,
                template = '<div class="chat-message emergency">[EMERGENCY] 🚨 {0}</div>',
                args = {"Total " .. result .. " kendaraan telah diimpound saat restart!"}
            })
        end
        print(('[AUTO-IMPOUND] %d kendaraan telah di-impound karena server akan restart'):format(result))
    end
end)

-- Startup cleanup - impound kendaraan yang mungkin tertinggal dari restart sebelumnya
Citizen.CreateThread(function()
    Wait(10000)
    
    local result = MySQL.Sync.execute(
        'UPDATE player_vehicles SET state = 2, garage = ?, depotprice = ? WHERE state = 0',
        {Config.StorageType or "insuransi", Config.DepotPrice or 120}
    )
    
    if result > 0 then
        print(('[AUTO-IMPOUND] %d kendaraan telah di-impound karena server restart'):format(result))
    end
end)

-- /impoundall command to impound all unused vehicles
RegisterCommand("impoundall", function(source, args, rawCommand)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if source ~= 0 and (not Player or not QBCore.Functions.HasPermission(source, "admin")) then
        TriggerClientEvent('QBCore:Notify', source, "Kamu tidak memiliki izin untuk menggunakan perintah ini!", "error", 5000)
        return
    end
    
    local vehicles = GetAllVehicles()
    local count = 0
    local pending = 0
    
    for _, vehicle in ipairs(vehicles) do
        local plate = GetVehicleNumberPlateText(vehicle)
        local driver = GetPedInVehicleSeat(vehicle, -1)
        
        if plate and plate ~= "" and driver == 0 then
            plate = plate:gsub("%s+", "")
            pending = pending + 1
            MySQL.Async.execute("UPDATE player_vehicles SET state = 2, garage = 'insuransi', depotprice = ? WHERE plate = ?", {Config.DepotPrice, plate}, function(affectedRows)
                if affectedRows > 0 then
                    if DoesEntityExist(vehicle) then
                        DeleteEntity(vehicle)
                        count = count + 1
                        print("[AUTO-IMPOUND] Kendaraan dengan plat " .. plate .. " telah diimpound dengan biaya depot $" .. Config.DepotPrice)
                    end
                end
                pending = pending - 1
                if pending == 0 then
                    if source ~= 0 then
                        TriggerClientEvent('QBCore:Notify', source, count .. " kendaraan berhasil diimpound dengan biaya depot $" .. Config.DepotPrice .. "!", "success", 5000)
                    end
                end
            end)
        end
    end
    
    if pending == 0 then
        TriggerClientEvent('QBCore:Notify', source, "Tidak ada kendaraan yang harus diimpound!", "error", 5000)
    end
end, false)

local function SendWarningMessage(timeLeft)
    if not Config.WarningMessage then
        print("[ERROR] Config.WarningMessage tidak ditemukan! Pastikan config.lua termuat dengan benar.")
        return
    end

    local message = Config.WarningMessage:gsub("{time}", tostring(timeLeft))

    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent('chat:clear', playerId)

        TriggerClientEvent('chat:addMessage', playerId, {
            template = '<div class="chat-message emergency">[EMERGENCY] 🚨 {0}</div>',
            args = { message }
        })
    end
    Wait(1000)
end

-- Auto Impound Regular
CreateThread(function()
    while true do
        Wait((Config.ImpoundInterval - Config.CountdownTime) * 1000)

        for i = Config.CountdownTime, 1, -5 do
            SendWarningMessage(i)
            Wait(5000)
        end

        -- Proses impound kendaraan
        local vehicles = GetAllVehicles()
        local impounded = 0

        for _, vehicle in ipairs(vehicles) do
            local plate = GetVehicleNumberPlateText(vehicle)
            local driver = GetPedInVehicleSeat(vehicle, -1)
            if plate and plate ~= "" and driver == 0 then
                local result = MySQL.Sync.execute(
    'UPDATE player_vehicles SET state = 2, garage = ?, depotprice = ? WHERE plate = ? AND state = 0',
    				{Config.StorageType or "insuransi", Config.DepotPrice, plate}
				)
                if result > 0 then
                    DeleteEntity(vehicle)
                    impounded = impounded + 1
                end
            end
        end

        -- Kirim pesan total kendaraan yang diimpound
        for _, playerId in ipairs(GetPlayers()) do
            TriggerClientEvent('chat:clear', playerId)
            TriggerClientEvent('chat:addMessage', playerId, {
                template = '<div class="chat-message emergency">[EMERGENCY] 🚨 {0}</div>',
                args = { "Total " .. impounded .. " kendaraan telah diimpound!" }
            })
        end
        print(('[AUTO-IMPOUND] %d kendaraan telah berhasil di-impound'):format(impounded))
    end
end)

local function GetPlayerByCitizenID(citizenid)
    for _, playerId in ipairs(GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        if Player and Player.PlayerData.citizenid == citizenid then
            return Player
        end
    end
    return nil
end

RegisterNetEvent('qb-autoimpound:server:ReleaseVehicle', function(plate, model)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    MySQL.Async.fetchAll('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
        if result and result[1] then
            local vehicleProps = nil
            if result[1].mods and type(result[1].mods) == "string" then
                vehicleProps = json.decode(result[1].mods)
            elseif result[1].vehicle and type(result[1].vehicle) == "string" then
                local success, decodedVehicle = pcall(json.decode, result[1].vehicle)
                if success and type(decodedVehicle) == "table" then
                    vehicleProps = decodedVehicle
                end
            end
            
            if not vehicleProps then
                vehicleProps = {
                    model = model,
                    plate = plate
                }
            end
            
            MySQL.Async.execute('UPDATE player_vehicles SET state = 0, depotprice = 0 WHERE plate = ? AND state = 2', {plate}, function(rowsChanged)
                if rowsChanged > 0 then
                    TriggerClientEvent('qb-autoimpound:client:SpawnVehicle', src, {
                        plate = plate,
                        model = model or result[1].vehicle,
                        properties = vehicleProps
                    })
                else
                    TriggerClientEvent('QBCore:Notify', src, "Kendaraan ini sudah diambil atau tidak diimpound!", "error")
                end
            end)
        else
            TriggerClientEvent('QBCore:Notify', src, "Data kendaraan tidak ditemukan!", "error")
        end
    end)
end)

QBCore.Functions.CreateCallback('qb-autoimpound:server:GetImpoundedVehicles', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.Async.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ? AND state = 2', {citizenid}, function(result)
        local vehicles = {}

        for _, v in pairs(result) do
            local vehicleModel = v.vehicle
            local vehicleProps = nil
            
            -- Try to get vehicle properties from mods or vehicle field if they contain JSON
            if v.mods and type(v.mods) == "string" then
                local success, decoded = pcall(json.decode, v.mods)
                if success and type(decoded) == "table" then
                    vehicleProps = decoded
                end
            elseif v.vehicle and type(v.vehicle) == "string" then
                local success, decoded = pcall(json.decode, v.vehicle)
                if success and type(decoded) == "table" then
                    vehicleProps = decoded
                    vehicleModel = decoded.model or v.vehicle
                end
            end
            
            -- If we couldn't get vehicle properties, create a basic structure
            if not vehicleProps then
                vehicleProps = {
                    model = vehicleModel,
                    plate = v.plate
                }
            end
            
            table.insert(vehicles, {
                model = vehicleModel,
                plate = v.plate,
                properties = vehicleProps
            })
        end
        cb(vehicles)
    end)
end)


RegisterNetEvent('qb-autoimpound:server:SpawnImpoundedVehicle', function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    MySQL.Async.fetchAll('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
        if result[1] then
            local vehicleProps = nil
            local vehicleMods = nil
            
            -- Try to decode vehicle JSON if available
            if result[1].vehicle and type(result[1].vehicle) == "string" then
                local success, decoded = pcall(json.decode, result[1].vehicle)
                if success and type(decoded) == "table" then
                    vehicleProps = decoded
                end
            end
            
            -- Try to decode mods JSON if available
            if result[1].mods and type(result[1].mods) == "string" then
                local success, decoded = pcall(json.decode, result[1].mods)
                if success and type(decoded) == "table" then
                    vehicleMods = decoded
                end
            end
            
            -- Create default properties if needed
            if not vehicleProps then
                vehicleProps = {
                    model = result[1].vehicle,
                    plate = plate
                }
            end
            
            if not vehicleMods then
                vehicleMods = {}
            end

            TriggerClientEvent('qb-autoimpound:client:SpawnVehicle', src, vehicleProps, vehicleMods)
            MySQL.Async.execute('UPDATE player_vehicles SET state = 0, depotprice = 0 WHERE plate = ?', {plate})
        else
            print("⚠️ ERROR: Kendaraan tidak ditemukan di database untuk plate:", plate)
        end
    end)
end)

--Added event for player remove money from taking vehicle in impound
RegisterNetEvent("qb-autoimpound:server:RemoveMoney", function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        Player.Functions.RemoveMoney("cash", amount, "Impound Retrieval")
    end
end)

print("qb-autoimpound Loaded! Made By Nafzz")


