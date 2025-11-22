local EvidencePoints = {}
local isFlashlightOn = false
local lastShotTime = 0

CreateThread(function()
    while true do
        local ped = cache.ped
        isFlashlightOn = IsFlashLightOn(ped)
        
        if not isFlashlightOn then
            lib.hideTextUI()
        end
        Wait(500)
    end
end)

local function CreateEvidencePoint(id, data)
    local point = lib.points.new({
        coords = data.coords,
        distance = 10,
        evidenceId = id,
        evidenceType = data.type,
        isUiOpen = false,
        
        onExit = function(self)
            if self.isUiOpen then
                lib.hideTextUI()
                self.isUiOpen = false
            end
        end,

        nearby = function(self)
            if not isFlashlightOn then return end
            
            if self.evidenceType == 'casing' then
                DrawMarker(1, self.coords.x, self.coords.y, self.coords.z - 0.98, 0, 0, 0, 0, 0, 0, 0.1, 0.1, 0.1, 255, 215, 0, 200, false, false, 2, false, nil, nil, false)
            else
                DrawMarker(23, self.coords.x, self.coords.y, self.coords.z - 0.98, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.05, 150, 0, 0, 200, false, false, 2, false, nil, nil, false)
            end

            if self.currentDistance < 1.5 then
                if not self.isUiOpen then
                    lib.showTextUI('[E] - Topla  \n [G] - Temizle', {
                        position = "right-center",
                        icon = 'magnifying-glass',
                        style = {
                            borderRadius = 0,
                            backgroundColor = '#48BB78',
                            color = 'white'
                        }
                    })
                    self.isUiOpen = true
                end

                if IsControlJustPressed(0, 38) then
                    if lib.progressBar({
                        duration = 2000,
                        label = 'Delil toplanıyor...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, car = true, combat = true },
                        anim = {
                            dict = 'pickup_object',
                            clip = 'pickup_low'
                        },
                    }) then
                        TriggerServerEvent('kod_evidence:pickup', id)
                    end
                end

                if IsControlJustPressed(0, 47) then 
                    if lib.progressBar({
                        duration = 3000,
                        label = 'Temizleniyor...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, car = true, combat = true },
                        anim = { dict = 'timetable@maid@cleaning_window@idle_a', clip = 'idle_a' }
                    }) then
                        TriggerServerEvent('kod_evidence:clean', id)
                        lib.hideTextUI()
                        self.isUiOpen = false
                    end
                end

            else
                if self.isUiOpen then
                    lib.hideTextUI()
                    self.isUiOpen = false
                end
            end
        end
    })
    
    EvidencePoints[id] = point
end

local function OpenArchiveMenu()
    lib.callback('kod_evidence:getArchives', false, function(reports)
        if not reports or #reports == 0 then
            lib.notify({title = 'Arşiv', description = 'Kayıtlı rapor bulunamadı.', type = 'error'})
            return
        end

        local options = {}
        for _, report in pairs(reports) do
            local data = json.decode(report.report_data)
            local icon = (report.evidence_type == 'blood') and 'droplet' or 'gun'
            
            -- 1. TÜRÜ TÜRKÇELEŞTİRME
            local typeLabel = "Bilinmiyor"
            if report.evidence_type == 'casing' then
                typeLabel = "Mermi Kovanı"
            elseif report.evidence_type == 'blood' then
                typeLabel = "Kan Örneği"
            end

            -- 2. TARİHİ SUNUCUDAN ALMA (Düzeltilen Kısım)
            -- Artık burada os.date kullanmıyoruz.
            local dateLabel = report.formatted_date or "Tarih Bilinmiyor"

            table.insert(options, {
                title = string.format("Rapor #%d (%s)", report.id, report.officer_name),
                description = string.format("Tarih: %s | Tür: %s", dateLabel, typeLabel),
                icon = icon,
                onSelect = function()
                    lib.registerContext({
                        id = 'archive_detail_'..report.id,
                        title = 'Arşiv Raporu #'..report.id,
                        menu = 'archive_menu_main',
                        options = {
                            {
                                title = 'Rapor Detayı',
                                description = data.formatted,
                                icon = 'file-lines',
                                readOnly = true
                            }
                        }
                    })
                    lib.showContext('archive_detail_'..report.id)
                end
            })
        end

        lib.registerContext({
            id = 'archive_menu_main',
            title = 'Laboratuvar Arşivi',
            menu = 'lab_main_menu',
            options = options
        })
        lib.showContext('archive_menu_main')
    end)
end

