local QBCore = exports['qb-core']:GetCoreObject()

-- Server event to call open identification card on valid players
RegisterServerEvent('tk-identification:server:showID', function(item, players)
	if #players > 0 then 
		for _,player in pairs(players) do 
			TriggerClientEvent('tk-identification:openID', player, item)
		end 
	end 
end)

QBCore.Commands.Add('getid', 'Menerima kartu identitas untuk karakter Anda.', {}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)

    if not Player then return end
    local card_metadata = {}
    card_metadata.type = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    card_metadata.citizenid = Player.PlayerData.citizenid
    card_metadata.firstName = Player.PlayerData.charinfo.firstname
    card_metadata.lastName = Player.PlayerData.charinfo.lastname
    card_metadata.dateofbirth = Player.PlayerData.charinfo.birthdate
    card_metadata.sex = (Player.PlayerData.charinfo.gender == 0 and 'Male' or 'Female')
    card_metadata.nationality = Player.PlayerData.charinfo.nationality
    card_metadata.cardtype = 'identification'

    local currentTime = os.time()
    local expiryTime = currentTime + 2629746

    card_metadata.issuedon = os.date('%m / %d / %Y', currentTime)
    card_metadata.expireson = os.date('%m / %d / %Y', expiryTime)
    card_metadata.description = ('Sex: %s | DOB: %s'):format(card_metadata.sex, card_metadata.dateofbirth)
    exports.ox_inventory:AddItem(source, 'identification', 1, card_metadata)
    TriggerClientEvent('QBCore:Notify', source, 'Anda telah menerima kartu identitas.', 'success')

end, 'admin') -- Membatasi command ini hanya untuk grup 'admin'