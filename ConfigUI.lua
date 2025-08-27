GST_ConfigUI = {}

local ConfigFrame = nil

local function CreateConfigUI()
    if ConfigFrame then
        return ConfigFrame
    end

    -- Create the main frame
    local frame = CreateFrame("Frame", "GSTConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(400, 350)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")

    -- Set up the backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    -- Add title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", 8, -8)
    frame.title:SetText("GearStick Configuration")

    -- Create container for settings
    local settingsContainer = CreateFrame("Frame", nil, frame)
    settingsContainer:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -20)
    settingsContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 50)

    -- Settings data with descriptions
    local settings = {
        { key = "2v2",       label = "2v2 Arena Tooltips",    desc = "Show 2v2 arena usage data in item tooltips" },
        { key = "3v3",       label = "3v3 Arena Tooltips",    desc = "Show 3v3 arena usage data in item tooltips" },
        { key = "pve",       label = "PvE Tooltips",          desc = "Show PvE usage data in item tooltips" },
        { key = "bis",       label = "Best-in-Slot Info",     desc = "Show best-in-slot recommendations in tooltips" },
        { key = "debug",     label = "Debug Mode",            desc = "Show debug information and extra details" },
        { key = "profiling", label = "Performance Profiling", desc = "Enable performance timing measurements" }
    }

    local checkboxes = {}
    local yOffset = -10

    -- Create checkboxes for each setting
    for i, setting in ipairs(settings) do
        -- Create checkbox
        local checkbox = CreateFrame("CheckButton", nil, settingsContainer, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", settingsContainer, "TOPLEFT", 10, yOffset)
        checkbox:SetSize(24, 24)

        -- Create label
        local label = settingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(setting.label)

        -- Create description
        local desc = settingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
        desc:SetText(setting.desc)
        desc:SetTextColor(0.7, 0.7, 0.7, 1)
        desc:SetWidth(300)

        -- Set checkbox state based on current setting
        checkbox:SetChecked(GearStickSettings[setting.key] == true)

        -- Handle checkbox clicks
        checkbox:SetScript("OnClick", function(self)
            local isChecked = self:GetChecked()
            GearStickSettings[setting.key] = isChecked

            if isChecked then
                GST_LogUser("Enabled " .. setting.label)
            else
                GST_LogUser("Disabled " .. setting.label)
            end
        end)

        checkboxes[setting.key] = checkbox
        yOffset = yOffset - 45
    end

    -- Add Summary button
    local summaryButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    summaryButton:SetSize(80, 24)
    summaryButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    summaryButton:SetText("Summary")
    summaryButton:SetScript("OnClick", function()
        if GST_Summary and GST_Summary.SlashCmd then
            GST_Summary.SlashCmd()
            frame:Hide()
        end
    end)

    -- Add Reset button
    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(80, 24)
    resetButton:SetPoint("LEFT", summaryButton, "RIGHT", 10, 0)
    resetButton:SetText("Reset All")
    resetButton:SetScript("OnClick", function()
        -- Reset all settings
        for _, setting in ipairs(settings) do
            GearStickSettings[setting.key] = false
            checkboxes[setting.key]:SetChecked(false)
        end
        GST_LogUser("All settings have been reset")
    end)

    -- Add close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    -- Make the frame movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Store references for refreshing
    frame.checkboxes = checkboxes
    frame.settings = settings

    ConfigFrame = frame
    return frame
end

local function RefreshConfigUI()
    if not ConfigFrame then
        return
    end

    -- Update checkbox states from current settings
    for _, setting in ipairs(ConfigFrame.settings) do
        local checkbox = ConfigFrame.checkboxes[setting.key]
        if checkbox then
            checkbox:SetChecked(GearStickSettings[setting.key] == true)
        end
    end
end

function GST_ConfigUI.ShowConfig()
    local frame = CreateConfigUI()
    RefreshConfigUI()
    frame:Show()
end

function GST_ConfigUI.SlashCmd(arg1)
    GST_ConfigUI.ShowConfig()
end

function GST_ConfigUI.RefreshIfVisible()
    if ConfigFrame and ConfigFrame:IsShown() then
        RefreshConfigUI()
    end
end
