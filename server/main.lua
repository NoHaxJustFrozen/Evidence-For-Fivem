local EvidenceStore = {}
local EvidenceCount = 0
local Framework = nil
local CoreName = nil

if GetResourceState('qb-core') == 'started' then
    CoreName = 'QB'
    Framework = exports['qb-core']:GetCoreObject()
elseif GetResourceState('es_extended') == 'started' then
    CoreName = 'ESX'
    Framework = exports['es_extended']:getSharedObject()
end

local function GetPlayerDetails(src)
    if not Framework then return nil, nil end
    local name = "Bilinmiyor"
    
    if CoreName == 'QB' then
        local Player = Framework.Functions.GetPlayer(src)
        if not Player then return nil, nil, name end
        name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        return Player.PlayerData.citizenid, (Player.PlayerData.metadata['bloodtype'] or "A+"), name
    elseif CoreName == 'ESX' then
        local xPlayer = Framework.GetPlayerFromId(src)
        if not xPlayer then return nil, nil, name end
        name = xPlayer.getName()
        return xPlayer.identifier, "A+", name
    end
end

local function hasGloves(source)
    local items = exports.ox_inventory:GetInventoryItems(source)
    if not items then return false end
    for _, item in pairs(items) do
        if Config.Gloves[item.name] then return true end
    end
    return false
end

RegisterNetEvent('kod_evidence:create', function(type, data)
    local src = source
    if EvidenceCount >= Config.MaxEvidenceLimit then return end
    
    local ped = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    if #(pCoords - data.coords) > 20.0 then return end

    local evidenceId = os.time() .. "_" .. math.random(1000, 9999)
    local metadata = {}
    local citizenid, bloodType, _ = GetPlayerDetails(src)
    local readableDate = os.date("%d/%m/%Y %H:%M:%S")

    if type == 'casing' then
        local weaponSerial = "YOK"
        if not hasGloves(src) then
            local weaponData = exports.ox_inventory:GetCurrentWeapon(src)
            if weaponData and weaponData.metadata.serial then
                weaponSerial = weaponData.metadata.serial
            end
        end
        metadata = {
            type = 'casing',
            weapon = data.weapon,
            serial = weaponSerial,
            ammo = data.ammoType,
            timestamp = os.time(),
            date = readableDate,
            description = "Seri No: " .. weaponSerial
        }
    elseif type == 'blood' then
        if not citizenid then return end
        metadata = {
            type = 'blood',
            dna = citizenid,
            bloodType = bloodType,
            timestamp = os.time(),
            date = readableDate,
            description = "Kan Grubu: " .. bloodType
        }
    end

    EvidenceStore[evidenceId] = {
        id = evidenceId,
        coords = data.coords,
        type = type,
        metadata = metadata
    }
    EvidenceCount = EvidenceCount + 1
    TriggerClientEvent('kod_evidence:client:syncOne', -1, evidenceId, EvidenceStore[evidenceId])
end)

RegisterNetEvent('kod_evidence:pickup', function(evidenceId)
    local src = source
    local evidence = EvidenceStore[evidenceId]
    if not evidence then return end
    
    local ped = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    if #(pCoords - evidence.coords) > 5.0 then return end

    local bagItemName = 'empty_evidence_bag'
    local bagCount = exports.ox_inventory:GetItemCount(src, bagItemName)
    
    if bagCount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Boş delil torban yok!'})
        return
    end

    if exports.ox_inventory:RemoveItem(src, bagItemName, 1) then
        local itemParams = {}
        if evidence.type == 'casing' then
            itemParams = {name = 'evidence_bullet', info = evidence.metadata}
        elseif evidence.type == 'blood' then
            itemParams = {name = 'evidence_blood', info = evidence.metadata}
        end

        local success, response = exports.ox_inventory:AddItem(src, itemParams.name, 1, itemParams.info)
        
        if success then
            EvidenceStore[evidenceId] = nil
            EvidenceCount = EvidenceCount - 1
            TriggerClientEvent('kod_evidence:client:remove', -1, evidenceId)
        else
            exports.ox_inventory:AddItem(src, bagItemName, 1)
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Envanter hatası.'})
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Delil torbası kullanılamadı.'})
    end
end)

RegisterNetEvent('kod_evidence:clean', function(evidenceId)
    local src = source
    local evidence = EvidenceStore[evidenceId]
    if not evidence then return end

    local ped = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    if #(pCoords - evidence.coords) > 5.0 then return end

    if exports.ox_inventory:RemoveItem(src, 'cleaning_cloth', 1) then
        exports.ox_inventory:AddItem(src, 'bloody_rag', 1)
        EvidenceStore[evidenceId] = nil
        EvidenceCount = EvidenceCount - 1
        TriggerClientEvent('kod_evidence:client:remove', -1, evidenceId)
    end
end)

RegisterNetEvent('kod_evidence:saveReport', function(type, reportData, itemSlot, itemName)
    local src = source
    local _, _, officerName = GetPlayerDetails(src)
    local jsonData = json.encode(reportData)

    exports.oxmysql:insert('INSERT INTO evidence_archive (officer_name, evidence_type, report_data) VALUES (?, ?, ?)', {
        officerName,
        type,
        jsonData
    }, function(id)
        if id then
            if itemSlot and itemName then
                exports.ox_inventory:RemoveItem(src, itemName, 1, nil, itemSlot)
            end
        end
    end)
end)

lib.callback.register('kod_evidence:getAll', function(source)
    return EvidenceStore
end)

-- GÜNCELLENEN KISIM: Tarih formatı sunucuda yapılıyor
lib.callback.register('kod_evidence:getArchives', function(source)
    local result = exports.oxmysql:query_async('SELECT * FROM evidence_archive ORDER BY id DESC LIMIT 50', {})
    
    if result then
        for i = 1, #result do
            local ts = result[i].created_at
            -- Eğer timestamp milisaniye (number) gelirse saniyeye çevir ve formatla
            if type(ts) == 'number' then
                result[i].formatted_date = os.date("%d/%m/%Y %H:%M", math.floor(ts / 1000))
            else
                -- Eğer string gelirse olduğu gibi kullan
                result[i].formatted_date = tostring(ts)
            end
        end
    end
    
    return result or {}
end)