Config = Config or {}

-- Jenis penyimpanan kendaraan + biaya
Config.StorageType = "insuransi"
Config.ImpoundRetrievalFee = 500

-- Pengaturan Interval Impound
Config.ImpoundInterval = 60 * 1000 -- 1 menit dalam milidetik
Config.CountdownTime = 30 -- Countdown sebelum impound (dalam detik)

-- Pesan peringatan
Config.WarningMessage = "Kendaraan akan diimpound dalam {time} detik!"
Config.RestartMessage = "🛠 Server akan restart! Semua kendaraan di luar garasi akan diimpound..."

Config.InsuranceGarage = {
    x = 265.41, y = 2600.35, z = 44.78, h = 275.0,
    spawnPoint = vector4(252.39, 2602.05, 44.92, 275.0)
}
