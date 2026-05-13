if not LibStub then
    local LIBSTUB_MAJOR, LIBSTUB_MINOR = "LibStub", 2
    local LibStub = _G[LIBSTUB_MAJOR]
    if not LibStub or LibStub.minor < LIBSTUB_MINOR then
        LibStub = LibStub or {libs = {}, minors = {} }
        _G[LIBSTUB_MAJOR] = LibStub
        LibStub.minor = LIBSTUB_MINOR
        function LibStub:NewLibrary(major, minor)
            if not major then error("Usage: LibStub:NewLibrary(major, minor)", 2) end
            if self.libs[major] and (not minor or self.minors[major] >= minor) then return nil end
            self.minors[major], self.libs[major] = minor, self.libs[major] or {}
            return self.libs[major]
        end
        function LibStub:GetLibrary(major, silent)
            if not self.libs[major] and not silent then error("Library "..tostring(major).." does not exist.", 2) end
            return self.libs[major], self.minors[major]
        end
        function LibStub:IterateLibraries() return pairs(self.libs) end
        setmetatable(LibStub, { __call = LibStub.GetLibrary })
    end
end

local MAJOR, MINOR = "LibItemLevel-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local CACHE = {}
local queue = {}
local isInspecting = false
local currentUnit = nil
local currentGUID = nil
local currentCallbacks = {}
local currentRetries = 0
local timeoutTimer = nil

local TIMEOUT = 60*15 -- cache timeout
local INSPECT_TIMEOUT = 2 -- seconds to wait for a result before giving up
local MAX_RETRIES = 3

local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local UnitAverageItemLevel = UnitAverageItemLevel
local CanInspect = CanInspect
local NotifyInspect = NotifyInspect
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = GetItemInfo

local function CalculateManualIlvl(unit)
    local totalIlvl = 0
    local has2H = false
    for slot = 1, 18 do
        if slot ~= 4 then -- Skip shirt
            local link = GetInventoryItemLink(unit, slot)
            if link then
                local _, _, _, ilvl, _, _, _, _, equipSlot = GetItemInfo(link)
                if ilvl then
                    totalIlvl = totalIlvl + ilvl
                    if slot == 16 and equipSlot == "INVTYPE_2HWEAPON" then has2H = true end
                end
            end
        end
    end
    
    local ohLink = GetInventoryItemLink(unit, 17)
    if has2H and not ohLink then
        local mhLink = GetInventoryItemLink(unit, 16)
        if mhLink then
            local _, _, _, mhIlvl = GetItemInfo(mhLink)
            if mhIlvl then totalIlvl = totalIlvl + mhIlvl end
        end
    end
    
    local divisor = 16
    if GetInventoryItemLink(unit, 18) then divisor = 17 end
    if totalIlvl > 0 then return totalIlvl / divisor end
    return 0
end

local function FireCallbacks(guid, ilvl)
    if currentGUID == guid then
        for _, callback in ipairs(currentCallbacks) do
            pcall(callback, guid, ilvl)
        end
        currentCallbacks = {}
    end
end

local ProcessNext -- forward declaration

local function StopTimeout()
    if timeoutTimer then
        timeoutTimer:Cancel()
        timeoutTimer = nil
    end
end

local function OnResult(ilvl)
    StopTimeout()
    if currentGUID then
        -- print("LibItemLevel: Caching results for:", UnitName(currentUnit), "iLvl:", format("%.2f", ilvl))
        CACHE[currentGUID] = { ilvl = ilvl, expires = GetTime() + TIMEOUT }
        FireCallbacks(currentGUID, ilvl)
    end
    ProcessNext()
end

local function OnTimeout()
    timeoutTimer = nil
    if not currentUnit or not UnitExists(currentUnit) or not UnitIsPlayer(currentUnit) then
        ProcessNext()
        return
    end

    -- Try one last manual calculation or standard API
    local ilvl = UnitAverageItemLevel(currentUnit) or 0
    if ilvl == 0 then
        ilvl = CalculateManualIlvl(currentUnit)
    end
    OnResult(ilvl)
