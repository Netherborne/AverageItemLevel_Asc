AiL = select(2, ...)
local CACHE = {}
local _print = print
local IsHeroClass = IsHeroClass
local C_Realm = C_Realm
local C_CharacterAdvancement = C_CharacterAdvancement
local C_MysticEnchant = C_MysticEnchant
local TIMEOUT = AiL.Config.TIMEOUT
local MAX_INSPECTIONS_TO_TIMEOUT = AiL.Config.MAX_INSPECTIONS_TO_TIMEOUT
local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitClass = UnitClass
local CanInspect = CanInspect
local NotifyInspect = NotifyInspect
local UnitAverageItemLevel = UnitAverageItemLevel
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = GetItemInfo
local GetSpellInfo = GetSpellInfo
local InCombatLockdown = InCombatLockdown
local _UnitSpecAndIcon = UnitSpecAndIcon
AiL.lastInspectGUID = nil
AiL.specListLookup = { -- LVL 10 passive internalID to specID
    -- PYROMANCER
    [92126] = 37,
    [92124] = 38,
    [300755] = 39,
    -- CULTIST
    [92131] = 40,
    [92130] = 41,
    [680750] = 96,
    [92129] = 42,
    -- VENOMANCER
    [92144] = 52,
    [92143] = 53,
    [92142] = 54,
    [680800] = 101,
    -- WITCH HUNTER
    [707064] = 97,
    [92093] = 11,
    [92091] = 10,
    [92094] = 12,
    -- REAPER
    [92145] = 56,
    [92147] = 57,
    [92146] = 55,
    -- TEMPLAR
    [92111] = 24,
    [92109] = 22,
    [92108] = 23,
    
    -- WITCH DOCTOR
    [92086] = 4,
    [92085] = 6,
    [92084] = 5,
    -- FELSWORN
    [92089] = 9,
    [92087] = 8,
    [92088] = 7,
    -- BARBARIAN
    [92083] = 3,
    [92082] = 1,
    [92081] = 2,
    -- PRIMALIST
    [92150] = 58,
    [92148] = 59,
    [92149] = 95,
    [680395] = 60,
    -- SUN CLERIC
    [707072] = 47,
    [92135] = 46,
    [92137] = 48,
    [92136] = 98,
    -- RANGER
    [92115] = 28,
    [92117] = 29,
    [92116] = 30,
    -- BLOODMAGE
    [92114] = 99,
    [681078] = 25,
    [92112] = 26,
    [92113] = 27,
    -- RUNEMASTER
    [92153] = 61,
    [92152] = 62,
    [92154] = 63,
    -- TINKER
    [92141] = 50,
    [92140] = 51,
    [92138] = 49,
    -- STORMBRINGER
    [92097] = 13,
    [92098] = 14,
    [92096] = 15,
    -- KNIGHT OF XOROTH
    [92101] = 16,
    [92104] = 17,
    [92100] = 18,
    -- GUARDIAN
    [92105] = 21,
    [92107] = 20,
    [92106] = 19,
    -- NECROMANCER
    [92121] = 34,
    [92123] = 35,
    [92122] = 36,
    -- CHRONOMANCER
    [92120] = 33,
    [92118] = 32,
    [92119] = 31,
    -- STARCALLER
    [680725] = 45,
    [92132] = 100,
    [92133] = 44,
    [92134] = 43,
}

--- DEBUG STUFF ---
function AiL.print(tag,...)
    if AiL.Options.Debug then
        local minLevel = AiL.Options.DebugLevel or 0
        if minLevel == 1 and tag == "INF" then
            return
        end
        if minLevel == 2 and (tag == "WRN" or tag == "INF") then
            return
        end
        local errorcolor = "ffff0000"
        local infoColor = "6fa8dc00"
        local warningColor = "ffff9900"

        if not ColorUtil or not ColorUtil.WrapTextInColorCode or tag == nil then
            tag = ""

        elseif tag == "ERR" then
            tag = ColorUtil.WrapTextInColorCode("ERROR: ",errorcolor)
        elseif tag == "INF" then
            tag = ColorUtil.WrapTextInColorCode("INFO: ",infoColor)
        elseif tag == "WRN" then
            tag = ColorUtil.WrapTextInColorCode("WARNING: ",warningColor)
        else
            tag = ""
        end


        _print(tag,...)
    end
end


local function UnitSpecAndIcon(unit)
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        return _UnitSpecAndIcon(unit)
    end
end
function AiL.toggleDebug()
    AiL.Options.Debug = not AiL.Options.Debug
    _print(AiL.Options.Debug and "Debug turned on." or "Debug turned off.")
end
------ CACHE ------
function AiL.getCache()
    return CACHE
end

function AiL.getCacheForUnit(unit)
    if not unit then
        return
    end
    local guid = UnitGUID(unit)
    if not CACHE[guid] then
        local spec, icon = UnitSpecAndIcon(unit)
        CACHE[guid] = {
            spec = spec,
            icon = " |T" .. icon .. ".blp:32:32:0:0|t ",
            ilvl = 0,
            true_ilvl = 0,
            specExpirationTime = 0,
            ilvlExpirationTime = 0,
            inspections = 0
        }
    end
    return CACHE[guid]
