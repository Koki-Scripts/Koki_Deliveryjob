local onJob = false
local currentVehicle = nil
local currentDelivery = nil
local deliveriesDone = 0
local carryingPackage = false
local packageObj = nil

local deliveryBlip = nil
local returnBlip = nil

function AttachPackage()
    lib.requestModel(`prop_cs_cardbox_01`, 5000)
    packageObj = CreateObject(`prop_cs_cardbox_01`, 0, 0, 0, true, true, true)
    AttachEntityToEntity(packageObj, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.25, 0.0, 0.0, 0.0, 90.0, 90.0, true, true, false, true, 1, true)
    RequestAnimDict("anim@heists@box_carry@")
    while not HasAnimDictLoaded("anim@heists@box_carry@") do Wait(10) end
    TaskPlayAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 8.0, -8, -1, 49, 0, false, false, false)
end

function RemovePackage()
    if packageObj then DeleteEntity(packageObj) packageObj = nil end
    ClearPedTasks(PlayerPedId())
end

function DeliverPackage(targetId)
    lib.progressBar({duration=3000, label='Doručuješ balík...', useWhileDead=false, canCancel=false, disable={car=true, move=true}})
    RemovePackage()
    carryingPackage = false
    deliveriesDone = deliveriesDone + 1

    if targetId then exports.ox_target:removeZone(targetId) end
    if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip=nil end

    if deliveriesDone >= Config.MaxDeliveries then
        lib.notify({title='Rozvoz', description='Doručil jsi všechny balíky. Vrať auto.', type='success'})
        AddReturnPoint()
    else
        NextDelivery()
    end
end

function TakePackage()
    if carryingPackage then
        lib.notify({title='Rozvoz', description='Už neseš balík!', type='error'})
        return
    end

    RequestAnimDict("mini@repair")
    while not HasAnimDictLoaded("mini@repair") do Wait(10) end
    TaskPlayAnim(PlayerPedId(), "mini@repair", "fixing_a_ped", 3.0, -1, -1, 49, 0, 0, 0, 0)

    if lib.progressBar({
        duration = 3000,
        label = 'Bereš balík z kufru...',
        useWhileDead = false,
        canCancel = false,
        disable = {car = true, move = true},
        anim = { dict = "mini@repair", clip = "fixing_a_ped", flags = 49 }
    }) then
        ClearPedTasks(PlayerPedId())
        carryingPackage = true
        AttachPackage()
        lib.notify({title='Balík', description='Dones balík ke dveřím.', type='inform'})

        local targetId = exports.ox_target:addSphereZone({
            coords = currentDelivery,
            radius = 1.5,
            debug = false,
            options = {{
                name='deliver_package',
                icon='fa-solid fa-box',
                label='Doručit balík',
                onSelect=function()
                    if carryingPackage then DeliverPackage(targetId) end
                end
            }}
        })
    else
        ClearPedTasks(PlayerPedId())
    end
end

