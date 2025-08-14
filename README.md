# 🚗 qb-autoimpound

`qb-autoimpound` is a **FiveM script** built for the **QBCore Framework**, designed to enhance vehicle management by providing both **automatic** and **manual impounding** systems. This script ensures that abandoned or unused vehicles are seamlessly transferred to an **impound garage** or **insurance garage**, requiring players to visit a specific location to retrieve their vehicles.

---

## 🔥 Features

### 🛠️ **Automatic Impound System**

- Unused or abandoned vehicles are **automatically sent to the impound garage** after a set period.
- The server can be configured to **impound vehicles at scheduled intervals** (e.g., every **30 minutes**).
- Players receive a **countdown notification** (e.g., **100 seconds before impound execution**), providing them with a chance to reclaim their vehicles.

### 👮 **Manual Impounding**

- **Admins or police officers** can manually impound vehicles using a command or interactive menu.
- Once impounded, vehicles are locked in the **designated impound garage** and cannot be retrieved through standard means.

### 🎮 **Realistic Impound Garage Interaction**

- Players must **physically visit the impound/insurance garage** to retrieve their vehicles.
- Simple **"E" key interaction** to open the **impound garage menu**, eliminating the need for `qb-target`.
- If no vehicles are available, players receive a **clear notification**:
  > "Your vehicle is not in the insurance garage."
<img width="252" height="181" alt="peview" src="https://github.com/user-attachments/assets/3771e4b2-cf40-4744-96bd-9259b153a2f6" />


### 🚘 **Accurate Vehicle Restoration**

- When retrieving an impounded vehicle, it **spawns at a designated location** based on database records.
- Vehicle properties such as **modifications, colors, and customizations** are correctly applied to ensure the vehicle appears exactly as it was before impound.

---

## 📌 Installation

### 🔹 **Rename Downloaded Files**

After downloading the zip file, rename it to **``qb-autoimpound``** before adding it to your resource server. and this code has been made in Indonesian, you can change the language according to your language in the notify code and others.

### 🔹 **Write In Your server.cfg**

Don't forget to **``ensure qb-autoimpound``** in your server.

### 🗺️ **Adding a Blip for the Insurance Garage**

To display a **blip on the map** for the insurance garage location, add the following configuration on your **``qb-garages/config.lua``**, you can change if you want to locate in another place in your server!

```lua
insuransi = {
    label = "Insurance Garage",
    type = "impound",  -- Impound garage type
    job = false,  -- No specific job required
    takeVehicle = vector3(265.41, 2600.35, 44.78),
    coords = vector3(265.41, 2600.35, 44.78),  -- Change according to the desired location
    spawnPoint = {
        vector4(252.39, 2602.05, 44.92, 275.0)  -- Vehicle spawn location after retrieval
    },
    showBlip = true,
    blipName = 'Insurance',
    blipNumber = 357,
    blipColor = 1,
    blipScale = 1.5,
    category = Config.VehicleClass['all']
}
```

### 🔄 **Make It Works Impound on Server Restart**

- You need comment this in **``qb-garages/server/main.lua``**
  ```lua
    AddEventHandler('onResourceStart', function(resource)
      if resource == GetCurrentResourceName() then
          Wait(100)
          if Config['AutoRespawn'] then
              MySQL.update('UPDATE player_vehicles SET state = 1 WHERE state = 0', {})
          else
              MySQL.update('UPDATE player_vehicles SET depotprice = 500 WHERE state = 0', {})
          end
      end
  end)
- Make sure in **``qb-garages/config.lua``**
  ```lua
  Config.AutoRespawn = false
- After a **server restart**, all unused vehicles are automatically **sent to the impound garage**, preventing abandoned vehicles from cluttering the world.
---
🎮 Take your **FiveM server** to the next level with `qb-autoimpound` and ensure proper vehicle management! 🚀

