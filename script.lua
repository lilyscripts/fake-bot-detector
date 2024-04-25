--[[

made by lilyscripts
https://discord.gg/FFjX2K47NR

]]

--// Configuration

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

--// Checks

assert(config, "you need a valid configuration to run this script! please check the docs again.")
assert(config.accounts, "no accounts set in configuration...")
assert(config.cooldown, "no cooldown set in configuration...")
assert(config.webhook, "no webhook set in configuration...")
assert(config.blockedUsers, "no blocked users set in configuration...")
assert(config.blockedRegexes, "no blocked regexes set in configuration...")
assert((config.debug == nil), "no debug set in configuration...")
assert((config.accounts[game.Players.LocalPlayer.Name]),
    "no current account found, make sure the usernames in getgenv().config.accounts are exact.")

--// Config Modifications

for index, value in next, config.blockedUsers do
    config.blockedUsers[index] = string.lower(value)
end

--// Initialization

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

local webhookBuilder = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/lilyscripts/webhook-builder/main/webhookBuilder.lua"))()

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
        local discordWebhook = webhookBuilder(config.webhook)
        discordWebhook:setContent(message)
        discordWebhook:send()
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

-- Levenshtein Distance Function (Credit - Max9598)
local function checkDistance(usernameOne, usernameTwo)
    local usernameOneLength = string.len(usernameOne)
    local usernameTwoLength = string.len(usernameTwo)
    local matrix = {}
    local cost = 0

    if (usernameOneLength == 0) then
        return usernameTwoLength
    elseif (usernameTwoLength == 0) then
        return usernameOneLength
    elseif (usernameOne == usernameTwo) then
        return 0
    end

    for i = 0, usernameOneLength, 1 do
        matrix[i] = {}
        matrix[i][0] = i
    end

    for j = 0, usernameTwoLength, 1 do
        matrix[0][j] = j
    end

    for i = 1, usernameOneLength, 1 do
        for j = 1, usernameTwoLength, 1 do
            if (usernameOne:byte(i) == usernameTwo:byte(j)) then
                cost = 0
            else
                cost = 1
            end
            matrix[i][j] = math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost)
        end
    end

    return ((usernameTwo:lower():find(usernameOne:lower()) and true) or (matrix[usernameOneLength][usernameTwoLength] <= 3 and usernameTwoLength - usernameOneLength <= 4)) and
        "fake" or "real"
end

-- Scans For Fake Bots
local function checkUsers()
    for _, player in next, players:GetPlayers() do
        local illegalName = false
        local playerName = string.lower(player.Name)
        local playerDisplayName = string.lower(player.DisplayName)
        local localPlayerName = string.lower(localPlayer.Name)
        local localPlayerDisplayName = string.lower(localPlayer.DisplayName)

        for _, regex in next, config.blockedRegexes do
            if ((string.match(playerName, regex)) or (string.match(playerDisplayName, regex))) then
                illegalName = true
            end
        end

        if (table.find(config.blockedUsers, playerName)) or (table.find(config.blockedUsers, playerDisplayName)) then
            illegalName = true
        end

        if
            (checkDistance(playerName, localPlayerName) == "fake") or
            (checkDistance(playerName, localPlayerDisplayName) == "fake") or
            (checkDistance(playerDisplayName, localPlayerName) == "fake") or
            (checkDistance(playerDisplayName, localPlayerDisplayName) == "fake") then
            illegalName = true
        end

        if (illegalName) then
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
