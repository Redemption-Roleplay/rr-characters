RegisterNetEvent("d-character:server:saveNewCharacter", function(data)
	local _source = source
	local identifier = exports["d-core"]:GetIdentifier(_source, "license")
	local PlayerData = {}
	PlayerData.charinfo = {}
	PlayerData.charinfo["firstname"] = data["Info"]["Firstname"]
	PlayerData.charinfo["lastname"] = data["Info"]["Lastname"]
	PlayerData.charinfo["gender"] = data["Sex"] == "Male" and 0 or 1

	if exports["d-core"]:Login(_source, false, PlayerData) then
		local PlayerData = exports["d-core"]:GetPlayer(_source).PlayerData
		local skinData = json.encode(data["Skin"])
		local clothingData = json.encode(data["Clothing"])
		MySQL.insert("INSERT INTO outfits (citizenid, cid, label, clothing) VALUES (?,?,?,?)", {
			PlayerData.citizenid,
			PlayerData.cid,
			"Starter Clothing",
			clothingData,
		}, function(id)
			MySQL.update(
				"UPDATE players SET skin = ?, outfit = ? WHERE citizenid = ?",
				{ skinData, id, PlayerData.citizenid },
				function() end
			)
		end)

		exports["d-core"]:ShowSuccess(GetCurrentResourceName(), GetPlayerName(_source) .. " has successfully loaded")
		exports["d-core"]:RefreshCommands(_source)

		TriggerClientEvent("d-character:client:spawnPlayer", _source, skinData, clothingData, data["Sex"], true)
	end
end)

RegisterNetEvent("d-character:server:spawnPlayer", function(citizenid, skin, clothing, sex, newPlayer)
	local _source = source
	if exports["d-core"]:Login(_source, citizenid) then
		exports["d-core"]:ShowSuccess(GetCurrentResourceName(), GetPlayerName(_source) .. " has successfully loaded")
		exports["d-core"]:RefreshCommands(_source)
		TriggerClientEvent("d-character:client:spawnPlayer", _source, skin, clothing, sex, newPlayer)
	end
end)

RegisterNetEvent("d-character:server:deleteCharacter", function(citizenid)
	local _source = source
	exports["d-core"]:DeleteCharacter(_source, citizenid)
	TriggerClientEvent("d-character:client:reloadSelect", _source)
end)

AddEventHandler("QBCore:Server:PlayerLoaded", function() end)

exports["d-core"]:CreateCallback("d-character:server:fetchCharacters", function(source, cb)
	local _source = source
	local identifier = exports["d-core"]:GetIdentifier(_source, "license")
	local characters = MySQL.query.await("SELECT * FROM players WHERE license = ?", { identifier })

	if characters then
		local rTable = {}

		for i = 1, #characters, 1 do
			local outfitId = characters[i].outfit
			local outfitData = MySQL.prepare.await("SELECT clothing FROM outfits WHERE id = ?", { outfitId })

			rTable[#rTable + 1] = {
				citizenid = characters[i].citizenid,
				charinfo = json.decode(characters[i].charinfo),
				skin = json.decode(characters[i].skin),
				outfit = json.decode(outfitData),
			}
		end

		cb(rTable, identifier)
	else
		cb({})
	end

	MySQL.prepare("SELECT * FROM players WHERE license = ?", { identifier }, function(result)
		if result then
			cb(result)
		else
			cb({})
		end
	end)
end)

exports["d-core"]:CreateCallback("d-character:server:GetDonationTierFromLicense", function(source, cb, license)
	cb(exports["d-core"]:GetDonationTierFromLicense(licence))
end)

exports["d-core"]:AddCommand("loadchar", "Load your character", {}, false, function(source)
	local _source = source
	local PlayerData = exports["d-core"]:GetPlayer(_source).PlayerData
	local Player = MySQL.query.await("SELECT * FROM players WHERE citizenid = ?", { PlayerData.citizenid })
	local Outfits = MySQL.query.await("SELECT * FROM outfits WHERE citizenid = ?", { PlayerData.citizenid })
	TriggerClientEvent("d-character:client:loadCharacter", _source, Player[1], Outfits)
end)
