-- server.lua
local onDutyDOT   = {}
local activeCalls = {}
local callCounter = 0

print("^2[SADOT] Script loaded and ready.")

-- Debug helper
local function DebugLog(msg)
    if Config.DebugMode then
        print("^3[SADOT DEBUG]: " .. msg)
    end
end

-- Webhook sender, with optional embed image
local function SendWebhook(webhookCfg, title, description, imageUrl)
    if not webhookCfg.Enable or webhookCfg.URL == "" then return end

    local embed = {{
        title       = title,
        description = description,
        color       = webhookCfg.EmbedColor,
        footer      = { text = os.date("%Y-%m-%d %H:%M:%S") }
    }}

    if imageUrl then
        embed[1].image = { url = imageUrl }
    end

    PerformHttpRequest(webhookCfg.URL, function() end, 'POST', json.encode({
        username = "SADOT System",
        embeds   = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Broadcast DOT blips
local function BroadcastDutyBlip(playerId, onDuty)
    TriggerClientEvent('sadot:toggleDutyBlip', -1, playerId, onDuty)
end

-- Role check for NUI Init
RegisterNetEvent('sadot:checkPermissions')
AddEventHandler('sadot:checkPermissions', function()
    local src = source
    local hasRole = false
    if Config.DotRoleName and exports.night_discordapi then
        hasRole = exports.night_discordapi:IsMemberPartOfThisRole(src, Config.DotRoleName, true)
    end
    if not hasRole and Config.UseAceFallback then
        hasRole = IsPlayerAceAllowed(src, "group.dot")
    end
    TriggerClientEvent('sadot:permissionsResult', src, hasRole)
end)

-- Return all active calls to NUI
RegisterNetEvent('sadot:getActiveCalls')
AddEventHandler('sadot:getActiveCalls', function()
    TriggerClientEvent('sadot:returnActiveCalls', source, activeCalls)
end)

-- Create a new 311 call via NUI
RegisterNetEvent('sadot:SubmitCall')
AddEventHandler('sadot:SubmitCall', function(data)
    local src     = source
    local postal  = data.postal
    local reason  = data.reason
    local photoUrl= data.photoUrl or nil
    local coords  = GetEntityCoords(GetPlayerPed(src))
    local phone   = exports['lb-phone']:GetPhoneNumber(src) or "Unknown"

    callCounter = callCounter + 1
    activeCalls[callCounter] = {
        caller   = src,
        phone    = phone,
        coords   = coords,
        postal   = postal,
        reason   = reason,
        photo    = photoUrl,
        uploads  = {},
        assigned = {},
        active   = true,
        time     = os.time(),
    }

    -- Notify on‑duty DOT players
    local dotCount = 0
    for pid in pairs(onDutyDOT) do
        TriggerClientEvent('sadot:receive311Call', pid,
            src, phone, reason, coords, callCounter, photoUrl)
        dotCount = dotCount + 1
    end

    -- Feedback to caller
    TriggerClientEvent('pNotify:SendNotification', src, {
        text    = (dotCount > 0) and Config.Messages.CallSent or Config.Messages.NoUnits,
        type    = (dotCount > 0) and 'success' or 'error',
        timeout = 5000,
        layout  = Config.NotifyLayout,
        theme   = 'gta'
    })

    -- Send Discord embed with image & phone
    SendWebhook(Config.Webhook311,
        "New 311 Call",
        string.format("**Caller:** %s\n**Phone:** %s\n**Postal:** %s\n**Reason:** %s",
            GetPlayerName(src), phone, postal, reason),
        photoUrl
    )
end)

-- Accept a call
RegisterNetEvent('sadot:AcceptCall')
AddEventHandler('sadot:AcceptCall', function(data)
    local src = source
    local call = activeCalls[data.callID]
    if call then
        table.insert(call.assigned, src)
        TriggerClientEvent('sadot:updateCallAssignment', -1, data.callID, call.assigned)
    end
end)

-- DOT uploads photo on a call
RegisterNetEvent('sadot:UploadPhoto')
AddEventHandler('sadot:UploadPhoto', function(data)
    local src     = source
    local callID  = data.callID
    local photoUrl= data.photoUrl
    local call    = activeCalls[callID]
    if call then
        table.insert(call.uploads, photoUrl)
        TriggerClientEvent('sadot:updateCallPhotos', -1, callID, call.uploads)
        SendWebhook(Config.Webhook311,
            string.format("DOT Photo for Call %d", callID),
            string.format("**Uploaded by:** %s\n**Call ID:** %d",
                GetPlayerName(src), callID),
            photoUrl
        )
    end
end)

-- Complete a call
RegisterNetEvent('sadot:CompleteCall')
AddEventHandler('sadot:CompleteCall', function(data)
    local src    = source
    local callID = data.callID
    local call   = activeCalls[callID]
    if call then
        call.active = false
        TriggerClientEvent('sadot:completeCallBlip', -1, callID)
        TriggerClientEvent('pNotify:SendNotification', src, {
            text    = string.format(Config.Messages.CallCompleted, callID),
            type    = 'success',
            timeout = 4000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })
        SendWebhook(Config.Webhook311,
            string.format("311 Call %d Completed", callID),
            string.format("**Completed by:** %s\n**Call ID:** %d",
                GetPlayerName(src), callID)
        )
    end
end)

-- /ondutydot clock in/out
RegisterCommand('ondutydot', function(source)
    local src     = source
    local hasRole = false
    if Config.DotRoleName and exports.night_discordapi then
        hasRole = exports.night_discordapi:IsMemberPartOfThisRole(src, Config.DotRoleName, true)
    end
    if not hasRole and Config.UseAceFallback then
        hasRole = IsPlayerAceAllowed(src, "group.dot")
    end
    if not hasRole then
        return TriggerClientEvent('pNotify:SendNotification', src, {
            text    = Config.Messages.NoPermission,
            type    = 'error',
            timeout = 5000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })
    end

    if onDutyDOT[src] then
        onDutyDOT[src] = nil
        BroadcastDutyBlip(src, false)
        TriggerClientEvent('sadot:removeDotWeapons', src)
        TriggerClientEvent('pNotify:SendNotification', src, {
            text    = Config.Messages.OffDuty,
            type    = 'info',
            timeout = 4000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })
        SendWebhook(Config.WebhookClock,
            "DOT Clock OUT",
            ("**%s** clocked OUT."):format(GetPlayerName(src))
        )
    else
        onDutyDOT[src] = true
        BroadcastDutyBlip(src, true)
        TriggerClientEvent('sadot:giveDotWeapons', src)
        TriggerClientEvent('pNotify:SendNotification', src, {
            text    = Config.Messages.OnDuty,
            type    = 'success',
            timeout = 4000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })
        SendWebhook(Config.WebhookClock,
            "DOT Clock IN",
            ("**%s** clocked IN."):format(GetPlayerName(src))
        )
    end
end, false)

-- Cleanup on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    if onDutyDOT[src] then
        onDutyDOT[src] = nil
        BroadcastDutyBlip(src, false)
    end
end)
