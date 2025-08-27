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


local function GetStatsKeyFromTooltipHelper(...)
	-- Extract stats with their values and sort by value (highest first)
	local stats = {}

	for i = 1, select("#", ...) do
		local region = select(i, ...)
		if region and region:GetObjectType() == "FontString" then
			local text = region:GetText() -- string or nil
			-- if first char is not +, skip line:
			GST_ItemUtils.ParseLineAndWriteSecondariesTable(text, stats)
		end
	end

	return GST_ItemUtils.ReduceSecondariesTableToSlug(stats)
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
			GST_LogDebug("2v2: " .. key)
			local choiceColor = "|cFFeeFF00"
			local rankText = " (#" .. usageDb2v2[key][2] .. ")"
			if usageDb2v2[key][2] == 1 then
				choiceColor = "|cFF11FF00"
			end
			tooltip:AddLine(
				"[2v2]: " .. choiceColor ..
				usageDb2v2[key][1] ..
				"% " .. rankText .. "|r players use this",
				0.90, 0.80,
				0.60,
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
			GST_LogDebug(key)
			local choiceColor = "|cFFeeFF00"
			local rankText = " (#" .. usageDb3v3[key][2] .. ")"
			if usageDb3v3[key][2] == 1 then
				choiceColor = "|cFF11FF00"
			end
			tooltip:AddLine(
				"[3v3]: " .. choiceColor ..
				usageDb3v3[key][1] ..
				"% " .. rankText .. "|r players use this",
				0.90, 0.80,
				0.60,
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
			GST_LogDebug(key)
			local choiceColor = "|cFFeeFF00"
			local rankText = " (#" .. usageDbPvE[key][2] .. ")"
			if usageDbPvE[key][2] == 1 then
				choiceColor = "|cFF11FF00"
			end
			tooltip:AddLine(
				"[PvE]: " .. choiceColor ..
				usageDbPvE[key][1] ..
				"% " .. rankText .. "|r players use this",
				0.90, 0.80,
				0.60,
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
		local addonLoadStart = debugprofilestop()

		-- Initialize SlotGearIndexes
		local indexStart = debugprofilestop()
		SlotGearIndexes.InitializeIndex()
		local indexEnd = debugprofilestop()
		local indexTime = indexEnd - indexStart

		-- Initialize EnchantsIndexes
		local enchantsIndexStart = debugprofilestop()
		EnchantsIndexes.InitializeIndex()
		local enchantsIndexEnd = debugprofilestop()
		local enchantsIndexTime = enchantsIndexEnd - enchantsIndexStart

		-- Initialize settings
		local settingsStart = debugprofilestop()
		if GearStickSettings == nil then
			GearStickSettings = {};
		end
		local settingsEnd = debugprofilestop()
		local settingsTime = settingsEnd - settingsStart

		-- Check for news updates
		local newsStart = debugprofilestop()
		local lastSeen = GearStickSettings["lastNewsNumber"] or 0
		if newsNumber > lastSeen then
			msgFrame:Show()
		end
		local newsEnd = debugprofilestop()
		local newsTime = newsEnd - newsStart

		-- Total addon load time
		local addonLoadEnd = debugprofilestop()
		local totalTime = addonLoadEnd - addonLoadStart

		-- Only print timing info if profiling is enabled
		GST_LogProfiling("SlotGearIndexes initialized in " .. string.format("%.2f", indexTime) .. "ms")
		GST_LogProfiling("EnchantsIndexes initialized in " .. string.format("%.2f", enchantsIndexTime) .. "ms")
		GST_LogProfiling("Settings initialized in " .. string.format("%.2f", settingsTime) .. "ms")
		GST_LogProfiling("News check completed in " .. string.format("%.2f", newsTime) .. "ms")
		GST_LogProfiling("Total addon load time: " .. string.format("%.2f", totalTime) .. "ms")
	elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
		local specChangeStart = debugprofilestop()

		-- Update UI components when spec changes
		-- arg1 is unit (should be "player")
		-- arg2 is new spec ID
		if arg1 == "player" then
			GST_LogDebug("Spec changed to " .. (arg2 or "unknown"))

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

			-- Update Config UI if it's currently shown
			if GST_ConfigUI and GST_ConfigUI.RefreshIfVisible then
				GST_ConfigUI.RefreshIfVisible()
			end

			-- Update Diff UI if it's currently shown
			if GST_DiffUI and GST_DiffUI.RefreshIfVisible then
				GST_DiffUI.RefreshIfVisible()
			end
		end

		local specChangeEnd = debugprofilestop()
		local specChangeTime = specChangeEnd - specChangeStart
		GST_LogProfiling("Spec change handler completed in " .. string.format("%.2f", specChangeTime) .. "ms")
	elseif event == "COMBAT_RATING_UPDATE" then
		local combatRatingStart = debugprofilestop()

		GST_LogDebug("Combat ratings updated - recalculating gear recommendations")

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

		-- Update Config UI if it's currently shown
		if GST_ConfigUI and GST_ConfigUI.RefreshIfVisible then
			GST_ConfigUI.RefreshIfVisible()
		end

		-- Update Diff UI if it's currently shown
		if GST_DiffUI and GST_DiffUI.RefreshIfVisible then
			GST_DiffUI.RefreshIfVisible()
		end

		local combatRatingEnd = debugprofilestop()
		local combatRatingTime = combatRatingEnd - combatRatingStart
		GST_LogProfiling("Combat rating update handler completed in " .. string.format("%.2f", combatRatingTime) .. "ms")
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
		GST_LogUser(
		"Pass one of: 2v2 3v3 pve bis talents enchants summary config diff news debug profiling status reset")
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

	if msg == "config" then
		GST_ConfigUI.SlashCmd(arg1)
		return
	end

	if msg == "diff" then
		GST_DiffUI.SlashCmd(arg1)
		return
	end

	if msg == "news" then
		msgFrame:Show()
		return
	end
	-- toggle profiling
	if msg == "profiling" then
		if GearStickSettings["profiling"] == true then
			GearStickSettings["profiling"] = false
			GST_LogUser("Disabled profiling")
		else
			GearStickSettings["profiling"] = true
			GST_LogUser("Enabled profiling")
		end
		return
	end
	-- reset all options
	if msg == "reset" then
		GearStickSettings = {}
		GST_LogUser("Settings have been reset.")
		return
	end
	-- print current settings to console
	if msg == "status" then
		GST_LogUser("")
		GST_LogUser("Current settings:")
		GST_LogUser("---------------------------")
		for key, value in pairs(GearStickSettings) do
			GST_LogUser(key, value)
		end
		return
	end
	if msg ~= "2v2" and msg ~= "3v3" and msg ~= "pve" and msg ~= "bis" and msg ~= "debug" then
		GST_LogUser("Pass one of: 2v2 3v3 bis pve debug profiling talents enchants summary config diff status reset")
		return
	end

	if GearStickSettings[msg] == true then
		GearStickSettings[msg] = false
		GST_LogUser("Disabled " .. msg .. " tooltips")
	else
		GearStickSettings[msg] = true
		GST_LogUser("Enabled " .. msg .. " tooltips")
	end
end
SLASH_GST1 = "/gst"
