-- Config.lua for SpecTip addon
-- Handles the addon settings panel for WoW 3.3.5



AiL = select(2, ...)

if not AiL then return end
AiL.Config = AiL.Config or {}
AiL.Config.TIMEOUT = 180
AiL.Config.MAX_INSPECTIONS_TO_TIMEOUT = 5


local addonName = "SpecTip"
SpecTipOptions = SpecTipOptions or {}

local defaults = {
    ShowIcon = true,
    Ilvl = true,
    Debug = false,
}


local function createSettingsPanel()
    local panel = CreateFrame("Frame", addonName .. "OptionsPanel")
    panel.name = addonName

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(addonName .. " Options")

    -- Show Icon checkbox
    local showIconCheckbox = CreateFrame("CheckButton", addonName .. "ShowIcon", panel, "InterfaceOptionsCheckButtonTemplate")
    showIconCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    if not showIconCheckbox.Text then
        showIconCheckbox.Text = showIconCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        showIconCheckbox.Text:SetPoint("LEFT", showIconCheckbox, "RIGHT", 4, 0)
    end
    showIconCheckbox.Text:SetText("Show spec icons in tooltips")
    showIconCheckbox.tooltipText = "Display class/spec icons next to the spec name in player tooltips."

    -- Ilvl checkbox
    local ilvlCheckbox = CreateFrame("CheckButton", addonName .. "Ilvl", panel, "InterfaceOptionsCheckButtonTemplate")
    ilvlCheckbox:SetPoint("TOPLEFT", showIconCheckbox, "BOTTOMLEFT", 0, -8)
    if not ilvlCheckbox.Text then
        ilvlCheckbox.Text = ilvlCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ilvlCheckbox.Text:SetPoint("LEFT", ilvlCheckbox, "RIGHT", 4, 0)
    end
    ilvlCheckbox.Text:SetText("Show item level in tooltips")
    ilvlCheckbox.tooltipText = "Display the average item level next to the spec in player tooltips."

    -- Debug checkbox
    local debugCheckbox = CreateFrame("CheckButton", addonName .. "Debug", panel, "InterfaceOptionsCheckButtonTemplate")
    debugCheckbox:SetPoint("TOPLEFT", ilvlCheckbox, "BOTTOMLEFT", 0, -8)
    if not debugCheckbox.Text then
        debugCheckbox.Text = debugCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        debugCheckbox.Text:SetPoint("LEFT", debugCheckbox, "RIGHT", 4, 0)
    end
    debugCheckbox.Text:SetText("Enable debug mode")
    debugCheckbox.tooltipText = "Enable debug output for troubleshooting."

    -- Function to refresh the panel
    local function RefreshPanel()
        showIconCheckbox:SetChecked(AiL.Options.ShowIcon)
        ilvlCheckbox:SetChecked(AiL.Options.Ilvl)
        debugCheckbox:SetChecked(AiL.Options.Debug)
    end

    -- Function to handle checkbox changes
    local function OnShowIconChanged(self)
        AiL.Options.ShowIcon = self:GetChecked() and true or false
    end

    local function OnIlvlChanged(self)
        AiL.Options.Ilvl = self:GetChecked() and true or false
    end

    local function OnDebugChanged(self)
        AiL.Options.Debug = self:GetChecked() and true or false
    end

    -- Set scripts
    showIconCheckbox:SetScript("OnClick", OnShowIconChanged)
    ilvlCheckbox:SetScript("OnClick", OnIlvlChanged)
    debugCheckbox:SetScript("OnClick", OnDebugChanged)

    -- Set the refresh function
    panel.refresh = RefreshPanel
    panel:SetScript("OnShow", RefreshPanel)


    -- Add the panel to the Interface Options
    InterfaceOptions_AddCategory(panel)

    -- Slash command to open the options
    SLASH_SpecTip1 = "/stip"
    SlashCmdList["SpecTip"] = function(msg)
        if msg == "cleanup" then
            AiL.cleanupStaleCache()
            _print("SpecTip: Cache cleanup completed.")
        else
            InterfaceOptionsFrame_OpenToCategory(addonName)
        end
    end 

end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

initFrame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name ~= addonName then
        return
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        AiL.cleanupStaleCache()
    elseif event == "ADDON_LOADED" then
        SpecTipOptions = SpecTipOptions or {}
        for key, value in pairs(defaults) do
            if SpecTipOptions[key] == nil then
                SpecTipOptions[key] = value
            end
        end
        AiL.Options = SpecTipOptions
        createSettingsPanel()
    end
end)