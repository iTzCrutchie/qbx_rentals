local config            = require 'config.client'
local currentSpawnPoint = 0
local rentalLocations   = {}
local cars              = {}
local bikes             = {}
local rentalVehicle     = 0

rentalLocations = lib.callback.await('qbx_rentals:server:getTables', false, 'locations')
cars = lib.callback.await('qbx_rentals:server:getTables', false, 'car')
bikes = lib.callback.await('qbx_rentals:server:getTables', false, 'bike')

lib.registerMenu({
    id              = 'rentalMenu',
    canClose        = true,
    disableInput    = false,
    title           = 'Rentals',
    position        = 'top-right',
    onClose     = function()
        CloseMenu(true)
    end,
    options         = {}, 
    }, function(selected, scrollIndex, args)
        local model
        local cost
    
        if scrollIndex then
    
            rentalType = args[scrollIndex].rentalType
            model = args[scrollIndex].model
            cost = args[scrollIndex].cost
                    
            TriggerEvent('qbx_rentals:client:spawnCar', model, cost, rentalType)

            currentSpawnPoint = 0
        else
  
            if not args[1] == 'returnVehicle' then return end
    
            TriggerEvent('qbx_rentals:client:returnVehicle')
    
        end
end)

-- Events

RegisterNetEvent('qbx_rentals:client:openMenu', function(rentalType)

    if rentalType == 'car' then


        local labels = {}
        local args = {}

        for i = 1, #cars do
            labels[i] = { label = cars[i].model, description = 'Rent ' .. cars[i].model .. ' for $' .. cars[i].cost}
            args[i] = {model = cars[i].model, cost = cars[i].cost, rentalType = rentalType}
        end

        for k, vehicle in pairs(cars) do

            lib.setMenuOptions('rentalMenu',                 { 
                label       = vehicle.model .. ' $' .. vehicle.cost,
                values      = labels,
                args        = args,
                close       = true,
            }, 1)
            lib.setMenuOptions('rentalMenu', { label = 'Return rental', description = 'Return the rental.', args = {'returnVehicle'}}, 2)


        end

        lib.showMenu('rentalMenu')

    elseif rentalType == 'bike' then

        local labels = {}
        local args = {}

        for i = 1, #bikes do
            labels[i] = { label = bikes[i].model, description = 'Rent ' .. bikes[i].model .. ' for $' .. bikes[i].cost}
            args[i] = {model = bikes[i].model, cost = bikes[i].cost, rentalType = rentalType}
        end

        for k, vehicle in pairs(bikes) do

            lib.setMenuOptions('rentalMenu',                 { 
                label       = vehicle.model .. ' $' .. vehicle.cost,
                values      = labels,
                args        = args,
                close       = true,
            }, 1)
            lib.setMenuOptions('rentalMenu', { label = 'Return rental', description = 'Return the rental.', args = {'returnVehicle'}}, 2)

        end

        lib.showMenu('rentalMenu')

    end


end)

RegisterNetEvent('qbx_rentals:client:spawnCar', function(model, cost, rentalType)

    local player = PlayerPedId()
    local spawnPoint

    for i = 1, #rentalLocations do
        if IsAnyVehicleNearPoint(rentalLocations[i].spawnPoint.x, rentalLocations[i].spawnPoint.y, rentalLocations[i].spawnPoint.z, 2.0) then
            lib.notify({
                title       = 'Area Blocked',
                description = 'Soemthing is in the way!',
                type        = 'error'
            })
            return
        end
    end

    spawnPoint = currentSpawnPoint

    if spawnPoint == 0 then
        return
    end

    canPurchase = lib.callback.await('qbx_rentals:server:moneyCheck', false, model, cost, rentalType)

    if not canPurchase then             
        lib.notify({
            title       = 'No money',
            description = 'You do not have the appropriate cash to rent this item',
            type        = 'error'
        })
        return
    end

    local netId = lib.callback.await('qbx_rentals:server:spawnVehicle', false, model, spawnPoint)

    rentalVehicle = netId

end)

