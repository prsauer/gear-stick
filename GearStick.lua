
local function CreateTTFunc(t)
	local ttfunc = function(tip, arg1, arg2)
		local itemID = nil

		local currentSpec = GetSpecialization()
		local currentSpecId = currentSpec and select(1, GetSpecializationInfo(currentSpec)) or "None"

		-- See ln#355 in TooltipDataHandler.lua for more context

		-- Could be great vault?
		-- GameTooltip:SetWeeklyReward(self.displayedItemDBID); from Blizzard_WeeklyRewards.lua
		-- 		accessor: GetWeeklyReward

		-- Used in many places
		-- GameTooltip:SetItemByID(self.rewardInfo.itemID); from RecruitAFriendFrame.lua
		-- GameTooltip:SetItemByID(self:GetID()); from QuestInfo.lua
		-- GameTooltip:SetItemByID(self.id); from PVPHonorSystem.lua
		-- 		accessor: GetItemByID
		
		-- GameTooltip:SetTradePlayerItem(self:GetParent():GetID()); from TradeFrame.xml
		-- GameTooltip:SetTradeTargetItem(self:GetParent():GetID()); from TradeFrame.xml
		-- GameTooltip:SetMerchantCostItem(self.index, self.item); from MoneyFrame.xml
		-- GameTooltip:SetBuybackItem(GetNumBuybackItems()); from MerchantFrame.xml
		-- GameTooltip:SetBuybackItem(button:GetID()); from MerchantFrame.lua
		-- GameTooltip:SetInboxItem(InboxFrame.openMailID, self:GetID()); from MailFrame.xml
		-- GameTooltip:SetInboxItem(InboxFrame.openMailID, index); from MailFrame.lua
		-- GameTooltip:SetSendMailItem(index); from MailFrame.lua
		-- GameTooltip:SetHyperlink(self.itemLink); from LootHistory.xml
		-- GameTooltip:SetQuestLogSpecialItem(self:GetID()); from Blizzard_ObjectiveTrackerShared.lua
		-- GameTooltip:SetUpgradeItem(); from Blizzard_ItemUpgradeUI.lua .. LoL no args.
		-- GameTooltip:SetItemInteractionItem(); from Blizzard_ItemInteractionUI.lua
		-- GameTooltip:SetTransmogrifyItem(self.transmogLocation); from Blizzard_Wardrobe.lua
		-- GameTooltip:SetHeirloomByItemID(self.itemID); from Blizzard_HeirloomCollection.lua
		-- GameTooltip:SetItemKey(data.itemID, data.itemLevel, data.itemSuffix, C_AuctionHouse.GetItemKeyRequiredLevel(data)); from Blizzard_AuctionHouseUtil.lua
		-- GameTooltip:SetRecipeResultItem(self.recipeSchematic.recipeID, reagents, self.transaction:GetAllocationItemGUID(), self:GetCurrentRecipeLevel()); from Blizzard_ProfessionsRecipeSchematicForm.lua
		-- GameTooltip:SetItemByGUID(itemGUID); from Blizzard_ProfessionsRecipeSchematicForm
		-- GameTooltip:SetRecipeReagentItem(recipeID, reagentSlotSchematic.dataSlotIndex); from Blizzard_ProfessionsRecipeSchematicForm
		-- GameTooltip:SetLFGDungeonReward(LFGDungeonReadyPopup.dungeonID, self.rewardID); from LFGFrame.lua
		-- GameTooltip:SetLFGDungeonShortageReward(LFGDungeonReadyPopup.dungeonID, self.rewardArg, self.rewardID); from LFGFrame.lua
		-- GameTooltip:SetLFGDungeonShortageReward(self.dungeonID, self.shortageIndex, self:GetID()); from LFGFrame.xml
		-- GameTooltip:SetLFGDungeonReward(self.dungeonID, self:GetID()); from LFGFrame.xml
		-- GameTooltip:SetVoidItem(VoidStorageFrame.page, self.slot); from Blizzard_VoidStorageUI.lua
		-- GameTooltip:SetVoidWithdrawalItem(self.slot); from Blizzard_VoidStorageUI.lua
		-- GameTooltip:SetRuneforgeResultItem(itemPreviewInfo.itemGUID, itemPreviewInfo.itemLevel); from Blizzard_RuneforgeFrame.lua

		-- These may not be TT for items?
		-- GameTooltip:SetQuestLogItem(self.type, self:GetID(), questID, showCollectionText);
		-- GameTooltip_ShowCompareItem(GameTooltip); from QuestInfo.lua
		-- GameTooltip:SetQuestItem(self.type, self:GetID(), showCollectionText);
		-- GameTooltip_ShowCompareItem(GameTooltip); from QuestInfo.lua
		-- SetQuestItem also called in QuestFrameTemplates.xml

		if (t == "SetMerchantItem") then
			-- GameTooltip:SetMerchantItem(button:GetID()); from MerchantFrame.lua
			local itemLink = GetMerchantItemLink(arg1)
			if itemLink ~= nil then
				local gear = Item:CreateFromItemLink(itemLink)
				itemID = gear:GetItemID()
			end
		elseif (t == "SetInventoryItem") then
			-- GameTooltip:SetInventoryItem("player", slot); from EquipmentFlyout.lua
			itemID = GetInventoryItemID(arg1, arg2)
			local res = C_TooltipInfo.GetInventoryItem(arg1, arg2)
			for key, value in pairs(res) do
				print(key, value)
			end

			if (res['type'] == 0) then
				local ttId = res['id']
				print("TOOLTIP:")
				print(ttId)
				print(itemID)
			end
			
		elseif (t == "SetBuybackItem") then
			C_TooltipInfo.GetBuybackItem(arg1);
			
			local itemLink = GetBuybackItemLink(arg1)
			if itemLink ~= nil then
				local gear = Item:CreateFromItemLink(itemLink)
				itemID = gear:GetItemID()
			end
		elseif (t == "SetLootItem") then
			-- GameTooltip:SetLootItem(self:GetSlotIndex()); from LootFrame.lua
			local itemLink = GetLootSlotLink(arg1)
			if itemLink ~= nil then
				local gear = Item:CreateFromItemLink(itemLink)
				itemID = gear:GetItemID()
			end
		elseif (t == "SetLootRollItem") then
			-- GameTooltip:SetLootRollItem(self:GetParent().rollID); from GroupLootFrame.xml
			--    SetLootRollItem = "GetLootRollItem", .. accessor documented in TooltipDataHandler.lua
			-- we'll use insecure GetLootRollItemLink(rollId)
			local itemLink = GetLootRollItemLink(arg1)
			if itemLink ~= nil then
				local gear = Item:CreateFromItemLink(itemLink)
				itemID = gear:GetItemID()
			end
		elseif (t == "SetBagItem") then
			-- GameTooltip:SetBagItem(bag, slot); from EquipmentFlyout.lua
			-- GameTooltip:SetBagItem(self:GetBagID(), self:GetID()); from ContainerFrame.lua
			--    GetBagItem .. accessor documented in TooltipDataHandler.lua
			local itemLocation = ItemLocation:CreateFromBagAndSlot(arg1, arg2)
			if C_Item.DoesItemExist(itemLocation) then
				local itemLink = C_Item.GetItemLink(itemLocation);
				if itemLink ~= nil then
					local gear = Item:CreateFromItemLink(itemLink)
					itemID = gear:GetItemID()
				end
			end
		elseif (t == "SetWeeklyReward") then
			-- TODO: debug this call, not much exposed for looking up weekly reward info
			print("GetWeeklyReward: " .. arg1)
			local data = C_TooltipInfo.GetWeeklyReward(arg1)
			print(data)
		elseif (t == "SetGuildBankItem") then
			-- GameTooltip:SetGuildBankItem(GetCurrentGuildBankTab(), self:GetID()); from Blizzard_GuildBankUI.lua
			--    GetGuildBankItem .. accessor documented in TooltipDataHandler.lua
			-- we'll use insecure GetGuildBankItemLink(tab, slot) - Returns itemLink
			local itemLink = GetGuildBankItemLink(arg1, arg2)
			if itemLink ~= nil then
				local gear = Item:CreateFromItemLink(itemLink)
				itemID = gear:GetItemID()
			end
		else
			if GearStickSettings["debug"] then
				print("GST unhandled tooltip: " .. tip)
			end 
		end

		if itemID then
            -- ["250202459"] = "|cFF11FF0071.4%|r players use this (bis)",
			local key = currentSpecId .. itemID
			if GearStickSettings["2v2"] and usageDb2v2[key] then
				GameTooltip:AddLine("[2v2]: |cFF11FF00" .. usageDb2v2[key][1] .. "%|r players use this" .. (usageDb2v2[key][2] and " (bis)" or ""), 0.90, 0.80, 0.60,  0);
				if usageDb2v2[key][3] ~= "" and GearStickSettings["bis"] then
					GameTooltip:AddLine("[2v2-bis]: " .. usageDb2v2[key][3], 0.90, 0.80, 0.60,  0);
				end
			end
			if GearStickSettings["3v3"] and usageDb3v3[key] then
				GameTooltip:AddLine("[3v3]: |cFF11FF00" .. usageDb3v3[key][1] .. "%|r players use this" .. (usageDb3v3[key][2] and " (bis)" or ""), 0.90, 0.80, 0.60,  0);
				if usageDb3v3[key][3] ~= "" and GearStickSettings["bis"] then
					GameTooltip:AddLine("[3v3-bis]: " .. usageDb3v3[key][3], 0.90, 0.80, 0.60,  0);
				end
			end
			if GearStickSettings["pve"] and usageDbPvE[key] then
				GameTooltip:AddLine("[PvE]: |cFF11FF00" .. usageDbPvE[key][1] .. "%|r players use this" .. (usageDbPvE[key][2] and " (bis)" or ""), 0.90, 0.80, 0.60,  0);
				if usageDbPvE[key][3] ~= "" and GearStickSettings["bis"] then
					GameTooltip:AddLine("[PvE-bis]: " .. usageDbPvE[key][3], 0.90, 0.80, 0.60,  0);
				end
			end
			-- if usageDb[itemID]["SoloShuffle"] then
			-- 	GameTooltip:AddLine(usageDb[itemID]["SoloShuffle"], 0.90, 0.80, 0.60,  0)
			-- end
			-- if usageDb[itemID]["PvE"] then
			-- 	GameTooltip:AddLine(usageDb[itemID]["PvE"], 0.90, 0.80, 0.60,  0)
			-- end
            if GearStickSettings["debug"] then
                GameTooltip:AddLine("GT.ItemID: " .. itemID, 1, 0.3, 0.3);
				GameTooltip:AddLine("GT.SpecId: " .. currentSpecId, 1, 0.3, 0.3);
            end
		end
	
        if GearStickSettings["debug"] then
		    GameTooltip:AddLine("GT.TTHook: "..t, 1, 0.3, 0.3);
        end
		GameTooltip:Show();
	end
	return ttfunc
