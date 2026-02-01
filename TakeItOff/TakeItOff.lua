-- TakeItOff Addon
-- Alerts you when specific items are equipped

local addonName, addon = ...

-- Expose addon namespace globally for settings panel
TakeItOffAddon = addon

-- Default database
local defaults = {
    itemIDs = {},  -- List of item IDs to watch for
    warningText = "TAKE IT OFF",  -- Customizable warning text
}

-- Get a clickable item link, falling back to item name if unavailable
-- Exposed via addon namespace for settings panel
local function GetItemLinkOrName(itemID)
    -- Try to get the full item link (clickable) using GetItemInfo
    -- GetItemInfo returns: itemName, itemLink, itemQuality, ...
    local itemName, itemLink = GetItemInfo(itemID)
    if itemLink then
        return itemLink
    end

    -- Fall back to item name if link isn't available yet (item not cached)
    if itemName then
        return itemName
    end

    return "Unknown Item"
end

-- Equipment slot IDs
local EQUIPMENT_SLOTS = {
    1,  -- Head
    2,  -- Neck
    3,  -- Shoulder
    4,  -- Shirt
    5,  -- Chest
    6,  -- Waist
    7,  -- Legs
    8,  -- Feet
    9,  -- Wrist
    10, -- Hands
    11, -- Finger 1
    12, -- Finger 2
    13, -- Trinket 1
    14, -- Trinket 2
    15, -- Back
    16, -- Main Hand
    17, -- Off Hand
    19, -- Tabard
}

-- Create the warning frame
local warningFrame = CreateFrame("Frame", "TakeItOffWarningFrame", UIParent)
warningFrame:SetSize(400, 60)
warningFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
warningFrame:SetFrameStrata("HIGH")
warningFrame:Hide()

-- Create the warning text
local warningText = warningFrame:CreateFontString(nil, "OVERLAY")
warningText:SetPoint("CENTER", warningFrame, "CENTER", 0, 0)
warningText:SetFont("Fonts\\FRIZQT__.TTF", 48, "OUTLINE")
warningText:SetText("TAKE IT OFF")
warningText:SetTextColor(1, 0, 0, 1)  -- Red color

-- Create the main event frame
local eventFrame = CreateFrame("Frame", "TakeItOffEventFrame", UIParent)

-- Check if any watched items are equipped
local function CheckEquippedItems()
    if not TakeItOffDB or not TakeItOffDB.itemIDs then
        warningFrame:Hide()
        return
    end

    local foundItem = false

    for _, slotID in ipairs(EQUIPMENT_SLOTS) do
        local itemID = GetInventoryItemID("player", slotID)
        if itemID then
            for _, watchedID in ipairs(TakeItOffDB.itemIDs) do
                if itemID == watchedID then
                    foundItem = true
                    break
                end
            end
        end
        if foundItem then break end
    end

    if foundItem then
        warningFrame:Show()
    else
        warningFrame:Hide()
    end
end

-- Update the warning text
local function SetWarningText(text)
    if not text or text == "" then
        text = defaults.warningText
    end
    TakeItOffDB.warningText = text
    warningText:SetText(text)
end

-- Get the current warning text
local function GetWarningText()
    return TakeItOffDB and TakeItOffDB.warningText or defaults.warningText
end

-- Get the default warning text
local function GetDefaultWarningText()
    return defaults.warningText
end

-- Initialize the addon
local function InitializeAddon()
    -- Set up SavedVariables
    if not TakeItOffDB then
        TakeItOffDB = {}
    end
    if not TakeItOffDB.itemIDs then
        TakeItOffDB.itemIDs = {}
    end
    if not TakeItOffDB.warningText then
        TakeItOffDB.warningText = defaults.warningText
    end

    -- Apply saved warning text
    warningText:SetText(TakeItOffDB.warningText)

    -- Initial check
    CheckEquippedItems()

    print("|cffff0000TakeItOff|r loaded. Use /tio help for commands.")
end

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            InitializeAddon()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        CheckEquippedItems()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        CheckEquippedItems()
    end
end)

-- Register events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

-- Expose functions for settings panel
addon.GetItemLinkOrName = GetItemLinkOrName
addon.CheckEquippedItems = CheckEquippedItems
addon.SetWarningText = SetWarningText
addon.GetWarningText = GetWarningText
addon.GetDefaultWarningText = GetDefaultWarningText

-- Slash commands
SLASH_TAKEITOFF1 = "/takeitoff"
SLASH_TAKEITOFF2 = "/tio"

