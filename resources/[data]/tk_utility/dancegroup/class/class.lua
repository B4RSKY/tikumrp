---@class dancegroup:OxClass
local dancegroup = lib.class('dancegroup')

function dancegroup:constructor(source)
    self.id = source
    self.emote = nil
    self.member = { [source] = 'pemilik' }
    self.lagidance = false
    return self
end

function dancegroup:getId()
    return self.id
end

function dancegroup:mulai(emote)
    local list = {}
    for id in pairs(self.member) do
        list[#list+1] = id
    end
    self.emote = emote
    self.lagidance = true
    lib.triggerClientEvent('tk_utility:dg:mulai', list, self.emote)
end

function dancegroup:berhenti()
    local list = {}
    for id in pairs(self.member) do
        list[#list+1] = id
    end
    self.emote = nil
    self.lagidance = false
    lib.triggerClientEvent('tk_utility:dg:stop', list)
end

function dancegroup:hapus(source, cb)
    local list = {}
    for id in pairs(self.member) do
        cb(id)
        list[#list+1] = id
        pcall(lib.notify, id, {description = 'Sesi dance group telah dibubarkan'})
    end
    lib.triggerClientEvent('tk_utility:dg:stop', list)
end

function dancegroup:gabung(source)
    self.member[source] = 'anggota'

    if self.lagidance then
        self:mulai(self.emote)
    end
end

function dancegroup:keluar(source, cb)
    if self.member[source] == 'pemilik' then
        self:hapus(source, cb)
        return
    end

    if cb then cb(source) end
    self.member[source] = nil
    lib.triggerClientEvent('tk_utility:dg:stop', source)
end

return dancegroup