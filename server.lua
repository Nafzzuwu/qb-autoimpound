QBCore = exports['qb-core']:GetCoreObject()


-- Configuration
Config = Config or {}
Config.ImpoundInterval = 1800 -- 5 minutes (in seconds)
Config.CountdownTime = 100 -- Countdown time before impound (in seconds)


-- /impoundall command to impound all unused vehicles
RegisterCommand("impoundall", function(source, args, rawCommand)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if source ~= 0 and (not Player or not QBCore.Functions.HasPermission(source, "admin")) then
        TriggerClientEvent('QBCore:Notify', source, "Kamu tidak memiliki izin untuk menggunakan perintah ini!", "error", 5000)
        return
    end

    local vehicles = GetAllVehicles()
    local count = 0
    local pending = 0 -- Untuk melacak jumlah operasi database yang sedang berlangsung

    for _, vehicle in ipairs(vehicles) do
        local plate = GetVehicleNumberPlateText(vehicle)
        local driver = GetPedInVehicleSeat(vehicle, -1)
        
        if plate and plate ~= "" and driver == 0 then
            plate = plate:gsub("%s+", "")
            pending = pending + 1 -- Tambahkan operasi yang sedang berlangsung

            MySQL.Async.execute("UPDATE player_vehicles SET state = 2, garage = 'insuransi' WHERE plate = ?", {plate}, function(affectedRows)
                if affectedRows > 0 then
                    if DoesEntityExist(vehicle) then
                        DeleteEntity(vehicle)
                        count = count + 1
                        print("[AUTO-IMPOUND] Kendaraan dengan plat " .. plate .. " telah diimpound.")
                    end
                end

                pending = pending - 1 -- Kurangi operasi yang sudah selesai
                if pending == 0 then -- Jika semua operasi selesai, kirim notifikasi
                    if source ~= 0 then
                        TriggerClientEvent('QBCore:Notify', source, count .. " kendaraan berhasil diimpound!", "success", 5000)
                    end
                end
            end)
        end
    end

    -- Jika tidak ada kendaraan yang perlu diimpound, langsung kirim notifikasi
    if pending == 0 then
        TriggerClientEvent('QBCore:Notify', source, "Tidak ada kendaraan yang bisa diimpound!", "error", 5000)
    end
end, false)


-- Fungsi untuk mengirim peringatan ke semua pemain melalui chat darurat
local function SendWarningMessage(timeLeft)
    if not Config.WarningMessage then
        print("[ERROR] Config.WarningMessage tidak ditemukan! Pastikan config.lua termuat dengan benar.")
        return
    end

    local message = Config.WarningMessage:gsub("{time}", tostring(timeLeft))

    -- Hapus pesan sebelumnya sebelum menampilkan yang baru
    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent('chat:clear', playerId) -- Bersihkan chat sebelumnya
        TriggerClientEvent('chat:addMessage', playerId, {
            color = {255, 0, 0}, -- Warna merah
            multiline = true,
            args = {"[EMERGENCY] 🚨", message}
        })
    end

    -- Tunggu 1 detik lalu hilangkan pesan secara otomatis (fade-out cepat)
    Wait(1000)
end

-- Auto Impound Regular
CreateThread(function()
    while true do
        Wait((Config.ImpoundInterval - Config.CountdownTime) * 1000) -- Mulai hitungan mundur

        for i = Config.CountdownTime, 1, -5 do -- Menampilkan pesan setiap 5 detik
            SendWarningMessage(i)
            Wait(5000) -- Tunggu 5 detik sebelum pesan baru muncul
        end

        -- Proses impound kendaraan
        local vehicles = GetAllVehicles()
        local impounded = 0

        for _, vehicle in ipairs(vehicles) do
            local plate = GetVehicleNumberPlateText(vehicle)
            local driver = GetPedInVehicleSeat(vehicle, -1)
            if plate and plate ~= "" and driver == 0 then
                local result = MySQL.Sync.execute(
                    'UPDATE player_vehicles SET state = 2, garage = ? WHERE plate = ? AND state = 0',
                    {Config.StorageType, plate}
                )
                if result > 0 then
                    DeleteEntity(vehicle)
                    impounded = impounded + 1
                end
            end
        end

        -- Kirim pesan total kendaraan yang diimpound
        for _, playerId in ipairs(GetPlayers()) do
            TriggerClientEvent('chat:clear', playerId) -- Bersihkan chat sebelumnya
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 0, 0},
                multiline = true,
                args = {"[EMERGENCY] 🚨", "Total " .. impounded .. " kendaraan telah diimpound!"}
            })
        end
        print(('[AUTO-IMPOUND] %d kendaraan telah berhasil di-impound'):format(impounded))
    end
