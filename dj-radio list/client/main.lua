local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isLoggedIn = false
local currentRadioChannel = 0
local radioListVisible = false
local radioUsers = {}
local speakingUsers = {}

-- Initialize
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

-- Radio channel update
RegisterNetEvent('dj-radio:client:updateChannel', function(channel)
    currentRadioChannel = channel
    print("[DJ-Radio] Channel updated to: " .. channel)
    
    if channel > 0 then
        TriggerServerEvent('dj-radio:server:joinChannel', channel)
        QBCore.Functions.Notify('Joined radio channel ' .. channel, 'success')
    else
        TriggerServerEvent('dj-radio:server:leaveChannel')
        QBCore.Functions.Notify('Left radio channel', 'error')
    end
    UpdateRadioList()
end)

-- Radio users update
RegisterNetEvent('dj-radio:client:updateUsers', function(users)
    radioUsers = users
    UpdateRadioList()
end)

-- Speaking indicator
RegisterNetEvent('dj-radio:client:speaking', function(playerId, speaking)
    if speaking then
        speakingUsers[playerId] = true
    else
        speakingUsers[playerId] = nil
    end
    UpdateSpeakingIndicators()
end)

-- Toggle radio list
RegisterCommand('radiolist', function()
    ToggleRadioList()
end)

-- Debug command
RegisterCommand('radiodebugclient', function()
    print("=== DJ-RADIO CLIENT DEBUG ===")
    print("Current Channel: " .. currentRadioChannel)
    print("Player Job: " .. (PlayerData.job and PlayerData.job.name or "unemployed"))
    print("Is Logged In: " .. tostring(isLoggedIn))
    print("Radio Users Count: " .. #radioUsers)
    print("Radio List Visible: " .. tostring(radioListVisible))
    
    -- Try to get current radio frequency from LocalPlayer.state
    if LocalPlayer.state.radioChannel then
        print("PMA-Voice Current Frequency: " .. LocalPlayer.state.radioChannel)
    else
        print("PMA-Voice Current Frequency: None")
    end
    
    for playerId, userData in pairs(radioUsers) do
        print("User " .. playerId .. ": " .. userData.name .. " (Channel: " .. userData.channel .. ")")
    end
    print("=== END DEBUG ===")
end)

-- Sync with current radio frequency
RegisterCommand('radiosync', function()
    if LocalPlayer.state.radioChannel then
        local currentFreq = LocalPlayer.state.radioChannel
        TriggerEvent('dj-radio:client:updateChannel', currentFreq)
        QBCore.Functions.Notify('Synced with radio frequency: ' .. currentFreq, 'success')
    else
        QBCore.Functions.Notify('No radio frequency detected', 'error')
    end
end)

-- Test speaking indicator
RegisterCommand('radiotalk', function()
    print("[DJ-Radio] Testing speaking indicator")
    TriggerServerEvent('dj-radio:server:startSpeaking')
    TriggerEvent('dj-radio:client:showOnUse', GetPlayerServerId(PlayerId()))
    
    -- Stop speaking after 3 seconds
    Citizen.SetTimeout(3000, function()
        TriggerServerEvent('dj-radio:server:stopSpeaking')
    end)
end)

-- Key mapping
RegisterKeyMapping('radiolist', 'Toggle Radio List', 'keyboard', Config.Keys.toggleRadioList)

-- Functions
function ToggleRadioList()
    if not isLoggedIn then return end
    
    radioListVisible = not radioListVisible
    
    if radioListVisible then
        UpdateRadioList()
        SendNUIMessage({
            action = "show"
        })
    else
        SendNUIMessage({
            action = "hide"
        })
    end
end

function UpdateRadioList()
    if not radioListVisible then return end
    
    local displayUsers = {}
    local playerJob = PlayerData.job and PlayerData.job.name or "unemployed"
    
    -- Check if player has permission to see radio list
    if not Config.JobPermissions[playerJob] then
        return
    end
    
    -- Get channel info
    local channelInfo = Config.RadioChannels[currentRadioChannel]
    local channelName = channelInfo and channelInfo.name or "Channel " .. currentRadioChannel
    
    -- Process radio users
    for playerId, userData in pairs(radioUsers) do
        if userData.channel == currentRadioChannel then
            local canSee = false
            
            -- Check permissions
            if Config.JobPermissions[playerJob].canSeeAll then
                canSee = true
            elseif userData.job == playerJob then
                canSee = true
            end
            
            if canSee then
                local distance = 0
                if Config.Visual.showPlayerDistance then
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local targetCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerId)))
                    distance = #(playerCoords - targetCoords)
                end
                
                table.insert(displayUsers, {
                    id = playerId,
                    name = userData.name,
                    job = userData.job,
                    distance = math.floor(distance),
                    speaking = speakingUsers[playerId] or false
                })
            end
        end
    end
    
    -- Sort by distance
    table.sort(displayUsers, function(a, b)
        return a.distance < b.distance
    end)
    
    -- Limit display
    if #displayUsers > Config.UISettings.maxDisplayUsers then
        for i = Config.UISettings.maxDisplayUsers + 1, #displayUsers do
            displayUsers[i] = nil
        end
    end
    
    SendNUIMessage({
        action = "updateList",
        data = {
            channel = currentRadioChannel,
            channelName = channelName,
            users = displayUsers,
            showDistance = Config.Visual.showPlayerDistance,
            showChannelName = Config.Visual.showChannelName
        }
    })
