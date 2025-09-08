local Utils = require 'shared.utils'

-- Heartbeat posisi → server (anti-AFK)
CreateThread(function()
    while true do
        Wait((Config.AfkDetect.HeartbeatSecs or 5) * 1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local speed = GetEntitySpeed(ped) -- m/s
        TriggerServerEvent('tk_referral:hb', coords.x, coords.y, coords.z, speed)
    end
end)


-- ===== UI Helpers (ox_lib) =====
local function openMyReferralPanel()
    local ok, code = lib.callback.await('tk_referral:getCode', false)
    if not ok then
        lib.notify({ type = 'error', description = code or 'Gagal ambil kode' })
        return
    end

    local summary = lib.callback.await('tk_referral:getSummary', false) or {}
    local progress = summary.progress
    local desc = ('Kode kamu: **%s**'):format(code)
    if progress and progress.completed == 0 then
        desc = desc .. ("\nProgress: %ds / %ds"):format(progress.seconds_active or 0, progress.requirement_seconds or Config.RequirementSeconds)
    end
    if summary.totalCompletedAsReferrer then
        desc = desc .. ("\nCompleted (sebagai referrer): %d"):format(summary.totalCompletedAsReferrer)
    end

    lib.registerContext({
        id = 'tk_referral_panel',
        title = 'Referral',
        options = {
            { title = 'Kode Referral', description = desc, icon = 'hashtag' },
            {
                title = 'Copy Kode',
                icon = 'clipboard',
                onSelect = function()
                    lib.setClipboard(code)
                    lib.notify({ type = 'success', description = 'Kode disalin ke clipboard.' })
                end
            },
            {
                title = 'Redeem Kode',
                icon = 'key',
                onSelect = function()
                    local input = lib.inputDialog('Redeem Kode Referral', {
                        { type = 'input', label = 'Masukkan Kode', placeholder = 'ABC123', required = true }
                    })
                    if input and input[1] then
                        TriggerServerEvent('tk_referral:redeem', input[1])
                    end
                end
            },
            {
                title = 'Ganti Kode (Grace Switch)',
                icon = 'rotate',
                description = 'Hanya tersedia 15 menit pertama / sebelum aktif > 5 menit',
                onSelect = function()
                    local input = lib.inputDialog('Ganti Kode Referral', {
                        { type = 'input', label = 'Masukkan Kode Baru', placeholder = 'ABC123', required = true }
                    })
                    if input and input[1] then
                        TriggerServerEvent('tk_referral:switchCode', input[1])
                    end
                end
            }
        }
    })
    lib.showContext('tk_referral_panel')
end

local function openTopPanel()
    local data = lib.callback.await('tk_referral:getTop', false) or { rows = {} }
    local opts = {}
    for i, r in ipairs(data.rows or {}) do
        opts[#opts+1] = {
            title = ('#%d %s'):format(i, r.alias or r.referrer_license),
            description = ('Completed: %d'):format(r.total or 0)
        }
    end
    if #opts == 0 then
        opts[1] = { title = 'Belum ada data leaderboard.' }
    end
    lib.registerContext({
        id = 'tk_referral_top',
        title = 'Top Referrers (Lifetime)',
        options = opts
    })
    lib.showContext('tk_referral_top')
end

-- ===== Commands =====
RegisterCommand('refcode', function() openMyReferralPanel() end)
RegisterCommand('ref', function() openMyReferralPanel() end)
RegisterCommand('refredeem', function(_, args)
    local code = args and args[1]
    if not code then
        local input = lib.inputDialog('Redeem Kode Referral', {
            { type = 'input', label = 'Masukkan Kode', placeholder = 'ABC123', required = true }
        })
        if not input or not input[1] then return end
        code = input[1]
    end
    TriggerServerEvent('tk_referral:redeem', code)
end)
RegisterCommand('ref_top', function() openTopPanel() end)
RegisterCommand('ref top', function() openTopPanel() end)

-- ===== Debug Tools =====
RegisterCommand('refdebug', function()
    if not Config.Debug.Enable then
        lib.notify({ type = 'error', description = 'Debug dimatikan di config.' })
        return
    end
    lib.registerContext({
        id = 'tk_referral_debug',
        title = 'Referral Debug Tools',
        options = {
            {
                title = 'Buat Kode TEST Acak (Owner: DEBUG)',
                icon = 'flask',
                onSelect = function()
                    local ok, dbgCode = lib.callback.await('tk_referral:debug:createCode', false)
                    if ok then
                        lib.setClipboard(dbgCode)
                        lib.notify({ type = 'success', description = ('Kode TEST dibuat: %s (tersalin)'):format(dbgCode) })
                    else
                        lib.notify({ type = 'error', description = dbgCode or 'Gagal membuat kode debug' })
                    end
                end
            },
            {
                title = 'Redeem Kode (input)',
                icon = 'key',
                onSelect = function()
                    local input = lib.inputDialog('Redeem Kode (DEBUG)', {
                        { type = 'input', label = 'Kode', placeholder = 'TESTxx / ABC123', required = true }
                    })
                    if input and input[1] then
                        TriggerServerEvent('tk_referral:redeem', input[1], true)
                    end
                end
            },
            {
                title = 'Buka Panel Saya',
                icon = 'user',
                onSelect = function() openMyReferralPanel() end
            },
            {
                title = 'Lihat Leaderboard',
                icon = 'trophy',
                onSelect = function() openTopPanel() end
            }
        }
    })
    lib.showContext('tk_referral_debug')
end)
