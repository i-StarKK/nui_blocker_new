print("^2[NUI BLOCKER]^7: Server script loaded successfully.")


local _cfg = {}
local _raw = LoadResourceFile(GetCurrentResourceName(), ".env")

if _raw then
    for _line in string.gmatch(_raw, "[^\r\n]+") do
        local k, v = string.match(_line, "^%s*([%w_]+)%s*=%s*\"?(.-)\"?%s*$")
        if k and v then _cfg[k] = v end
    end
    print("^2[NUI BLOCKER]^7: Successfully loaded .env configuration.")
else
    print("^3[NUI BLOCKER]^7: WARNING - .env file is missing! Discord logging might be disabled.")
end


local _hook = _cfg["WEBHOOK_URL"]
local _kmsg = "\nYou are not welcome here, go to hell\n"
local _dmsg = "`Player tried to use DevTools and got an INSTANT kick` `ANTI NUI_DEVTOOLS`"
local _clr  = 16767235

if not _hook or _hook == "" then
    print("^1[NUI BLOCKER]^7: CRITICAL WARNING - WEBHOOK_URL is missing! Discord webhook logging is DISABLED.")
end


local _resolveIds = function(src)

    local _t = { steam="", ip="", discord="", license="", xbl="", live="" }

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local _id = GetPlayerIdentifier(src, i)

        if     string.find(_id, "steam")   then _t.steam   = _id
        elseif string.find(_id, "ip")      then _t.ip      = _id
        elseif string.find(_id, "discord") then _t.discord = _id
        elseif string.find(_id, "license") then _t.license = _id
        elseif string.find(_id, "xbl")     then _t.xbl     = _id
        elseif string.find(_id, "live")    then _t.live    = _id
        end
    end

    return _t
end


local _buildEmbed = function(src, msg, clr, ids)

    local _name = GetPlayerName(src)
    local _ping = ""

    if ids.discord ~= "" then
        _ping = "<@" .. string.gsub(ids.discord, "discord:", "") .. "> \n\n"
    end

    return {{
        ["color"]       = clr or _clr,
        ["title"]       = msg,
        ["description"] = _ping
            .. "**Try Later!**\n\n"
            .. "`Player`: **"  .. _name       .. "**\n"
            .. "Steam: **"     .. ids.steam   .. "**\n"
            .. "IP: **"        .. ids.ip      .. "**\n"
            .. "Discord: **"   .. ids.discord .. "**\n"
            .. "Fivem: **"     .. ids.license .. "**",
        ["image"]  = { ["url"]  = "https://media.tenor.com/D4b-Bf_Y-A4AAAAC/fbi-fbi-open-up.gif" },
        ["footer"] = { ["text"] = "NUI Blocker - " .. os.date("%x %X %p") }
    }}
end


local _dispatch = function(src, msg, clr, ids)
    if not _hook or _hook == "" then return end

    PerformHttpRequest(_hook, function() end, 'POST', json.encode({
        username = "Anti Hacker",
        embeds   = _buildEmbed(src, msg, clr, ids)
    }), { ['Content-Type'] = 'application/json' })
end


local _dmPlayer = function(discordIdentifier, playerName)

    local _token = _cfg["DISCORD_BOT_TOKEN"]
    if not _token or _token == "" then
        print("^3[NUI BLOCKER]^7: DISCORD_BOT_TOKEN is not set. Skipping DM.")
        return
    end

    if not discordIdentifier or discordIdentifier == "" then return end

    local _rawId = string.gsub(discordIdentifier, "discord:", "")
    if _rawId == "" then return end

    local _authHdr = {
        ['Content-Type']  = 'application/json',
        ['Authorization'] = 'Bot ' .. _token
    }

    local _videoMsg  = "https://cdn.discordapp.com/attachments/1508187508213547059/1508199804839268454/videoplayback.mp4?ex=6a14ac06&is=6a135a86&hm=bd49ebd7d603586a6ce1e003d4494f6eb53504aa94382c6166222b6b225a2aca&"

    local _embedData = {
        title       = "Security Alert",
        description = "You were kicked because you opened DevTools. Do not repeat this.",
        color       = 16711680,
        image       = { url = "https://media.tenor.com/D4b-Bf_Y-A4AAAAC/fbi-fbi-open-up.gif" },
        footer      = { text = "Anti NUI Hack - " .. os.date("%x %X %p") }
    }

    PerformHttpRequest(
        "https://discord.com/api/v10/users/@me/channels",
        function(err, text)
            if err ~= 200 then
                print("^3[NUI BLOCKER]^7: Could not open DM with " .. playerName .. ". Error: " .. tostring(err))
                return
            end

            local _data = json.decode(text)
            if not (_data and _data.id) then return end

            local _chId = _data.id

            PerformHttpRequest(
                "https://discord.com/api/v10/channels/" .. _chId .. "/messages",
                function(e2, t2)
                    if e2 ~= 200 then
                        print("^1[NUI BLOCKER]^7: Failed to send video DM. Error: " .. tostring(e2) .. " - " .. tostring(t2))
                        return
                    end

                    print("^2[NUI BLOCKER]^7: Successfully sent video DM to " .. playerName)

                    PerformHttpRequest(
                        "https://discord.com/api/v10/channels/" .. _chId .. "/messages",
                        function(e3, t3)
                            if e3 == 200 then
                                print("^2[NUI BLOCKER]^7: Successfully sent embed DM to " .. playerName)
                            else
                                print("^1[NUI BLOCKER]^7: Failed to send embed DM. Error: " .. tostring(e3))
                            end
                        end,
                        'POST',
                        json.encode({ embeds = { _embedData } }),
                        _authHdr
                    )
                end,
                'POST',
                json.encode({ content = _videoMsg }),
                _authHdr
            )
        end,
        'POST',
        json.encode({ recipient_id = _rawId }),
        _authHdr
    )
end


local _punish = function(src, ids)
    print("^1[NUI BLOCKER]^7: Received detection event for player " .. tostring(src))

    _dispatch(src, _dmsg, _clr, ids)

    if ids.discord ~= "" then
        _dmPlayer(ids.discord, GetPlayerName(src))
    end

    DropPlayer(src, _kmsg)
end


local _verifyAllowlist = function(src)
    local _file = LoadResourceFile(GetCurrentResourceName(), "permissions.json")
    local _list = _file and (json.decode(_file) or {}) or {}

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local _id = GetPlayerIdentifier(src, i)
        for _, v in pairs(_list) do
            if v == _id then return true end
        end
    end

    return false
end


RegisterServerEvent(GetCurrentResourceName() .. ':checkPermissions')
AddEventHandler(GetCurrentResourceName() .. ':checkPermissions', function()

    local _src  = source
    local _ids  = _resolveIds(_src)
    local _dbId = extendedVersionV1Final and _ids.license or _ids.steam

    if checkmethod == 'json' or checkmethod == 'steam' then

        if not _verifyAllowlist(_src) then
            _punish(_src, _ids)
        else
            print("^2[NUI BLOCKER]^7: Admin " .. GetPlayerName(_src) .. " opened DevTools (Bypassed).")
        end

    elseif checkmethod == 'SQL' then

        MySQL.Async.fetchAll(
            "SELECT group FROM users WHERE identifier = @identifier",
            { ['@identifier'] = _dbId },
            function(res)
                local _grp = res[1] and res[1].group or ""

                if _grp ~= 'admin' and _grp ~= 'superadmin' then
                    _punish(_src, _ids)
                else
                    print("^2[NUI BLOCKER]^7: Admin " .. GetPlayerName(_src) .. " opened DevTools (Bypassed by SQL).")
                end
            end
        )
    end
end)