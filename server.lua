ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local playerCooldowns = {}
local COOLDOWN = 300 
local spamThreshold = 2
local spamCounter = {}

local WEBHOOK_URL = 'WEBHOOK_LINK'

local function sendDiscordLog(playerName, playerId)
    local connect = {
        {
            ["color"] = 16711680, 
            ["title"] = "Kick za zneužití triggeru",
            ["description"] = ("Hráč **%s** (ID: %s) byl kicknut za zneužití triggeru rozvozu."):format(playerName, playerId),
            ["footer"] = {
                ["text"] = "Delivery package script | Anti-spam"
            }
        }
    }
    PerformHttpRequest(WEBHOOK_URL, function(err, text, headers) end, 'POST', json.encode({username = "Delivery package", embeds = connect}), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('delivery:finishJob', function(deliveries)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local now = os.time()

    if not spamCounter[src] then spamCounter[src] = 0 end

    if playerCooldowns[src] and now - playerCooldowns[src] < COOLDOWN then
        spamCounter[src] = spamCounter[src] + 1
        local remaining = COOLDOWN - (now - playerCooldowns[src])

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Rozvoz',
            description = ('Počkej %s sekund, než dostaneš další odměnu.'):format(remaining),
            type = 'error'
        })

        if spamCounter[src] >= spamThreshold then
            local playerName = GetPlayerName(src) or "Unknown"

            sendDiscordLog(playerName, src)

            DropPlayer(src, 'Zkoušel jsi zneužít trigger rozvozu.')
        end
        return
    end

    if deliveries > 0 then
        local rewardPerDelivery = math.random(5000, 10000)
        local totalReward = deliveries * rewardPerDelivery
        xPlayer.addInventoryItem('money', totalReward)

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Výplata',
            description = ('Doručil jsi %s balíků a získal %s$ v inventáři.'):format(deliveries, totalReward),
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Výplata',
            description = 'Nedoručil jsi žádný balík, nedostal jsi zaplaceno.',
            type = 'error'
        })
    end

    playerCooldowns[src] = now
    spamCounter[src] = 0
end)
