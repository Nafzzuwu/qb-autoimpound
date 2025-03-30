QBCore = exports['qb-core']:GetCoreObject()

function SetVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) then return end
    QBCore.Functions.SetVehicleProperties(vehicle, props)
end

RegisterNetEvent('qb-autoimpound:spawnVehicle')
AddEventHandler('qb-autoimpound:spawnVehicle', function(plate, vehicleProps, garage)
    if not vehicleProps or not vehicleProps.model then return end

    local model = GetHashKey(vehicleProps.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end

    local spawnPoint = vector4(266.0, 2599.5, 44.75, 90.0)
    local veh = CreateVehicle(model, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, false)

    if DoesEntityExist(veh) then
        SetVehicleProperties(veh, vehicleProps)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    end
end)

RegisterNetEvent('qb-autoimpound:requestRetrieveVehicle', function()
    TriggerServerEvent('qb-autoimpound:retrieveVehicle')
end)


RegisterNetEvent('qb-autoimpound:fetchImpoundedVehicles', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local vehicles = MySQL.query.await('SELECT * FROM player_vehicles WHERE garage = ?', {"insuransi"})
    TriggerClientEvent('qb-garages:openImpoundMenu', src, vehicles)
end)

RegisterNetEvent('qb-autoimpound:requestRetrieveVehicle', function()
    TriggerServerEvent('qb-autoimpound:retrieveVehicle')
end)

RegisterNetEvent('qb-autoimpound:client:SpawnVehicle', function(vehicleData)
    -- Pastikan vehicleData.model ada
    if not vehicleData or not vehicleData.model then
        print("❌ Data kendaraan tidak valid:", json.encode(vehicleData or {})) -- DEBUG
        return QBCore.Functions.Notify("Data kendaraan tidak valid!", "error")
    end

    -- Pastikan kita punya properti untuk kendaraan
    if not vehicleData.properties then
        print("❌ Tidak ada properti kendaraan!") -- DEBUG
        vehicleData.properties = {}
    end

    QBCore.Functions.SpawnVehicle(vehicleData.model, function(veh)
        if veh then
            -- Set plate kendaraan
            SetVehicleNumberPlateText(veh, vehicleData.plate)
            SetEntityCoords(veh, Config.InsuranceGarage.spawnPoint.xyz)
            SetEntityHeading(veh, Config.InsuranceGarage.spawnPoint.w)
            
            -- Masukkan pemain ke kendaraan
            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", vehicleData.plate)

            -- Terapkan properti kendaraan
            print("🔹 Menerapkan properti kendaraan:", json.encode(vehicleData.properties)) -- DEBUG
            QBCore.Functions.SetVehicleProperties(veh, vehicleData.properties)

            QBCore.Functions.Notify("Kendaraan telah diambil dari garasi asuransi!", "success")
        else
            QBCore.Functions.Notify("Gagal men-spawn kendaraan.", "error")
        end
    end, Config.InsuranceGarage.spawnPoint, true)
end)



-- Tambahkan event untuk membuka menu garasi asuransi saat menekan E
CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local garageCoords = vector3(Config.InsuranceGarage.x, Config.InsuranceGarage.y, Config.InsuranceGarage.z)
        
        if #(playerCoords - garageCoords) < 2.0 then
            DrawText3D(Config.InsuranceGarage.x, Config.InsuranceGarage.y, Config.InsuranceGarage.z + 0.5, "[E] Buka Garasi Asuransi")
            if IsControlJustReleased(0, 38) then -- Key E
                TriggerEvent('qb-autoimpound:client:OpenInsuranceGarage')
            end
        end
    end
end)

RegisterNetEvent('qb-autoimpound:client:OpenInsuranceGarage', function()
    local vehicles = {
        {
            header = "Garasi Asuransi",
            isMenuHeader = true
        }
    }
    
    QBCore.Functions.TriggerCallback('qb-autoimpound:server:GetImpoundedVehicles', function(impoundedVehicles)
        if #impoundedVehicles == 0 then
            QBCore.Functions.Notify("Tidak ada kendaraan di garasi asuransi!", "error")
            return
        end
        
        for _, v in pairs(impoundedVehicles) do
            print("🔹 Menambahkan kendaraan ke menu:", v.model, v.plate) -- DEBUG
            
            vehicles[#vehicles + 1] = {
                header = v.model .. " - " .. v.plate,
                txt = "Ambil Kendaraan",
                params = {
                    event = "qb-autoimpound:client:TakeVehicle", -- Perbaiki event di sini
                    args = { plate = v.plate, model = v.model }
                }
            }
        end
        
        vehicles[#vehicles + 1] = {
            header = "Tutup Menu",
            params = { event = "qb-menu:closeMenu" }
        }
        
        print("🔹 Membuka menu garasi asuransi") -- DEBUG
        exports['qb-menu']:openMenu(vehicles)
    end)
end)

RegisterNetEvent("qb-autoimpound:client:TakeVehicle", function(vehicleData)
    if not vehicleData or not vehicleData.plate then
        print("❌ Data kendaraan tidak valid:", json.encode(vehicleData)) -- DEBUG
        return
    end

    print("🔹 Mengambil kendaraan dari garasi:", vehicleData.plate, vehicleData.model) -- DEBUG
    TriggerServerEvent("qb-autoimpound:server:ReleaseVehicle", vehicleData.plate, vehicleData.model)
end)


-- Fungsi untuk menampilkan teks di layar
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end