end

function AiL.ClearCache()
    CACHE = {}
end

function AiL.resetAllExpirations()
    for _, data in pairs(CACHE) do
        data.specExpirationTime = 0
        data.ilvlExpirationTime = 0
    end
end

function AiL.cleanupStaleCache()
    local currentTime = GetTime()
    local staleThreshold = currentTime - 600  -- 10 minutes ago
    for guid, data in pairs(CACHE) do
        if data.specExpirationTime > 0 and data.ilvlExpirationTime > 0 and
           data.specExpirationTime < staleThreshold and data.ilvlExpirationTime < staleThreshold then
            CACHE[guid] = nil
            AiL.print("INF","Removed stale cache entry for GUID:", guid)
        end
    end
end

function AiL.SetInspectTimeout(newTimeout)
    TIMEOUT = newTimeout > 0 and newTimeout or 1
    AiL.resetAllExpirations()
end

local function IsIlvlThrottled(unit)
    return AiL.getCacheForUnit(unit).ilvlExpirationTime > GetTime()
end

local function IsSpecThrottled(unit)
    return AiL.getCacheForUnit(unit).specExpirationTime > GetTime()
end

function AiL.updateCacheSpec(unit)
    if not unit then return end
    
    if IsSpecThrottled(unit) then
        return
    end
    
    local timeNow = GetTime()
    local class, classFile = UnitClass(unit)
    local newSpec, newIcon = UnitSpecAndIcon(unit)
    if not newSpec or not newIcon then
        AiL.print("ERR","UnitSpecAndIcon did not return valid info for", UnitName(unit),".")
        newSpec = class or "?"
    end
    newIcon = " |T" .. (newIcon or "INV_Misc_QuestionMark") .. ".blp:32:32:0:0|t "
    local data = AiL.getCacheForUnit(unit)
    -- Is CoA --
    if IsCustomClass(unit) then
        data.spec = newSpec
        
        if newSpec ~= UnitClass(unit) then -- UnitSpecAndIcon returned Specialization so we need to append the class
            data.spec = newSpec .. " " .. UnitClass(unit)
            data.icon = newIcon
            data.specExpirationTime = timeNow + TIMEOUT
            return
        end
        AiL.print("INF","No specialization was reported by UnitSpecAndIcon(unit). Inspecting Build.")

        local activeSpec = C_CharacterAdvancement.GetInspectInfo(unit)
        if not activeSpec then
            AiL.print("WRN",tostring(UnitName(unit)),"does not have any specialization active.")
            return
        end

        local entries = C_CharacterAdvancement.GetInspectedBuild(unit, activeSpec)
        if not entries or type(entries) ~= "table" then
            AiL.print("ERR","GetInspectedBuild did not return entries for spec #",activeSpec," of", UnitName(unit))
            return
        end

        for i, v in ipairs(entries) do
            local rank = v.Rank
            local internalID = v.EntryId
            local entry = C_CharacterAdvancement.GetEntryByInternalID(v.EntryId)
            if entry then
                local spellID = entry.Spells[rank]
                local specID = AiL.specListLookup[spellID]
                if specID then

                    local specInfo = C_ClassInfo.GetSpecInfoByID(specID)
                    if specInfo then
                        if  specInfo.SpecFilename then 
                            data.icon = " |T" .. "Interface\\Icons\\"..specInfo.SpecFilename..".blp:32:32:0:0|t "
                        end
                        if specInfo.Name then
                            data.spec = specInfo.Name.." "..UnitClass(unit)
                        end
                    end
                    data.specExpirationTime = timeNow + TIMEOUT
                    AiL.print("INF","Matched found. ",UnitName(unit),"is now",data.spec)
                    local onEventScript = GameTooltip:GetScript("OnEvent")
                    if onEventScript then
                        onEventScript(GameTooltip, "AIL_COA_SPEC_FOUND")
                    end
                    return
                end
            end
        end

        AiL.print("WRN","No spec info found for",UnitName(unit),". Defaulting to class only.")
    
    -- Is Hero or OG9 --
    else
        local legendaryEnchantID = MysticEnchantUtil.GetLegendaryEnchantID(unit)
        if legendaryEnchantID then
            local name, _, icon = GetSpellInfo(legendaryEnchantID)
            if icon then
                newSpec = name
                newIcon = " |T" .. icon .. ".blp:32:32:0:0|t "
            end
        end  
        -- if seasonal (Elune), spec == class so timeout instantly. if not, timeout when spec ~= class			
        data.spec = newSpec or data.spec or class or "?"
        data.icon = newIcon
        if C_Realm.IsSeasonal() or data.spec ~= class then
            data.specExpirationTime = timeNow + TIMEOUT
        end
	end
end

