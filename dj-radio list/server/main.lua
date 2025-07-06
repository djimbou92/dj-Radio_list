local QBCore = exports['qb-core']:GetCoreObject()
local radioUsers = {}
local speakingUsers = {}

-- Player joins radio channel
RegisterNetEvent('dj-radio:server:joinChannel', function(channel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local playerJob = Player.PlayerData.job.name
    
    -- Check if player has permission for this channel
    local hasPermission = false
    local channelInfo = Config.RadioChannels[channel]
    
    if channelInfo then
        for _, job in pairs(channelInfo.jobs) do
            if job == playerJob then
                hasPermission = true
                break
            end
        end
    else
        -- Allow any channel if not specifically configured
        hasPermission = true
    end
    
    if not hasPermission then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to join this radio channel!', 'error')
        return
    end
    
    -- Add player to radio users
    radioUsers[src] = {
        name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        job = playerJob,
        channel = channel,
        coords = GetEntityCoords(GetPlayerPed(src))
    }
    
    -- Update all clients on the same channel
    UpdateChannelUsers(channel)
    
    print(string.format("[DJ-Radio] %s joined channel %d", radioUsers[src].name, channel))
end)

-- Player leaves radio channel
RegisterNetEvent('dj-radio:server:leaveChannel', function()
    local src = source
    
    if radioUsers[src] then
        local channel = radioUsers[src].channel
        radioUsers[src] = nil
        speakingUsers[src] = nil
        
        -- Update all clients on the channel
        UpdateChannelUsers(channel)
        
        print(string.format("[DJ-Radio] Player %d left channel %d", src, channel))
    end
end)

-- Player starts speaking
RegisterNetEvent('dj-radio:server:startSpeaking', function()
    local src = source
    
    if radioUsers[src] then
        speakingUsers[src] = true
        local channel = radioUsers[src].channel
        
        -- Notify all clients on the same channel
        for playerId, userData in pairs(radioUsers) do
            if userData.channel == channel then
                TriggerClientEvent('dj-radio:client:speaking', playerId, src, true)
            end
        end
        
        -- Show radio list to all users on channel
        for playerId, userData in pairs(radioUsers) do
            if userData.channel == channel then
                TriggerClientEvent('dj-radio:client:showOnUse', playerId, src)
            end
        end
    end
end)

-- Player stops speaking
RegisterNetEvent('dj-radio:server:stopSpeaking', function()
    local src = source
    
    if radioUsers[src] then
        speakingUsers[src] = nil
        local channel = radioUsers[src].channel
        
        -- Notify all clients on the same channel
        for playerId, userData in pairs(radioUsers) do
            if userData.channel == channel then
                TriggerClientEvent('dj-radio:client:speaking', playerId, src, false)
            end
        end
    end
end)

-- Update coordinates periodically
Citizen.CreateThread(function()
    while true do
        for playerId, userData in pairs(radioUsers) do
            if GetPlayerPed(playerId) ~= 0 then
                userData.coords = GetEntityCoords(GetPlayerPed(playerId))
            end
        end
        
        Citizen.Wait(5000) -- Update every 5 seconds
    end
end)

-- Functions
function UpdateChannelUsers(channel)
    local channelUsers = {}
    
    for playerId, userData in pairs(radioUsers) do
        if userData.channel == channel then
            channelUsers[playerId] = userData
        end
    end
    
    -- Send updated list to all users on this channel
    for playerId, userData in pairs(radioUsers) do
        if userData.channel == channel then
            TriggerClientEvent('dj-radio:client:updateUsers', playerId, channelUsers)
        end
    end
end

-- Player disconnected
RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    if radioUsers[src] then
        local channel = radioUsers[src].channel
        radioUsers[src] = nil
        speakingUsers[src] = nil
        UpdateChannelUsers(channel)
    end
end)

-- Resource stop cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        radioUsers = {}
        speakingUsers = {}
    end
end)

-- Admin commands
QBCore.Commands.Add('radiolist', 'Toggle radio list (Admin)', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "police" or Player.PlayerData.job.name == "ambulance" then
        TriggerClientEvent('dj-radio:client:updateChannel', source, 0)
    end
end, 'admin')

-- Debug command
QBCore.Commands.Add('radiodebug', 'Debug radio users (Admin)', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == "police" or Player.PlayerData.job.name == "ambulance" then
        print("=== RADIO DEBUG ===")
        for playerId, userData in pairs(radioUsers) do
            print(string.format("Player %d: %s (Job: %s, Channel: %d)", playerId, userData.name, userData.job, userData.channel))
        end
        print("=== END DEBUG ===")
    end
end, 'admin')
