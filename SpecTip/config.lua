-- Config.lua for SpecTip addon
-- Handles the addon settings panel for WoW 3.3.5



AiL = select(2, ...)

if not AiL then return end
AiL.Config = AiL.Config or {}


local addonName = "SpecTip"
SpecTipOptions = SpecTipOptions or {}
local defaults = {
    ShowIcon = true,
    Ilvl = true,
    Debug = false,
    DebugLevel = 0,
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

    -- Debug level dropdown
    local debugLevelDropdown = CreateFrame("Frame", addonName .. "DebugLevelDropdown", panel, "UIDropDownMenuTemplate")
    debugLevelDropdown:SetPoint("LEFT", debugCheckbox.Text, "RIGHT", 10, -2)
    UIDropDownMenu_SetWidth(debugLevelDropdown, 90)

    local function OnDebugLevelSelected(self, arg1)
        AiL.Options.DebugLevel = arg1
        UIDropDownMenu_SetSelectedValue(debugLevelDropdown, arg1)
        UIDropDownMenu_SetText(debugLevelDropdown, arg1 == 2 and "Errors Only" or (arg1 == 1 and "Warnings/Errors" or "All"))
    end

    UIDropDownMenu_Initialize(debugLevelDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.text = "All"
        info.arg1 = 0
        info.func = OnDebugLevelSelected
        info.value = 0
        info.checked = (AiL.Options.DebugLevel or 0) == 0
        UIDropDownMenu_AddButton(info, level)

        info.text = "Warnings/Errors"
        info.arg1 = 1
        info.func = OnDebugLevelSelected
        info.value = 1
        info.checked = (AiL.Options.DebugLevel or 0) == 1
        UIDropDownMenu_AddButton(info, level)

        info.text = "Errors Only"
        info.arg1 = 2
        info.func = OnDebugLevelSelected
        info.value = 2
        info.checked = (AiL.Options.DebugLevel or 0) == 2
        UIDropDownMenu_AddButton(info, level)
    end)

    -- Function to refresh the panel
    local function RefreshPanel()
        showIconCheckbox:SetChecked(AiL.Options.ShowIcon)
        ilvlCheckbox:SetChecked(AiL.Options.Ilvl)
        debugCheckbox:SetChecked(AiL.Options.Debug)

        local currentLevel = AiL.Options.DebugLevel or 0
        UIDropDownMenu_SetSelectedValue(debugLevelDropdown, currentLevel)
        UIDropDownMenu_SetText(debugLevelDropdown, currentLevel == 2 and "Errors Only" or (currentLevel == 1 and "Warnings/Errors" or "All"))

        if AiL.Options.Debug then
            UIDropDownMenu_EnableDropDown(debugLevelDropdown)
        else
            UIDropDownMenu_DisableDropDown(debugLevelDropdown)
        end
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
        if AiL.Options.Debug then
            UIDropDownMenu_EnableDropDown(debugLevelDropdown)
        else
            UIDropDownMenu_DisableDropDown(debugLevelDropdown)
        end
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
        InterfaceOptionsFrame_OpenToCategory(addonName)
    end 

end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")

initFrame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
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