end

function UpdateSpeakingIndicators()
    if not radioListVisible then return end
    
    SendNUIMessage({
        action = "updateSpeaking",
        data = {
            speakingUsers = speakingUsers
        }
    })
end

-- Show radio list temporarily when someone uses radio
RegisterNetEvent('dj-radio:client:showOnUse', function(playerId)
    if not Config.UISettings.showOnRadioUse then return end
    
    if not radioListVisible then
        SendNUIMessage({
            action = "showTemporary"
        })
        UpdateRadioList()
        
        if Config.UISettings.autoHide then
            SetTimeout(Config.UISettings.autoHideDelay, function()
                if not radioListVisible then
                    SendNUIMessage({
                        action = "hide"
                    })
                end
            end)
        end
    end
end)

-- Monitor radio usage (hook into pma-voice events)
RegisterNetEvent('pma-voice:radioActive', function(talking)
    if talking then
        TriggerServerEvent('dj-radio:server:startSpeaking')
    else
        TriggerServerEvent('dj-radio:server:stopSpeaking')
    end
    
    -- Show radio list when using radio
    if talking then
        TriggerEvent('dj-radio:client:showOnUse', GetPlayerServerId(PlayerId()))
    end
end)

-- Additional pma-voice radio talking events
RegisterNetEvent('pma-voice:setTalkingOnRadio', function(talking)
    if talking then
        TriggerServerEvent('dj-radio:server:startSpeaking')
    else
        TriggerServerEvent('dj-radio:server:stopSpeaking')
    end
    
    if talking then
        TriggerEvent('dj-radio:client:showOnUse', GetPlayerServerId(PlayerId()))
    end
end)

-- Monitor radio talking with key detection
Citizen.CreateThread(function()
    while true do
        if currentRadioChannel > 0 then
            local isRadioPressed = IsControlPressed(0, 21) -- Left Alt
            local isRadioJustPressed = IsControlJustPressed(0, 21)
            local isRadioJustReleased = IsControlJustReleased(0, 21)
            
            if isRadioJustPressed then
                print("[DJ-Radio] Radio key pressed - starting speaking")
                TriggerServerEvent('dj-radio:server:startSpeaking')
                TriggerEvent('dj-radio:client:showOnUse', GetPlayerServerId(PlayerId()))
            elseif isRadioJustReleased then
                print("[DJ-Radio] Radio key released - stopping speaking")
                TriggerServerEvent('dj-radio:server:stopSpeaking')
            end
        end
        Citizen.Wait(0)
    end
end)

-- Monitor radio channel changes (hook into qb-radio or pma-voice)
RegisterNetEvent('pma-voice:setRadioChannel', function(channel)
    TriggerEvent('dj-radio:client:updateChannel', channel)
end)

-- Additional radio system hooks
RegisterNetEvent('qb-radio:onRadioJoin', function(channel)
    TriggerEvent('dj-radio:client:updateChannel', channel)
end)

