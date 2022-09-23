local promptGroup = nil
local inSelector, inCustomization = false, false
local lightsEnabled = {
	selector = false,
	customization = false,
}

local currentMenu = nil
local uiSkin = {}
local uiClothing = {}

local temporaryPed = nil

local currentCamera = nil
local groundCamera, fixedCamera = nil, nil
local tempCamera, tempCamera2 = nil, nil
local interP, interP2 = false, false
local interPSettings = {
	cam1 = vec3(-0.5, 0.0, -0.7),
	cam2 = vec3(-0.5, 0.0, 0.6),
	cam3 = vec3(-1.5, 0.0, 0.0),
}

local Skin = {}
local Clothing = {}
local CharacterData = {}
local TempCharacterData = {}
local DefaultCharacterSkin = {}

local numberTable = {}
for tempNum = -100, 100, 1 do
	numberTable[#numberTable + 1] = tempNum
end

Skin["Male"] = {}
Skin["Female"] = {}
Clothing["Male"] = {}
Clothing["Female"] = {}
CharacterData["Sex"] = nil
CharacterData["Skin"] = {}
CharacterData["Features"] = {}
CharacterData["Clothing"] = {}
TempCharacterData["Sex"] = nil
TempCharacterData["Skin"] = {}
TempCharacterData["Features"] = {}
TempCharacterData["Clothing"] = {}
TempCharacterData["Info"] = {
	["Firstname"] = nil,
	["Lastname"] = nil,
	["Age"] = nil,
	["Nationality"] = nil,
}

local SendReactMessage = function(action, data)
	SendNUIMessage({
		action = action,
		data = data,
	})
end

local GetDonationTierFromLicense = function(license)
	exports["d-core"]:TriggerCallback("d-character:server:GetDonationTierFromLicense", function(tier)
		return tier
	end, license)
end

local createLights = function(area)
	CreateThread(function()
		while inSelector do
			Wait(0)
			if lightsEnabled["selector"] then
				DrawLightWithRange(-559.59, -3780.75, 238.59, 255, 255, 255, 50.0, 50.0)
			end

			if lightsEnabled["customization"] then
				DrawLightWithRange(-560.0, -3781.16, 238.59, 255, 255, 255, 50.0, 50.0)
			end
		end
	end)
end

local createCamera = function()
	groundCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA")
	SetCamCoord(groundCamera, -555.925, -3778.71, 238.59)
	SetCamRot(groundCamera, -20.0, 0.0, 83)
	SetCamActive(groundCamera, true)
	RenderScriptCams(true, false, 1, true, true)
	Wait(3000)

	fixedCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA")
	SetCamCoord(fixedCamera, -561.21, -3776.22, 239.59)
	SetCamRot(fixedCamera, -20.0, 0.0, 270.0)
	SetCamActive(fixedCamera, true)
	SetCamActiveWithInterp(fixedCamera, groundCamera, 3900, true, true)
	Wait(4000)

	DestroyCam(groundCamera)
	interP = true
end

local interpCamera = function(entity)
	SetCamActiveWithInterp(fixedCamera, tempCamera, 1200, true, true)
	tempCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA")
	AttachCamToEntity(tempCamera, entity, interPSettings["cam1"].x, interPSettings["cam1"].y, interPSettings["cam1"].z)
	SetCamActive(tempCamera, true)
	SetCamRot(tempCamera, -4.0, 0, 270.0)
	if interP then
		SetCamActiveWithInterp(tempCamera, fixedCamera, 1200, true, true)
		interP = false
	end
end

local interpCamera2 = function(camera, entity)
	SetCamActiveWithInterp(fixedCamera, tempCamera, 1200, true, true)
	tempCamera2 = CreateCam("DEFAULT_SCRIPTED_CAMERA")
	AttachCamToEntity(tempCamera2, entity, interPSettings[camera].x, interPSettings[camera].y, interPSettings[camera].z)
	SetCamActive(tempCamera2, true)
	SetCamRot(tempCamera2, 0.0, 0, 270.0)
	if interP2 then
		SetCamActiveWithInterp(tempCamera2, tempCamera, 1200, true, true)
		interP2 = false
	end
end

local switchCamera = function()
	if currentCamera == "cam1" then
		currentCamera = "cam2"
		interpCamera2("cam2", temporaryPed)
	elseif currentCamera == "cam2" then
		currentCamera = "cam3"
		interpCamera2("cam3", temporaryPed)
	elseif currentCamera == "cam3" then
		currentCamera = "cam1"
		interpCamera2("cam1", temporaryPed)
	end
end

local updateCharacterValue = function(ped, sex, name, value)
	TempCharacterData.Skin[name] = value or 0
	name = tostring(name) or nil
	value = tonumber(value) or 0

	if name == "BODIES_UPPER" then
		Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, false, true, true)
		Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, false, true, true)
		Citizen.InvokeNative(0x704C908E9C405136, ped)

		Wait(10)
		Citizen.InvokeNative(0x704C908E9C405136, ped)
		Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, 0, 1, 1, 1, 0)
	elseif name == "heads" then
		Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, false, true, true)
	elseif name == "hair" then
		if value == 0 then
			Citizen.InvokeNative(0xD710A5007C2AC539, ped, 0x864B03AE, 0)
			Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, 0, 1, 1, 1, 0)
		else
			Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, false, true, true)
		end
	elseif name == "teeth" then
		RequestAnimDict("FACE_HUMAN@GEN_MALE@BASE")
		while not HasAnimDictLoaded("FACE_HUMAN@GEN_MALE@BASE") do
			Citizen.Wait(100)
		end
		TaskPlayAnim(ped, "FACE_HUMAN@GEN_MALE@BASE", "Face_Dentistry_Loop", 1090519040, -4, -1, 17, 0, 0, 0, 0, 0, 0)
		Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, false, true, true)
	elseif name == "eyes" then
		Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, false, true, true)
	elseif name == "beards_complete" then
		if value == 0 then
			Citizen.InvokeNative(0xD710A5007C2AC539, ped, 0x864B03AE, 0)
			Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, 0, 1, 1, 1, 0)
		else
			if sex == "Male" then
				Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, false, true, true)
			end
		end
	end
