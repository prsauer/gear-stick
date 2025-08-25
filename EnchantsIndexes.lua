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

-- Function to initialize the global index (call this once when the addon loads)
function EnchantsIndexes.InitializeIndex()
    if not GSTEnchantsIndex then
        GSTEnchantsIndex = EnchantsIndexes.BuildIndex()
    end
end

-- Example usage:
-- EnchantsIndexes.InitializeIndex() -- Call this once when addon loads
-- local results = EnchantsIndexes.LookupBySpecSlotBracket(250, "HEAD", "pve") -- Get all head enchants for spec 250 in PvE bracket
