# GuusLegacyManager

GuusLegacyManager is a World of Warcraft addon designed to help players manage legacy raid and dungeon content more efficiently. It provides tools and features to track progress, organize groups, and streamline the experience for 10-man raid events.

## Features

* Hire legacy companions (Lites) to assist in raids
* Raid tracking options: refresh On login of character with a manual option available when hiring companions for example.
* option to enable / disable Raid tracking
* added icon on minimap
* Easy-to-use configuration

## Installation

1. Download the addon files.
2. Extract the contents to your World of Warcraft Add-ons directory:

   * Interface\\AddOns\\GuusLegacyManager

3. Restart World of Warcraft completely (do not just reload UI).

## Troubleshooting

### Common Issues:

1. **"\_G (a nil value)" error**:

   * This has been fixed in the latest version
   * Make sure you have the updated LibStub.lua file
   * Try disabling other addons temporarily

2. **"Global environment (\_G) not available"**:

   * Delete the addon folder and reinstall fresh
   * Make sure all files extracted correctly
   * Restart WoW completely (close and reopen)

3. **For Private Servers**:

   * Some private servers have different loading behaviors
   * Try placing the addon in a different load order
   * Check if the server requires specific interface versions

### Installation Steps:

1. Delete any existing GuusLegacyManager folder
2. Extract all files to Interface\\AddOns\\GuusLegacyManager
3. Ensure folder structure is correct (libs folder with 4 .lua files)
4. Restart WoW completely (not /reload UI)
5. Check addon list in-game to verify it's loaded

## 