end

local updateCharacterClothing = function(ped, sex, name, value)
	TempCharacterData.Clothing[name] = value or nil
	name = tostring(name) or nil
	value = tonumber(value) or nil

	Citizen.InvokeNative(0xD710A5007C2AC539, ped, GetHashKey(name), 0)
	if name == "shirts_full" then
		Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, false, true, true)
	elseif name == "boots" or name == "pants" then
		Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, false, true, true)
	end

	Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, value, false, true, true)

	Citizen.InvokeNative(0x704C908E9C405136, PlayerPedId())
	Citizen.InvokeNative(0xAAB86462966168CE, PlayerPedId(), 1)
	Citizen.InvokeNative(0xCC8CA3E88256E58F, PlayerPedId(), 0, 1, 1, 1, 0)
end

local updateCharacterFace = function(index, value, new)
	local new = new or false
	local ped = new and temporaryPed or PlayerPedId()
	local sex = new and TempCharacterData["Sex"] or (IsPedMale() and "Male" or "Female")

	local index = tonumber(index)
	local value = tonumber(value)

	TempCharacterData.Features[index] = value or 1.0

	Citizen.InvokeNative(0x5653AB26C82938CF, ped, index, value)
end

local fixCharacterValues = function(ped, sex)
	Citizen.InvokeNative(0x77FF8D35EEC6BBC4, ped, 0, 0)
	while not Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, ped) do
		Wait(0)
	end

	print(sex)

	Citizen.InvokeNative(0x0BFA1BD465CDFEFD, ped)
	Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, Skin[sex]["BODIES_UPPER"][1], false, true, true)
	Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, Skin[sex]["BODIES_LOWER"][1], false, true, true)
	Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, Skin[sex]["heads"][1], false, true, true)
	Citizen.InvokeNative(0xD710A5007C2AC539, ped, 0x1D4C528A, 0)
	Citizen.InvokeNative(0xD710A5007C2AC539, ped, 0x3F1F01E5, 0)
	Citizen.InvokeNative(0xD710A5007C2AC539, ped, 0xDA0E2C55, 0)
	Citizen.InvokeNative(0x704C908E9C405136, ped)
	Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, 0, 1, 1, 1, 0)
end

