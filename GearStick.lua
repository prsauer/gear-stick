local newsNumber = 4
local newsText = "New features: /gst talents, /gst enchants & /gst summary             Check us out at gearstick.io"

local msgFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
msgFrame:SetBackdrop({
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 5, bottom = 3 }
})
msgFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
msgFrame:SetBackdropBorderColor(0.4, 0.4, 0.4)
msgFrame:SetWidth(200)
msgFrame:SetHeight(150)
msgFrame:SetPoint("LEFT", 140, 140)
msgFrame:SetFrameStrata("TOOLTIP")
msgFrame:Hide()
msgFrame.header = msgFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
msgFrame.header:SetPoint("TOPLEFT", 10, -10)
msgFrame.header:SetText("gearstick updates")

msgFrame.text = msgFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
msgFrame.text:SetPoint("CENTER", 0, 0)
msgFrame.text:SetText(newsText)
msgFrame.text:SetWidth(200)

local button = CreateFrame("Button", nil, msgFrame)
button:SetPoint("TOP", msgFrame, "BOTTOM", 0, 10)
button:SetWidth(128)
button:SetHeight(32)
button:SetText("OK")
button:SetNormalFontObject("GameFontNormal")

local ntex = button:CreateTexture()
ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
ntex:SetTexCoord(0, 0.625, 0, 0.6875)
ntex:SetAllPoints()
button:SetNormalTexture(ntex)

local htex = button:CreateTexture()
htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
htex:SetTexCoord(0, 0.625, 0, 0.6875)
htex:SetAllPoints()
button:SetHighlightTexture(htex)

local ptex = button:CreateTexture()
ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
ptex:SetTexCoord(0, 0.625, 0, 0.6875)
ptex:SetAllPoints()
button:SetPushedTexture(ptex)

button:SetScript("OnClick", function(self, button, down)
	GearStickSettings["lastNewsNumber"] = newsNumber
	msgFrame:Hide()
end)

local function debug(tbl)
	for key, value in pairs(tbl) do
		print(key, value)
	end
end

local function GetStatsKeyFromTooltipHelper(...)
	--["CRIT_RATING", "VERSATILITY", "HASTE_RATING", "MASTERY_RATING"]
	local crit = ""
	local versa = ""
	local haste = ""
	local mast = ""
	local count = 0
	for i = 1, select("#", ...) do
		local region = select(i, ...)
		if region and region:GetObjectType() == "FontString" then
			local text = region:GetText() -- string or nil
			if (text ~= nil and string.find(text, "%+.*Versatility")) then
				count = count + 1
				versa = "VERSATILITY"
			end
			if (text ~= nil and string.find(text, "%+.*Critical Strike")) then
				count = count + 1
				crit = "CRIT_RATING"
			end
			if (text ~= nil and string.find(text, "%+.*Haste")) then
				count = count + 1
				haste = "HASTE_RATING"
			end
			if (text ~= nil and string.find(text, "%+.*Mastery")) then
				count = count + 1
				mast = "MASTERY_RATING"
			end
		end
	end

	local rval = ""

	if (count > 0 and crit ~= "") then
		rval = crit
		count = count - 1
		if (count > 0) then
			rval = rval .. "-"
		end
	end

	if (count > 0 and versa ~= "") then
		rval = rval .. versa
		count = count - 1
		if (count > 0) then
			rval = rval .. "-"
		end
	end

	if (count > 0 and haste ~= "") then
		rval = rval .. haste
		count = count - 1
		if (count > 0) then
			rval = rval .. "-"
		end
	end

	if (count > 0 and mast ~= "") then
		rval = rval .. mast
	end

	return rval
end

local function GetStatsKeyFromTooltip(tooltip)
	return GetStatsKeyFromTooltipHelper(tooltip:GetRegions())
end