RegisterNetEvent('qb-radio:onRadioLeave', function()
    TriggerEvent('dj-radio:client:updateChannel', 0)
end)

-- Hook into radio item usage
RegisterNetEvent('qb-radio:use', function(frequency)
    if frequency then
        TriggerEvent('dj-radio:client:updateChannel', frequency)
    end
end)

-- Hook into radio frequency changes
RegisterNetEvent('qb-radio:client:setRadioFrequency', function(frequency)
    TriggerEvent('dj-radio:client:updateChannel', frequency)
end)

-- Hook into radio joining/leaving
RegisterNetEvent('qb-radio:client:joinRadio', function(frequency)
    TriggerEvent('dj-radio:client:updateChannel', frequency)
end)

RegisterNetEvent('qb-radio:client:leaveRadio', function()
    TriggerEvent('dj-radio:client:updateChannel', 0)
end)

-- Hook into pma-voice radio events
RegisterNetEvent('pma-voice:radioChannelChanged', function(channel)
    TriggerEvent('dj-radio:client:updateChannel', channel)
end)

-- Monitor radio frequency in a loop
Citizen.CreateThread(function()
    local lastFreq = 0
    while true do
        -- Check if player has radio item and get frequency
        -- Use LocalPlayer.state for pma-voice radio channel
        if LocalPlayer.state.radioChannel then
            local currentFreq = LocalPlayer.state.radioChannel
            if currentFreq and currentFreq ~= lastFreq then
                lastFreq = currentFreq
                TriggerEvent('dj-radio:client:updateChannel', currentFreq)
                print("[DJ-Radio] Detected frequency change to: " .. currentFreq)
            end
        end
        Citizen.Wait(1000) -- Check every second
    end
end)

-- Manual channel set for testing
RegisterCommand('setradio', function(source, args)
    local channel = tonumber(args[1])
    if channel then
        TriggerEvent('dj-radio:client:updateChannel', channel)
        QBCore.Functions.Notify('Radio channel set to ' .. channel, 'success')
    else
        QBCore.Functions.Notify('Usage: /setradio [channel]', 'error')
    end
end)

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    radioListVisible = false
    SendNUIMessage({
        action = "hide"
    })
    cb('ok')
end)

-- Initialize on resource start
Citizen.CreateThread(function()
    if LocalPlayer.state.isLoggedIn then
        PlayerData = QBCore.Functions.GetPlayerData()
        isLoggedIn = true
    end
    
    -- Monitor LocalPlayer state changes for radio channel
    AddStateBagChangeHandler('radioChannel', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(bagName, key, value, reserved, replicated)
        if value and value ~= currentRadioChannel then
            print("[DJ-Radio] Radio channel changed via state: " .. value)
            TriggerEvent('dj-radio:client:updateChannel', value)
        elseif not value and currentRadioChannel ~= 0 then
            print("[DJ-Radio] Radio channel cleared via state")
            TriggerEvent('dj-radio:client:updateChannel', 0)
        end
    end)
    
    -- Monitor LocalPlayer state changes for radio talking
    AddStateBagChangeHandler('radioTalking', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(bagName, key, value, reserved, replicated)
        if value then
            print("[DJ-Radio] Radio talking started via state")
            TriggerServerEvent('dj-radio:server:startSpeaking')
            TriggerEvent('dj-radio:client:showOnUse', GetPlayerServerId(PlayerId()))
        else
            print("[DJ-Radio] Radio talking stopped via state")
            TriggerServerEvent('dj-radio:server:stopSpeaking')
        end
    end)
    
    -- Wait a bit then check if we need to auto-join a channel for testing
    Citizen.Wait(5000)
    if currentRadioChannel == 0 then
        -- Check if player already has a radio channel set
        if LocalPlayer.state.radioChannel then
            print("[DJ-Radio] Found existing radio channel: " .. LocalPlayer.state.radioChannel)
            TriggerEvent('dj-radio:client:updateChannel', LocalPlayer.state.radioChannel)
        else
            -- Auto-join channel 1 for testing if no channel is set
            print("[DJ-Radio] Auto-joining channel 1 for testing")
            TriggerEvent('dj-radio:client:updateChannel', 1)
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if isLoggedIn then
            TriggerServerEvent('dj-radio:server:leaveChannel')
        end
    end
end)