SlashCmdList["TAKEITOFF"] = function(msg)
    local command, arg = msg:match("^(%S+)%s*(.*)$")
    command = command and command:lower() or ""

    if command == "add" then
        local itemID = tonumber(arg)
        if itemID then
            -- Check if already in list
            for _, id in ipairs(TakeItOffDB.itemIDs) do
                if id == itemID then
                    print("|cffff0000TakeItOff:|r Item ID " .. itemID .. " is already in the list.")
                    return
                end
            end
            table.insert(TakeItOffDB.itemIDs, itemID)
            local itemLink = GetItemLinkOrName(itemID)
            print("|cffff0000TakeItOff:|r Added item: " .. itemLink)
            CheckEquippedItems()
        else
            print("|cffff0000TakeItOff:|r Invalid item ID. Usage: /tio add <itemID>")
        end

    elseif command == "remove" then
        local itemID = tonumber(arg)
        if itemID then
            for i, id in ipairs(TakeItOffDB.itemIDs) do
                if id == itemID then
                    table.remove(TakeItOffDB.itemIDs, i)
                    local itemLink = GetItemLinkOrName(itemID)
                    print("|cffff0000TakeItOff:|r Removed item: " .. itemLink)
                    CheckEquippedItems()
                    return
                end
            end
            print("|cffff0000TakeItOff:|r Item ID " .. itemID .. " was not in the list.")
        else
            print("|cffff0000TakeItOff:|r Invalid item ID. Usage: /tio remove <itemID>")
        end

    elseif command == "list" then
        if #TakeItOffDB.itemIDs == 0 then
            print("|cffff0000TakeItOff:|r No items in the watch list.")
        else
            print("|cffff0000TakeItOff:|r Watched items:")
            for _, itemID in ipairs(TakeItOffDB.itemIDs) do
                local itemLink = GetItemLinkOrName(itemID)
                print("  - " .. itemLink)
            end
        end

    elseif command == "clear" then
        TakeItOffDB.itemIDs = {}
        print("|cffff0000TakeItOff:|r Cleared all items from the watch list.")
        CheckEquippedItems()

    elseif command == "debug" then
        -- Show equipped items for debugging and toggle warning display
        print("|cffff0000TakeItOff:|r Debug - Equipped items:")
        for _, slotID in ipairs(EQUIPMENT_SLOTS) do
            local itemID = GetInventoryItemID("player", slotID)
            if itemID then
                local itemLink = GetItemLinkOrName(itemID)
                print("  Slot " .. slotID .. ": " .. itemLink)
            end
        end
        print("|cffff0000TakeItOff:|r Debug - Watched items:")
        for i, watchedID in ipairs(TakeItOffDB.itemIDs) do
            print("  [" .. i .. "] ID: " .. watchedID .. " (type: " .. type(watchedID) .. ")")
        end
        -- Toggle the warning display for testing
        if warningFrame:IsShown() then
            warningFrame:Hide()
            print("|cffff0000TakeItOff:|r Test warning hidden.")
        else
            warningFrame:Show()
            print("|cffff0000TakeItOff:|r Test warning shown.")
        end

    elseif command == "options" then
        -- Open the settings panel
        if addon.OpenSettings then
            addon.OpenSettings()
        else
            print("|cffff0000TakeItOff:|r Settings panel not available.")
        end

    elseif command == "text" then
        -- Set custom warning text
        if arg and arg ~= "" then
            SetWarningText(arg)
            print("|cffff0000TakeItOff:|r Warning text set to: " .. arg)
        else
            print("|cffff0000TakeItOff:|r Current warning text: " .. GetWarningText())
            print("|cffff0000TakeItOff:|r Usage: /tio text <your custom text>")
        end

    elseif command == "resettext" then
        -- Reset warning text to default
        SetWarningText(defaults.warningText)
        print("|cffff0000TakeItOff:|r Warning text reset to default: " .. defaults.warningText)

    else
        print("|cffff0000TakeItOff|r Commands:")
        print("  /tio add <itemID> - Add an item to watch")
        print("  /tio remove <itemID> - Remove an item from watch")
        print("  /tio list - Show all watched items")
        print("  /tio clear - Clear all watched items")
        print("  /tio options - Open settings panel")
        print("  /tio text <text> - Set custom warning text")
        print("  /tio resettext - Reset warning text to default")
        print("  /tio debug - Show debug info and toggle test warning")
        print("  /tio help - Show this help message")
    end
end
