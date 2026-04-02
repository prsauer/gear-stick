GST_TalentDropdown = {}

-- Cache player spec to avoid calling in secure context
local cachedSpecID = nil
local cachedClassID = nil

local function UpdatePlayerSpec()
    local currentSpec = GetSpecialization()
    if currentSpec then
        cachedSpecID = select(1, GetSpecializationInfo(currentSpec))
        cachedClassID = select(3, UnitClass("player"))
    end
end

local function ImportTalentString(talentCode, buildName)
    if InCombatLockdown() then
        GST_LogUser("Cannot import talents during combat.")
        return
    end

    local dialog = ClassTalentLoadoutImportDialog
    if not dialog then
        GST_LogUser("Talent import dialog not available.")
        return
    end

    dialog:ShowDialog()

    -- Find the import editbox and name editbox within the dialog
    local importBox = dialog.ImportControl and dialog.ImportControl.InputContainer and
        dialog.ImportControl.InputContainer.EditBox
    local nameBox = dialog.NameControl and dialog.NameControl.InputContainer and
        dialog.NameControl.InputContainer.EditBox

    if importBox then
        importBox:SetText(talentCode)
    end

    if nameBox then
        nameBox:SetText("GST - " .. buildName)
    end
end

local function GetBuildsForSpec(specID, classID)
    if not GSTLoadoutsDb then return {} end

    local bracketBuilds = {}
    for _, loadout in ipairs(GSTLoadoutsDb) do
        if loadout.classId == classID and loadout.specId == specID then
            local bracket = loadout.bracket or "Unknown"
            if not bracketBuilds[bracket] then
                bracketBuilds[bracket] = {}
            end
            table.insert(bracketBuilds[bracket], loadout)
        end
    end

    -- Sort within each bracket by rank
    for _, builds in pairs(bracketBuilds) do
        table.sort(builds, function(a, b)
            return (a.rank or 0) < (b.rank or 0)
        end)
    end

    return bracketBuilds
end

local function SetupDropdownHook()
    -- Menu.ModifyMenu is available in WoW 11.0+ (Blizzard_Menu framework)
    if not Menu or not Menu.ModifyMenu then
        GST_LogDebug("Menu.ModifyMenu not available - talent dropdown integration skipped")
        return
    end

    Menu.ModifyMenu("MENU_CLASS_TALENT_PROFILE", function(owner, rootDescription, contextData)
        if not cachedSpecID or not cachedClassID then
            UpdatePlayerSpec()
        end
        if not cachedSpecID or not cachedClassID then return end

        local bracketBuilds = GetBuildsForSpec(cachedSpecID, cachedClassID)

        -- Check if there are any builds to show
        local hasBuild = false
        for _ in pairs(bracketBuilds) do
            hasBuild = true
            break
        end
        if not hasBuild then return end

        -- Add divider and header
        rootDescription:CreateDivider()
        rootDescription:CreateTitle("GearStick Loadouts")

        -- Sort brackets for consistent ordering
        local sortedBrackets = {}
        for bracket in pairs(bracketBuilds) do
            table.insert(sortedBrackets, bracket)
        end
        table.sort(sortedBrackets)

        for _, bracket in ipairs(sortedBrackets) do
            local builds = bracketBuilds[bracket]
            local bracketLabel = string.upper(bracket)

            if #builds == 1 then
                -- Single build: show directly without submenu
                local build = builds[1]
                local label = string.format("%s: #%d %s", bracketLabel, build.rank or 0, build.name or "Unknown")
                local btn = rootDescription:CreateButton(label, function()
                    local code, name = build.code, label
                    C_Timer.After(0, function()
                        ImportTalentString(code, name)
                    end)
                    return MenuResponse.CloseAll
                end)
                btn:SetTooltip(function(tooltip, desc)
                    GameTooltip_SetTitle(tooltip, label)
                    GameTooltip_AddNormalLine(tooltip, "Source: gearstick.io ladder data")
                    GameTooltip_AddNormalLine(tooltip, "Bracket: " .. bracketLabel)
                    GameTooltip_AddBlankLine(tooltip)
                    GameTooltip_AddInstructionLine(tooltip, "Click to open import dialog")
                end)
            else
                -- Multiple builds: create a submenu per bracket
                local bracketMenu = rootDescription:CreateButton(bracketLabel)
                bracketMenu:SetSelectionIgnored()

                for _, build in ipairs(builds) do
                    local label = string.format("#%d %s", build.rank or 0, build.name or "Unknown")
                    local btn = bracketMenu:CreateButton(label, function()
                        local code, name = build.code, bracketLabel .. " " .. label
                        C_Timer.After(0, function()
                            ImportTalentString(code, name)
                        end)
                        return MenuResponse.CloseAll
                    end)
                    btn:SetTooltip(function(tooltip, desc)
                        GameTooltip_SetTitle(tooltip, label)
                        GameTooltip_AddNormalLine(tooltip, "Source: gearstick.io ladder data")
                        GameTooltip_AddNormalLine(tooltip, "Bracket: " .. bracketLabel)
                        GameTooltip_AddNormalLine(tooltip, "Rank: #" .. (build.rank or 0))
                        GameTooltip_AddBlankLine(tooltip)
                        GameTooltip_AddInstructionLine(tooltip, "Click to open import dialog")
                    end)
                end
            end
        end
    end)

    GST_LogDebug("GearStick talent dropdown hook registered")
end

function GST_TalentDropdown.Initialize()
    UpdatePlayerSpec()
    SetupDropdownHook()
end

function GST_TalentDropdown.OnSpecChanged()
    UpdatePlayerSpec()
end
