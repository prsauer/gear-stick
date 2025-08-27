GST_DiffUI = {}

local DiffFrame = nil

local function CreateDiffUI()
    if DiffFrame then
        return DiffFrame
    end

    -- Create the main frame
    local frame = CreateFrame("Frame", "GSTDiffFrame", UIParent, "BackdropTemplate")
    frame:SetSize(600, 200)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")

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
    frame.title:SetText("Diff")

    -- Add the diff text
    local diffText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    diffText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    diffText:SetText(
    "CsbBV7//nP39x/JJympTqouKSAAAAAAAAAAAAzMzMMmNzYmBzwYMTDzMZMWmZmZGzYmlZAzMjNmZWmZeAYAGsBLjRjtBkZCwGG")
    diffText:SetWidth(580)
    diffText:SetJustifyH("CENTER")

    -- Add Summary button
    local summaryButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    summaryButton:SetSize(80, 24)
    summaryButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -8)
    summaryButton:SetText("Summary")
    summaryButton:SetScript("OnClick", function()
        if GST_Summary and GST_Summary.SlashCmd then
            GST_Summary.SlashCmd()
            frame:Hide() -- Close the diff panel
        end
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

    DiffFrame = frame
    return frame
end

function GST_DiffUI.ShowDiff()
    local frame = CreateDiffUI()
    frame:Show()
end

function GST_DiffUI.SlashCmd(arg1)
    GST_DiffUI.ShowDiff()
end

function GST_DiffUI.RefreshIfVisible()
    if DiffFrame and DiffFrame:IsShown() then
        -- Nothing to refresh for this static display
    end
end
