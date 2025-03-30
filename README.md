# Auto-Impond-System-QBCore-
qb-autoimpound is a FiveM script built for the QBCore Framework that manages the automatic and manual impounding of vehicles in the game. This script ensures that abandoned or unused vehicles are transferred to an impound garage or insurance garage, requiring players to visit a specific location to retrieve their vehicles.

🔹 Key Features of qb-autoimpound
1️⃣ Automatic Impound System
Vehicles that are left unused or abandoned for a certain period are automatically sent to the impound garage.

The server can be scheduled to impound vehicles at regular intervals (e.g., every 5 minutes).

Players receive a countdown notification before their vehicles are impounded, such as 100 seconds before impound execution.

2️⃣ Manual Impounding
Admins or police officers can manually impound vehicles using a command or menu.

Impounded vehicles are transferred to a specific garage and cannot be retrieved by conventional means.

3️⃣ Impound Garage Interaction with "E" Key
To retrieve an impounded vehicle, players must visit the impound/insurance garage.

Players can simply press the "E" key to open the impound garage menu, eliminating the need for qb-target.

If no vehicles are available, players receive a notification:
"Your vehicle is not in the insurance garage."

4️⃣ Proper Vehicle Spawning with Saved Data
When a vehicle is retrieved from the impound garage, it spawns at a designated location based on database records.

Vehicle properties such as modifications, colors, and customizations are correctly restored upon spawning.

5️⃣ Impound Reset on Server Restart
Whenever the server restarts, all unused vehicles are automatically moved to the impound garage.