function NextDelivery()
    if deliveriesDone >= Config.MaxDeliveries then
        lib.notify({title='Rozvoz', description='Doručil jsi všechny balíky. Vrať auto.', type='success'})
        AddReturnPoint()
        return
    end

    currentDelivery = Config.Locations[math.random(1,#Config.Locations)]

    if deliveryBlip then RemoveBlip(deliveryBlip) end
    deliveryBlip = AddBlipForCoord(currentDelivery.x, currentDelivery.y, currentDelivery.z)
    SetBlipSprite(deliveryBlip,280)
    SetBlipDisplay(deliveryBlip,4)
    SetBlipScale(deliveryBlip,0.9)
    SetBlipColour(deliveryBlip,5)
    SetBlipAsShortRange(deliveryBlip,false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Doruč balík')
    EndTextCommandSetBlipName(deliveryBlip)
    SetBlipRoute(deliveryBlip,true)
    SetBlipRouteColour(deliveryBlip,5)

    if currentVehicle then
        exports.ox_target:addLocalEntity(currentVehicle,{
            {
                name='take_package',
                icon='fa-solid fa-box',
                label='Vyndat balík',
                canInteract=function(entity,distance,coords,name) return not carryingPackage and onJob end,
                onSelect=TakePackage
            }
        })
    end

    lib.notify({title='Rozvoz', description=('Zbývá %s/%s balíků.'):format(deliveriesDone, Config.MaxDeliveries), type='inform'})
end

function StartJob()
    onJob = true
    deliveriesDone = 0

    DoScreenFadeOut(800)
    Wait(1500)

    lib.progressBar({duration=3000,label='Připravuješ vozidlo...', useWhileDead=false, canCancel=false, disable={car=true, move=true}})

    local spawn = Config.VehicleSpawn
    lib.requestModel(Config.Vehicle,5000)
    currentVehicle = CreateVehicle(Config.Vehicle, spawn.x, spawn.y, spawn.z, spawn.w, true, true)
    SetVehicleNumberPlateText(currentVehicle,'KURYR'..math.random(100,999))

    DoScreenFadeIn(800)
    NextDelivery()
end

function EndJob()
    if DoesEntityExist(currentVehicle) then DeleteVehicle(currentVehicle) end
    if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip=nil end
    if returnBlip then RemoveBlip(returnBlip) returnBlip=nil end

    TriggerServerEvent('delivery:finishJob', deliveriesDone)

    onJob=false
    deliveriesDone=0
    currentVehicle=nil
    currentDelivery=nil
    carryingPackage=false
    RemovePackage()
end

function AddReturnPoint()
    if returnBlip then RemoveBlip(returnBlip) returnBlip=nil end
    returnBlip = AddBlipForCoord(Config.FinishJob)
    SetBlipSprite(returnBlip,50)
    SetBlipScale(returnBlip,0.9)
    SetBlipColour(returnBlip,1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Vrácení dodávky')
    EndTextCommandSetBlipName(returnBlip)
    SetBlipRoute(returnBlip,true)
    SetBlipRouteColour(returnBlip,1)

    lib.registerContext({
        id='finish_delivery_menu',
        title='Ukončit rozvážku',
        options={{title='Vrátit vozidlo',description=('Doručeno: %s/%s'):format(deliveriesDone,Config.MaxDeliveries),icon='fa-solid fa-van-shuttle',onSelect=EndJob}}
    })

    lib.showContext('finish_delivery_menu')
end

function OpenMainMenu()
    local options = {}
    if not onJob then
        table.insert(options, {title='Začít rozvážku', icon='fa-solid fa-play', onSelect=StartJob})
    else
        table.insert(options, {title='Ukončit rozvážku', icon='fa-solid fa-stop', onSelect=EndJob})
    end

    lib.registerContext({
        id='delivery_main_menu',
        title='Kurýrní služba',
        options=options
    })

    lib.showContext('delivery_main_menu')
end

CreateThread(function()
    local npc = Config.NPC
    lib.requestModel(npc.model,5000)
    local ped = CreatePed(0,npc.model,npc.coords.x,npc.coords.y,npc.coords.z-1,npc.coords.w,false,true)

    SetEntityInvincible(ped,true)
    SetBlockingOfNonTemporaryEvents(ped,true)
    SetPedCanRagdoll(ped,false)
    SetPedCanRagdollFromPlayerImpact(ped,false)
    FreezeEntityPosition(ped,true)
    SetEntityAsMissionEntity(ped,true,true)
    TaskStartScenarioInPlace(ped,'WORLD_HUMAN_CLIPBOARD',0,true)

    exports.ox_target:addLocalEntity(ped,{
        {
            name='delivery_menu',
            icon='fa-solid fa-truck',
            label='Rozvážka balíků',
            onSelect=OpenMainMenu
        }
    })

    local npcBlip = AddBlipForCoord(npc.coords.x,npc.coords.y,npc.coords.z)
    SetBlipSprite(npcBlip,479)
    SetBlipDisplay(npcBlip,4)
    SetBlipScale(npcBlip,0.8)
    SetBlipColour(npcBlip,5)
    SetBlipAsShortRange(npcBlip,true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Kurýrní služba')
    EndTextCommandSetBlipName(npcBlip)

    local coords = vec3(npc.coords.x,npc.coords.y,npc.coords.z)
    CreateThread(function()
        while true do
            Wait(100)
            local pedCoords = GetEntityCoords(ped)
            if #(pedCoords - coords) > 0.1 then
                SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
            end
        end
    end)

    CreateThread(function()
        while true do
            Wait(500)
            local playerPed = PlayerPedId()
            local dist = #(GetEntityCoords(playerPed)-GetEntityCoords(ped))
            if dist<5.0 then
                if IsPedBeingJacked(ped) or IsPedRagdoll(ped) or IsPedInMeleeCombat(playerPed) then
                    TriggerServerEvent('delivery:kickPlayer', GetPlayerServerId(PlayerId()))
                end
            end
        end
    end)
end)
