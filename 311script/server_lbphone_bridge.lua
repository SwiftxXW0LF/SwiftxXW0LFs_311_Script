-- server_lbphone_bridge.lua

if not Config.EnableLBPhoneIntegration then
    print("^3[SADOT LB Phone]: Integration DISABLED in config.lua.")
    return
end

print("^2[SADOT LB Phone]: Bridge loaded and active.")

-- Debug helper
local function DebugLog(msg)
    if Config.DebugMode then
        print("^3[SADOT LB Phone DEBUG]: " .. msg)
    end
end

-- Utility: return a list of on-duty DOT units for LB-Phone
-- Expects LB-Phone to call this event with signature: TriggerEvent('lbphone:getOnlineEmployees', jobName, callback)
RegisterNetEvent('lbphone:getOnlineEmployees')
AddEventHandler('lbphone:getOnlineEmployees', function(job, cb)
    DebugLog(("LB Phone requested online employees for job: %s"):format(job))
    if job ~= "sadot" then
        DebugLog("Not SADOT, exiting.")
        return
    end

    local onlineDOT = {}

    -- Pull from core onDutyDOT table
    for playerId, data in pairs(onDutyDOT) do
        local name = GetPlayerName(playerId) or "Unknown"
        local phone = exports['lb-phone']:GetPhoneNumber(playerId) or "N/A"
        table.insert(onlineDOT, {
            id        = playerId,
            name      = name,
            phone     = phone,
            onDuty    = true,
            clockInAt = data.clockIn
        })
    end

    -- If no one is online and we're debugging, return a fake unit
    if Config.DebugMode and #onlineDOT == 0 then
        DebugLog("DebugMode: injecting fake DOT Technician.")
        table.insert(onlineDOT, {
            id        = 0,
            name      = "Test DOT Technician",
            phone     = "000-0000",
            onDuty    = true,
            clockInAt = os.time()
        })
    end

    DebugLog(("Returning %d DOT units to LB Phone."):format(#onlineDOT))
    cb(onlineDOT)
end)

-- Optional: allow LB-Phone to update player job when they clock in/out
RegisterNetEvent('sadot:lbphone:updateJob')
AddEventHandler('sadot:lbphone:updateJob', function(playerId, jobName, jobLabel)
    if not playerId or not jobName then return end
    local xPlayer = exports['lb-phone']:GetPlayer(playerId)
    if xPlayer then
        xPlayer.job      = jobName
        xPlayer.jobLabel = jobLabel
        print(("^2[SADOT LB Phone]: Updated job for ID %s ? %s"):format(playerId, jobName))
    else
        DebugLog(("Could not find LB-Phone player %s to update job."):format(playerId))
    end
end)
