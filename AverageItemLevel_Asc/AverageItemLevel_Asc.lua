AiL = select(2, ...)
AiL.Options = AiL.Options or {}
AiL.hiddenText = "|HAiLC|h" -- used as hidden text to be able to find our custom line in the tooltip easier
AiL.specListLookup = AiL.specListLookup or {}
local IsHeroClass = IsHeroClass
local C_Realm = C_Realm
local UnitLevel = UnitLevel
local UnitIsPlayer = UnitIsPlayer

local function OnTooltipSetUnitHandler(self)
    local _, unit = self:GetUnit()
    if not unit or not UnitIsPlayer(unit) then
        return
    end
    local unitCache = AiL.getCacheForUnit(unit)
    local spec = unitCache.spec
    local icon = AiL.Options.ShowIcon and unitCache.icon or ""
    local color = AiL.getColorforUnitSpec(unit, spec)
    self:AddLine(" ")
    self:AddDoubleLine(AiL.hiddenText .. icon .. color:WrapText(spec),
        AiL.getColoredIlvlString(UnitLevel(unit), AiL.getCacheForUnit(unit).true_ilvl))
    AiL.notifyInspections(unit)
end

local function GameTooltipOnEvent(self, event, ...)
    local _, unit = self:GetUnit()
    if not unit or not UnitIsPlayer(unit) then
        return
    end
    if event == "INSPECT_TALENT_READY" then
        for i = 1, self:NumLines() do
            if string.match(_G["GameTooltipTextLeft" .. i]:GetText() or "", AiL.hiddenText) then 
                _G["GameTooltipTextRight" .. i]:SetText(AiL.getColoredIlvlString(UnitLevel(unit),
                    AiL.getCacheForUnit(unit).true_ilvl))
            end
        end
        AiL.updateCacheIlvl(unit)
    elseif event == "AIL_FINAL_INSPECT_REACHED" then
        for i = 1, self:NumLines() do
            if string.match(_G["GameTooltipTextLeft" .. i]:GetText() or "", AiL.hiddenText) then
                _G["GameTooltipTextRight" .. i]:SetText(AiL.getColoredIlvlString(UnitLevel(unit),
                    AiL.getCacheForUnit(unit).true_ilvl))
            end
        end
    elseif (event == "MYSTIC_ENCHANT_INSPECT_RESULT" and (IsHeroClass(unit) or C_Realm.IsLive())) or
        (event == "INSPECT_CHARACTER_ADVANCEMENT_RESULT" and select(1, ...) == "CA_INSPECT_OK") then
        AiL.updateCacheSpec(unit)
        for i = 1, self:NumLines() do
            if string.match(_G["GameTooltipTextLeft" .. i]:GetText() or "", AiL.hiddenText) then
                local unitCache = AiL.getCacheForUnit(unit)
                local spec = unitCache.spec
                local icon = AiL.Options.ShowIcon and unitCache.icon or ""
                local color = AiL.getColorforUnitSpec(unit, spec)
                _G["GameTooltipTextLeft" .. i]:SetText(AiL.hiddenText .. icon .. color:WrapText(spec))
            end
        end
    end
    GameTooltip:Show()
end

GameTooltip:RegisterEvent("INSPECT_TALENT_READY")
GameTooltip:RegisterEvent("MYSTIC_ENCHANT_INSPECT_RESULT")
GameTooltip:RegisterEvent("AIL_FINAL_INSPECT_REACHED")
GameTooltip:RegisterEvent("INSPECT_CHARACTER_ADVANCEMENT_RESULT")
GameTooltip:HookScript("OnEvent", GameTooltipOnEvent)

if GameTooltip:HasScript("OnTooltipSetUnit") then
    GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnitHandler)
else
    GameTooltip:SetScript("OnTooltipSetUnit", OnTooltipSetUnitHandler)
end