end

do
	hooksecurefunc(GameTooltip, "SetWeeklyReward", CreateTTFunc("SetWeeklyReward"));
	hooksecurefunc(GameTooltip, "SetBagItem", CreateTTFunc("SetBagItem"));
	hooksecurefunc(GameTooltip, "SetBuybackItem", CreateTTFunc("SetBuybackItem"));
	hooksecurefunc(GameTooltip, "SetMerchantItem", CreateTTFunc("SetMerchantItem"));
	hooksecurefunc(GameTooltip, "SetInventoryItem", CreateTTFunc("SetInventoryItem"));
	hooksecurefunc(GameTooltip, "SetGuildBankItem", CreateTTFunc("SetGuildBankItem"));
	hooksecurefunc(GameTooltip, "SetLootItem", CreateTTFunc("SetLootItem"));
	hooksecurefunc(GameTooltip, "SetLootRollItem", CreateTTFunc("SetLootRollItem"));
end

local frame = CreateFrame("FRAME"); -- Need a frame to respond to events
frame:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded

function frame:OnEvent(event, arg1)
	if event == "ADDON_LOADED" and arg1 == "GearStick" then
		if GearStickSettings == nil then
			GearStickSettings = {};
		end
	end
end

frame:SetScript("OnEvent", frame.OnEvent);

SlashCmdList.GST = function(arg1)
	if arg1 == nil or arg1 == "" then
		print("Invalid. Pass one of: 2v2 3v3 pve bis debug status reset")
		return
	end
	-- force argument to lowercase
	local msg = string.lower(arg1)
	-- reset all options
	if msg == "reset" then
		GearStickSettings = {}
		print("GearStick settings have been reset.")
		return
	end
	-- print current settings to console
	if msg == "status" then
		print("")
		print("GearStick current settings:")
		print ("---------------------------")
		for key, value in pairs(GearStickSettings) do
			print(key, value)
		end
		return
	end
	if msg ~= "2v2" and msg~= "3v3" and msg ~= "pve" and msg ~= "bis" and msg ~= "debug" then
		print("Invalid. Pass one of: 2v2 3v3 bis pve debug status reset")
		return
	end

	if GearStickSettings[msg] == true then
		GearStickSettings[msg] = false
		print("Disabled " .. msg .. " tooltips")
	else
		GearStickSettings[msg] = true
		print("Enabled " .. msg .. " tooltips")
	end
end
SLASH_GST1 = "/gst"
