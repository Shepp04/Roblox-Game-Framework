# 📦 DataManager

**DataManager** is a server-side module that handles player data in a Roblox game using **ProfileStore** and **ReplicatedData**. It provides a clean API to manage persistent profiles, synchronize data with clients, and modularly extend player data with additional sections.

This module is designed to be flexible, safe, and easy to extend across different systems like Daily Rewards, Stats, Inventory, etc.

---

## 🚀 Features

- Persistent data via ProfileStore
- Automatic syncing to clients using ReplicatedData
- Live player sessions with safe termination
- Modular **Reconciliation System** for adding new sections to player data without breaking old profiles

---

## 🧩 Understanding Reconciliation

Reconciliation ensures that a player's data always contains the required keys for a given system (e.g., `Data.DailyRewards`). This prevents runtime errors due to missing fields, especially when new systems are added after a profile has already been created.

### 🧠 Key Idea

Instead of assuming a section exists in `profile.Data`, **you register a section and template once**, and the system guarantees it will be there before other code uses it.

---

## 📘 API Documentation

### `DataManager:LoadPlayerProfile(player: Player): PlayerProfile?`

Loads a player’s persistent profile. Called on `PlayerAdded`. Also triggers reconciliation and replication.

### `DataManager:ReleasePlayerProfile(player: Player)`

Ends the player’s session, saving their profile and cleaning up connections. Should be called on `PlayerRemoving`.

---

### `DataManager:GetPlayerProfile(player: Player, yield: boolean?): PlayerProfile?`

Returns the full player profile (including `.Data` and `.Info`). If `yield` is true, it will wait until the profile has loaded.

### `DataManager:GetPlayerData(player: Player, yield: boolean?): table?`

Returns only the `.Data` section of the player’s profile. Useful for scripts that don’t need metadata.

---

### `DataManager:ResetData(player: Player): boolean`

Wipes and reinitializes the player's `.Data` table to the default template. Intended for dev/debug use.

---

## 🧩 Reconciliation API

### `DataManager:RegisterReconcileSection(sectionType: "Info" | "Data", sectionName: string, template: {})`

Registers a modular section to be reconciled into every player’s data upon login.

✅ Use this in feature modules (e.g., DailyRewards) to add your data structure safely.

```lua
DataManager:RegisterReconcileSection("Data", "DailyRewards", {
	LastClaim = 0,
	Streak = 0,
	ClaimedToday = false,
})
