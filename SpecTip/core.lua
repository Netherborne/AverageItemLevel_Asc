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

AiL.specListLookup = {
    -- PYROMANCER
    [92126] = {'Flameweaving','Ability_Mage_FieryPayback'},
    [92124] = {'Incineration','Ability_Warlock_Backdraft'},
    [92128] = {'Draconic','INV_Weapon_Hand_06'},
    -- CULTIST
    [92131] = {'Heretic','spell_shadow_rune'},
    [92130] = {'Corruption','Achievement_Boss_CThun'},
    [680750] = {'Dreadnought','inv_shield_grimbatolraid_d_02'},
    [92129] = {'Godblade','INV_Sword_61'},
    -- VENOMANCER
    [92144] = {'Fortitude','ability_mount_hordescorpionamber'},
    [92143] = {'Stalking','inv_pet_spiderdemon'},
    [92142] = {'Rotweaver','_LiquidStone_Poison'},
    [680800] = {'Vizier','rogue_paralytic_poison'},
    [680837] = {'Vizier','rogue_paralytic_poison'},
    -- WITCH HUNTER
    [707064] = {'Black Knight','inv_helmet_23'},
    [92093] = {'Darkness','Ability_Warlock_ImprovedSoulLeech'},
    [92091] = {'Boltslinger','_d3preparation'},
    [92094] = {'Inquisition','Ability_Rogue_StayofExecution'},
    [707063] = {'Inquisition','Ability_Rogue_StayofExecution'},
    -- REAPER
    [92145] = {'Harvest','ability_rogue_sealfate'},
    [92147] = {'Domination','ability_touchofanimus'},
    [92146] = {'Soul','inv_artifact_thalkielsdiscord'},
    -- TEMPLAR
    [92111] = {'Crusader','Ability_Paladin_BlessedHands'},
    [92109] = {'Oathkeeper','_D3blindingflash'},
    [92108] = {'Zealot','_D3deadlyreach'},
    
    -- WITCH DOCTOR
    [92086] = {'Shadowhunting','Ability_Hunter_SurvivalInstincts'},
    [92085] = {'Brewing','INV_Misc_Cauldron_Nature'},
    [92084] = {'Voodoo','INV_Misc_Idol_02'},
    -- FELSWORN
    [92089] = {'Tyrant','Ability_Warlock_DemonicPower'},
    [92087] = {'Slaying','INV_Weapon_Glave_01'},
    [92088] = {'Infernal','Spell_Shadow_FingerOfDeath'},
    -- BARBARIAN
    [92083] = {'Ancestry','Achievement_Dungeon_UtgardeKeep_Normal'},
    [92082] = {'Headhunting','5_axe_(3)_Border'},
    [92081] = {'Brutality','Ability_Warrior_BloodFrenzy'},
    -- PRIMALIST
    [92150] = {'Life','Spell_Shaman_BlessingOfEternals'},
    [92148] = {'Wildwalker','_BearAttack_BrownFire'},
    [92149] = {'Geomancy','inv_elementalearth2'},
    [680395] = {'Mountain King','item_earthenmight'},
    -- SUN CLERIC
    [707072] = {'Valkyrie','inv_valkiergoldpet'},
    [92135] = {'Piety','ability_racial_finalverdict'},
    [92137] = {'Seraphim','Spell_Holy_Crusade'},
    [92136] = {'Blessings','Ability_Paladin_SacredCleansing'},
    -- RANGER
    [92115] = {'Archery','Ability_Hunter_LongShots'},
    [92117] ={'Farstrider','INV_Misc_Map02'},
    [92116] = {'Brigand','ability_rogue_rollthebones02'},
    -- BLOODMAGE
    [92114] = {'Eternal','achievement_dungeon_jeshowlis'},
    [681078] = {'Fleshweaver','custom_t_handsofblood_border'},
    [92112] = {'Sanguine','Spell_Shadow_LifeDrain'},
    [92113] = {'Accursed','Spell_DeathKnight_Gnaw_Ghoul'},
    -- RUNEMASTER
    [92153] = {'Engravement','70_inscription_vantus_rune_azure'},
    [92152] = {'Glyphic','_D3arcanetorrent'},
    [92154] = {'Riftblade','INV_Weapon_Shortblade_79'},
    -- TINKER
    [92141] = {'Mechanics','INV_Misc_EngGizmos_06'},
    [92140] = {'Invention','INV_Gizmo_RocketBootExtreme'},
    [92138] = {'Demolition','INV_Musket_04'},
    -- STORMBRINGER
    [92097] = {'Wind','Spell_Nature_InvisibilityTotem'},
    [92098] ={'Maelstrom','Achievement_Boss_Thorim'},
    [92096] = {'Lightning','ability_vehicle_electrocharge'},
    -- KNIGHT OF XOROTH
    [92101] = {'Hellfire','Spell_Shadow_ShadowandFlame'},
    [92104] = {'Defiance','INV_Belt_18'},
    [92100] = {'War','INV_MISC_HOOK_01'},
    -- GUARDIAN
    [92105] = {'Vanguard','Ability_Warrior_SwordandBoard'},
    [92107] = {'Inspiration','Achievement_BG_winWSG_3-0'},
    [92106] = {'Gladiator','Achievement_BG_KillFlagCarriers_grabFlag_CapIt'},
    -- NECROMANCER
    [92121] = {'Death','achievement_dungeon_naxxramas_25man'},
    [92123] = {'Animation','_D3wallofzombies'},
    [92122] = {'Rime','Achievement_Boss_Amnennar_the_Coldbringer'},
    -- CHRONOMANCER
    [92120] = {'Artificer','inv_wand_1h_pvp400_c_01'},
    [92118] = {'Duality','inv_enchant_philostone_lv2'},
    [92119] = {'Displacement','_AuraCloak_Ice'},
    -- STARCALLER
    [680725] = {'Warden','_liquidstone_water'},
    [92132] = {'Moon Guard','ability_hunter_carve'},
    [92133] = {'Sentinel','_Diablo3_ArrowRain_Mage'},
    [92134] = {'Moon Priest','Spell_Frost_ManaRecharge'},
}