RegisterNetEvent('qbx_rentals:client:returnVehicle', function()

    if rentalVehicle == 0 then return end

    local delVeh = lib.callback.await('qbx_rentals:server:deleteVehicle', false, rentalVehicle)

    if delVeh then
        rentalVehicle = 0
    end

end)

-- Functions

function CloseMenu(isFullMenuClose, keyPressed, previousMenu)
    if isFullMenuClose or not keyPressed or keyPressed == 'Escape' then
        lib.hideMenu(false)
        return
    end
end

local createNPC = function()
    for k, ped in pairs(rentalLocations) do

        if ped.pedHash then
        
            createdPed = CreatePed(5, ped.pedHash, ped.coords.x, ped.coords.y, ped.coords.z, ped.coords.w, false, false )

            SetModelAsNoLongerNeeded(ped.pedHash)
            FreezeEntityPosition(createdPed, true)
            SetEntityInvincible(createdPed, true)
            SetBlockingOfNonTemporaryEvents(createdPed, true)
            TaskStartScenarioInPlace(createdPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
        end

    end
end

local createBike = function()

    for k, bike in pairs(rentalLocations) do

        if bike.bikeHash then

            createdBike = CreateVehicle(bike.bikeHash, bike.coords.x, bike.coords.y, bike.coords.z, false, false)
            SetModelAsNoLongerNeeded(bike.bikeHash)
            SetEntityAsMissionEntity(createdBike, true, true)
            SetVehicleOnGroundProperly(createdBike)
            SetEntityInvincible(createdBike, true)
            SetVehicleDirtLevel(createdBike, 0.0)
            SetVehicleDoorsLocked(createdBike, 3)
            FreezeEntityPosition(createBike, true)
            SetVehicleNumberPlateText(createdBike, 'Rent Me')

        end

    end

end

local spawnNPC = function()

    for k, ped in pairs(rentalLocations) do

        if ped.pedHash then

            RequestModel(ped.pedHash)

            while not HasModelLoaded(ped.pedHash)do
                Wait(5)
            end

        end       

    end
    
    createNPC()

end

local spawnBike = function()

    for k, bike in pairs(rentalLocations) do

        if bike.bikeHash then

            RequestModel(bike.bikeHash)

            while not HasModelLoaded(bike.bikeHash) do
                Wait(5)
            end

        end

    end

    createBike()

end

CreateThread(function()

    spawnNPC()
    spawnBike()

    for k, rentals in pairs(rentalLocations) do

        exports.ox_target:addSphereZone({
            coords      = rentals.coords,
            size        = vec3(1, 1, 2),
            rotation    = -20,
            debug = config.debug,
            options = {
                {
                    icon = 'fa fa-briefcase',
                    label = 'Rentals',
                    onSelect = function()
                        currentSpawnPoint = rentals.spawnPoint
                        if rentals.rentalType == 'car' then
                            TriggerEvent('qbx_rentals:client:openMenu', rentals.rentalType)
                        elseif rentals.rentalType == 'bike' then
                            TriggerEvent('qbx_rentals:client:openMenu', rentals.rentalType)
                        end
                    end,
                    distance = 2,
                }
            }
        })

        if rentals.rentalType == 'car' then
            rentals.blip = AddBlipForCoord(rentals.coords.x, rentals.coords.y, rentals.coords.z)
            SetBlipSprite(rentals.blip, 56)
            SetBlipDisplay(rentals.blip, 4)
            SetBlipScale(rentals.blip, 0.65)
            SetBlipColour(rentals.blip, 50)
            SetBlipAsShortRange(rentals.blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(rentals.label)
            EndTextCommandSetBlipName(rentals.blip)
        elseif rentals.rentalType == 'bike' then
            rentals.blip = AddBlipForCoord(rentals.coords.x, rentals.coords.y, rentals.coords.z)
            SetBlipSprite(rentals.blip, 106)
            SetBlipDisplay(rentals.blip, 4)
            SetBlipScale(rentals.blip, 0.65)
            SetBlipColour(rentals.blip, 0)
            SetBlipAsShortRange(rentals.blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(rentals.label)
            EndTextCommandSetBlipName(rentals.blip)
        end


    end

end)