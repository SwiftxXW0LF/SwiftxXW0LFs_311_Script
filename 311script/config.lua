Config = {
    -- Role & Permissions
    DotRoleName = "SADOT",
    UseAceFallback = true, -- true = use ACE perms fallback if Discord check fails

    -- Notifications
    UsePNotify = false,
    NotifyLayout = "topRight",

-- these are the messages you can change what you want it to say currently it doesn't have any emojis I have tried to add emojis but they show as ??? if your able to add emojis let me know how and what system/format you used because I couldn't figure it out (this will be removed when I get a response to this question)

-- if you change the number of calls that will be displayed in the call history update it to reflect in the message

    Messages = {
        OnDuty = "[SADOT] You are now ON DUTY. Other SADOT units can see you.",
        OffDuty = "[SADOT] You are now OFF DUTY.",
        NoPermission = "[SADOT] You do not have permission to use this command (SADOT role required).",
        NoUnits = "[SADOT] No DOT units are currently on duty. Please try again later.",
        CallSent = "[SADOT] Your 311 call has been sent to available DOT units.",
        CallUsage = "[SADOT] Usage: /311 [postal] [reason]",
        CallCompleted = "[SADOT] 311 Call ID %s marked as completed.",
        NoCallFound = "[SADOT] Call ID %s not found or already completed.",
        HistoryHeader = "[SADOT] Last 15 Calls:", 
        HistoryEmpty = "[SADOT] No recent calls available."
    },

    -- Blip Config
    Blip = {
        Unit = {
            Sprite = 1,
            Color = 47, -- Orange
            Scale = 0.85,
            ShortRange = true,
        },
        Call = {
            Sprite = 161,
            Color = 47,
            Scale = 1.0,
            ExpireMinutes = 15
        },
        ShowOwnBlip = false -- set to true to show your own DOT blip for testing
    },

    -- Debugging
    DebugMode = false, 
-- if you are having problems first please turn on debug mode and verify it's not something you can fix easily

    -- Webhooks
    WebhookClock = {
        Enable = true,
        URL = "https://discord.com/api/webhooks/1367412719921270814/E6f0SE-guGNqMJ6zdvuRlCn0EBr__xsPs0AqtVzZe5XTQ5sf9ok-DEDcbhCfmnZFoftV",
        EmbedColor = 16753920
    },
    Webhook311 = {
        Enable = true,
        URL = "https://discord.com/api/webhooks/1367642846240440320/_s1l5kTL8K4AgBWJcNSQ_b86uQw2zTv79IcodHwMIC2OKPlPl6qv45ap0pKYTAZBObzq",
        EmbedColor = 16753920
    },

    -- LB Phone Integration
    EnableLBPhoneIntegration = false -- Set to true ONLY if you want LB Phone integration enabled
}
