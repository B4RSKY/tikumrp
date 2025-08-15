local QBCore = exports['qb-core']:GetCoreObject()
local spawnedPeds = {}
local hasAddLocalEntity = exports.ox_target and exports.ox_target.addLocalEntity ~= nil

local function isJobAllowed()
    local data = QBCore.Functions.GetPlayerData()
    if not data or not data.job then return false end
    local jobs = (Config.Client and Config.Client.AllowedJobs) or {}
    local minGrade = jobs[data.job.name]
    return minGrade and data.job.grade.level >= minGrade
end

-- ===Menu Self Service KTP===
local function openMenuMandiri()
    lib.registerContext({
        id = 'menu_mandiri',
        title = 'REQUEST KTP MANDIRI',
        options = {{
            title = 'Buat KTP (1 Bulan)',
            icon = 'id-card',
            onSelect = function()
                local mugshot = ''
                if Config.UseMugshotBase64 then
                    local ok, shot = pcall(function()
                        return exports["MugShotBase64"]:GetMugShotBase64(PlayerPedId(), true)
                    end)
                    mugshot = (ok and shot) and shot or ''
                end
                TriggerServerEvent('sky-license:server:selfCreate', mugshot)
            end
        }}
    })
    lib.showContext('menu_mandiri')
end

--Panel Audit
local function _badge(txt) return ('[%s]'):format(txt) end

