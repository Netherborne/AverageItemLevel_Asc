AiL = select(2, ...)
AiL.Options = AiL.Options or {}
AiL.hiddenText = "|HAiLC|h" -- used as hidden text to be able to find our custom line in the tooltip easier
AiL.specListLookup = AiL.specListLookup or {}
local IsHeroClass = IsHeroClass
local C_Realm = C_Realm
local UnitLevel = UnitLevel
local UnitIsPlayer = UnitIsPlayer
local UnitExists = UnitExists
local GameTooltipSpecTipIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
GameTooltipSpecTipIcon:SetSize(20, 20)


local function OnTooltipSetUnitHandler(self)
    GameTooltipSpecTipIcon:Hide()
    if AiL.inspectionTimer then
        AiL.inspectionTimer:Cancel()
        -- AiL.print("INF","Cancelled inspection timer")
        AiL.inspectionTimer = nil
    end

    local _, unit = self:GetUnit()
    if not unit or not UnitIsPlayer(unit) then
        return
    end
    -- local check,unitCache = pcall(AiL.getCacheForUnit, unit)
    -- if not check or not unitCache or not unitCache.spec then
    --     AiL.print("ERR","Error retrieving cache, reason: " .. tostring(check))
    --     return
    -- end
    local unitCache = AiL.getCacheForUnit(unit)
    local spec = unitCache.spec
    local iconPath = AiL.Options.ShowIcon and unitCache.icon or nil
    local color = AiL.getColorforUnitSpec(unit, spec)
    self:AddLine(" ")
    
    local lineText = AiL.hiddenText .. color:WrapText(spec)
    if iconPath then
        lineText = "       " .. lineText -- Add padding for the icon
    end

    if AiL.Options.Ilvl then
        self:AddDoubleLine(lineText,
            AiL.getColoredIlvlString(UnitLevel(unit), AiL.getCacheForUnit(unit).true_ilvl))
    else
        self:AddLine(lineText)
    end
    if iconPath then
        local numLines = self:NumLines()
        local leftLine = _G["GameTooltipTextLeft" .. numLines]
        GameTooltipSpecTipIcon:SetTexture(iconPath)
        GameTooltipSpecTipIcon:SetPoint("LEFT", leftLine, "LEFT", 0, 0)
        GameTooltipSpecTipIcon:Show()
    else
        GameTooltipSpecTipIcon:Hide()
    end
    local beforeTimerGUID = UnitGUID(unit)
    -- AiL.print("INF","Starting inspection timer")
    AiL.inspectionTimer = Timer.NewTimer(0.3, function()
        local timerGUID = UnitGUID(unit)
        if timerGUID ~= beforeTimerGUID then
            -- AiL.print("WRN","GUID changed during inspection timer. Cancelling.")
            AiL.inspectionTimer = nil
            return
        end
        -- AiL.print("INF","Timer triggered")
        AiL.notifyInspections(unit, "ALL")
        AiL.inspectionTimer = nil
    end)
end

local function updateSpecTooltipText(self, unit)
    if not unit then return end
    for i = 1, self:NumLines() do
        local leftLine = _G["GameTooltipTextLeft" .. i]
        if leftLine then
            local text = leftLine:GetText() or ""
            if string.find(text, AiL.hiddenText, 1, true) then
                local unitCache = AiL.getCacheForUnit(unit)
                local spec = unitCache.spec
                local iconPath = AiL.Options.ShowIcon and unitCache.icon or nil
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

local function updateIlvlTooltipText(self, unit)
    if not AiL.Options.Ilvl or not unit then
        return
    end
    for i = 1, self:NumLines() do
        local leftLine = _G["GameTooltipTextLeft" .. i]
        local rightLine = _G["GameTooltipTextRight" .. i]
        if leftLine and rightLine then
            local text = leftLine:GetText() or ""
            if string.find(text, AiL.hiddenText, 1, true) then
                rightLine:SetText(AiL.getColoredIlvlString(UnitLevel(unit), AiL.getCacheForUnit(unit).true_ilvl))
            end
        end
    end
end

local function GameTooltipOnEvent(self, event, ...)
    local _, unit = self:GetUnit()
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
        return
    end
    if not AiL.lastInspectGUID or AiL.lastInspectGUID ~= UnitGUID(unit) then
        AiL.print("WRN","Received event", event, "while mouseover GUID is ",UnitGUID(unit), "but inspection results were for", AiL.lastInspectGUID,". Ignoring event.");
        return
    end

    if event == "AIL_COA_SPEC_FOUND" then
        updateSpecTooltipText(self, unit)
    elseif event == "INSPECT_TALENT_READY" then
        if AiL.Options.Ilvl then
            AiL.updateCacheIlvl(unit)
            updateIlvlTooltipText(self, unit)
        end
    elseif event == "AIL_FINAL_INSPECT_REACHED" then
        if AiL.Options.Ilvl then
            updateIlvlTooltipText(self, unit)
        end
    elseif (event == "MYSTIC_ENCHANT_INSPECT_RESULT" and (IsHeroClass(unit) or C_Realm.IsLive())) or
        (event == "INSPECT_CHARACTER_ADVANCEMENT_RESULT" and select(1, ...) == "CA_INSPECT_OK") then
        AiL.updateCacheSpec(unit)
        updateSpecTooltipText(self, unit)
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

GameTooltip:HookScript("OnHide", function(self)
    if AiL.inspectionTimer then
        AiL.inspectionTimer:Cancel()
        -- AiL.print("INF","Cancelled inspection timer")
        AiL.inspectionTimer = nil
    end
    GameTooltipSpecTipIcon:Hide()
end)