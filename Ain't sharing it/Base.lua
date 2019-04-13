AintSharingIt = AintSharingIt or {}
AintSharingIt.WhiteList = {}

function AintSharingIt:Init()
	self.ModPath = ModPath
	self.SavePath = SavePath .. "AintSharingItConfig.txt"
	self.Options = {PrivateMods = {}}
	self.MenuId = "my_fucking_privacy"
	self:Load()
	self.Setup = true
end

function AintSharingIt:Load()
	local file = io.open(self.SavePath, "r")
	if file then
		self.Options = json.decode(file:read("*all"))
		file:close()
	end
end

function AintSharingIt:Save()
	local file = io.open(self.SavePath, "w+")
	if file then
		file:write(json.encode(self.Options))
		file:close()
	end
end

if not AintSharingIt.Setup then
	AintSharingIt:Init()
	AintSharingIt.Setup = true
end

Hooks:Add("LocalizationManagerPostInit", "AintSharingItLoc", function(loc)
	LocalizationManager:add_localized_strings({
		my_fucking_privacy = "Ain't sharing it",
		my_fucking_privacy_desc = "Choose which mods are not allowed to be shared with the other client, disabled mods are automatically not shared",
		my_fucking_privacy_share_nothing = "Don't share any mod",
		my_fucking_privacy_share_nothing_desc = "None of your mods would be shared if option is turned on, this doesn't mean your lobby/game is counted as non-modded",
		my_fucking_privacy_no_white_list = "Warning: Failed to get white list...",		
	})
end)


function MenuCallbackHandler:is_not_modded_client()
	return not self:is_modded_client()
end

function MenuCallbackHandler:build_mods_list()
	local mods = {}

	if AintSharingIt.Options.ShareNothing then
		return mods
	end

	local BLT = rawget(_G, "BLT")
	if BLT and BLT.Mods then
		for _, mod in pairs(BLT.Mods:Mods()) do
			local data = mod:GetJsonData()
			local Id = data.name or mod:GetId()
			if not AintSharingIt.WhiteList[Id] and mod:IsEnabled() and not AintSharingIt.Options.PrivateMods[Id] then
				table.insert(mods, {mod:GetName(), mod:GetId()})
			end
		end
	end

	return mods
end

function MenuCallbackHandler:ZeClbkOfMyFuckingPrivacy(item)
	AintSharingIt.Options.PrivateMods[item._parameters.name] = item:value() == "on"
	AintSharingIt:Save()
end

function MenuCallbackHandler:ZeClbkOfMyFuckingPrivacyShareNothing(item)
	AintSharingIt.Options.ShareNothing = item:value() == "on"
	AintSharingIt:Save()
end

Hooks:Add("MenuManagerSetupCustomMenus", "AintSharingItBuildMenu", function(self, nodes)
	dohttpreq("https://raw.githubusercontent.com/ModWorkshop/WhiteListedPD2Mods/master/README.txt", function(data)
		MenuHelper:NewMenu(AintSharingIt.MenuId)
		if string.is_nil_or_empty(data) then
			log("[AintSharingIt] Could not get whitelist")		
			local menu = MenuHelper:GetMenu(AintSharingIt.MenuId)
			menu._items_list = menu._items_list or {}
			local item = menu:create_item({
				type = "MenuItemDivider",
				color = Color.yellow,
				text_id = "my_fucking_privacy_no_white_list"
			}, {name = "NoWhiteListWarning"})
			item._priority = 0
			table.insert(menu._items_list, item)
		else
			for _, mod in pairs(string.split(data, "\n")) do
				AintSharingIt.WhiteList[mod] = true
			end
		end
		MenuHelper:AddToggle({
			id = "ShareNothing",
			title = "my_fucking_privacy_share_nothing",
			desc = "my_fucking_privacy_share_nothing_desc",
			callback = "ZeClbkOfMyFuckingPrivacyShareNothing",
			value = AintSharingIt.Options.ShareNothing == true,
			menu_id = AintSharingIt.MenuId,
		})
		for _, mod in pairs(BLT.Mods:Mods()) do
			local data = mod:GetJsonData()
			local Id = data.name or mod:GetId()
			if not AintSharingIt.WhiteList[Id] and mod:IsEnabled() then				
				MenuHelper:AddToggle({
					id = Id,
					title = Id,
					callback = "ZeClbkOfMyFuckingPrivacy",
					value = AintSharingIt.Options.PrivateMods[Id] == true,
					menu_id = AintSharingIt.MenuId,
					localized = false,
				})
			end
		end
		nodes[AintSharingIt.MenuId] = MenuHelper:BuildMenu(AintSharingIt.MenuId)
		MenuHelper:AddMenuItem(nodes[BLTModManager.Constants:LuaModOptionsMenuID()], AintSharingIt.MenuId, "my_fucking_privacy", "my_fucking_privacy_desc")			
	end)
end)
