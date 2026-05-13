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

local MAJOR, MINOR = "LibSpecInspect-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local CACHE = {}
local queue = {}
local isInspecting = false
local currentUnit = nil
local currentGUID = nil
local currentCallbacks = {}
local timeoutTimer = nil

local TIMEOUT = 60*15 -- cache timeout
local INSPECT_TIMEOUT = 2 -- seconds to wait for a result before giving up

local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitClass = UnitClass
local CanInspect = CanInspect
local NotifyInspect = NotifyInspect
local GetSpellInfo = GetSpellInfo
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local UnitLevel = UnitLevel

lib.specListLookup = { -- LVL 10 passive internalID to specID
    -- PYROMANCER
    [92126] = 37, [92124] = 38, [300755] = 39,
    -- CULTIST
    [92131] = 40, [92130] = 41, [680750] = 96, [92129] = 42,
    -- VENOMANCER
    [92144] = 52, [92143] = 53, [92142] = 54, [680800] = 101,
    -- WITCH HUNTER
    [707064] = 97, [92093] = 11, [92091] = 10, [92094] = 12,
    -- REAPER
    [92145] = 56, [92147] = 57, [92146] = 55,
    -- TEMPLAR
    [92111] = 24, [92109] = 22, [92108] = 23,
    -- WITCH DOCTOR
    [92086] = 4, [92085] = 6, [92084] = 5,
    -- FELSWORN
    [92089] = 9, [92087] = 8, [92088] = 7,
    -- BARBARIAN
    [92083] = 3, [92082] = 1, [92081] = 2,
    -- PRIMALIST
    [92150] = 58, [92148] = 59, [92149] = 95, [680395] = 60,
    -- SUN CLERIC
    [707072] = 47, [92135] = 46, [92137] = 48, [92136] = 98,
    -- RANGER
    [92115] = 28, [92117] = 29, [92116] = 30,
    -- BLOODMAGE
    [92114] = 99, [681078] = 25, [92112] = 26, [92113] = 27,
    -- RUNEMASTER
    [92153] = 61, [92152] = 62, [92154] = 63,
    -- TINKER
    [92141] = 50, [92140] = 51, [92138] = 49,
    -- STORMBRINGER
    [92097] = 13, [92098] = 14, [92096] = 15,
    -- KNIGHT OF XOROTH
    [92101] = 16, [92104] = 17, [92100] = 18,
    -- GUARDIAN
    [92105] = 21, [92107] = 20, [92106] = 19,
    -- NECROMANCER
    [92121] = 34, [92123] = 35, [92122] = 36,
    -- CHRONOMANCER
    [92120] = 33, [92118] = 32, [92119] = 31,
    -- STARCALLER
    [680725] = 45, [92132] = 100, [92133] = 44, [92134] = 43,
}

local function GetUnitSpecAndIcon(unit)
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        if _G.UnitSpecAndIcon then
            return _G.UnitSpecAndIcon(unit)
        end
    end
end

local function FireCallbacks(guid, spec, icon)
    if currentGUID == guid then
        for _, callback in ipairs(currentCallbacks) do
            pcall(callback, guid, spec, icon)
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

local function OnTimeout()
    timeoutTimer = nil
    if not currentUnit or not UnitExists(currentUnit) or not UnitIsPlayer(currentUnit) then
        ProcessNext()
        return
    end
    -- If we timed out, fire with whatever we can get now
    local spec, icon = GetUnitSpecAndIcon(currentUnit)
    if not spec then
        local class = UnitClass(currentUnit)
        spec = class
    end
    FireCallbacks(currentGUID, spec, icon)
    ProcessNext()
end

function ProcessNext()
    StopTimeout()
    
    if #queue == 0 then
        isInspecting = false
        currentUnit = nil
        currentGUID = nil
        return
    end

    local next = table.remove(queue, 1)
    currentUnit = next.unit
    currentGUID = next.guid
    currentCallbacks = next.callbacks
    
    -- Safeguard: Ensure unit still exists and is a player before proceeding
    if not currentUnit or not UnitExists(currentUnit) or not UnitIsPlayer(currentUnit) or UnitGUID(currentUnit) ~= currentGUID then
        ProcessNext()
        return
    end
    
    -- Check cache first
    local cached = CACHE[currentGUID]
    if cached and cached.expires > GetTime() then
        -- print("LibSpecInspect: Queued cache hit for:", UnitName(currentUnit))
        FireCallbacks(currentGUID, cached.spec, cached.icon)
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

        if IsCustomClass(currentUnit) and UnitLevel(currentUnit) >= 10 then
            C_CharacterAdvancement.InspectUnit(currentUnit)
        elseif IsHeroClass(currentUnit) or IsDefaultClass(currentUnit) then
            if C_MysticEnchant.CanInspect(currentUnit) then
                C_MysticEnchant.Inspect(currentUnit, true)
            else
                OnTimeout()
            end
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
        -- print("LibSpecInspect: Immediate cache hit for:", UnitName(unit))
        if callback then
            callback(guid, cached.spec, cached.icon)
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
    
    if event == "MYSTIC_ENCHANT_INSPECT_RESULT" or 
       (event == "INSPECT_CHARACTER_ADVANCEMENT_RESULT" and select(1, ...) == "CA_INSPECT_OK") then
        
        local unit = currentUnit
        if not unit or not UnitExists(unit) or UnitGUID(unit) ~= currentGUID or not UnitIsPlayer(unit) then
            ProcessNext()
            return
        end

        local class, classFile = UnitClass(unit)
        local newSpec, newIcon = GetUnitSpecAndIcon(unit)
        
        local finalSpec, finalIcon
        
        if IsCustomClass(unit) then
            if newSpec and newSpec ~= class then
                finalSpec = newSpec .. " " .. class
                finalIcon = newIcon
            else
                local activeSpec = C_CharacterAdvancement.GetInspectInfo(unit)
                if activeSpec then
                    local entries = C_CharacterAdvancement.GetInspectedBuild(unit, activeSpec)
                    if entries then
                        for _, v in ipairs(entries) do
                            local entry = C_CharacterAdvancement.GetEntryByInternalID(v.EntryId)
                            if entry then
                                local rank = v.Rank
                                local spellID = entry.Spells[rank]
                                local specID = lib.specListLookup[spellID]
                                if specID then
                                    local specInfo = C_ClassInfo.GetSpecInfoByID(specID)
                                    if specInfo then
                                        finalIcon = "Interface\\Icons\\"..(specInfo.SpecFilename or "INV_Misc_QuestionMark")
                                        finalSpec = (specInfo.Name or "Unknown").." "..class
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            local legendaryEnchantID = MysticEnchantUtil.GetLegendaryEnchantID(unit)
            if legendaryEnchantID then
                local name, _, icon = GetSpellInfo(legendaryEnchantID)
                if icon then
                    newSpec = name
                    newIcon = icon
                end
            end
            finalSpec = newSpec or class
            finalIcon = newIcon
        end

        if finalSpec then
            -- print("LibSpecInspect: Caching results for:", UnitName(unit), "Spec:", finalSpec)
            CACHE[currentGUID] = { spec = finalSpec, icon = finalIcon, expires = GetTime() + TIMEOUT }
            FireCallbacks(currentGUID, finalSpec, finalIcon)
        end
        
        ProcessNext()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MYSTIC_ENCHANT_INSPECT_RESULT")
frame:RegisterEvent("INSPECT_CHARACTER_ADVANCEMENT_RESULT")
frame:SetScript("OnEvent", OnEvent)

function lib:ClearCache()
    CACHE = {}
end

function lib:GetCachedInfo(guid)
    return CACHE[guid]
end
