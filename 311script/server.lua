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

-- Webhook sender
local function SendWebhook(webhookCfg, title, description)
    if not webhookCfg.Enable or not webhookCfg.URL or webhookCfg.URL == "" then return end
    local embed = {{
        title       = title,
        description = description,
        color       = webhookCfg.EmbedColor,
        footer      = { text = os.date("%Y-%m-%d %H:%M:%S") }
    }}
    PerformHttpRequest(webhookCfg.URL, function() end, 'POST', json.encode({
        username = "SADOT System",
        embeds   = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Helper: broadcast duty-blip toggle to everyone
local function BroadcastDutyBlip(playerId, onDuty)
    TriggerClientEvent('sadot:toggleDutyBlip', -1, playerId, onDuty)
end

-- /ondutydot
RegisterCommand('ondutydot', function(source)
    local src  = source
    local name = GetPlayerName(src)

    -- permission check
    local hasRole = false
    if Config.DotRoleName and exports.night_discordapi then
        hasRole = exports.night_discordapi:IsMemberPartOfThisRole(src, Config.DotRoleName, true)
    end
    if not hasRole and Config.UseAceFallback then
        hasRole = IsPlayerAceAllowed(src, "group.dot")
    end
    if not hasRole then
        TriggerClientEvent('pNotify:SendNotification', src, {
            text    = Config.Messages.NoPermission,
            type    = 'error',
            timeout = 5000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })
        return
    end

    if onDutyDOT[src] then
        -- CLOCK OUT
        local clockIn = onDutyDOT[src].clockIn or os.time()
        local dur     = os.time() - clockIn
        local h       = math.floor(dur / 3600)
        local m       = math.floor((dur % 3600) / 60)
        local s       = dur % 60

        BroadcastDutyBlip(src, false)
        onDutyDOT[src] = nil

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
            ("**%s** has clocked OUT.\nShift time: %02d:%02d:%02d")
            :format(name, h, m, s)
        )
    else
        -- CLOCK IN
        onDutyDOT[src] = { clockIn = os.time() }

        TriggerClientEvent('sadot:giveDotWeapons', src)
        TriggerClientEvent('pNotify:SendNotification', src, {
            text    = Config.Messages.OnDuty,
            type    = 'success',
            timeout = 4000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })

        BroadcastDutyBlip(src, true)

        SendWebhook(Config.WebhookClock,
            "DOT Clock IN",
            ("**%s** has clocked IN for duty."):format(name)
        )
    end
end, false)

-- /311
RegisterCommand('311', function(source, args)
    local src  = source
    local name = GetPlayerName(src)

    if #args < 2 then
        TriggerClientEvent('pNotify:SendNotification', src, {
            text    = Config.Messages.CallUsage,
            type    = 'error',
            timeout = 5000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })
        return
    end

    local postal = args[1]
    table.remove(args, 1)
    local reason = table.concat(args, ' ')
    local coords = GetEntityCoords(GetPlayerPed(src))

    callCounter = callCounter + 1
    activeCalls[callCounter] = {
        caller = src,
        coords = coords,
        postal = postal,
        reason = reason,
        active = true,
        time   = os.time()
    }

    local dotCount = 0
    for playerId in pairs(onDutyDOT) do
        TriggerClientEvent('sadot:receive311Call', playerId, src, reason, coords, callCounter)
        dotCount = dotCount + 1
    end

    if dotCount > 0 then
        TriggerClientEvent('pNotify:SendNotification', src, {
            text    = Config.Messages.CallSent,
            type    = 'success',
            timeout = 5000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })
        SendWebhook(Config.Webhook311,
            "New 311 Call",
            ("**Caller:** %s\n**Postal:** %s\n**Reason:** %s\n**Coords:** (%.2f, %.2f)")
            :format(name, postal, reason, coords.x, coords.y)
        )
    else
        TriggerClientEvent('pNotify:SendNotification', src, {
            text    = Config.Messages.NoUnits,
            type    = 'error',
            timeout = 5000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })
    end
end, false)

-- /completecall
RegisterCommand('completecall', function(source, args)
    local src  = source
    local name = GetPlayerName(src)

    if #args < 1 then
        TriggerClientEvent('pNotify:SendNotification', src, {
            text    = Config.Messages.CallUsage,
            type    = 'error',
            timeout = 5000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })
        return
    end

    local callID = tonumber(args[1])
    local data   = activeCalls[callID]
    if not callID or not data then
        TriggerClientEvent('pNotify:SendNotification', src, {
            text    = Config.Messages.NoCallFound:format(callID),
            type    = 'error',
            timeout = 5000,
            layout  = Config.NotifyLayout,
            theme   = 'gta'
        })
        return
    end

    -- mark it completed and remove the blip
    data.active = false
    TriggerClientEvent('sadot:completeCallBlip', -1, callID)

    -- in-game notification
    TriggerClientEvent('pNotify:SendNotification', src, {
        text    = Config.Messages.CallCompleted:format(callID),
        type    = 'success',
        timeout = 4000,
        layout  = Config.NotifyLayout,
        theme   = 'gta'
    })

    -- enriched webhook embed
    SendWebhook(Config.Webhook311,
        "311 Call Completed",
        string.format(
            "**Call ID:** %d\n**Caller:** %s\n**Postal:** %s\n**Reason:** %s\n**Coords:** (%.2f, %.2f)\n**Completed By:** %s",
            callID,
            GetPlayerName(data.caller),
            data.postal,
            data.reason,
            data.coords.x, data.coords.y,
            name
        )
    )
end, false)

-- /callhistory
RegisterCommand('callhistory', function(source)
    local src   = source
    local count = 0

    TriggerClientEvent('chat:addMessage', src, { args = {"SADOT", Config.Messages.HistoryHeader} })
    for id,data in pairs(activeCalls) do
        local status = data.active and "Active" or "Completed"
        TriggerClientEvent('chat:addMessage', src, {
            args = { ("ID: %d | Postal: %s | Reason: %s | Status: %s")
                     :format(id, data.postal, data.reason, status) }
        })
        count = count + 1
        if count >= 15 then break end
    end

    if count == 0 then
        TriggerClientEvent('chat:addMessage', src, { args = {"SADOT", Config.Messages.HistoryEmpty} })
    end
end, false)

-- Disconnect cleanup (auto-clock-out with duration)
AddEventHandler('playerDropped', function()
    local src = source
    if onDutyDOT[src] then
        local clockIn = onDutyDOT[src].clockIn or os.time()
        local dur     = os.time() - clockIn
        local h       = math.floor(dur / 3600)
        local m       = math.floor((dur % 3600) / 60)
        local s       = dur % 60

        onDutyDOT[src] = nil
        BroadcastDutyBlip(src, false)

        local name = GetPlayerName(src) or "Unknown"
        SendWebhook(Config.WebhookClock,
            "DOT Clock OUT (Disconnect)",
            ("**%s** disconnected and was clocked out.\nShift time: %02d:%02d:%02d")
            :format(name, h, m, s)
        )
    end
end)

-- LB Phone bridge placeholder
if Config.EnableLBPhoneIntegration then
    DebugLog("LB Phone integration is ENABLED.")
    -- << add lb-phone event hooks here >>
else
    DebugLog("LB Phone integration is DISABLED.")
end
