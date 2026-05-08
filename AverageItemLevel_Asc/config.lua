-- Config.lua for AverageItemLevel addon
-- Handles the addon settings panel for WoW 3.3.5



AiL = select(2, ...)
-- Set default options if not already set
if not AiL then return end

local addonName = "AverageItemLevel_Asc"

AverageItemLevelOptions = AverageItemLevelOptions or {}

local defaults = {
    ShowIcon = true,
    Ilvl = true,
    Debug = false,
}

local initFrame = CreateFrame("Frame")



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
    SLASH_AVERAGEITEMLEVEL1 = "/ail"
    SLASH_AVERAGEITEMLEVEL2 = "/averageitemlevel"
    SlashCmdList["AVERAGEITEMLEVEL"] = function()
        InterfaceOptionsFrame_OpenToCategory(addonName)
    end 

end

initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then
        return
    end

    AverageItemLevelOptions = AverageItemLevelOptions or {}
    for key, value in pairs(defaults) do
        if AverageItemLevelOptions[key] == nil then
            AverageItemLevelOptions[key] = value
        end
    end
    AiL.Options = AverageItemLevelOptions
    createSettingsPanel()
end)