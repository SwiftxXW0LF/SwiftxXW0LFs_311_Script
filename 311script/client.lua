`																	-- client.lua
local dotUnitBlips = {}
local callBlips    = {}
local isOnDuty     = false
local role         = 'civilian'

-- Debug helper
local function DebugLog(msg)
    if Config.DebugMode then
        print("^3[SADOT DEBUG]: " .. msg)
    end
end

-- Ask server for permissions on load
Citizen.CreateThread(function()
    TriggerServerEvent('sadot:checkPermissions')
end)

-- Handle permission result
RegisterNetEvent('sadot:permissionsResult')
AddEventHandler('sadot:permissionsResult', function(canDuty)
    role     = canDuty and 'dot' or 'civilian'
    isOnDuty = false
    SendNUIMessage({ type = 'Init', role = role, onDuty = isOnDuty })
end)

-- NUI → server callbacks
RegisterNUICallback('GetActiveCalls', function(_, cb)
    TriggerServerEvent('sadot:getActiveCalls')
    cb({ ok = true })
end)

RegisterNUICallback('SubmitCall', function(data, cb)
    TriggerServerEvent('sadot:SubmitCall', {
        postal   = data.postal,
        reason   = data.reason,
        photoUrl = data.photoUrl
    })
    cb({ ok = true })
end)

RegisterNUICallback('ToggleDuty', function(_, cb)
    ExecuteCommand('ondutydot')
    cb({ ok = true })
end)

RegisterNUICallback('OpenMDT', function(_, cb)
    TriggerServerEvent('sadot:openMDT')
    cb({ ok = true })
end)

RegisterNUICallback('AcceptCall', function(data, cb)
    TriggerServerEvent('sadot:AcceptCall', { callID = data.callID })
    cb({ ok = true })
end)

RegisterNUICallback('CompleteCall', function(data, cb)
    TriggerServerEvent('sadot:CompleteCall', { callID = data.callID })
    cb({ ok = true })
end)

RegisterNUICallback('UploadPhoto', function(data, cb)
    TriggerServerEvent('sadot:UploadPhoto', {
        callID   = data.callID,
        photoUrl = data.photoUrl
    })
    cb({ ok = true })
end)

RegisterNUICallback('CallCaller', function(data, cb)
    -- Attempt to call via your phone export
    if exports['lb-phone'] and exports['lb-phone'].CallNumber then
        exports['lb-phone']:CallNumber(data.phone)
    else
        TriggerEvent('phone:client:CallNumber', data.phone)
    end
    cb({ ok = true })
end)

-- Server → NUI updates
RegisterNetEvent('sadot:returnActiveCalls')
AddEventHandler('sadot:returnActiveCalls', function(calls)
    SendNUIMessage({ type = 'ReturnActiveCalls', calls = calls })
end)

RegisterNetEvent('sadot:updateCallAssignment')
AddEventHandler('sadot:updateCallAssignment', function(callID, assigned)
    SendNUIMessage({ type = 'UpdateAssignment', callID = callID, assigned = assigned })
end)

RegisterNetEvent('sadot:updateCallPhotos')
AddEventHandler('sadot:updateCallPhotos', function(callID, uploads)
    SendNUIMessage({ type = 'UpdateCallPhotos', callID = callID, uploads = uploads })
end)

-- Blip & duty handling
RegisterNetEvent('sadot:toggleDutyBlip')
AddEventHandler('sadot:toggleDutyBlip', function(playerId, onDuty)
    -- update own duty state
    if playerId == GetPlayerServerId(PlayerId()) then
        isOnDuty = onDuty
        SendNUIMessage({ type = 'DutyStatus', onDuty = isOnDuty })
    end

    -- skip own blip if configured
    if not Config.Blip.ShowOwnBlip and playerId == GetPlayerServerId(PlayerId()) then
        return
    end

    if onDuty then
        local function spawnBlip()
            local ped = GetPlayerPed(GetPlayerFromServerId(playerId))
            if DoesEntityExist(ped) then
                local b = AddBlipForEntity(ped)
                SetBlipSprite(b, Config.Blip.Unit.Sprite)
                SetBlipColour(b, Config.Blip.Unit.Color)
                SetBlipScale(b, Config.Blip.Unit.Scale)
                SetBlipAsShortRange(b, Config.Blip.Unit.ShortRange)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString("DOT Tech – " .. GetPlayerName(GetPlayerFromServerId(playerId)))
                EndTextCommandSetBlipName(b)
                dotUnitBlips[playerId] = b
                DebugLog("Created DOT blip for "..playerId)
            else
                SetTimeout(1000, spawnBlip)
            end
        end
        spawnBlip()
    else
        if dotUnitBlips[playerId] then
            RemoveBlip(dotUnitBlips[playerId])
            dotUnitBlips[playerId] = nil
            DebugLog("Removed DOT blip for "..playerId)
        end
    end
end)

-- Keep DOT blips moving
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        for pid, b in pairs(dotUnitBlips) do
            local ped = GetPlayerPed(GetPlayerFromServerId(pid))
            if DoesEntityExist(ped) then
                SetBlipCoords(b, GetEntityCoords(ped))
            end
        end
    end
end)

-- New 311 call arrives
RegisterNetEvent('sadot:receive311Call')
AddEventHandler('sadot:receive311Call', function(callerId, phone, reason, coords, callID, photoUrl)
    -- create map blip
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, Config.Blip.Call.Sprite)
    SetBlipColour(blip, Config.Blip.Call.Color)
    SetBlipScale(blip, Config.Blip.Call.Scale)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("311 Call – " .. reason)
    EndTextCommandSetBlipName(blip)
    callBlips[callID] = blip

    -- forward to NUI if on‑duty
    if isOnDuty then
        SendNUIMessage({
            type    = 'NewCall',
            callID  = callID,
            postal  = '',
            reason  = reason,
            caller  = callerId,
            phone   = phone,
            coords  = coords,
            photoUrl= photoUrl,
        })
    end

    -- pNotify/chat alert
    local callerName = GetPlayerName(GetPlayerFromServerId(callerId))
    local txt = ("[SADOT 311] %s: %s"):format(callerName, reason)
    if Config.UsePNotify then
        TriggerEvent('pNotify:SendNotification', {
            text    = txt,
            type    = 'info',
            timeout = 8000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })
    else
        TriggerEvent('chat:addMessage', { args = {"SADOT 311", txt} })
    end
end)

-- Mark call completed on map
RegisterNetEvent('sadot:completeCallBlip')
AddEventHandler('sadot:completeCallBlip', function(callID)
    if callBlips[callID] then
        RemoveBlip(callBlips[callID])
        callBlips[callID] = nil
        DebugLog("Removed call blip "..callID)
    end
end)

-- Cleanup on disconnect
AddEventHandler('playerDropped', function()
    for _, b in pairs(dotUnitBlips) do RemoveBlip(b) end
    for _, b in pairs(callBlips)    do RemoveBlip(b) end
    dotUnitBlips = {}
    callBlips    = {}
end)
