
local function CreateTTFunc(t)
	local ttfunc = function(tip, arg1, arg2)
		local itemID = nil

		local currentSpec = GetSpecialization()
		local currentSpecId = currentSpec and select(1, GetSpecializationInfo(currentSpec)) or "None"

		if (t == "SetMerchantItem") then
			local itemLink = GetMerchantItemLink(arg1)
			if itemLink ~= nil then
				local gear = Item:CreateFromItemLink(itemLink)
				itemID = gear:GetItemID()
			end
		elseif (t == "SetInventoryItem") then
			local itemLink = GetInventoryItemLink(arg1, arg2)
			if itemLink ~= nil then
				local gear = Item:CreateFromItemLink(itemLink)
				itemID = gear:GetItemID()
			end
		elseif (t == "SetBuybackItem") then
			local itemLink = GetBuybackItemLink(arg1)
			if itemLink ~= nil then
				local gear = Item:CreateFromItemLink(itemLink)
				itemID = gear:GetItemID()
			end
		elseif (t == "SetLootItem") then
			local itemLink = GetLootSlotLink(arg1)
			if itemLink ~= nil then
				local gear = Item:CreateFromItemLink(itemLink)
				itemID = gear:GetItemID()
			end
		else
			local itemLocation = ItemLocation:CreateFromBagAndSlot(arg1, arg2)
			if C_Item.DoesItemExist(itemLocation) then
				local itemLink = C_Item.GetItemLink(itemLocation);
				local gear = Item:CreateFromItemLink(itemLink)
				itemID = gear:GetItemID()
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