local function OpenLabMenu()
    local items = exports.ox_inventory:GetPlayerItems()
    local evidenceOptions = {}
    
    table.insert(evidenceOptions, {
        title = "Arşiv Kayıtları",
        description = "Geçmiş analiz raporlarını görüntüle.",
        icon = "box-archive",
        iconColor = "#38bdf8",
        onSelect = OpenArchiveMenu
    })

    for _, item in pairs(items) do
        if item.name == 'evidence_bullet' or item.name == 'evidence_blood' then
            local meta = item.metadata
            local title = item.label
            
            local function analyzeEvidence()
                if lib.progressBar({ 
                    duration = 5000, 
                    label = 'Laboratuvar analizi yapılıyor...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = {
                        dict = 'missheistdockssetup1clipboard@base',
                        clip = 'base',
                        flag = 49
                    },
                    prop = {
                        model = 'p_amb_clipboard_01',
                        bone = 18905,
                        pos = vec3(0.10, 0.02, 0.08),
                        rot = vec3(-80.0, 0.0, 0.0)
                    }
                }) then
                    local reportString = ""
                    local formattedDate = meta.date or "Tarih Bilgisi Yok (Eski Delil)"

                    local reportType = "unknown"
                    if item.name == 'evidence_bullet' then
                        reportType = "casing"
                        reportString = string.format(
                            "### BALİSTİK RAPORU\n\n" ..
                            "**Ateşlenme Zamanı:** %s\n" ..
                            "**Silah Seri Numarası:** %s\n" ..
                            "**Silah Modeli (Hash):** %s",
                            formattedDate,
                            meta.serial or "Tespit Edilemedi (Eldiven?)",
                            meta.weapon or "Bilinmiyor"
                        )
                    elseif item.name == 'evidence_blood' then
                        reportType = "blood"
                        local currentTime = GetCloudTimeAsInt()
                        local passed = (currentTime - (meta.timestamp or 0))
                        
                        if passed > Config.BloodDegradeTime then
                            reportString = string.format(
                                "### DNA ANALİZ RAPORU\n\n" ..
                                "**Durum:** BOZULMUŞ ÖRNEK\n" ..
                                "Örnek çok eski olduğu için DNA yapısı parçalanmış. Kimlik tespiti yapılamıyor."
                            )
                        else
                            reportString = string.format(
                                "### DNA ANALİZ RAPORU\n\n" ..
                                "**Olay Zamanı:** %s\n" ..
                                "**DNA Eşleşmesi (CitizenID):** %s\n" ..
                                "**Kan Grubu:** %s",
                                formattedDate,
                                meta.dna or "Bilinmiyor",
                                meta.bloodType or "Bilinmiyor"
                            )
                        end
                    end
                    
                    TriggerServerEvent('kod_evidence:saveReport', reportType, {
                        formatted = reportString,
                        meta = meta
                    }, item.slot, item.name)

                    lib.registerContext({
                        id = 'evidence_result_'..item.slot,
                        title = 'Analiz Sonucu',
                        menu = 'lab_main_menu',
                        options = {
                            {
                                title = '',
                                description = reportString,
                                icon = 'file-medical',
                                readOnly = true
                            }
                        }
                    })
                    lib.showContext('evidence_result_'..item.slot)
                end
            end
            
            table.insert(evidenceOptions, {
                title = title,
                description = "Slot: " .. item.slot .. " | Detaylı inceleme için seçin.",
                icon = 'microscope',
                onSelect = analyzeEvidence
            })
        end
    end
    
    lib.registerContext({
        id = 'lab_main_menu',
        title = 'Adli Tıp Laboratuvarı',
        options = evidenceOptions
    })
    
    lib.showContext('lab_main_menu')
end

RegisterNetEvent('kod_evidence:client:syncOne', function(id, data)
    CreateEvidencePoint(id, data)
end)

RegisterNetEvent('kod_evidence:client:remove', function(id)
    if EvidencePoints[id] then
        if EvidencePoints[id].isUiOpen then
            lib.hideTextUI()
        end
        EvidencePoints[id]:remove()
        EvidencePoints[id] = nil
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    lib.callback('kod_evidence:getAll', false, function(evidences)
        for id, data in pairs(evidences) do
            CreateEvidencePoint(id, data)
        end
    end)
end)

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        if IsPedShooting(ped) then
            local currentTime = GetGameTimer()
            if currentTime - lastShotTime > 5000 then
                lastShotTime = currentTime
                
                local weapon = GetSelectedPedWeapon(ped)
                TriggerServerEvent('kod_evidence:create', 'casing', {
                    coords = GetEntityCoords(ped),
                    weapon = weapon,
                    ammoType = GetPedAmmoTypeFromWeapon(ped, weapon)
                })
            end
        end
    end
end)

CreateThread(function()
    for _, lab in pairs(Config.Labs) do
        exports.ox_target:addSphereZone({
            coords = lab.coords,
            radius = lab.radius,
            options = {
                {
                    name = 'open_lab',
                    icon = 'fas fa-flask',
                    label = 'Laboratuvarı Kullan',
                    groups = lab.job,
                    onSelect = OpenLabMenu
                }
            }
        })
    end
end)