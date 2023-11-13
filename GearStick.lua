
local function CreateTTFunc(t)
	local ttfunc = function(tip, arg1, arg2)
		local itemID = nil

		local currentSpec = GetSpecialization()
		local currentSpecId = currentSpec and select(1, GetSpecializationInfo(currentSpec)) or "None"

		if (t == "SetMerchantItem") then
			local itemLink = GetMerchantItemLink(arg1)
			local gear = Item:CreateFromItemLink(itemLink)
			itemID = gear:GetItemID()
		elseif (t == "SetInventoryItem") then
			local itemLink = GetInventoryItemLink(arg1, arg2)
			local gear = Item:CreateFromItemLink(itemLink)
			itemID = gear:GetItemID()
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
				GameTooltip:AddLine("[2v2]: |cFF11FF00" .. usageDb2v2[key][1] .. "%|r players use this" .. (usageDb2v2[key][2] and " (bis)" or ""), 0.90, 0.80, 0.60,  0)
			end
			-- if usageDb3v3[key] then
			-- 	GameTooltip:AddLine("[3v3]: " .. usageDb3v3[key], 0.90, 0.80, 0.60,  0)
			-- end
			if GearStickSettings["PvE"] and usageDbPve[key] then
				GameTooltip:AddLine("[PvE]: |cFF11FF00" .. usageDbPve[key][1] .. "%|r players use this" .. (usageDbPve[key][2] and " (bis)" or ""), 0.90, 0.80, 0.60,  0)
			end
			-- if usageDb[itemID]["SoloShuffle"] then
			-- 	GameTooltip:AddLine(usageDb[itemID]["SoloShuffle"], 0.90, 0.80, 0.60,  0)
			-- end
			-- if usageDb[itemID]["PvE"] then
			-- 	GameTooltip:AddLine(usageDb[itemID]["PvE"], 0.90, 0.80, 0.60,  0)
			-- end
            if GearStickSettings["Debug"] then
                GameTooltip:AddLine("GT.ItemID: " .. itemID, 1, 0.3, 0.3);
            end
		end
	
        if GearStickSettings["Debug"] then
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

SlashCmdList.GST = function(msg)
	if msg == nil or msg == "" then
		print("Invalid. Pass one of: 2v2 PvE Debug")
		return
	end
	if msg ~= "2v2" and msg ~= "PvE" and msg ~= "Debug" then
		print("Invalid. Pass one of: 2v2 PvE Debug")
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
