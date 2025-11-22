local function OpenLabMenu()
    -- Oyuncunun cebindeki delil itemlerini bul (ox_inventory export)
    local items = exports.ox_inventory:GetPlayerItems()
    local evidenceOptions = {}
    
    for _, item in pairs(items) do
        if item.name == 'evidence_bullet' or item.name == 'evidence_blood' then
            local meta = item.metadata
            local title = item.label
            local desc = "Henüz analiz edilmedi."
            
            -- Analiz Mantığı (Client side simülasyon, gerçek veri meta'da zaten var)
            local function analyzeEvidence()
                if lib.progressBar({ duration = 5000, label = 'Analiz Ediliyor...' }) then
                    local info = {}
                    
                    if item.name == 'evidence_bullet' then
                        info = {
                            { label = 'Silah Seri No', value = meta.serial },
                            { label = 'Silah Hash', value = meta.weapon }
                        }
                    elseif item.name == 'evidence_blood' then
                        -- Bozulma kontrolü
                        local passed = (os.time() - (meta.timestamp or 0))
                        if passed > Config.BloodDegradeTime then
                            info = { { label = 'DURUM', value = 'BOZULMUŞ ÖRNEK' } }
                        else
                            -- Serverdan isim çekmek için callback gerekebilir ama
                            -- basitçe citizenid'yi gösterelim:
                            info = { 
                                { label = 'DNA Eşleşmesi', value = meta.dna },
                                { label = 'Kan Grubu', value = meta.bloodType }
                            }
                        end
                    end
                    
                    -- Sonucu Alert olarak göster
                    lib.registerContext({
                        id = 'evidence_result_'..item.slot,
                        title = 'Analiz Sonucu',
                        options = {
                            {
                                title = 'Analiz Raporu',
                                description = json.encode(info, {indent=true}),
                                icon = 'file-medical'
                            }
                        }
                    })
                    lib.showContext('evidence_result_'..item.slot)
                end
            end
            
            table.insert(evidenceOptions, {
                title = title,
                description = "Slot: " .. item.slot,
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

-- Laboratuvar Target Noktası
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