local GeneratePlayerModel = function(ped, sex, skin, clothing)
	local skin = skin or CharacterData["Skin"]
	local clothing = clothing or CharacterData["Clothing"]
	local ped = ped or PlayerPedId()

	fixCharacterValues(ped, sex)

	if skin and clothing then
		for k, v in pairs(skin) do
			updateCharacterValue(ped, sex, k, v, false)
		end

		for k, v in pairs(clothing) do
			updateCharacterClothing(ped, sex, k, v, false)
		end

		Wait(250)
		Citizen.InvokeNative(0x704C908E9C405136, ped)
		Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, 0, 1, 1, 1, 0)

		return true
	else
		print("Failed to generate player model!", "No data available")
		return false
	end
end

local createTemporaryPed = function(new, sex, skin, clothing)
	local sex = sex or "Male"
	local model = sex == "Male" and GetHashKey("mp_male") or GetHashKey("mp_female")

	RequestModel(model)
	while not HasModelLoaded(model) do
		Wait(0)
	end

	if temporaryPed then
		DeletePed(temporaryPed)
		Wait(500)
	end

	temporaryPed = CreatePed(model, -558.9098, -3775.616, 238.59 - 0.5, 137.98, false, 0)

	NetworkSetEntityInvisibleToNetwork(temporaryPed, true)

	if new then
		fixCharacterValues(temporaryPed, sex)
	else
		local bool = GeneratePlayerModel(temporaryPed, sex, skin, clothing)
	end
end

local fetchTrueValue = function(type, hash)
	for i = 1, #Skin[TempCharacterData["Sex"]][type], 1 do
		if Skin[TempCharacterData["Sex"]][type][i] == hash then
			return i
		end
	end
end

local fetchTrueClothingValue = function(type, hash)
	for i = 1, #Clothing[TempCharacterData["Sex"]][type], 1 do
		if Clothing[TempCharacterData["Sex"]][type][i] == hash then
			return i
		end
	end
end

local fetchFaceValues = function()
	local rTable = {}

	for k, v in pairs(Config.FaceFeatures) do
		rTable[k] = { hash = v, numbers = numberTable }
	end

	return rTable
end

