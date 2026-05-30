AiL = select(2, ...)
AiL.Options = AiL.Options or {}
AiL.hiddenText = "|HAiLC|h" -- used as hidden text to be able to find our custom line in the tooltip easier
local LibItemLevel = LibStub("LibItemLevel-1.0")
local LibSpecInspect = LibStub("LibSpecInspect-1.0")
local IsHeroClass = IsHeroClass
local UnitLevel = UnitLevel
local UnitIsPlayer = UnitIsPlayer
local UnitExists = UnitExists

AiL.lastInspect = {}
local GameTooltipSpecTipIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
GameTooltipSpecTipIcon:SetSize(20, 20)


local function doCleanup()
    if GameTooltipSpecTipIcon:IsShown() then
        GameTooltipSpecTipIcon:Hide()
    end
end



local function updateSpecTooltipText(self,unit,spec,icon)
    if not unit then return end
    for i = 1, self:NumLines() do
        local leftLine = _G["GameTooltipTextLeft" .. i]
        if leftLine then
            local text = leftLine:GetText() or ""
            if string.find(text, AiL.hiddenText, 1, true) then
               
                local iconPath = AiL.Options.ShowIcon and icon or nil
                local color = AiL.getColorforUnitSpec(unit, spec)
                local lineText = AiL.hiddenText .. color:WrapText(spec)
                if iconPath then
                    lineText = "       " .. lineText
                    GameTooltipSpecTipIcon:SetTexture(iconPath)
                    GameTooltipSpecTipIcon:SetPoint("LEFT", leftLine, "LEFT", 0, 0)
                    GameTooltipSpecTipIcon:Show()
                else
                    GameTooltipSpecTipIcon:Hide()
                end
                leftLine:SetText(lineText)
            end
        end
    end
end

local function updateIlvlTooltipText(self,unit,guid,ilvl)
    if not AiL.Options.Ilvl or not unit then
        return
    end
    for i = 1, self:NumLines() do
        local leftLine = _G["GameTooltipTextLeft" .. i]
        local rightLine = _G["GameTooltipTextRight" .. i]
        if leftLine and rightLine then
            local text = leftLine:GetText() or ""
            if string.find(text, AiL.hiddenText, 1, true) then
                rightLine:SetText(AiL.getColoredIlvlString(UnitLevel(unit), ilvl))
            end
        end
    end
end


local function doInspections(unit)
    LibSpecInspect:InspectPriority(unit, function(guid, spec, icon, role, isTimeout)
        local onEventScript = GameTooltip:GetScript("OnEvent")
        if onEventScript then
            onEventScript(GameTooltip, "SPECTIP_UPDATE_SPEC", unit, spec, icon, role, isTimeout)
        end
    end)

    if AiL.Options.Ilvl then
        LibItemLevel:InspectPriority(unit, function(guid, ilvl, isTimeout)
            local onEventScript = GameTooltip:GetScript("OnEvent")
            if onEventScript then
                onEventScript(GameTooltip, "SPECTIP_UPDATE_ILVL", unit, guid, ilvl, isTimeout)
            end
        end)
    end
end

local function OnTooltipSetUnitHandler(self)
  local _, unit = self:GetUnit()
    if not unit or not UnitIsPlayer(unit) then
        return
    end
    self:AddLine(" ")
    
    local spec, icon = UnitSpecAndIcon(unit)
    local color = AiL.getColorforUnitSpec(unit, spec)
    local lineText = AiL.hiddenText .. color:WrapText(spec)
    if icon then
        lineText = "       " .. lineText -- Add padding for the icon
    end
    if AiL.Options.Ilvl then
        self:AddDoubleLine(lineText,"(?)")
    else
        self:AddLine(lineText)
    end
    updateSpecTooltipText(self,unit,spec,icon)
    AiL.lastInspect.guid = UnitGUID(unit)
    doInspections(unit)
end



local function GameTooltipOnEvent(self, event, ...)
    local _, unit = self:GetUnit()
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
        return
    end
    if not AiL.lastInspect.guid or AiL.lastInspect.guid ~= UnitGUID(unit) then
        AiL.print("WRN","Received data for",AiL.lastInspect.name, "but current unit is",UnitName(unit),". Ignoring.");
        return
    end
    if event == "SPECTIP_UPDATE_SPEC" then
        local unit, spec, icon, role, isTimeout = ...
        updateSpecTooltipText(self, unit, spec, icon)
        GameTooltip:Show()
        return
    end
    if event == "SPECTIP_UPDATE_ILVL" then
        local unit, guid, ilvl, isTimeout = ...
        updateIlvlTooltipText(self, unit, guid, ilvl)
        GameTooltip:Show()
    end
end


GameTooltip:HookScript("OnEvent", GameTooltipOnEvent)
GameTooltip:RegisterEvent("SPECTIP_UPDATE_SPEC")
GameTooltip:RegisterEvent("SPECTIP_UPDATE_ILVL")
if GameTooltip:HasScript("OnTooltipSetUnit") then
    GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnitHandler)
else
    GameTooltip:SetScript("OnTooltipSetUnit", OnTooltipSetUnitHandler)
end

GameTooltip:HookScript("OnHide", doCleanup)
GameTooltip:HookScript("OnTooltipCleared", doCleanup)