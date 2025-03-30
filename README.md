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

### 🚘 **Accurate Vehicle Restoration**
- When retrieving an impounded vehicle, it **spawns at a designated location** based on database records.
- Vehicle properties such as **modifications, colors, and customizations** are correctly applied to ensure the vehicle appears exactly as it was before impound.

### 🔄 **Persistent Impound on Server Restart**
- After a **server restart**, all unused vehicles are automatically **sent to the impound garage**, preventing abandoned vehicles from cluttering the world.

---

🎮 Take your **FiveM server** to the next level with `qb-autoimpound` and ensure proper vehicle management! 🚀