local fetchSkinValues = function()
	local rTable = {}

	for k, v in pairs(Skin[TempCharacterData["Sex"]]) do
		rTable[k] = {}
		TempCharacterData.Skin[k] = v[1]

		for i = 1, #v, 1 do
			rTable[k][#rTable[k] + 1] = v[i]
		end
	end

	return rTable
end

local fetchClothingValues = function()
	local rTable = {}

	for k, v in pairs(Clothing[TempCharacterData["Sex"]]) do
		rTable[k] = {}
		rTable[k][1] = "None"
		for i = 1, #v, 1 do
			rTable[k][#rTable[k] + 1] = v[i]
		end
	end

	return rTable
end

-- local registerFaceFeaturesMenu = function()
-- 	if not TempCharacterData["Sex"] then
-- 		local sex = IsPedMale(PlayerPedId()) and "Male" or "Female"
-- 		TempCharacterData["Sex"] = sex
-- 	end

-- 	local optionValues = fetchFaceValues()
-- 	local options = {}

-- 	for k, v in pairs(optionValues) do
-- 		options[#options + 1] = {
-- 			label = exports["d-core"]:SplitStr(k, "_"),
-- 			values = v.numbers,
-- 			defaultIndex = CharacterData.Features[k] or 1,
-- 			args = { type = k },
-- 		}
-- 	end

-- 	lib.registerMenu({
-- 		id = "character_facefeatures_menu",
-- 		title = "Face Features",
-- 		position = "top-right",
-- 		onSideScroll = function(selected, scrollIndex, args)
-- 			updateCharacterFace(optionValues[args["type"]]["hash"], ((scrollIndex - 101) / 100))
-- 			Wait(250)
-- 			Citizen.InvokeNative(0x704C908E9C405136, ped)
-- 			Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, 0, 1, 1, 1, 0)
-- 		end,
-- 		onSelected = function(selected, scrollIndex, args)
-- 			print(selected, scrollIndex, json.encode(args))
-- 		end,
-- 		onClose = function()
-- 			print("Menu Closed")
-- 			lib.showMenu("character_creator_menu")
-- 		end,
-- 		options = options,
-- 	}, function(selected, scrollIndex, args)
-- 		lib.showMenu("character_creator_menu")
-- 	end)
-- end

local openClothingMenu = function()
	if not TempCharacterData["Sex"] then
		local sex = IsPedMale(PlayerPedId()) and "Male" or "Female"
		TempCharacterData["Sex"] = sex
	end

	local clothingValues = fetchClothingValues()

	for k, v in pairs(clothingValues) do
		uiClothing[#uiClothing + 1] = {
			id = (#uiClothing + 1),
			type = k,
			label = exports["d-core"]:SplitStr(k, "_"),
			values = v,
			value = CharacterData.Clothing[k] or 1,
		}
	end

	currentMenu = "clothingMenu"

	SetNuiFocus(true, true)
	SendReactMessage("setInitialData", {
		cloth = uiClothing,
		title = "Clothing Menu",
	})

	SendReactMessage("setMenu", "scrollMenu")
	SendReactMessage("setVisible", true)
end

local openCreatorMenu = function()
	if not TempCharacterData["Sex"] then
		local sex = IsPedMale(PlayerPedId()) and "Male" or "Female"
		TempCharacterData["Sex"] = sex
	end

	interpCamera2("cam2", temporaryPed)

	local optionValues = fetchSkinValues()

	uiSkin = {
		{
			id = 1,
			label = "Body",
			type = "BODIES_UPPER",
			values = optionValues["BODIES_UPPER"],
			value = CharacterData.Skin["body"] or 0,
		},
		{
			id = 2,
			label = "Heads",
			type = "heads",
			values = optionValues["heads"],
			value = CharacterData.Skin["heads"] or 0,
		},
		{
			id = 3,
			label = "Hair",
			type = "hair",
			values = optionValues["hair"],
			value = CharacterData.Skin["hair"] or 0,
		},
		{
			id = 4,
			label = "Teeth",
			type = "teeth",
			values = optionValues["teeth"],
			value = CharacterData.Skin["teeth"] or 0,
		},
		{
			id = 5,
			label = "Eyes",
			type = "eyes",
			values = optionValues["eyes"],
			value = CharacterData.Skin["eyes"] or 0,
		},
		{
			id = 6,
			label = "Beards",
			type = "beards_complete",
			values = optionValues["beards_complete"],
			value = CharacterData.Skin["beards_complete"] or 0,
		},
	}

	currentMenu = "skinMenu"

	SetNuiFocus(true, true)
	SendReactMessage("setInitialData", {
		cloth = uiSkin,
		title = "Skin Menu",
	})

	SendReactMessage("setMenu", "scrollMenu")
	SendReactMessage("setVisible", true)
end

RegisterNUICallback("updateMenuVariable", function(res)
	local type = res.type
	local id = res.id

	if currentMenu == "skinMenu" then
		local skinHash = nil
		local skinType = nil

		for i = 1, #uiSkin, 1 do
			if uiSkin[i].id == id then
				uiSkin[i].value = type == "decrease" and uiSkin[i].value - 1 or uiSkin[i].value + 1
				skinHash = uiSkin[i].values[uiSkin[i].value]
				skinType = uiSkin[i].type
			end
		end

		updateCharacterValue(temporaryPed, TempCharacterData["Sex"], skinType, skinHash)
		Citizen.InvokeNative(0x704C908E9C405136, temporaryPed)
		Citizen.InvokeNative(0xCC8CA3E88256E58F, temporaryPed, 0, 1, 1, 1, 0)
	elseif currentMenu == "clothingMenu" then
		local skinHash = nil
		local skinType = nil

		for i = 1, #uiClothing, 1 do
			if uiClothing[i].id == id then
				uiClothing[i].value = type == "decrease" and uiClothing[i].value - 1 or uiClothing[i].value + 1
				skinHash = uiClothing[i].values[uiClothing[i].value]
				skinType = uiClothing[i].type
			end
		end

		print(skinHash, skinType)

		updateCharacterClothing(temporaryPed, TempCharacterData["Sex"], skinType, skinHash)
		Citizen.InvokeNative(0x704C908E9C405136, temporaryPed)
		Citizen.InvokeNative(0xCC8CA3E88256E58F, temporaryPed, 0, 1, 1, 1, 0)
	end
end)

RegisterNUICallback("cameraClicked", function(res)
	local camera = res
	if camera == "head" then
		interpCamera2("cam2", temporaryPed)
	elseif camera == "body" then
		interpCamera2("cam3", temporaryPed)
	elseif camera == "feet" then
		interpCamera2("cam1", temporaryPed)
	end
end)

RegisterNUICallback("continueClicked", function()
	if currentMenu == "skinMenu" then
		openClothingMenu()
	elseif currentMenu == "clothingMenu" then
		SetNuiFocus(false, false)
		SendReactMessage("setVisible", false)
		Wait(100)

		TriggerServerEvent("d-character:server:saveNewCharacter", TempCharacterData)
	end
end)

RegisterNUICallback("deleteCharacter", function(res)
	TriggerServerEvent("d-character:server:deleteCharacter", res.cid)
end)

RegisterNUICallback("previewCharacter", function(res)
	createTemporaryPed(false, res.data.sex, res.data.skin, res.data.outfit)
end)

RegisterNUICallback("selectCharacter", function(res)
	SendReactMessage("setVisible", false)

	TriggerServerEvent(
		"d-character:server:spawnPlayer",
		res.data.citizenid,
		res.data.skin,
		res.data.outfit,
		res.data.sex,
		false
	)
end)

RegisterNUICallback("createNewCharacter", function(res)
	SendReactMessage("setVisible", false)

	TempCharacterData["Info"]["Firstname"] = res.inputFirstname or "John"
	TempCharacterData["Info"]["Lastname"] = res.inputLastname or "Doe"
	TempCharacterData["Info"]["Age"] = res.inputDOB or "1890-01-01"
	TempCharacterData["Sex"] = res.inputGender or "Male"

	createTemporaryPed(true, TempCharacterData["Sex"])
	interP = true
	interpCamera(temporaryPed)
	PlaySoundFrontend("gender_left", "RDRO_Character_Creator_Sounds", true, 0)
	Wait(2000)
	if temporaryPed then
		exports["menuapi"].CloseAll()
		DoScreenFadeOut(1500)
		Wait(2000)
		interpCamera2("cam3", temporaryPed)
		currentCamera = "cam3"
		interP2 = true
		SetEntityCoords(temporaryPed, -558.56, -3781.16, 237.59)
		SetEntityHeading(temporaryPed, 87.21)
		lightsEnabled["selector"] = false
		lightsEnabled["customization"] = true
		inCustomization = true
		DoScreenFadeIn(1500)
		openCreatorMenu()
	end
end)

RegisterNetEvent("d-character:client:reloadSelect", function()
	exports["menuapi"]:CloseAll()

	if lib.progressCircle({
		duration = 1500,
		label = "Loading your characters..",
		canCancel = false,
	}) then
		exports["d-core"]:TriggerCallback("d-character:server:fetchCharacters", function(characters, licence)
			local PlayerTier = GetDonationTierFromLicense(license) or 0
			local options = {}
			if characters and #characters > 0 then
				for i = 1, #characters, 1 do
					options[#options + 1] = {
						name = characters[i].charinfo.firstname .. " " .. characters[i].charinfo.lastname,
						cid = characters[i].citizenid,
						data = {
							citizenid = characters[i].citizenid,
							sex = characters[i].charinfo.gender == 0 and "Male" or "Female",
							skin = characters[i].skin,
							outfit = characters[i].outfit,
						},
					}
				end

				currentMenu = nil

				SetNuiFocus(true, true)
				SendReactMessage("setCharacters", {
					characters = options,
					canCreate = (#characters < Config.MaxCharacters[PlayerTier]) and true or false,
				})

				SendReactMessage("setMenu", "charMenu")
				SendReactMessage("setVisible", true)
			else
				currentMenu = nil

				SetNuiFocus(true, true)
				SendReactMessage("setCharacters", {
					characters = {},
					canCreate = true,
				})

				SendReactMessage("setMenu", "charMenu")
				SendReactMessage("setVisible", true)
			end
		end)
	end
end)

RegisterNetEvent("d-character:client:initCharSelect", function()
	exports["menuapi"]:CloseAll()

	DoScreenFadeIn(500)
	inSelector = true
	lightsEnabled["selector"] = true
	createLights("selector")
	Wait(500)
	DestroyAllCams(true)

	if not groundCamera then
		createCamera()
	end

	if lib.progressCircle({
		duration = 1500,
		label = "Loading your characters..",
		canCancel = false,
	}) then
		exports["d-core"]:TriggerCallback("d-character:server:fetchCharacters", function(characters, licence)
			local PlayerTier = GetDonationTierFromLicense(license) or 0
			local options = {}
			if characters and #characters > 0 then
				for i = 1, #characters, 1 do
					options[#options + 1] = {
						name = characters[i].charinfo.firstname .. " " .. characters[i].charinfo.lastname,
						cid = characters[i].citizenid,
						data = {
							citizenid = characters[i].citizenid,
							sex = characters[i].charinfo.gender == 0 and "Male" or "Female",
							skin = characters[i].skin,
							outfit = characters[i].outfit,
						},
					}
				end

				currentMenu = nil

				SetNuiFocus(true, true)
				SendReactMessage("setCharacters", {
					characters = options,
					canCreate = (#characters < Config.MaxCharacters[PlayerTier]) and true or false,
				})

				SendReactMessage("setMenu", "charMenu")
				SendReactMessage("setVisible", true)
			else
				currentMenu = nil

				SetNuiFocus(true, true)
				SendReactMessage("setCharacters", {
					characters = {},
					canCreate = true,
				})

				SendReactMessage("setMenu", "charMenu")
				SendReactMessage("setVisible", true)
			end
		end)
	end
end)

AddEventHandler("onResourceStop", function()
	if temporaryPed then
		DeletePed(temporaryPed)
	end

	DestroyAllCams()
end)

RegisterNetEvent("d-character:client:loadCharacter", function(player, outfits)
	local skin = player.skin
	local outfit = {}
	local sex = json.decode(player.charinfo).gender

	if type(skin) ~= "table" then
		skin = json.decode(skin)
	end

	for i = 1, #outfits, 1 do
		if outfits[i].id == player.outfit then
			outfit = outfits[i].clothing
			break
		end
	end

	if type(outfit) ~= "table" then
		outfit = json.decode(outfit)
	end

	CharacterData["Sex"] = sex == 0 and "Male" or "Female"
	CharacterData["Skin"] = skin
	CharacterData["Clothing"] = outfit

	if CharacterData["Sex"] == "Female" then
		SetPedOutfitPreset(PlayerPedId(), 17)
		Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), 0x9925C067, 0)
		Citizen.InvokeNative(0xCC8CA3E88256E58F, PlayerPedId(), 0, 1, 1, 1, 0)
	else
		SetPedOutfitPreset(PlayerPedId(), 43)
	end

	Citizen.InvokeNative(0x77FF8D35EEC6BBC4, PlayerPedId(), 0, 0)
	Citizen.InvokeNative(0x0BFA1BD465CDFEFD, PlayerPedId())
	Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), 0x1D4C528A, 0)
	Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), 0x3F1F01E5, 0)
	Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), 0xDA0E2C55, 0)
	Citizen.InvokeNative(0x704C908E9C405136, PlayerPedId())
	Citizen.InvokeNative(0xCC8CA3E88256E58F, PlayerPedId(), 0, 1, 1, 1, 0)

	local bool = GeneratePlayerModel(PlayerPedId(), CharacterData["Sex"], skin, outfit)