end

function ProcessNext()
    StopTimeout()
    
    if #queue == 0 then
        isInspecting = false
        currentUnit = nil
        currentGUID = nil
        currentRetries = 0
        return
    end

    local next = table.remove(queue, 1)
    currentUnit = next.unit
    currentGUID = next.guid
    currentCallbacks = next.callbacks
    currentRetries = 0
    
    -- Safeguard: Ensure unit still exists and is a player before proceeding
    if not currentUnit or not UnitExists(currentUnit) or not UnitIsPlayer(currentUnit) or UnitGUID(currentUnit) ~= currentGUID then
        ProcessNext()
        return
    end

    -- Check cache first
    local cached = CACHE[currentGUID]
    if cached and cached.expires > GetTime() then
        -- print("LibItemLevel: Queued cache hit for:", UnitName(currentUnit))
        FireCallbacks(currentGUID, cached.ilvl)
        ProcessNext()
        return
    end

    isInspecting = true
    
    -- Safely wait 200ms before triggering the inspection
    Timer.NewTimer(0.2, function()
        -- Safeguard: Ensure unit is still valid after the delay
        if not currentUnit or not UnitExists(currentUnit) or not UnitIsPlayer(currentUnit) or UnitGUID(currentUnit) ~= currentGUID then
            ProcessNext()
            return
        end

        -- Start timeout timer
        timeoutTimer = Timer.NewTimer(INSPECT_TIMEOUT, OnTimeout)

        if CanInspect(currentUnit) then
            NotifyInspect(currentUnit)
        else
            OnTimeout()
        end
    end)
end

function lib:Inspect(unit, callback, priority)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    
    local guid = UnitGUID(unit)
    
    -- If already inspecting this unit, just add to callbacks
    if isInspecting and currentGUID == guid then
        if callback then
            table.insert(currentCallbacks, callback)
        end
        return
    end
    
    -- Check cache
    local cached = CACHE[guid]
    if cached and cached.expires > GetTime() then
        -- print("LibItemLevel: Immediate cache hit for:", UnitName(unit))
        if callback then
            callback(guid, cached.ilvl)
        end
        return
    end

    -- Check if already in queue
    local foundIndex = nil
    for i, entry in ipairs(queue) do
        if entry.guid == guid then
            foundIndex = i
            break
        end
    end

    if foundIndex then
        local entry = queue[foundIndex]
        if callback then
            table.insert(entry.callbacks, callback)
        end
        if priority then
            -- Move to front
            table.remove(queue, foundIndex)
            table.insert(queue, 1, entry)
        end
    else
        local entry = { unit = unit, guid = guid, callbacks = { callback } }
        if priority then
            table.insert(queue, 1, entry)
        else
            table.insert(queue, entry)
        end
    end
    
    if not isInspecting then
        ProcessNext()
    end
end

function lib:InspectPriority(unit, callback)
    self:Inspect(unit, callback, true)
end

local function OnEvent(self, event, ...)
    if not isInspecting then return end
    
    if event == "INSPECT_TALENT_READY" then
        local unit = currentUnit
        if not unit or not UnitExists(unit) or UnitGUID(unit) ~= currentGUID or not UnitIsPlayer(unit) then
            ProcessNext()
            return
        end

        local ilvl = UnitAverageItemLevel(unit) or 0
        if ilvl == 0 then
            ilvl = CalculateManualIlvl(unit)
        end

        if ilvl > 0 or currentRetries >= MAX_RETRIES then
            OnResult(ilvl)
        else
            currentRetries = currentRetries + 1
            if CanInspect(unit) then
                NotifyInspect(unit)
                -- Reset timeout timer
                StopTimeout()
                timeoutTimer = Timer.NewTimer(INSPECT_TIMEOUT, OnTimeout)
            else
                OnResult(ilvl)
            end
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("INSPECT_TALENT_READY")
frame:SetScript("OnEvent", OnEvent)

function lib:ClearCache()
    CACHE = {}
end

function lib:GetCachedInfo(guid)
    return CACHE[guid]
end
