-- TakeItOff Settings Panel
-- Provides a settings interface for managing watched items

local addonName, addon = ...

-- Wait for addon to be fully loaded before creating settings
local settingsFrame = CreateFrame("Frame")
settingsFrame:RegisterEvent("ADDON_LOADED")

local function CreateSettingsPanel()
    -- Main settings panel frame
    local panel = CreateFrame("Frame", "TakeItOffSettingsPanel")
    panel.name = "TakeItOff"

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cffff0000Take It Off|r")

    -- Description
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Alerts you when specific items are equipped.")

    -- Warning text label
    local warningTextLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    warningTextLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    warningTextLabel:SetText("Warning Text:")

    -- Warning text input frame (container for EditBox)
    local warningTextFrame = CreateFrame("Frame", "TakeItOffWarningTextFrame", panel, "BackdropTemplate")
    warningTextFrame:SetSize(200, 24)
    warningTextFrame:SetPoint("LEFT", warningTextLabel, "RIGHT", 8, 0)
    warningTextFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    warningTextFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    warningTextFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    -- Warning text EditBox
    local warningTextInput = CreateFrame("EditBox", "TakeItOffWarningTextInput", warningTextFrame)
    warningTextInput:SetSize(190, 20)
    warningTextInput:SetPoint("CENTER", 0, 0)
    warningTextInput:SetFontObject(GameFontHighlight)
    warningTextInput:SetAutoFocus(false)
    warningTextInput:SetMaxLetters(50)

    -- Set initial text after addon loads
    warningTextInput:SetScript("OnShow", function(self)
        if addon.GetWarningText then
            self:SetText(addon.GetWarningText())
        end
    end)

    -- Save on Enter key
    warningTextInput:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        if addon.SetWarningText then
            addon.SetWarningText(text)
            print("|cffff0000TakeItOff:|r Warning text set to: " .. (text ~= "" and text or addon.GetDefaultWarningText()))
        end
        self:ClearFocus()
    end)

    -- Save on focus lost
    warningTextInput:SetScript("OnEditFocusLost", function(self)
        local text = self:GetText()
        if addon.SetWarningText then
            addon.SetWarningText(text)
        end
    end)

    -- Escape key clears focus
    warningTextInput:SetScript("OnEscapePressed", function(self)
        if addon.GetWarningText then
            self:SetText(addon.GetWarningText())
        end
        self:ClearFocus()
    end)

    -- Reset button
    local resetTextBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetTextBtn:SetSize(60, 22)
    resetTextBtn:SetPoint("LEFT", warningTextFrame, "RIGHT", 8, 0)
    resetTextBtn:SetText("Reset")
    resetTextBtn:SetScript("OnClick", function()
        if addon.SetWarningText and addon.GetDefaultWarningText then
            local defaultText = addon.GetDefaultWarningText()
            addon.SetWarningText(defaultText)
            warningTextInput:SetText(defaultText)
            print("|cffff0000TakeItOff:|r Warning text reset to default: " .. defaultText)
        end
    end)

    -- Instructions
    local instructions = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    instructions:SetPoint("TOPLEFT", warningTextLabel, "BOTTOMLEFT", 0, -16)
    instructions:SetText("Drag and drop items here to add them to the watch list:")

    -- Drop zone frame
    local dropZone = CreateFrame("Button", "TakeItOffDropZone", panel)
    dropZone:SetSize(300, 60)
    dropZone:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -8)

    -- Drop zone background
    local dropBg = dropZone:CreateTexture(nil, "BACKGROUND")
    dropBg:SetAllPoints()
    dropBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    -- Drop zone border
    local dropBorder = CreateFrame("Frame", nil, dropZone, "BackdropTemplate")
    dropBorder:SetAllPoints()
    dropBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    dropBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    -- Drop zone text
    local dropText = dropZone:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropText:SetPoint("CENTER")
    dropText:SetText("|cff888888Drop items here|r")

    -- Drop zone hover effect
    dropZone:SetScript("OnEnter", function(self)
        dropBorder:SetBackdropBorderColor(1, 0.8, 0, 1)
        dropText:SetText("|cffffd100Drop items here|r")
    end)

    dropZone:SetScript("OnLeave", function(self)
        dropBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        dropText:SetText("|cff888888Drop items here|r")
    end)

    -- Handle item drops via cursor
    dropZone:SetScript("OnReceiveDrag", function(self)
        local infoType, itemID, itemLink = GetCursorInfo()
        if infoType == "item" then
            ClearCursor()
            addon.AddItemToWatchList(itemID)
        end
    end)

    dropZone:SetScript("OnClick", function(self)
        local infoType, itemID, itemLink = GetCursorInfo()
        if infoType == "item" then
            ClearCursor()
            addon.AddItemToWatchList(itemID)
        end
    end)

    -- Watch list label
    local listLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    listLabel:SetPoint("TOPLEFT", dropZone, "BOTTOMLEFT", 0, -16)
    listLabel:SetText("Watched Items:")

    -- Scroll frame for the item list
    local scrollFrame = CreateFrame("ScrollFrame", "TakeItOffScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(320, 200)
    scrollFrame:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", 0, -8)

    -- Content frame inside scroll
    local scrollChild = CreateFrame("Frame", "TakeItOffScrollChild")
    scrollChild:SetSize(300, 200)
    scrollFrame:SetScrollChild(scrollChild)

    -- Store item row frames for reuse
    local itemRows = {}

    -- Function to refresh the watch list display
    local function RefreshWatchList()
        -- Hide all existing rows
        for _, row in ipairs(itemRows) do
            row:Hide()
        end

        if not TakeItOffDB or not TakeItOffDB.itemIDs then
            return
        end

        local yOffset = 0
        for i, itemID in ipairs(TakeItOffDB.itemIDs) do
            -- Create or reuse a row
            local row = itemRows[i]
            if not row then
                row = CreateFrame("Frame", nil, scrollChild)
                row:SetSize(300, 24)

                -- Item icon
                row.icon = row:CreateTexture(nil, "ARTWORK")
                row.icon:SetSize(20, 20)
                row.icon:SetPoint("LEFT", 4, 0)

                -- Item name/link text
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
                row.text:SetWidth(200)
                row.text:SetJustifyH("LEFT")

                -- Remove button
                row.removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.removeBtn:SetSize(60, 20)
                row.removeBtn:SetPoint("RIGHT", -4, 0)
                row.removeBtn:SetText("Remove")

                -- Hover highlight
                row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
                row.highlight:SetAllPoints()
                row.highlight:SetColorTexture(1, 1, 1, 0.1)

                itemRows[i] = row
            end

            row:SetPoint("TOPLEFT", 0, yOffset)

            -- Get item info
            local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)

            if itemTexture then
                row.icon:SetTexture(itemTexture)
            else
                row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end

            if itemLink then
                row.text:SetText(itemLink)
            elseif itemName then
                row.text:SetText(itemName)
            else
                row.text:SetText("Item ID: " .. itemID)
            end

            -- Store itemID for remove button
            row.itemID = itemID
            row.removeBtn:SetScript("OnClick", function()
                addon.RemoveItemFromWatchList(row.itemID)
            end)

            row:Show()
            yOffset = yOffset - 26
        end

        -- Update scroll child height
        local totalHeight = math.max(200, #TakeItOffDB.itemIDs * 26)
        scrollChild:SetHeight(totalHeight)
    end

    -- Store refresh function for external access
    addon.RefreshSettingsWatchList = RefreshWatchList

    -- Add item function (used by drop zone and can be called externally)
    function addon.AddItemToWatchList(itemID)
        if not TakeItOffDB then TakeItOffDB = {} end
        if not TakeItOffDB.itemIDs then TakeItOffDB.itemIDs = {} end

        -- Check if already in list
        for _, id in ipairs(TakeItOffDB.itemIDs) do
            if id == itemID then
                local itemLink = addon.GetItemLinkOrName(itemID)
                print("|cffff0000TakeItOff:|r Item " .. itemLink .. " is already in the list.")
                return false
            end
        end

        table.insert(TakeItOffDB.itemIDs, itemID)
        local itemLink = addon.GetItemLinkOrName(itemID)
        print("|cffff0000TakeItOff:|r Added item: " .. itemLink)

        if addon.CheckEquippedItems then
            addon.CheckEquippedItems()
        end

        RefreshWatchList()
        return true
    end

    -- Remove item function
    function addon.RemoveItemFromWatchList(itemID)
        if not TakeItOffDB or not TakeItOffDB.itemIDs then return false end

        for i, id in ipairs(TakeItOffDB.itemIDs) do
            if id == itemID then
                table.remove(TakeItOffDB.itemIDs, i)
                local itemLink = addon.GetItemLinkOrName(itemID)
                print("|cffff0000TakeItOff:|r Removed item: " .. itemLink)

                if addon.CheckEquippedItems then
                    addon.CheckEquippedItems()
                end

                RefreshWatchList()
                return true
            end
        end
        return false
    end

    -- Clear all button
    local clearBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    clearBtn:SetSize(100, 24)
    clearBtn:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -8)
    clearBtn:SetText("Clear All")
    clearBtn:SetScript("OnClick", function()
        if TakeItOffDB then
            TakeItOffDB.itemIDs = {}
            print("|cffff0000TakeItOff:|r Cleared all items from the watch list.")
            if addon.CheckEquippedItems then
                addon.CheckEquippedItems()
            end
            RefreshWatchList()
        end
    end)

    -- Refresh when panel is shown
    panel:SetScript("OnShow", function()
        RefreshWatchList()
    end)

    -- Register with Blizzard's addon settings
    -- Using the modern Settings API (Dragonflight+)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        addon.settingsCategory = category
    else
        -- Fallback for older versions using InterfaceOptions
        if InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(panel)
        end
    end

    addon.settingsPanel = panel

    return panel
end

-- Initialize settings after addon loads
settingsFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == addonName then
        -- Delay creation slightly to ensure main addon is fully initialized
        C_Timer.After(0, function()
            CreateSettingsPanel()
        end)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Slash command to open settings
local function OpenSettings()
    if Settings and Settings.OpenToCategory and addon.settingsCategory then
        Settings.OpenToCategory(addon.settingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(addon.settingsPanel)
        InterfaceOptionsFrame_OpenToCategory(addon.settingsPanel) -- Called twice intentionally
    end
end

addon.OpenSettings = OpenSettings
