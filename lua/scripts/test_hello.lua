-- EastCore test script
local function OnLogin(event, player)
    player:SendBroadcastMessage("Welcome to EastCore, " .. player:GetName() .. "!")
end
RegisterPlayerEvent(3, OnLogin)