end)

RegisterNetEvent("d-character:client:spawnPlayer", function(skin, clothing, sex, newPlayer, coords)
	if type(skin) ~= "table" then
		skin = json.decode(skin)
	end

	if type(clothing) ~= "table" then
		clothing = json.decode(clothing)
	end

	CharacterData["Sex"] = sex
	CharacterData["Skin"] = skin
	CharacterData["Clothing"] = clothing

	DoScreenFadeOut(500)
	Wait(1000)

	local model = sex == "Male" and GetHashKey("mp_male") or GetHashKey("mp_female")
	RequestModel(model)
	while not HasModelLoaded(model) do
		Wait(0)
	end

	if sex == "Female" then
		SetPedOutfitPreset(PlayerPedId(), 17)
		Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), 0x9925C067, 0)
		Citizen.InvokeNative(0xCC8CA3E88256E58F, PlayerPedId(), 0, 1, 1, 1, 0)
	else
		SetPedOutfitPreset(PlayerPedId(), 43)
	end

	Citizen.InvokeNative(0xED40380076A31506, PlayerId(), model, false)
	Citizen.InvokeNative(0x77FF8D35EEC6BBC4, PlayerPedId(), 0, 0)

	Citizen.InvokeNative(0x0BFA1BD465CDFEFD, PlayerPedId())
	Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), 0x1D4C528A, 0)
	Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), 0x3F1F01E5, 0)
	Citizen.InvokeNative(0xD710A5007C2AC539, PlayerPedId(), 0xDA0E2C55, 0)
	Citizen.InvokeNative(0x704C908E9C405136, PlayerPedId())
	Citizen.InvokeNative(0xCC8CA3E88256E58F, PlayerPedId(), 0, 1, 1, 1, 0)

	if GeneratePlayerModel(PlayerPedId(), sex, skin, clothing) then
		Wait(1000)
		if newPlayer then
			SetEntityCoords(PlayerPedId(), Config.DefaultSpawn["x"], Config.DefaultSpawn["y"], Config.DefaultSpawn["z"])
			SetEntityHeading(PlayerPedId(), Config.DefaultSpawn["h"])
			FreezeEntityPosition(PlayerPedId(), false)
			TriggerServerEvent("QBCore:Server:OnPlayerLoaded")
			TriggerEvent("QBCore:Client:OnPlayerLoaded")

			RenderScriptCams(false, true, 500, true, true)
			SetCamActive(groundCamera, false)
			DestroyCam(groundCamera, true)
			SetCamActive(fixedCamera, false)
			DestroyCam(fixedCamera, true)

			SetEntityVisible(PlayerPedId(), true)
			NetworkSetEntityInvisibleToNetwork(PlayerPedId(), false)
			Wait(500)
			DoScreenFadeIn(250)
		else
			local coords = coords or Config.DefaultSpawn

			SetEntityCoords(PlayerPedId(), coords["x"], coords["y"], coords["z"])
			SetEntityHeading(PlayerPedId(), coords["h"])
			FreezeEntityPosition(PlayerPedId(), false)
			TriggerServerEvent("QBCore:Server:OnPlayerLoaded")
			TriggerEvent("QBCore:Client:OnPlayerLoaded")

			RenderScriptCams(false, true, 500, true, true)
			SetCamActive(groundCamera, false)
			DestroyCam(groundCamera, true)
			SetCamActive(fixedCamera, false)
			DestroyCam(fixedCamera, true)

			SetEntityVisible(PlayerPedId(), true)
			NetworkSetEntityInvisibleToNetwork(PlayerPedId(), false)
			Wait(500)
			DoScreenFadeIn(250)
		end
	else
		print("Failed to generate player")
	end
