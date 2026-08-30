GST_ConfigUI = {}

local ConfigFrame = nil

-- Helper to create a horizontal divider line
local function CreateDivider(parent, yOffset)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, yOffset)
    line:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    return line
end

-- Helper to create a section header
local function CreateSectionHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOffset)
    header:SetText(text)
    header:SetTextColor(1.0, 0.82, 0.0, 1) -- Gold color matching WoW UI conventions
    return header
end

local function CreateConfigUI()
    if ConfigFrame then
        return ConfigFrame
    end

    -- Create the main frame
    local frame = CreateFrame("Frame", "GSTConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(380, 460)
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
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    -- Add title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", 12, -12)
    frame.title:SetText("GearStick Settings")

    -- Add version text next to title
    local version = GetAddOnMetadata("GearStick", "Version") or ""
    if version ~= "" then
        local versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        versionText:SetPoint("LEFT", frame.title, "RIGHT", 8, 0)
        versionText:SetText("v" .. version)
        versionText:SetTextColor(0.5, 0.5, 0.5, 1)
    end

    -- Divider below title
    CreateDivider(frame, -32)

    -- Settings grouped by section
    local sections = {
        {
            title = "Tooltip Data",
            settings = {
                { key = "2v2",   label = "2v2 Arena",    desc = "Show 2v2 arena usage data in item tooltips" },
                { key = "3v3",   label = "3v3 Arena",    desc = "Show 3v3 arena usage data in item tooltips" },
                { key = "pve",   label = "PvE",          desc = "Show PvE usage data in item tooltips" },
                { key = "bis",   label = "Best-in-Slot",  desc = "Show best-in-slot recommendations in tooltips" },
            }
        },
        {
            title = "Features",
            settings = {
                { key = "talentDropdown", label = "Talent Loadout Dropdown", desc = "Add GearStick builds to the talent loadout dropdown menu", default = true },
            }
        },
        {
            title = "Developer",
            settings = {
                { key = "debug",     label = "Debug Mode",            desc = "Show debug information and extra details" },
                { key = "profiling", label = "Performance Profiling", desc = "Enable performance timing measurements" },
            }
        },
    }

    -- Flatten settings for refresh logic
    local allSettings = {}
    for _, section in ipairs(sections) do
        for _, setting in ipairs(section.settings) do
            table.insert(allSettings, setting)
        end
    end

    local checkboxes = {}
    local yOffset = -42

    -- Create sections with headers and checkboxes
    for sectionIndex, section in ipairs(sections) do
        -- Section header
        CreateSectionHeader(frame, section.title, yOffset)
        yOffset = yOffset - 18

        -- Checkboxes within the section
        for _, setting in ipairs(section.settings) do
            local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
            checkbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
            checkbox:SetSize(24, 24)

            -- Label
            local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
            label:SetText(setting.label)

            -- Description below label
            local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
            desc:SetText(setting.desc)
            desc:SetTextColor(0.55, 0.55, 0.55, 1)
            desc:SetWidth(300)

            -- Set checkbox state
            local value = GearStickSettings[setting.key]
            if value == nil then
                value = setting.default or false
            end
            checkbox:SetChecked(value)

            -- Handle clicks
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
            yOffset = yOffset - 42
        end

        -- Divider between sections (not after the last one)
        if sectionIndex < #sections then
            yOffset = yOffset - 4
            CreateDivider(frame, yOffset)
            yOffset = yOffset - 10
        end
    end

    -- Bottom area divider
    CreateDivider(frame, -420)

    -- Summary button
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

    -- Reset button
    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(80, 24)
    resetButton:SetPoint("LEFT", summaryButton, "RIGHT", 8, 0)
    resetButton:SetText("Reset All")
    resetButton:SetScript("OnClick", function()
        for _, setting in ipairs(allSettings) do
            local defaultVal = setting.default or false
            GearStickSettings[setting.key] = defaultVal
            checkboxes[setting.key]:SetChecked(defaultVal)
        end
        GST_LogUser("All settings have been reset")
    end)

    -- Website text in bottom-right
    local siteText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    siteText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 14)
    siteText:SetText("gearstick.io")
    siteText:SetTextColor(0.4, 0.4, 0.4, 1)

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    -- Make frame movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Close on escape
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)

    -- Store references for refreshing
    frame.checkboxes = checkboxes
    frame.settings = allSettings

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
            local value = GearStickSettings[setting.key]
            if value == nil then
                value = setting.default or false
            end
            checkbox:SetChecked(value)
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