--- DEBUG STUFF ---
function AiL.print(...)
    if AiL.Options.Debug then
        _print(...)
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
        -- INITIAL DATA BEFORE CACHE
		
        local spec, iconName = UnitSpecAndIcon(unit)
        AiL.print("No cache found for ",UnitName(unit),". Initializing to",spec)
        if IsCustomClass(unit) then
            spec = (spec == UnitClass(unit)) and spec or (spec .. " " .. UnitClass(unit))
        end
        local icon = " |T" .. (iconName or "INV_Misc_QuestionMark") .. ".blp:32:32:0:0|t "
        CACHE[guid] = {
            spec = spec,
            icon = icon,
            iconName = iconName,
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
            AiL.print("Removed stale cache entry for GUID:", guid)
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
        AiL.print("No specialization was reported by UnitSpecAndIcon(unit). Inspecting Build.")

        ---------------- COA TEST ---------------
        local activeSpec = C_CharacterAdvancement.GetInspectInfo(unit) or 1
        if not activeSpec then
            AiL.print("active spec of ", tostring(UnitName(unit)), " is null.")
            return
        end

        local entries = C_CharacterAdvancement.GetInspectedBuild(unit, activeSpec)
        if not entries or type(entries) ~= "table" then
            AiL.print("GetInspectedBuild did not return entries for spec ",activeSpec," of", UnitName(unit))
            return
        end

        for i, v in ipairs(entries) do
            local rank = v.Rank
            local internalID = v.EntryId
            local entry = C_CharacterAdvancement.GetEntryByInternalID(v.EntryId)
            if entry then
                local spellID = entry.Spells[rank]
                -- AiL.print("Inspecting CoA build entry ", i, " with spellID ", spellID, " for ", UnitName(unit))
                if AiL.specListLookup[spellID] then
                    data.spec = AiL.specListLookup[spellID][1] .. " " .. UnitClass(unit)
                    AiL.print("Inspecting CoA class spec ", UnitName(unit), "is now", data.spec)
                    data.icon = "Interface\\Icons\\".. AiL.specListLookup[spellID][2]
                    data.icon = " |T" .. data.icon .. ".blp:32:32:0:0|t "
                    data.specExpirationTime = timeNow + TIMEOUT
                    return
                end
            end
        end

        AiL.print(UnitName(unit), "no spec info found for ActiveSpec=",activeSpec)
    
    -- Is Hero --
    elseif IsHeroClass(unit) or C_Realm.IsLive() then
			local legendaryEnchantID = MysticEnchantUtil.GetLegendaryEnchantID(unit)
			if legendaryEnchantID then
				local name, _, icon = GetSpellInfo(legendaryEnchantID)
				if icon then
					newSpec = name
					newIcon = " |T" .. icon .. ".blp:32:32:0:0|t "
				end
			end  
            -- if seasonal, spec == class so timeout instantly. if not, timeout when spec ~= class			
			data.spec = newSpec or data.spec or class or "?"
			data.icon = newIcon
			if C_Realm.IsSeasonal() or data.spec ~= class then
				data.specExpirationTime = timeNow + TIMEOUT
			end
		else        
			-- catch-all for seasonal draft if not caught above?
			data.spec = newSpec or class
			data.icon = newIcon
			data.specExpirationTime = timeNow + TIMEOUT
		end
end

function AiL.notifyInspections(unit)
    if not unit then return end

    if AscensionInspectFrame and AscensionInspectFrame:IsShown() then	
        return
    end
	-- CombatLockdown is to verify with inspect...
    -- if InCombatLockdown() then
    --     return
    -- end
    if AiL.Options.Ilvl and not IsIlvlThrottled(unit) and CanInspect(unit) then
        NotifyInspect(unit)
    end
    if not IsSpecThrottled(unit) and IsCustomClass(unit) then
        C_CharacterAdvancement.InspectUnit(unit)
    end
    if IsHeroClass(unit) or C_Realm.IsLive() then
        if C_MysticEnchant.CanInspect(unit) and not IsSpecThrottled(unit) then
            AiL.print("Requesting Mystic Enchant inspect for ",UnitName(unit))
            C_MysticEnchant.Inspect(unit, true)
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
        AiL.print("Inspect result for", UnitName(unit), ":", data.ilvl, "-->", ilvl, ",saving.")
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
            AiL.print("Reached inspection limit for", UnitName(unit), ",stopping.")
            data.ilvlExpirationTime = timeNow + TIMEOUT
            data.inspections = 0
            return
        end
        AiL.print("Inspect result for", UnitName(unit), ":", data.ilvl, "-->", ilvl, ",repeating...")
        data.ilvlExpirationTime = 0
        data.ilvl = ilvl
        -- scaling reporting wrong ilvl workaround        
        AiL.notifyInspections(unit)
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