end)

CreateThread(function()
	for i = 1, #cloth_hash_names, 1 do
		local v = cloth_hash_names[i]
		if
			v.category_hashname == "BODIES_LOWER"
			or v.category_hashname == "BODIES_UPPER"
			or v.category_hashname == "heads"
			or v.category_hashname == "hair"
			or v.category_hashname == "teeth"
			or v.category_hashname == "eyes"
			or v.category_hashname == "beards_complete"
		then
			if v.ped_type == "female" and v.is_multiplayer and v.hashname ~= "" then
				if Skin["Female"][v.category_hashname] == nil then
					Skin["Female"][v.category_hashname] = {}
				end
				Skin["Female"][v.category_hashname][#Skin["Female"][v.category_hashname] + 1] = v.hash
			elseif v.ped_type == "male" and v.is_multiplayer and v.hashname ~= "" then
				if Skin["Male"][v.category_hashname] == nil then
					Skin["Male"][v.category_hashname] = {}
				end
				Skin["Male"][v.category_hashname][#Skin["Male"][v.category_hashname] + 1] = v.hash
			end
		else
			if v.ped_type == "female" and v.is_multiplayer and v.hashname ~= "" then
				if Clothing["Female"][v.category_hashname] == nil then
					Clothing["Female"][v.category_hashname] = {}
				end
				Clothing["Female"][v.category_hashname][#Clothing["Female"][v.category_hashname] + 1] = v.hash
			elseif v.ped_type == "male" and v.is_multiplayer and v.hashname ~= "" then
				if Clothing["Male"][v.category_hashname] == nil then
					Clothing["Male"][v.category_hashname] = {}
				end
				Clothing["Male"][v.category_hashname][#Clothing["Male"][v.category_hashname] + 1] = v.hash
			end
		end
	end
end)

exports("Character", function()
	return { Skin, Clothing }
end)
