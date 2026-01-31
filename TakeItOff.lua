-- TakeItOff Addon
-- Alerts you when specific items are equipped

local addonName, addon = ...

-- Default database
local defaults = {
    itemIDs = {},  -- List of item IDs to watch for
}

-- Equipment slot IDs (1-19)
local EQUIPMENT_SLOTS = {
    INVSLOT_HEAD,           -- 1
    INVSLOT_NECK,           -- 2
    INVSLOT_SHOULDER,       -- 3
    INVSLOT_BODY,           -- 4 (shirt)
    INVSLOT_CHEST,          -- 5
    INVSLOT_WAIST,          -- 6
    INVSLOT_LEGS,           -- 7
    INVSLOT_FEET,           -- 8
    INVSLOT_WRIST,          -- 9
    INVSLOT_HAND,           -- 10
    INVSLOT_FINGER1,        -- 11
    INVSLOT_FINGER2,        -- 12
    INVSLOT_TRINKET1,       -- 13
    INVSLOT_TRINKET2,       -- 14
    INVSLOT_BACK,           -- 15
    INVSLOT_MAINHAND,       -- 16
    INVSLOT_OFFHAND,        -- 17
    INVSLOT_RANGED,         -- 18
    INVSLOT_TABARD,         -- 19
}

-- Create the warning frame
local warningFrame = CreateFrame("Frame", "TakeItOffWarningFrame", UIParent)
warningFrame:SetSize(400, 60)
warningFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
warningFrame:SetFrameStrata("HIGH")
warningFrame:Hide()

-- Create the warning text
local warningText = warningFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
warningText:SetPoint("CENTER", warningFrame, "CENTER", 0, 0)
warningText:SetText("TAKE IT OFF")
warningText:SetTextColor(1, 0, 0, 1)  -- Red color
warningText:SetFont(warningText:GetFont(), 48, "OUTLINE")

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

-- Initialize the addon
local function InitializeAddon()
    -- Set up SavedVariables
    if not TakeItOffDB then
        TakeItOffDB = {}
    end
    if not TakeItOffDB.itemIDs then
        TakeItOffDB.itemIDs = {}
    end

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
            local itemName = C_Item.GetItemNameByID(itemID) or "Unknown"
            print("|cffff0000TakeItOff:|r Added item: " .. itemName .. " (ID: " .. itemID .. ")")
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
                    local itemName = C_Item.GetItemNameByID(itemID) or "Unknown"
                    print("|cffff0000TakeItOff:|r Removed item: " .. itemName .. " (ID: " .. itemID .. ")")
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
                local itemName = C_Item.GetItemNameByID(itemID) or "Unknown"
                print("  - " .. itemName .. " (ID: " .. itemID .. ")")
            end
        end

    elseif command == "clear" then
        TakeItOffDB.itemIDs = {}
        print("|cffff0000TakeItOff:|r Cleared all items from the watch list.")
        CheckEquippedItems()

    elseif command == "test" then
        -- Toggle the warning display for testing
        if warningFrame:IsShown() then
            warningFrame:Hide()
            print("|cffff0000TakeItOff:|r Test warning hidden.")
        else
            warningFrame:Show()
            print("|cffff0000TakeItOff:|r Test warning shown.")
        end

    else
        print("|cffff0000TakeItOff|r Commands:")
        print("  /tio add <itemID> - Add an item to watch")
        print("  /tio remove <itemID> - Remove an item from watch")
        print("  /tio list - Show all watched items")
        print("  /tio clear - Clear all watched items")
        print("  /tio test - Toggle test warning display")
        print("  /tio help - Show this help message")
    end
end
