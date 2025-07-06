# DJ Radio List

A comprehensive radio list system for QBCore that displays who's on the radio with visual indicators.

## Features

- **Visual Radio List**: Shows all users on the same radio channel
- **Speaking Indicators**: Visual indicators when someone is speaking
- **Job-Based Permissions**: Different permissions for police, EMS, and gangs
- **Distance Display**: Shows distance to other radio users
- **Auto-Show**: Automatically shows when someone uses radio
- **Modern UI**: Clean, responsive interface with animations

## Installation

1. Place the `dj-radio` folder in your resources directory
2. Add `ensure dj-radio` to your server.cfg
3. Configure the settings in `config.lua`

## Configuration

### Radio Channels
Edit `config.lua` to configure radio channels:
```lua
Config.RadioChannels = {
    [1] = { name = "Police Main", jobs = {"police"} },
    [2] = { name = "Police Tac", jobs = {"police"} },
    [4] = { name = "EMS Main", jobs = {"ambulance"} },
    -- Add more channels as needed
}
```

### Job Permissions
Configure who can see what:
```lua
Config.JobPermissions = {
    police = {
        canSeeAll = true,      -- Can see all radio users
        channels = {1, 2, 3, 911}
    },
    ambulance = {
        canSeeAll = true,
        channels = {4, 5, 911}
    }
}
```

## Usage

- Press **F9** to toggle the radio list
- The list automatically shows when someone uses radio
- Speaking users are highlighted in green
- Distance to other users is displayed

## Commands

- `/radiolist` - Toggle radio list
- `/radiodebug` - Debug radio users (admin only)

## Dependencies

- qb-core
- pma-voice (for radio integration)

## Support

This script integrates with pma-voice for radio functionality. Make sure you have the latest version of pma-voice installed.

## License

Free to use and modify.
