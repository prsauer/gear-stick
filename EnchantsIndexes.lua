-- Enchants Index Functions
-- Builds an index for the GSTEnchantsDb database for fast lookups

EnchantsIndexes = {}

-- Global index table that gets built once
GSTEnchantsIndex = nil

-- Build an index table that maps concatenated keys (specId_slotType_bracket) to arrays of database indexes
function EnchantsIndexes.BuildIndex()
    local index = {}

    -- Iterate through the entire database
    for i = 1, #GSTEnchantsDb do
        local entry = GSTEnchantsDb[i]
        local specId = entry.specId
        local slotType = entry.slotType
        local bracket = entry.bracket

        -- Create the concatenated key
        local key = specId .. "_" .. slotType .. "_" .. bracket

        -- Initialize the array for this key if it doesn't exist
        if not index[key] then
            index[key] = {}
        end

        -- Add the current database index to the array
        table.insert(index[key], i)
    end

    return index
end

-- Lookup function that takes specId, slotType, and bracket and returns an array of matching entries
function EnchantsIndexes.LookupBySpecSlotBracket(specId, slotType, bracket)
    -- Ensure the global index exists
    if not GSTEnchantsIndex then
        GSTEnchantsIndex = EnchantsIndexes.BuildIndex()
    end

    -- Create the concatenated key
    local key = specId .. "_" .. slotType .. "_" .. bracket

    -- Get the array of indexes for this key
    local indexArray = GSTEnchantsIndex[key]

    if not indexArray then
        return {} -- Return empty array if no matches found
    end

    -- Build the result array by looking up each index in the database
    local result = {}
    for _, dbIndex in ipairs(indexArray) do
        table.insert(result, GSTEnchantsDb[dbIndex])
    end

    return result
end

-- Memoization cache for batch lookups
EnchantsIndexes.batchCache = {}

-- Batch lookup function that pre-loads enchant data for multiple slot types at once
-- Takes specId, bracket, and an array of slotTypes
-- Returns a table mapping slotType -> array of enchant items
function EnchantsIndexes.BatchLookupBySlotTypes(specId, bracket, slotTypes)
    -- Ensure the global index exists
    if not GSTEnchantsIndex then
        GSTEnchantsIndex = EnchantsIndexes.BuildIndex()
    end

    -- Create a cache key from the parameters
    local cacheKey = specId .. "_" .. bracket .. "_" .. table.concat(slotTypes, ",")

    -- Check if we have a cached result
    if EnchantsIndexes.batchCache[cacheKey] then
        return EnchantsIndexes.batchCache[cacheKey]
    end

    local result = {}

    -- Pre-initialize all slot type arrays
    for _, slotType in ipairs(slotTypes) do
        result[slotType] = {}
    end

    -- Build all the keys we need to look up
    local keysToLookup = {}
    for _, slotType in ipairs(slotTypes) do
        local key = specId .. "_" .. slotType .. "_" .. bracket
        keysToLookup[key] = slotType
    end

    -- Look up each key and populate the result
    for key, slotType in pairs(keysToLookup) do
        local indexArray = GSTEnchantsIndex[key]
        if indexArray then
            for _, dbIndex in ipairs(indexArray) do
                table.insert(result[slotType], GSTEnchantsDb[dbIndex])
            end
        end
    end

    -- Cache the result
    EnchantsIndexes.batchCache[cacheKey] = result

    return result
end

-- Function to initialize the global index (call this once when the addon loads)
function EnchantsIndexes.InitializeIndex()
    if not GSTEnchantsIndex then
        GSTEnchantsIndex = EnchantsIndexes.BuildIndex()
    end
end

-- Example usage:
-- EnchantsIndexes.InitializeIndex() -- Call this once when addon loads
-- local results = EnchantsIndexes.LookupBySpecSlotBracket(250, "HEAD", "pve") -- Get all head enchants for spec 250 in PvE bracket
-- local batchResults = EnchantsIndexes.BatchLookupBySlotTypes(250, "pve", {"HEAD", "CHEST", "LEGS"}) -- Get all enchants for head/chest/legs