-- === Per-license Audit ===
local function openAuditByLicense(licenseId, page)
    lib.callback('sky-license:server:getAuditByLicense', false, function(res)
        if not res then
            return lib.notify({ title='Audit', description='Gagal memuat audit lisensi.', type='error' })
        end
        local opts = {}
        for _, row in ipairs(res.items or {}) do
            local title = ('%s %s %s'):format(_badge(row.license_type:upper()), row.action, row.ts_h)
            local desc = ('Actor: %s\n%s'):format(row.actor_disp or '-', row.details_h or '')
            opts[#opts+1] = {
                title = title, description = desc, icon = 'scroll',
                onSelect = function()
                    lib.alertDialog({
                        header = title,
                        content = ('%s\n\nActor: %s\nHolder: %s\nJob: %s\n\nDetail:\n%s'):format(
                            row.ts_h,
                            row.actor_disp or '-',
                            row.holder_disp or '-',
                            row.actor_jobgrade or '-',
                            row.details_h or '-'
                        ),
                        centered = true
                    })
                end
            }
        end

        local total = res.total or 0
        local pageNow = res.page or 1
        local size = res.pageSize or 10
        local hasPrev = pageNow > 1
        local hasNext = (pageNow * size) < total
        if hasPrev then
            opts[#opts+1] = { title='‹ Sebelumnya', icon='chevron-left', onSelect=function() openAuditByLicense(licenseId, pageNow-1) end }
        end
        if hasNext then
            opts[#opts+1] = { title='Berikutnya ›', icon='chevron-right', onSelect=function() openAuditByLicense(licenseId, pageNow+1) end }
        end

        lib.registerContext({
            id = 'menu_audit_license'..licenseId..'_'..pageNow,
            title = ('Audit License #%d (Total %d)'):format(licenseId, total),
            options = opts
        })
        lib.showContext('menu_audit_license'..licenseId..'_'..pageNow)
    end, licenseId, page or 1, 10)
end

-- ================== PANEL MANAGE LICENSE ==================
local function openLicenseActions(row, returnPage)
    local opts = {
        {
            title = 'Perpanjang...',
            icon = 'calendar',
            description = ('Berlaku saat ini: %s'):format(row.expires_at_h),
            onSelect = function()
                local newd = lib.inputDialog('Perpanjang License', {
                    { type = 'date', label = 'Tanggal Berlaku Baru', required = true, format = "DD/MM/YYYY" }
                })
                if not newd then return end
                local newMs = newd[1] -- ms
                if not newMs then return end
                local newSec = math.floor(newMs / 1000)
                TriggerServerEvent('sky-license:server:extendLicense', row.id, newSec)
                lib.notify({ title = 'Proses', description = 'Memperpanjang license...', type = 'inform' })
                Wait(300)
                TriggerEvent('sky-license:client:manageOpen', returnPage)
            end
        },
        {
            title = 'Cabut',
            icon = 'ban',
            description = 'Hapus license & item',
            onSelect = function()
                local ok = lib.alertDialog({
                    header = 'Konfirmasi Pencabutan',
                    content = ('Pencabutan license untuk %s (%s)?'):format(row.holder_name, row.holder_citizenid),
                    centered = true,
                    cancel = true,
                    labels = { confirm = 'Cabut', cancel = 'Batal' }
                })
                if ok ~= 'confirm' then return end
                TriggerServerEvent('sky-license:server:revokeLicense', row.id)
                lib.notify({ title = 'Proses', description = 'Revoking...', type = 'inform' })
                Wait(300)
                TriggerEvent('sky-license:client:manageOpen', returnPage)
            end
        },
        {
            title = 'Lihat Audit',
            icon = 'scroll',
            description = 'Riwayat aksi untuk lisensi ini',
            onSelect = function() openAuditByLicense(row.id, 1) end
        },
    }

    lib.registerContext({
        id = 'menu_license_action' .. row.id,
        title = ('License: %s (%s)'):format(row.holder_name, row.holder_citizenid),
        description = ('Diterbitkan: %s oleh %s\nBerlaku: %s'):format(row.issued_at_h, row.issuer_name, row.expires_at_h),
        options = opts
    })
    lib.showContext('menu_license_action' .. row.id)
end

local function fetchIssuableTypes(cb)
    lib.callback('sky-license:server:getIssuableTypes', false, function(list)
        cb(list or {})
    end)
end

local function isValidUrl(s)
    if type(s) ~= 'string' then return false end
    if #s > 2048 then return false end
    return s:match('^https?://') ~= nil
end

-- === Menu buat License ===
local function openMenuBuat()
    if not isJobAllowed() then
        return lib.notify({ title = 'Tidak Ada Akses', description = 'Job/grade tidak diizinkan.', type = 'error' })
    end

    fetchIssuableTypes(function(list)
        if #list == 0 then
            return lib.notify({ title = 'Tidak Ada Akses', description = 'Job ini tidak punya izin menerbitkan lisensi.', type = 'error' })
        end

        local options = {}
        for _, t in ipairs(list) do
            options[#options+1] = { value = t.code, label = t.title }
        end

        local pick = lib.inputDialog('Pilih Tipe License', {
            { type = 'select', label = 'Tipe License', options = options, required = true },
        })
        if not pick then return end

        local ltype = pick[1]
        local tdef = Config.LicenseTypes[ltype]
        if not tdef then
            return lib.notify({ title = 'Error', description = 'Tipe license tidak dikenal.', type = 'error' })
        end

        local fields = {
            { type = 'number', label = 'ID Player', description = 'Masukkan ID player', required = true, min = 1 },
            { type = 'date', label = 'Berlaku Sampai', description = 'Tanggal akhir berlaku', required = true, format = "DD/MM/YYYY" },
        }

        if tdef.require_photo then
            fields[#fields+1] = {
                type = 'select', label = 'Jenis Foto',
                options = {
                    { value = 'auto', label = 'Otomatis' },
                    { value = 'manual', label = 'Manual (Link URL)' },
                },
                required = true, default = 'auto'
            }
            fields[#fields+1] = {
                type = 'input', label = 'Link Foto (jika manual)',
                description = 'Contoh: https://imgur.com/xxxx.jpg',
                required = false
            }
        end

        local input = lib.inputDialog(('Terbitkan %s'):format(tdef.title or ltype), fields)
        if not input then return end

        local idx = 0
        local targetId = tonumber(input[idx+1]); idx = idx + 1
        local expireMs = input[idx+1];          idx = idx + 1

        local photo = ''
        if tdef.require_photo then
            local mode = input[idx+1];          idx = idx + 1
            local link = input[idx+1] or '';    idx = idx + 1

            if mode == 'auto' then
                if Config.UseMugshotBase64 then
                    local ok, shot = pcall(function()
                        return exports["MugShotBase64"]:GetMugShotBase64(PlayerPedId(), true)
                    end)
                    photo = (ok and shot) or ''
                    if photo == '' then
                        return lib.notify({ title='Error', description='Gagal mengambil mugshot.', type='error' })
                    end
                else
                    return lib.notify({ title='Error', description='Mugshot tidak diaktifkan di config.', type='error' })
                end
            elseif mode == 'manual' then
                if link == '' or not isValidUrl(link) then
                    return lib.notify({ title='Error', description='Link foto tidak valid (wajib http/https).', type='error' })
                end
                photo = link
            else
                return lib.notify({ title='Error', description='Mode foto tidak dikenal.', type='error' })
            end
        end

        TriggerServerEvent('sky-license:server:requestData', ltype, targetId, photo, expireMs)
    end)
end

-- ==== Filter Manage License ====
local MANAGE_PAGE = 1
local MANAGE_SIZE = 10
local manageFilters = { status = nil, search = nil }

local function openManageFilterDialog()
    local statusOpts = {
        { value = 'all',     label = 'Semua' },
        { value = 'active',  label = 'Active' },
        { value = 'expired', label = 'Expired' },
    }
    local input = lib.inputDialog('Filter Manage License', {
        { type = 'input',  label = 'Cari (nama/citizen)', required = false, default = manageFilters.search },
        { type = 'select', label = 'Status', options = statusOpts, required = false, default = manageFilters.status }
    })
    if not input then return end
    manageFilters.search = (input[1] and input[1] ~= '') and input[1] or nil
    manageFilters.status = input[2]
end

local function _hasManageFilters()
    return (manageFilters.search and manageFilters.search ~= '') or (manageFilters.status and manageFilters.status ~= 'all')
end

-- ==== BUKA MANAGE ====
RegisterNetEvent('sky-license:client:manageOpen', function(page)
    MANAGE_PAGE = page or 1

    lib.callback('sky-license:server:getLicenses', false, function(res)
        if not res then
            return lib.notify({ title = 'Manage License', description = 'Gagal memuat data.', type = 'error' })
        end

        local opts = {}

        opts[#opts+1] = {
            title = 'Filter…',
            icon = 'filter',
            description = ('Status: %s  |  Search: %s'):format(manageFilters.status or 'all', manageFilters.search or '-'),
            onSelect = function()
                openManageFilterDialog()
                TriggerEvent('sky-license:client:manageOpen', 1)
            end
        }
        if _hasManageFilters() then
            opts[#opts+1] = {
                title = 'Clear Filters',
                icon = 'x-circle',
                description = 'Hapus semua filter',
                onSelect = function()
                    manageFilters = { status = nil, search = nil }
                    TriggerEvent('sky-license:client:manageOpen', 1)
                end
            }
        end

        for _, row in ipairs(res.items or {}) do
            local lt = (Config.LicenseTypes and Config.LicenseTypes[row.license_type])
            local ltTitle = (lt and lt.title) or (row.license_type or 'unknown')
            opts[#opts+1] = {
                title = ('%s (%s) - %s'):format(row.holder_name, row.holder_citizenid, ltTitle),
                icon = 'id-card',
                description = ('Diterbitkan: %s oleh %s\nKedaluwarsa: %s'):format(row.issued_at_h, row.issuer_name, row.expires_at_h),
                onSelect = function() openLicenseActions(row, MANAGE_PAGE) end
            }
        end

        local total = res.total or 0
        local hasPrev = MANAGE_PAGE > 1
        local hasNext = (MANAGE_PAGE * MANAGE_SIZE) < total
        if hasPrev then
            opts[#opts+1] = { title = '‹ Sebelumnya', icon = 'chevron-left', onSelect = function() TriggerEvent('sky-license:client:manageOpen', MANAGE_PAGE - 1) end }
        end
        if hasNext then
            opts[#opts+1] = { title = 'Berikutnya ›', icon = 'chevron-right', onSelect = function() TriggerEvent('sky-license:client:manageOpen', MANAGE_PAGE + 1) end }
        end

        lib.registerContext({
            id = 'menu_manange_license_'..MANAGE_PAGE,
            title = 'Manage License',
            options = opts
        })
        lib.showContext('menu_manange_license_'..MANAGE_PAGE)
    end, MANAGE_PAGE, MANAGE_SIZE, { search = manageFilters.search, status = manageFilters.status })
end)

-- ==== Menu Audit Log====
local AUDIT_PAGE = 1
local AUDIT_SIZE = 10
local auditFilters = {
    license_type = nil,
    action = nil,
    actor = nil,
    holder = nil,
    from = nil,
    to = nil
}

-- === Global Audit ===
local function openAuditFilters()
    local types = {}
    for code, def in pairs(Config.LicenseTypes or {}) do
        types[#types+1] = { value = code, label = def.title or code }
    end
    table.sort(types, function(a,b) return a.label < b.label end)

    local actions = {
        { value = 'issue', label = 'Issue' },
        { value = 'extend', label = 'Extend' },
        { value = 'revoke', label = 'Revoke' },
        { value = 'auto_expire', label = 'Auto Expire' },
        { value = 'auto_suspend', label = 'Auto Suspend' },
        { value = 'auto_reactivate', label = 'Auto Reactivate' },
        { value = 'sync_update', label = 'Sync Update' },
        { value = 'reissue_item', label = 'Reissue Item' },
    }

    local input = lib.inputDialog('Filter Audit', {
        { type = 'select', label = 'Tipe Lisensi', options = types, required = false },
        { type = 'select', label = 'Aksi', options = actions, required = false },
        { type = 'input',  label = 'Penerbit (nama/citizen/job)', required = false },
        { type = 'input',  label = 'Pemilik (nama/citizen)', required = false },
        { type = 'date',   label = 'Dari Tanggal', required = false, format = 'DD/MM/YYYY' },
        { type = 'date',   label = 'Sampai Tanggal', required = false, format = 'DD/MM/YYYY' },
    })
    if not input then return end

    auditFilters.license_type = input[1]
    auditFilters.action = input[2]
    auditFilters.actor = input[3]
    auditFilters.holder = input[4]
    auditFilters.from = input[5]
    auditFilters.to = input[6]
end

local function openAuditGlobal(page)
    AUDIT_PAGE = page or 1
    lib.callback('sky-license:server:getAudit', false, function(res)
        if not res then
            return lib.notify({ title='Audit', description='Gagal memuat audit.', type='error' })
        end
        local opts = {}

        opts[#opts+1] = {
            title = 'Filter…',
            icon = 'filter',
            description = 'Atur filter audit',
            onSelect = function()
                openAuditFilters()
                openAuditGlobal(1)
            end
        }

        if (auditFilters.license_type or auditFilters.action or auditFilters.actor or auditFilters.holder or auditFilters.from or auditFilters.to) then
            opts[#opts+1] = {
                title = 'Clear Filters',
                icon = 'x-circle',
                description = 'Hapus filter audit',
                onSelect = function()
                    auditFilters = { license_type = nil, action = nil, actor = nil, holder = nil, from = nil, to = nil }
                    openAuditGlobal(1)
                end
            }
        end

        for _, row in ipairs(res.items or {}) do
            local title = ('%s %s %s'):format(_badge(row.license_type:upper()), row.action, row.ts_h)
            local desc = ('Penerbit: %s • Pemilik: %s\n%s'):format(
                row.actor_disp or '-', row.holder_disp or '-', row.details_h or ''
            )
            opts[#opts+1] = {
                title = title, description = desc, icon = 'scroll',
                onSelect = function()
                    lib.alertDialog({
                        header = title,
                        content = ('%s\n\nPenerbit: %s\nPemilik: %s\nJob: %s\n\nDetail:\n%s'):format(
                            row.ts_h,
                            row.actor_disp or '-',
                            row.holder_disp or '-',
                            row.actor_jobgrade or '-',
                            row.details_h or '-'
                        ),
                        centered = true
                    })
                end
            }
        end

        local total = res.total or 0
        local hasPrev = AUDIT_PAGE > 1
        local hasNext = (AUDIT_PAGE * AUDIT_SIZE) < total
        if hasPrev then
            opts[#opts+1] = { title='‹ Sebelumnya', icon='chevron-left', onSelect=function() openAuditGlobal(AUDIT_PAGE-1) end }
        end
        if hasNext then
            opts[#opts+1] = { title='Berikutnya ›', icon='chevron-right', onSelect=function() openAuditGlobal(AUDIT_PAGE+1) end }
        end

        lib.registerContext({
            id = 'menu_audit_global_'..AUDIT_PAGE,
            title = ('Audit Log (Total %d)').format and ('Audit Log (Total %d)'):format(total) or 'Audit Log',
            options = opts
        })
        lib.showContext('menu_audit_global_'..AUDIT_PAGE)
    end, AUDIT_PAGE, AUDIT_SIZE, auditFilters)
end

-- PANEL UTAMA
local function openMenuUtama()
    if not isJobAllowed() then
        return lib.notify({ title = 'Akses Ditolak', description = 'Job/grade tidak diizinkan.', type = 'error' })
    end

    lib.registerContext({
        id = 'menu_utama_license_',
        title = 'Layanan KTP (Petugas)',
        options = {
            { title = 'Buat License', icon = 'user-check', onSelect = openMenuBuat },
            { title = 'Manage License', icon = 'folder-open', onSelect = function() TriggerEvent('sky-license:client:manageOpen', 1) end },
            { title = 'Audit Log', icon = 'scroll', onSelect = function() openAuditGlobal(1) end }
        }
    })
    lib.showContext('menu_utama_license_')
end

local function addPedTarget(ped, label, icon, onSelect, canInteract)
    if not ped or ped == 0 then return end
    local opts = {{
        name = 'target_license' .. tostring(ped),
        icon = icon or 'fa-solid fa-id-card',
        label = label or 'Layanan KTP',
        distance = 2.0,
        canInteract = canInteract,
        onSelect = onSelect
    }}
    if hasAddLocalEntity then exports.ox_target:addLocalEntity(ped, opts)
    else exports.ox_target:addEntity(ped, opts) end
end

local function spawnPedAt(st, onSelect, canInteract)
    lib.requestModel(st.pedModel, 3000)
    local ped = CreatePed(0, st.pedModel, st.coords.x, st.coords.y, st.coords.z - 1.0, st.heading or 0.0, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if st.scenario then TaskStartScenarioInPlace(ped, st.scenario, 0, true) end
    addPedTarget(ped, st.label, st.icon, onSelect, canInteract)
    spawnedPeds[#spawnedPeds+1] = ped
end

local function addZoneTarget(st, onSelect, canInteract)
    exports.ox_target:addBoxZone({
        coords = st.center,
        size = vec3(st.length, st.width, (st.maxZ - st.minZ)),
        rotation = st.heading or 0.0,
        debug = false,
        options = {{
            name = 'zone_license' .. st.id,
            icon = st.icon or 'fa-solid fa-id-card',
            label = st.label or 'Layanan KTP',
            onSelect = onSelect,
            canInteract = canInteract
        }}
    })
end

CreateThread(function()
    for _, st in ipairs((Config.Client and Config.Client.OfficerStations) or {}) do
        local gate = function(_, distance) return distance <= (st.distance or 2.0) and isJobAllowed() end
        if st.mode == 'ped' then
            spawnPedAt(st, openMenuUtama, gate)
        elseif st.mode == 'zone' then
            addZoneTarget(st, openMenuUtama, gate)
        end
    end

    --Bagian Mandiri
    for _, st in ipairs((Config.Client and Config.Client.SelfStations) or {}) do
        local gate = function(_, distance) return distance <= (st.distance or 2.0) end
        if st.mode == 'zone' then
            addZoneTarget(st, openMenuMandiri, gate)
        elseif st.mode == 'ped' then
            spawnPedAt(st, openMenuMandiri, gate)
        end
    end
end)

RegisterNetEvent('tk:lic:cl:showConfirm', function(dialogData, licenseType, targetId, photo, expireTs)
    local ok = lib.inputDialog('Konfirmasi License', dialogData)
    if not ok or not ok[6] then return end
    TriggerServerEvent('sky-license:server:Buatin', licenseType, targetId, photo or '', expireTs)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)