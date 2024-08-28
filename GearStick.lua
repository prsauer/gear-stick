
local function writeTooltip(tooltip, itemID, currentSpecId)
	local key = currentSpecId .. itemID
	local itemInventoryType = C_Item.GetItemInventoryTypeByID(itemID)

	if GearStickSettings["2v2"] then
		if usageDb2v2[key] then
			tooltip:AddLine("[2v2]: |cFF11FF00" .. usageDb2v2[key][1] .. "%|r players use this" .. (usageDb2v2[key][2] and " (bis)" or ""), 0.90, 0.80, 0.60,  0);
			if usageDb2v2[key][3] ~= "" and GearStickSettings["bis"] then
				tooltip:AddLine("[2v2-bis]: " .. usageDb2v2[key][3], 0.90, 0.80, 0.60,  0);
			end
		else
			if GearStickSettings["bis"] and itemInventoryType and usageDb2v2[currentSpecId .. itemInventoryType] then
				tooltip:AddLine("[2v2-bis]: " .. usageDb2v2[currentSpecId .. itemInventoryType][3], 0.90, 0.80, 0.60,  0);
			end
		end
	end

	if GearStickSettings["3v3"] then
		if usageDb3v3[key] then
			tooltip:AddLine("[3v3]: |cFF11FF00" .. usageDb3v3[key][1] .. "%|r players use this" .. (usageDb3v3[key][2] and " (bis)" or ""), 0.90, 0.80, 0.60,  0);
			if usageDb3v3[key][3] ~= "" and GearStickSettings["bis"] then
				tooltip:AddLine("[3v3-bis]: " .. usageDb3v3[key][3], 0.90, 0.80, 0.60,  0);
			end
		else
			if GearStickSettings["bis"] and itemInventoryType and usageDb3v3[currentSpecId .. itemInventoryType] then
				tooltip:AddLine("[3v3-bis]: " .. usageDb3v3[currentSpecId .. itemInventoryType][3], 0.90, 0.80, 0.60,  0);
			end
		end
	end

	if GearStickSettings["pve"] then
		if usageDbPvE[key] then
			tooltip:AddLine("[PvE]: |cFF11FF00" .. usageDbPvE[key][1] .. "%|r players use this" .. (usageDbPvE[key][2] and " (bis)" or ""), 0.90, 0.80, 0.60,  0);
			if usageDbPvE[key][3] ~= "" and GearStickSettings["bis"] then
				tooltip:AddLine("[PvE-bis]: " .. usageDbPvE[key][3], 0.90, 0.80, 0.60,  0);
			end
		else
			if GearStickSettings["bis"] and itemInventoryType and usageDbPvE[currentSpecId .. itemInventoryType] then
				tooltip:AddLine("[PvE-bis]: " .. usageDbPvE[currentSpecId .. itemInventoryType][3], 0.90, 0.80, 0.60,  0);
			end
		end
	end

	if GearStickSettings["debug"] then
		tooltip:AddLine("GT.ItemID: " .. itemID, 1, 0.3, 0.3);
		tooltip:AddLine("GT.itemInventoryType: " .. itemInventoryType, 1, 0.3, 0.3);
		tooltip:AddLine("GT.SpecId: " .. currentSpecId, 1, 0.3, 0.3);
	end
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

function GST_OnTooltipSetItem(tooltip, tooltipData)

	local currentSpec = GetSpecialization()
	local currentSpecId = currentSpec and select(1, GetSpecializationInfo(currentSpec)) or "None"

	local itemID = nil
	if (tooltipData ~= nil and tooltipData['type'] == 0 and tooltipData['id'] ~= nil) then
		itemID = tooltipData['id']
	end

	if (itemID) then
		writeTooltip(tooltip, itemID, currentSpecId)
	end

	tooltip:Show();
end

frame:SetScript("OnEvent", frame.OnEvent);
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, GST_OnTooltipSetItem)

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
