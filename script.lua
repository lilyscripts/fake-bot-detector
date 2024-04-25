--[[

made by lilyscripts
https://discord.gg/FFjX2K47NR

]]

--// Checks

assert(config, "you need a valid configuration to run this script! please check the docs again.")
assert(config.accounts, "no accounts set in configuration...")
assert(config.cooldown, "no cooldown set in configuration...")
assert(config.webhook, "no webhook set in configuration...")
assert(config.blockedUsers, "no blocked users set in configuration...")
assert(config.blockedRegexes, "no blocked regexes set in configuration...")
assert((config.debug ~= nil), "no debug set in configuration...")

--// Initialization

local players = game:GetService("Players")
local httpService = game:GetService("HttpService")

local localPlayer = players.LocalPlayer

--// Main Script

-- Gets CSRF Token For Block Request
local function getCsrfToken(cookie)
    local csrfRequest = request({
        Url = "https://www.roblox.com/home",
        Headers = {
            ["Cookie"] = (".ROBLOSECURITY=" .. cookie)
        }
    })

    local csrfToken = (string.split(string.split(csrfRequest.Body, 'data-token="')[2], '"')[1]) -- Kinda Ugly, I Know

    if (config.debug) then
        print("Retrieved CSRF Token - " .. csrfToken)
    end

    return csrfToken
end

-- Sends A Webhook Notification
local function sendMessage(message)
    if ((config.webhook) and (config.webhook ~= "")) then
        local discordRequest = request({
            Url = config.webhook,
            Method = "POST",
            Body = httpService:JSONEncode({
                ["content"] = message
            }),
            Headers = {
                ["Content-Type"] = "application/json"
            }
        })

        if (config.debug) then
            print("Sent Discord Message - " .. message)
            print("Discord Message Status Code - " .. tostring(discordRequest.StatusCode))
        end
    end
end

-- Blocks The Inputted User
local function blockUser(player)
    local blockEndpoint = ("https://accountsettings.roblox.com/v1/users/" .. tostring(player.UserId) .. "/block")
    local cookie = config.accounts[localPlayer.Name]
    local csrfToken = getCsrfToken(cookie)

    local blockRequest = request({
        Url = blockEndpoint,
        Method = "POST",
        Headers = {
            ["Cookie"] = (".ROBLOSECURITY=" .. cookie),
            ["x-csrf-token"] = csrfToken
        }
    })

    if (blockRequest.StatusCode == 200) then
        sendMessage("**Success** - Blocked: `" .. player.Name .. "`")

        if (config.debug) then
            print("Success - Blocked: `" .. player.Name .. "`")
        end

        return true, cookie, csrfToken
    else
        sendMessage("**Error** - Request returned status code: `" .. tostring(blockRequest.StatusCode) .. "`")

        if (config.debug) then
            print("Error - Request returned status code: `" .. tostring(blockRequest.StatusCode) .. "`")
        end

        return false
    end
end

-- Unblocks The User TO Prevent Block Limit
local function unblockUser(player, cookie, csrfToken)
    local unblockEndpoint = ("https://accountsettings.roblox.com/v1/users/" .. tostring(player.UserId) .. "/unblock")

    local unblockRequest = request({
        Url = unblockEndpoint,
        Method = "POST",
        Headers = {
            ["Cookie"] = (".ROBLOSECURITY=" .. cookie),
            ["x-csrf-token"] = csrfToken
        }
    })

    if (unblockRequest.StatusCode == 200) then
        sendMessage("**Success** - Unblocked: `" .. player.Name .. "`")

        if (config.debug) then
            print("Success - Unblocked: `" .. player.Name .. "`")
        end
    else
        sendMessage("**Error** - Request returned status code: `" .. tostring(unblockRequest.StatusCode) .. "`")

        if (config.debug) then
            print("Error - Request returned status code: `" .. tostring(unblockRequest.StatusCode) .. "`")
        end
    end
end

-- Scans For Fake Bots
local function checkUsers()
    for _, player in next, players:GetPlayers() do
        local illegalRegex = false
        local playerName = string.lower(player.Name)
        local playerDisplayName = string.lower(player.DisplayName)

        for _, regex in next, config.blockedRegexes do
            if ((string.match(playerName, regex)) or (string.match(playerDisplayName, regex))) then
                illegalRegex = true
            end
        end

        if
            ((table.find(config.blockedUsers, playerName)) or
                (table.find(config.blockedUsers, playerDisplayName)) or
                (illegalRegex)) and
            (playerName ~= string.lower(localPlayer.Name))
        then
            spawn(function()
                if (config.debug) then
                    print("Found User - " .. player.name)
                end

                local blocked, cookie, csrfToken = blockUser(player)

                if (config.debug) then
                    print("Attempted block, output - ", blocked)
                end

                if (blocked) then
                    unblockUser(player, cookie, csrfToken)
                end
            end)
        end
    end
end

-- Scans For Fake Bots Every X Seconds
-- Don't Bash Me For Not Using PlayerAdded Please :(
while (true) do
    task.wait(config.cooldown)

    checkUsers()
end
