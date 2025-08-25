-- if (debug) print(...) function:
function GST_LogDebug(...)
    if GearStickSettings and GearStickSettings["debug"] then
        print("|cFF00FF00[GearStick Debug]|r", ...)
    end
end

-- if (profiling) print(...) function:
function GST_LogProfiling(...)
    if GearStickSettings and GearStickSettings["profiling"] then
        print("|cFF00FFFF[GearStick Profiling]|r", ...)
    end
end

-- generic print (user land) function, just wraps print()
function GST_LogUser(...)
    print("|cFF00AAFF[GearStick]|r", ...)
end

local profileTimers = {}

function GST_TimerStart(name)
    if GearStickSettings and GearStickSettings["profiling"] then
        profileTimers[name] = debugprofilestop()
    end
end

function GST_TimerStop(name)
    if GearStickSettings and GearStickSettings["profiling"] then
        local startTime = profileTimers[name]
        if startTime then
            local endTime = debugprofilestop()
            local duration = endTime - startTime
            print(string.format("|cFF00FFFF[GearStick Profiling]|r %s: %.3fms", name, duration))
        end
    end
end

local function debug(tbl, indent)
    indent = indent or ""
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print(indent .. key .. ":")
            debug(value, indent .. "  ")
        else
            print(indent .. key .. ": " .. tostring(value))
        end
    end
end

function GST_DebugTable(tbl)
    if GearStickSettings and GearStickSettings["debug"] then
        debug(tbl, "")
    end
end