local function writeTooltip(tooltip, itemID, currentSpecId)
	local statsKey = GetStatsKeyFromTooltip(tooltip)
	local key = currentSpecId .. itemID .. '-' .. statsKey
	local itemInventoryType = C_Item.GetItemInventoryTypeByID(itemID)

	if GearStickSettings["2v2"] then
		if usageDb2v2[key] then
			tooltip:AddLine(
				"[2v2]: |cFF11FF00" ..
				usageDb2v2[key][1] .. "%|r players use this" .. (usageDb2v2[key][2] and " (bis)" or ""), 0.90, 0.80, 0.60,
				0);
			if usageDb2v2[key][3] ~= "" and GearStickSettings["bis"] then
				tooltip:AddLine("[2v2-bis]: " .. usageDb2v2[key][3], 0.90, 0.80, 0.60, 0);
			end
		else
			if GearStickSettings["bis"] and itemInventoryType and usageDb2v2[currentSpecId .. itemInventoryType] then
				tooltip:AddLine("[2v2-bis]: " .. usageDb2v2[currentSpecId .. itemInventoryType][3], 0.90, 0.80, 0.60, 0);
			end
		end
	end

	if GearStickSettings["3v3"] then
		if usageDb3v3[key] then
			tooltip:AddLine(
				"[3v3]: |cFF11FF00" ..
				usageDb3v3[key][1] .. "%|r players use this" .. (usageDb3v3[key][2] and " (bis)" or ""), 0.90, 0.80, 0.60,
				0);
			if usageDb3v3[key][3] ~= "" and GearStickSettings["bis"] then
				tooltip:AddLine("[3v3-bis]: " .. usageDb3v3[key][3], 0.90, 0.80, 0.60, 0);
			end
		else
			if GearStickSettings["bis"] and itemInventoryType and usageDb3v3[currentSpecId .. itemInventoryType] then
				tooltip:AddLine("[3v3-bis]: " .. usageDb3v3[currentSpecId .. itemInventoryType][3], 0.90, 0.80, 0.60, 0);
			end
		end
	end

	if GearStickSettings["pve"] then
		if usageDbPvE[key] then
			tooltip:AddLine(
				"[PvE]: |cFF11FF00" ..
				usageDbPvE[key][1] .. "%|r players use this" .. (usageDbPvE[key][2] and " (bis)" or ""), 0.90, 0.80, 0.60,
				0);
			if usageDbPvE[key][3] ~= "" and GearStickSettings["bis"] then
				tooltip:AddLine("[PvE-bis]: " .. usageDbPvE[key][3], 0.90, 0.80, 0.60, 0);
			end
		else
			if GearStickSettings["bis"] and itemInventoryType and usageDbPvE[currentSpecId .. itemInventoryType] then
				tooltip:AddLine("[PvE-bis]: " .. usageDbPvE[currentSpecId .. itemInventoryType][3], 0.90, 0.80, 0.60, 0);
			end
		end
	end

	if GearStickSettings["debug"] then
		tooltip:AddLine("GT.ItemID: " .. itemID, 1, 0.3, 0.3);
		tooltip:AddLine("GT.itemInventoryType: " .. itemInventoryType, 1, 0.3, 0.3);
		tooltip:AddLine("GT.SpecId: " .. currentSpecId, 1, 0.3, 0.3);
	end
end

local frame = CreateFrame("FRAME");                   -- Need a frame to respond to events
frame:RegisterEvent("ADDON_LOADED");                  -- Fired when saved variables are loaded
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED"); -- Fired when player changes spec
frame:RegisterEvent("COMBAT_RATING_UPDATE");          -- Fired when player stats change (equipment, enchants, gems)

function frame:OnEvent(event, arg1, arg2)
	if event == "ADDON_LOADED" and arg1 == "GearStick" then
		if GearStickSettings == nil then
			GearStickSettings = {};
		end
		local lastSeen = GearStickSettings["lastNewsNumber"] or 0
		if newsNumber > lastSeen then
			msgFrame:Show()
		end
	elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
		-- Update UI components when spec changes
		-- arg1 is unit (should be "player")
		-- arg2 is new spec ID
		if arg1 == "player" then
			if GearStickSettings["debug"] then
				print("GearStick: Spec changed to " .. (arg2 or "unknown"))
			end

			-- Update Summary UI if it's currently shown
			if GST_Summary and GST_Summary.RefreshIfVisible then
				GST_Summary.RefreshIfVisible()
			end

			-- Update Talents UI if it's currently shown
			if GST_Talents and GST_Talents.RefreshIfVisible then
				GST_Talents.RefreshIfVisible()
			end

			-- Update Enchants UI if it's currently shown
			if GST_Enchants and GST_Enchants.RefreshIfVisible then
				GST_Enchants.RefreshIfVisible()
			end
		end
	elseif event == "COMBAT_RATING_UPDATE" then
		if GearStickSettings["debug"] then
			print("GearStick: Combat ratings updated - recalculating gear recommendations")
		end

		-- Recalculate gear recommendations when stats change
		-- This catches equipment changes, enchant changes, gem changes, etc.

		-- Update Summary UI if it's currently shown
		if GST_Summary and GST_Summary.RefreshIfVisible then
			GST_Summary.RefreshIfVisible()
		end

		-- Update Enchants UI if it's currently shown
		if GST_Enchants and GST_Enchants.RefreshIfVisible then
			GST_Enchants.RefreshIfVisible()
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
		print("Pass one of: 2v2 3v3 pve bis talents enchants summary news debug status reset")
		GST_Summary.SlashCmd("")
		return
	end
	-- force argument to lowercase
	local msg = string.lower(arg1)

	if msg == "talents" then
		GST_Talents.SlashCmd(arg1)
		return
	end

	if msg == "enchants" then
		GST_Enchants.SlashCmd(arg1)
		return
	end

	if msg == "summary" then
		GST_Summary.SlashCmd(arg1)
		return
	end

	if msg == "news" then
		msgFrame:Show()
		return
	end
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
		print("---------------------------")
		for key, value in pairs(GearStickSettings) do
			print(key, value)
		end
		return
	end
	if msg ~= "2v2" and msg ~= "3v3" and msg ~= "pve" and msg ~= "bis" and msg ~= "debug" then
		print("Pass one of: 2v2 3v3 bis pve debug talents enchants summary status reset")
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
