AiL = select(2, ...)
local _print = print

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

function AiL.toggleDebug()
    AiL.Options.Debug = not AiL.Options.Debug
    _print(AiL.Options.Debug and "Debug turned on." or "Debug turned off.")
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