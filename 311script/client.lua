-- client.lua

local dotUnitBlips = {}
local callBlips    = {}

-- Debug helper
local function DebugLog(msg)
    if Config.DebugMode then
        print("^3[SADOT DEBUG]: " .. msg)
    end
end

-- Toggle a DOT unit blip
RegisterNetEvent('sadot:toggleDutyBlip')
AddEventHandler('sadot:toggleDutyBlip', function(playerId, onDuty)
    -- optionally hide your own
    if not Config.Blip.ShowOwnBlip and playerId == GetPlayerServerId(PlayerId()) then
        return
    end

    if onDuty then
        local function spawn()
            local ped = GetPlayerPed(GetPlayerFromServerId(playerId))
            if DoesEntityExist(ped) then
                local b = AddBlipForEntity(ped)
                SetBlipSprite(b, Config.Blip.Unit.Sprite)
                SetBlipColour(b, Config.Blip.Unit.Color)
                SetBlipScale(b, Config.Blip.Unit.Scale)
                SetBlipAsShortRange(b, Config.Blip.Unit.ShortRange)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString("DOT Technician - " .. GetPlayerName(GetPlayerFromServerId(playerId)))
                EndTextCommandSetBlipName(b)
                dotUnitBlips[playerId] = b
                DebugLog("Created duty blip for "..playerId)
            else
                SetTimeout(1000, spawn)
            end
        end
        spawn()
    else
        if dotUnitBlips[playerId] then
            RemoveBlip(dotUnitBlips[playerId])
            dotUnitBlips[playerId] = nil
            DebugLog("Removed duty blip for "..playerId)
        end
    end
end)

-- Keep DOT blips synced
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

-- Receive a new 311 call
RegisterNetEvent('sadot:receive311Call')
AddEventHandler('sadot:receive311Call', function(callerId, msg, coords, callID)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, Config.Blip.Call.Sprite)
    SetBlipColour(blip, Config.Blip.Call.Color)
    SetBlipScale(blip, Config.Blip.Call.Scale)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("311 Call - " .. msg)
    EndTextCommandSetBlipName(blip)
    callBlips[callID] = blip

    local callerName = GetPlayerName(GetPlayerFromServerId(callerId))
    local txt = ("[SADOT 311] %s: %s"):format(callerName, msg)
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

-- Complete a 311 call
RegisterNetEvent('sadot:completeCallBlip')
AddEventHandler('sadot:completeCallBlip', function(callID)
    if callBlips[callID] then
        RemoveBlip(callBlips[callID])
        callBlips[callID] = nil
        DebugLog("Removed call blip "..callID)
    end
end)

-- Give DOT weapons
RegisterNetEvent('sadot:giveDotWeapons')
AddEventHandler('sadot:giveDotWeapons', function()
    local ped = PlayerPedId()
    local weps = {
        "WEAPON_FIREEXTINGUISHER", "WEAPON_FLARE", "WEAPON_PETROLCAN",
        "WEAPON_CROWBAR", "WEAPON_KNIFE", "WEAPON_HAMMER",
        "WEAPON_FLASHLIGHT", "WEAPON_WRENCH"
    }
    for _, w in ipairs(weps) do
        GiveWeaponToPed(ped, GetHashKey(w), 1, false, false)
    end
    SetCurrentPedWeapon(ped, GetHashKey("WEAPON_FLASHLIGHT"), true)
end)

-- Remove DOT weapons
RegisterNetEvent('sadot:removeDotWeapons')
AddEventHandler('sadot:removeDotWeapons', function()
    local ped = PlayerPedId()
    local weps = {
        "WEAPON_FIREEXTINGUISHER", "WEAPON_FLARE", "WEAPON_PETROLCAN",
        "WEAPON_CROWBAR", "WEAPON_KNIFE", "WEAPON_HAMMER",
        "WEAPON_FLASHLIGHT", "WEAPON_WRENCH"
    }
    for _, w in ipairs(weps) do
        RemoveWeaponFromPed(ped, GetHashKey(w))
    end
end)

-- Cleanup on drop
AddEventHandler('playerDropped', function()
    for _, b in pairs(dotUnitBlips) do RemoveBlip(b) end
    for _, b in pairs(callBlips)    do RemoveBlip(b) end
    dotUnitBlips = {}
    callBlips    = {}
end)
