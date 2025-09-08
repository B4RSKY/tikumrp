local M = {}

-- Base36 untuk kode unik singkat
local function toBase36(num)
    local digits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local res = ''
    repeat
        local r = (num % 36) + 1
        res = digits:sub(r, r) .. res
        num = math.floor(num / 36)
    until num == 0
    return res
end

-- Hash string sederhana → angka
local function simpleHash(s)
    local h = 5381
    for i = 1, #s do
        h = ((h << 5) + h) ~ s:byte(i)
        h = h & 0x7fffffff
    end
    return h
end

-- Generate kode dari license + citizenid (6–8 char)
function M.generateCode(license, citizenid, prefix, randLen)
    prefix = prefix or 'TIKUM-'
    randLen = math.max(4, math.min(8, randLen or 6))
    local seed = (license or '') .. ':' .. (citizenid or '') .. ':' .. tostring(os.time()) .. ':' .. tostring(math.random(1, 1e9))
    local n = simpleHash(seed)
    local base = toBase36(n):gsub('[^0-9A-Z]', '')
    -- pastikan cukup panjang
    if #base < randLen then base = (base .. '00000000'):sub(1, randLen) end
    return prefix .. base:sub(1, randLen)
end

function M.now() return os.time() end

function M.formatDiscordEmbed(title, description, fields)
    return {
        username = 'TK Referral',
        embeds = {{
            title = title,
            description = description,
            color = 11862711, -- ungu-ish
            fields = fields or {},
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }}
    }
end

return M