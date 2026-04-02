GST_TalentDropdown = {}

-- Nil out a key using Blizzard's own mixin to avoid taint propagation.
-- Used by TalentLoadoutManager (Numy) and TalentTreeTweaks to fix the
-- CastingBarFrame.barType taint caused by Menu.ModifyMenu on the talent dropdown.
local function secureNil(tbl, key)
    TextureLoadingGroupMixin.RemoveTexture({ textures = tbl }, key)
end

-- Cache player spec to avoid calling in secure context
local cachedSpecID = nil
local cachedClassID = nil
local cachedSpecName = nil
local cachedClassName = nil

local function UpdatePlayerSpec()
    local currentSpec = GetSpecialization()
    if currentSpec then
        cachedSpecID = select(1, GetSpecializationInfo(currentSpec))
        cachedSpecName = select(2, GetSpecializationInfo(currentSpec))
        local _, classFile = UnitClass("player")
        cachedClassID = select(3, UnitClass("player"))
        cachedClassName = classFile
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
    local nameBox = dialog.NameControl and dialog.NameControl.EditBox

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
            -- Deep copy to avoid taint from SavedVariable table references
            table.insert(bracketBuilds[bracket], {
                name = tostring(loadout.name or "Unknown"),
                code = tostring(loadout.code or ""),
                rank = tonumber(loadout.rank) or 0,
                bracket = tostring(bracket),
            })
        end
    end

    -- Sort within each bracket by rank
    for _, builds in pairs(bracketBuilds) do
        table.sort(builds, function(a, b)
            return a.rank < b.rank
        end)
    end

    return bracketBuilds
end

local cachedEnabled = true
local cachedBuilds = {}

local function RefreshCachedBuilds()
    if cachedSpecID and cachedClassID then
        cachedBuilds = GetBuildsForSpec(cachedSpecID, cachedClassID)
    else
        cachedBuilds = {}
    end
    cachedEnabled = not GearStickSettings or GearStickSettings["talentDropdown"] ~= false
end

local function SetupDropdownHook()
    -- Menu.ModifyMenu is available in WoW 11.0+ (Blizzard_Menu framework)
    if not Menu or not Menu.ModifyMenu then
        GST_LogDebug("Menu.ModifyMenu not available - talent dropdown integration skipped")
        return
    end

    RefreshCachedBuilds()

    Menu.ModifyMenu("MENU_CLASS_TALENT_PROFILE", function(owner, rootDescription, contextData)
        if not cachedEnabled then return end

        -- Everything used in this callback must be pre-cached — do NOT access
        -- SavedVariables or call Blizzard APIs from the menu's secure context,
        -- as it will taint CastingBarFrame.barType.
        if not cachedSpecID or not cachedClassID then return end

        local bracketBuilds = cachedBuilds

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

        -- Filter shuffle brackets to only show the one matching current spec
        local myShuffleKey = nil
        if cachedClassName and cachedSpecName then
            myShuffleKey = "shuffle_" .. string.lower(cachedClassName) .. "_" .. string.lower(cachedSpecName)
        end

        -- Sort brackets for consistent ordering
        local sortedBrackets = {}
        for bracket in pairs(bracketBuilds) do
            if string.sub(bracket, 1, 8) == "shuffle_" then
                if bracket == myShuffleKey then
                    table.insert(sortedBrackets, bracket)
                end
            else
                table.insert(sortedBrackets, bracket)
            end
        end
        table.sort(sortedBrackets)

        for _, bracket in ipairs(sortedBrackets) do
            local builds = bracketBuilds[bracket]
            local bracketLabel
            if string.sub(bracket, 1, 8) == "shuffle_" then
                bracketLabel = "Shuffle"
            else
                bracketLabel = string.upper(bracket)
            end

            local bracketMenu = rootDescription:CreateButton(bracketLabel)
            bracketMenu:SetSelectionIgnored()

            for _, build in ipairs(builds) do
                local label = string.format("#%d %s", build.rank or 0, build.name or "Unknown")
                local bCode = build.code
                local bImportName = bracketLabel .. " " .. label
                local bRank = build.rank
                local bLabel = bracketLabel
                local btn = bracketMenu:CreateButton(label, function()
                    C_Timer.After(0, function()
                        ImportTalentString(bCode, bImportName)
                    end)
                end)
                btn:SetTooltip(function(tooltip, desc)
                    tooltip:SetText(label)
                    tooltip:AddLine("Source: gearstick.io ladder data", 1, 1, 1)
                    tooltip:AddLine("Bracket: " .. bLabel, 1, 1, 1)
                    tooltip:AddLine("Rank: #" .. bRank, 1, 1, 1)
                    tooltip:AddLine(" ")
                    tooltip:AddLine("Click to open import dialog", 0, 1, 0)
                end)
            end
        end
    end)

    GST_LogDebug("GearStick talent dropdown hook registered")
end

local function ApplyCastbarTaintFix()
    -- Skip if TalentTreeTweaks or TalentLoadoutManager already handle this
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        if C_AddOns.IsAddOnLoaded("TalentTreeTweaks") then return end
        if C_AddOns.IsAddOnLoaded("TalentLoadoutManager") then return end
    end

    local talentsTab = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if not talentsTab then return end

    -- Menu.ModifyMenu on MENU_CLASS_TALENT_PROFILE taints data that flows through
    -- enableCommitCastBar into CastingBarFrame.barType, causing "attempted to
    -- index a forbidden table" on loadout switch. Removing the property breaks
    -- the taint chain. Technique from Numy's ReduceTaint module.
    secureNil(talentsTab, "enableCommitCastBar")
    GST_LogDebug("Applied castbar taint fix for talent dropdown")
end

function GST_TalentDropdown.Initialize()
    UpdatePlayerSpec()
    SetupDropdownHook()
    ApplyCastbarTaintFix()
end

function GST_TalentDropdown.OnSpecChanged()
    UpdatePlayerSpec()
    RefreshCachedBuilds()
end