end)

-- Impound saat restart
-- Impound kendaraan saat server restart
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Pastikan Config.RestartMessage tersedia
    if not Config.RestartMessage then
        print("[ERROR] Config.RestartMessage tidak ditemukan! Pastikan config.lua termuat dengan benar.")
        return
    end

    -- Kirim pesan peringatan restart ke semua pemain
    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent('chat:clear', playerId) -- Bersihkan chat sebelumnya
        TriggerClientEvent('chat:addMessage', playerId, {
            color = {255, 0, 0}, -- Warna merah
            multiline = true,
            args = {"[EMERGENCY] 🚨", Config.RestartMessage}
        })
    end

    -- Tunggu 5 detik sebelum mulai impound kendaraan
    Wait(2000)

    local vehicles = GetAllVehicles()
    local impounded = 0

    for _, vehicle in ipairs(vehicles) do
        local plate = GetVehicleNumberPlateText(vehicle)
        local driver = GetPedInVehicleSeat(vehicle, -1)

        -- Impound hanya jika kendaraan tidak dikendarai pemain
        if plate and plate ~= "" and driver == 0 then
            local result = MySQL.Sync.execute(
                'UPDATE player_vehicles SET state = 2, garage = ? WHERE plate = ? AND state = 0',
                {Config.StorageType, plate}
            )
            if result > 0 then
                DeleteEntity(vehicle)
                impounded = impounded + 1
            end
        end
    end

    -- Kirim pesan jumlah kendaraan yang diimpound ke semua pemain
    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent('chat:clear', playerId) -- Bersihkan chat sebelumnya
        TriggerClientEvent('chat:addMessage', playerId, {
            color = {255, 0, 0},
            multiline = true,
            args = {"[EMERGENCY] 🚨", "Total " .. impounded .. " kendaraan telah diimpound saat restart!"}
        })
    end

    print(('[AUTO-IMPOUND] %d kendaraan telah di-impound karena server restart'):format(impounded))
end)

---
local function GetPlayerByCitizenID(citizenid)
    for _, playerId in ipairs(GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        if Player and Player.PlayerData.citizenid == citizenid then
            return Player
        end
    end
    return nil
end


-- Mengeluarkan kendaraan dari impound
RegisterNetEvent('qb-autoimpound:server:ReleaseVehicle', function(plate, model)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    MySQL.Async.fetchAll('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
        if result and result[1] then
            -- Check if mods exists and is a valid JSON string
            local vehicleProps = nil
            if result[1].mods and type(result[1].mods) == "string" then
                vehicleProps = json.decode(result[1].mods)
            elseif result[1].vehicle and type(result[1].vehicle) == "string" then
                -- Try to use vehicle field if it contains JSON data
                local success, decodedVehicle = pcall(json.decode, result[1].vehicle)
                if success and type(decodedVehicle) == "table" then
                    vehicleProps = decodedVehicle
                end
            end
            
            -- If we couldn't get vehicle properties, create a basic structure
            if not vehicleProps then
                vehicleProps = {
                    model = model,
                    plate = plate
                }
            end
            
            -- Pastikan kendaraan hanya diubah statusnya jika masih diimpound
            MySQL.Async.execute('UPDATE player_vehicles SET state = 0 WHERE plate = ? AND state = 2', {plate}, function(rowsChanged)
                if rowsChanged > 0 then
                    -- Kirim data kendaraan ke client untuk di-spawn
                    TriggerClientEvent('qb-autoimpound:client:SpawnVehicle', src, {
                        plate = plate,
                        model = model or result[1].vehicle, -- Use model from argument or fallback to db value
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
            MySQL.Async.execute('UPDATE player_vehicles SET state = 0 WHERE plate = ?', {plate})
        else
            print("⚠️ ERROR: Kendaraan tidak ditemukan di database untuk plate:", plate)
        end
    end)
end)

