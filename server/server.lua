local config        = require 'config.server'
local ox_inventory  = exports.ox_inventory
local QBX           = exports.qbx_core

--[[
QBX:CreateUseableItem('rentalpapers', function(source, item, plate)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
end)
]]

RegisterServerEvent('syn_rentals:server:rentalpapers', function(source, plate, model)
    local player = QBX:GetPlayer(source)
    local info = {}
    info.citizenid = player.PlayerData.citizenid
    info.firstname = player.PlayerData.charinfo.firstname
    info.lastname = player.PlayerData.charinfo.lastname
    info.rentalplate = plate
    info.rentalmodel = model
    ox_inventory:AddItem(source, 'rentalpapers', 1, info)
end)

RegisterServerEvent('syn_rentals:server:removepapers', function(source, plate, model)
    local info = {}
    info.rentalplate = plate
    local item = ox_inventory:GetSlotWithItem(source, 'rentalpapers', info)
    ox_inventory:RemoveItem(source, 'rentalpapers', 1, item.metadata)
end)

local function moneyCheck(source, model, cost, rentalType)

    if rentalType == 'car' then
        for k, v in pairs(config.cars) do 
            if model == v.model then
                cost = v.cost
            end

            local player = QBX:GetPlayer(source)
            if player.PlayerData.money.cash <= cost then 
                return false
            else
                ox_inventory:RemoveItem(source, 'cash', cost)
                return true
            end
        end
    elseif rentalType == 'bike' then
        for k, v in pairs(config.bikes) do 
            if model == v.model then
                cost = v.cost
            end

            local player = QBX:GetPlayer(source)
            if player.PlayerData.money.cash <= cost then 
                return false
            else
                ox_inventory:RemoveItem(source, 'cash', cost)
                return true
            end
        end
    end

end

lib.callback.register('syn_rentals:server:moneyCheck', moneyCheck)

lib.callback.register('syn_rentals:server:getTables', function(source, rentalType)

    if rentalType == 'locations' then
        return config.rentalLocations
    elseif rentalType == 'car' then
        return config.cars
    elseif rentalType == 'bike' then
        return config.bikes
    end

end)

lib.callback.register('syn_rentals:server:spawnVehicle', function(source, model, coords)

    local netId = qbx.spawnVehicle({model = model, spawnSource = coords, warp = GetPlayerPed(source)})
    if not netId or netId == 0 then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 then return end

    local plate = GetVehicleNumberPlateText(veh)
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
    TriggerEvent('syn_rentals:server:rentalpapers', source, plate, model)
    Entity(veh).state.fuel = 100
    return netId

end)

local function deleteVehicle(source, netId)

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local plate = GetVehicleNumberPlateText(vehicle)
    TriggerEvent('syn_rentals:server:removepapers', source, plate)
    DeleteEntity(vehicle)
    TriggerClientEvent('ox_lib:notify', source, {
        id = 'vehicleReturn',
        title = 'Returned Vehicle',
        description = 'You have returned the vehicle',
        type = 'success'
    })

    return true

end

lib.callback.register('syn_rentals:server:deleteVehicle', deleteVehicle)