Config = {}

-- Radio settings
Config.RadioChannels = {
    -- Police channels
    [1] = { name = "Police Main", jobs = {"police"} },
    [2] = { name = "Police Tac", jobs = {"police"} },
    [3] = { name = "Police Command", jobs = {"police"} },
    
    -- EMS channels
    [4] = { name = "EMS Main", jobs = {"ambulance"} },
    [5] = { name = "EMS Emergency", jobs = {"ambulance"} },
    
    -- Gang channels (example)
    [100] = { name = "Gang Channel", jobs = {"gang"} },
    [101] = { name = "Mafia Channel", jobs = {"mafia"} },
    
    -- Public channels
    [911] = { name = "Emergency", jobs = {"police", "ambulance"} },
}

-- UI Settings
Config.UISettings = {
    position = "top-right", -- top-left, top-right, bottom-left, bottom-right
    showOnRadioUse = true,  -- Show UI when someone uses radio
    autoHide = true,        -- Auto hide after radio use
    autoHideDelay = 3000,   -- Auto hide delay in ms
    maxDisplayUsers = 10,   -- Maximum users to display
}

-- Key bindings
Config.Keys = {
    toggleRadioList = 'F9', -- Key to toggle radio list
}

-- Job permissions
Config.JobPermissions = {
    police = {
        canSeeAll = true,      -- Can see all radio users
        channels = {1, 2, 3, 911}
    },
    ambulance = {
        canSeeAll = true,
        channels = {4, 5, 911}
    },
    gang = {
        canSeeAll = false,     -- Can only see same gang members
        channels = {100}
    },
    mafia = {
        canSeeAll = false,
        channels = {101}
    },
    -- Allow unemployed/civilian for testing
    unemployed = {
        canSeeAll = true,
        channels = {1, 2, 3, 4, 5, 100, 101, 911}
    },
    civilian = {
        canSeeAll = true,
        channels = {1, 2, 3, 4, 5, 100, 101, 911}
    }
}

-- Visual settings
Config.Visual = {
    showSpeakingIndicator = true,  -- Show when someone is speaking
    showChannelName = true,        -- Show channel name in UI
    showPlayerDistance = true,     -- Show distance to other players
    speakingColor = "#00ff00",     -- Color when speaking
    normalColor = "#ffffff",       -- Normal color
}