function AiL.notifyInspections(unit, type)
    if not unit  then 
        AiL.print("ERR","notifyInspections: No unit passed to function")
        return 
    end
    if not UnitExists(unit) or not UnitIsPlayer(unit)  then 
        AiL.print("WRN","notifyInspections: Unit does not exist or is not a player.")
        return
    end
    if AscensionInspectFrame and AscensionInspectFrame:IsShown() then	
        AiL.print("WRN","notifyInspections: AscensionInspectFrame is shown")
        return
    end
  
    AiL.lastInspectGUID = UnitGUID(unit)
    if type == "ALL" or type == "ILVL_ONLY" then
        
        -- ITEM LEVEL INSPECTION
        if AiL.Options.Ilvl and not IsIlvlThrottled(unit) then
            if CanInspect(unit) then
                AiL.print("INF","Requesting ilvl inspection for ",UnitName(unit))
                NotifyInspect(unit)
            else
                AiL.print("WRN","Cannot inspect", UnitName(unit), "for ilvl at this time. Too far away?")
            end
        end
    end

    if type == "ALL" or type == "SPEC_ONLY" then
        -- SPECIALIZATION INSPECTION FOR COA
        if not IsSpecThrottled(unit) and IsCustomClass(unit) and UnitLevel(unit) >= 10 then
            AiL.print("INF","Requesting spec inspection for ",UnitName(unit))
            C_CharacterAdvancement.InspectUnit(unit)

        -- SPECIALIZATION INSPECTION FOR HERO and OG9 CLASSES
        elseif IsHeroClass(unit) or C_Realm.IsLive() then
            if C_MysticEnchant.CanInspect(unit) and not IsSpecThrottled(unit) then
                AiL.print("INF","Requesting Mystic Enchant inspect for ",UnitName(unit))
                C_MysticEnchant.Inspect(unit, true)
            else
                AiL.print("WRN","Cannot inspect", UnitName(unit), "for spec at this time.")
            end
        end
    end
end

-- Fallback Scanner when Ascension's UnitAverageItemLevel returns nil or 0
-- this one skips shirt slot so value may differ from API
function AiL.CalculateManualIlvl(unit)
    local totalIlvl = 0
    local has2H = false
    for slot = 1, 18 do
        if slot ~= 4 then 
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

function AiL.updateCacheIlvl(unit)
    if not unit or not UnitExists(unit) then return end

    if not AiL.Options.Ilvl or IsIlvlThrottled(unit) then
        return
    end
    local ilvl = UnitAverageItemLevel(unit)
    if not ilvl or ilvl == 0 then
        ilvl = AiL.CalculateManualIlvl(unit)
    end
    if ilvl == nil then
        return
    end 
    local data = AiL.getCacheForUnit(unit)
    local timeNow = GetTime()
    if ilvl > 0 and data.ilvl == ilvl then
        AiL.print("INF","Inspect result for", UnitName(unit), ":",  format("%.02f",data.ilvl), "-->", format("%.02f",ilvl), ",saving.")
        data.ilvlExpirationTime = timeNow + TIMEOUT
        data.inspections = 0
        data.true_ilvl = ilvl
		-- def
        local onEventScript = GameTooltip:GetScript("OnEvent")
        if onEventScript then
            onEventScript(GameTooltip, "AIL_FINAL_INSPECT_REACHED")
        end
    elseif data.ilvl ~= ilvl or ilvl == 0 then
        if data.inspections >= MAX_INSPECTIONS_TO_TIMEOUT then
            AiL.print("WRN","Reached inspection limit for", UnitName(unit), ",stopping.")
            data.ilvlExpirationTime = timeNow + TIMEOUT
            data.inspections = 0
            return
        end
        AiL.print("INF","Inspect result for", UnitName(unit), ":", format("%.02f",data.ilvl), "-->", format("%.02f",ilvl), ",repeating...")
        data.ilvlExpirationTime = 0
        data.ilvl = ilvl
        -- scaling reporting wrong ilvl workaround        
        AiL.notifyInspections(unit,"ILVL_ONLY")
        data.inspections = data.inspections + 1
    end
end

function AiL.getColorforUnitSpec(unit, spec)
    local color
    if spec == UnitClass(unit) or IsCustomClass(unit) then
        color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
    end
    if not color then
        color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]
    end
    return color
end

function AiL.getColoredIlvlString(unitLevel, itemLevel)
    local color = WHITE_FONT_COLOR
    local expansionTarget = Enum.Expansion.Vanilla

    if unitLevel > 70 then
        expansionTarget = Enum.Expansion.WoTLK
    elseif unitLevel > 60 then
        expansionTarget = Enum.Expansion.TBC
    end

    local softCap = GetItemLevelSoftCap(expansionTarget)
    if itemLevel <= softCap then
        color = ColorUtil:Lerp(color, ITEM_QUALITY_COLORS[Enum.ItemQuality.Epic], itemLevel / softCap)
    else
        color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]
    end

    if itemLevel > 0 then
        return "(" .. color:WrapText(format("%.02f", itemLevel)) .. ")"
    else
        color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Poor]
        return "(" .. color:WrapText("?") .. ")"
    end
end