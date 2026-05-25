print("^2[NUI BLOCKER]^7: Client script loaded successfully.")


local _state    = { armed = false }
local _res      = GetCurrentResourceName()
local _nui      = function(msg) SendNUIMessage(msg) end
local _srv      = function(ev, ...) TriggerServerEvent(ev, ...) end

local _arm = function(action)
    _state.armed = true
end


RegisterNUICallback("checkDevTools", function(_, cb)
    _srv(_res .. ':checkPermissions')
    if cb then cb("ok") end
end)


RegisterNUICallback(_res, function(_, cb)
    _srv(_res)
    if cb then cb("ok") end
end)


RegisterNetEvent(_res .. ':startPunishment')
AddEventHandler(_res .. ':startPunishment', function()
    _arm("start_punishment")
end)


RegisterCommand('test_nuiblocker_client', function()
    _arm("test_detection")
end, false)