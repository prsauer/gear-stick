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
