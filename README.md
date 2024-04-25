# fake bot detector
## how to use
```lua
getgenv().config = {
    ["accounts"] = { -- Exact Username(s)
        ["account username"] = "account cookie",
        ["account username 2"] = "account cookie 2"
    },
    ["cooldown"] = 10,      -- Cooldown Between Checking For Fake Bots
    ["webhook"] = "",       -- Webhook Notifier (Set To "" If You Don't Want It)
    ["levenshtein"] = true, -- Detects Similar Usernames To Those In Blocked Users (Advanced, Recommended)
    ["blockedUsers"] = {    -- Blocked Usernames / Display Names
        "username 1",
        "display name 1",
    },
    ["blockedRegexes"] = { -- Blocked Username / Display Name Regexes (Advanced, Recommended)
        "regex 1",
        "regex 2"
    },
    ["debug"] = false -- For Development Purposes
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/lilyscripts/fake-bot-detector/main/script.lua"))()
```
## features
- multi account support (all accounts run the same script)
- customizable cooldown between checks
- discord webhook notifier
- custom blocked username / display name support
- custom blocked username / display name regex (advanced detection) support
## why you should use this script
- its 100% free and open sourced
- it helps, if not destroys all fake bot methods (that people actually fall for)
- easy to set up and readable
## faq
- (q) why does this script need my roblox cookie?
- (a) because it needs it to send the requests to ban the fake bot out of your server

- (q) i need help, where do i find support?
- (a) join the discord - https://discord.gg/S4NHgEVmxy
