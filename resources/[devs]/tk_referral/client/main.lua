CreateThread(function()
    while true do
        Wait((Config.AfkDetect.HeartbeatSecs or 5) * 1000)
        local ped = PlayerPedId()
        local c = GetEntityCoords(ped)
        local spd = GetEntitySpeed(ped)
        TriggerServerEvent('tk_referral:hb', c.x, c.y, c.z, spd)
    end
end)

local function openTopPanel()
    local data = lib.callback.await('tk_referral:getTop', false) or { rows = {} }
    local opts = {}
    for i, r in ipairs(data.rows or {}) do
        opts[#opts+1] = {
        title = ('#%d %s'):format(i, r.alias or r.referrer_license),
        description = ('Completed: %d'):format(r.total or 0)
        }
    end
    if #opts == 0 then opts[1] = { title = 'Belum ada data leaderboard.' } end
    lib.registerContext({ id='tk_referral_top', title='Leaderboard Invitation', options=opts })
    lib.showContext('tk_referral_top')
end

local function openClaimsPanel(kind)
    local res = lib.callback.await('tk_referral:getClaims', false, kind) or {}
    local title = (kind=='referred') and 'Claim (Yang Di Redeem)' or 'Claim (Meredeem)'
    local opts = {}

    if res.count and res.count > 1 then
        opts[#opts+1] = {
        title = ('Claim ALL (%d)'):format(res.count), icon='check',
        onSelect = function() TriggerServerEvent('tk_referral:claimAll', kind) end
        }
    end

    for _, c in ipairs(res.items or {}) do
        local label = ('#%d %s'):format(c.id, c.reason or 'reward')
        opts[#opts+1] = {
        title = label, description = c.preview or '', icon='gift',
        onSelect = function() TriggerServerEvent('tk_referral:claimOne', c.id) end
        }
    end

    if #opts == 0 then opts[1] = { title = 'Tidak ada reward yang bisa di-claim.' } end
    lib.registerContext({ id='tk_referral_claim_'..kind, title=title, options=opts })
    lib.showContext('tk_referral_claim_'..kind)
end

local function openMyReferralPanel()
    local ok, code = lib.callback.await('tk_referral:getCode', false)
    if not ok then lib.notify({ type='error', description=code or 'Gagal ambil kode' }); return end
    local summary = lib.callback.await('tk_referral:getSummary', false) or {}
    local progress = summary.progress
    local desc = ('Kode: **%s**'):format(code)
    if progress and progress.completed == 0 then
        desc = desc .. ("\nProgress aktif: %ds / %ds"):format(progress.seconds_active or 0, progress.requirement_seconds or Config.RequirementSeconds)
    end
    if summary.totalCompletedAsReferrer then
        desc = desc .. ("\nCompleted (sebagai referrer): %d"):format(summary.totalCompletedAsReferrer)
    end

    lib.registerContext({
        id = 'tk_referral_panel',
        title = 'Referral',
        options = {
        { title='Info', description=desc, icon='info' },
        { title='Copy Kode', icon='clipboard', onSelect=function() lib.setClipboard(code); lib.notify({type='success',description='Kode disalin.'}) end },
        {
            title='Redeem Kode', icon='key',
            onSelect=function()
            local input = lib.inputDialog('Redeem Kode', {
                { type='input', label='Kode', placeholder='TIKUM-ABC123', required=true }
            })
            if input and input[1] then TriggerServerEvent('tk_referral:redeem', input[1]) end
            end
        },
        { title='Claim (Referred)', description = 'Ini Jika Kode anda yang di redeem',  icon='gift',   onSelect=function() openClaimsPanel('referred') end },
        { title='Claim (Referrer)', description = 'Ini Jika anda Meredeem Kode Teman',  icon='trophy', onSelect=function() openClaimsPanel('referrer') end },
        { title='Leaderboard',      icon='ranking-star', onSelect=function() openTopPanel() end },
        -- {
        --     title='Ganti Kode (Grace)', icon='rotate',
        --     description='Hanya 15 menit pertama / aktif ≤ 300 detik',
        --     onSelect=function()
        --     local input = lib.inputDialog('Ganti Kode', {{ type='input', label='Kode Baru', required=true }})
        --     if input and input[1] then TriggerServerEvent('tk_referral:switchCode', input[1]) end
        --     end
        -- },
        }
    })
    lib.showContext('tk_referral_panel')
end

RegisterCommand('ref', function() openMyReferralPanel() end)
RegisterCommand('refcode', function() openMyReferralPanel() end)
RegisterCommand('ref_top', function() openTopPanel() end)
RegisterCommand('refdebug', function()
    if not Config.Debug.Enable then lib.notify({type='error',description='Debug off.'}); return end
    local ok, code = lib.callback.await('tk_referral:debug:createCode', false)
    if ok then lib.setClipboard(code); lib.notify({type='success',description=('Kode DEBUG: %s (tersalin)'):format(code)}) end
end)