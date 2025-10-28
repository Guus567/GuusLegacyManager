# Microbot_Guus_Legacy_Manager
## Features

- **Multi-Character Management**: Automatically tracks all characters across your account
- **Smart Role Selection**: Shows only appropriate roles based on character class
- **Legacy Command Generation**: Generates `.z addlegacy "CharacterName" role` commands
- **Clean Interface**: Intuitive GUI with color-coded role buttons
- **Cross-Character Persistence**: Character data persists across logins
- **Faction Display**: Shows Alliance/Horde indicators for each character

## Installation

1. Download the addon files
2. Extract to your `World of Warcraft/Interface/AddOns/` directory
3. Ensure the folder is named `GuusLegacyManager`
4. Restart World of Warcraft or reload UI (`/reload`)

## Commands

### Primary Commands
- `/legacy` or `/glm` - Open the character selection window
- `/legacy show` - Open the character selection window
- `/legacy menu` - Open the character selection window

### Management Commands
- `/legacy list` - Display all saved characters in chat
- `/legacy refresh` - Refresh the character list and update current character
- `/legacy clear` - Clear all saved character data
- `/legacy help` - Show available commands

## How to Use

### Basic Usage
1. Log into each character you want to track (only needs to be done once per character)
2. Use `/legacy` to open the character selection window
3. Click the appropriate role button next to any character name
4. The addon will execute: `.z addlegacy "CharacterName" role`
