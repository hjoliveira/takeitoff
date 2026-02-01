-- Unit tests for TakeItOff addon
-- Run with: busted tests/TakeItOff_spec.lua

local WoWMock = require("tests.wow_api_mock")

-- Helper to load the addon (main file only)
local function loadAddon()
    -- Set up the addon loading environment
    local addonName = "TakeItOff"
    local addonTable = {}

    -- Load the addon file with the varargs WoW provides
    local chunk, err = loadfile("TakeItOff/TakeItOff.lua")
    if not chunk then
        error("Failed to load addon: " .. tostring(err))
    end

    -- Execute directly in _G (like WoW does)
    chunk(addonName, addonTable)

    -- Fire ADDON_LOADED event to initialize
    WoWMock.fireEvent("ADDON_LOADED", addonName)

    return addonTable
end

-- Helper to load the addon with settings
local function loadAddonWithSettings()
    local addonName = "TakeItOff"
    local addonTable = {}

    -- Load the main addon file
    local mainChunk, mainErr = loadfile("TakeItOff/TakeItOff.lua")
    if not mainChunk then
        error("Failed to load main addon: " .. tostring(mainErr))
    end
    mainChunk(addonName, addonTable)

    -- Load the settings file
    local settingsChunk, settingsErr = loadfile("TakeItOff/Settings.lua")
    if not settingsChunk then
        error("Failed to load settings: " .. tostring(settingsErr))
    end
    settingsChunk(addonName, addonTable)

    -- Fire ADDON_LOADED event to initialize both
    WoWMock.fireEvent("ADDON_LOADED", addonName)

    return addonTable
end

describe("TakeItOff Addon", function()

    before_each(function()
        -- Reset mock state before each test
        WoWMock.reset()
        WoWMock.install()
    end)

    describe("Initialization", function()

        it("should create the warning frame", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()
            assert.is_not_nil(frame)
        end)

        it("should hide warning frame on load", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()
            assert.is_false(frame:IsShown())
        end)

        it("should initialize empty database", function()
            loadAddon()
            assert.is_not_nil(TakeItOffDB)
            assert.is_not_nil(TakeItOffDB.itemIDs)
            assert.are.equal(0, #TakeItOffDB.itemIDs)
        end)

        it("should register slash commands", function()
            loadAddon()
            assert.is_not_nil(SlashCmdList["TAKEITOFF"])
        end)

        it("should print loaded message", function()
            loadAddon()
            local found = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("TakeItOff") and msg:find("loaded") then
                    found = true
                    break
                end
            end
            assert.is_true(found)
        end)

    end)

    describe("Add command", function()

        it("should add item ID to watch list", function()
            loadAddon()
            WoWMock.runSlashCommand("add 12345")
            assert.are.equal(1, #TakeItOffDB.itemIDs)
            assert.are.equal(12345, TakeItOffDB.itemIDs[1])
        end)

        it("should not add duplicate item IDs", function()
            loadAddon()
            WoWMock.runSlashCommand("add 12345")
            WoWMock.runSlashCommand("add 12345")
            assert.are.equal(1, #TakeItOffDB.itemIDs)
        end)

        it("should add multiple different items", function()
            loadAddon()
            WoWMock.runSlashCommand("add 12345")
            WoWMock.runSlashCommand("add 67890")
            assert.are.equal(2, #TakeItOffDB.itemIDs)
        end)

        it("should reject invalid item IDs", function()
            loadAddon()
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("add notanumber")
            assert.are.equal(0, #TakeItOffDB.itemIDs)
            local foundError = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("Invalid") then
                    foundError = true
                    break
                end
            end
            assert.is_true(foundError)
        end)

    end)

    describe("Remove command", function()

        it("should remove item ID from watch list", function()
            loadAddon()
            WoWMock.runSlashCommand("add 12345")
            WoWMock.runSlashCommand("remove 12345")
            assert.are.equal(0, #TakeItOffDB.itemIDs)
        end)

        it("should handle removing non-existent item", function()
            loadAddon()
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("remove 99999")
            local foundMessage = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("was not in the list") then
                    foundMessage = true
                    break
                end
            end
            assert.is_true(foundMessage)
        end)

    end)

    describe("List command", function()

        it("should show empty list message", function()
            loadAddon()
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("list")
            local foundMessage = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("No items") then
                    foundMessage = true
                    break
                end
            end
            assert.is_true(foundMessage)
        end)

        it("should list watched items", function()
            loadAddon()
            WoWMock.runSlashCommand("add 12345")
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("list")
            local foundItem = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("12345") then
                    foundItem = true
                    break
                end
            end
            assert.is_true(foundItem)
        end)

    end)

    describe("Clear command", function()

        it("should clear all items from watch list", function()
            loadAddon()
            WoWMock.runSlashCommand("add 12345")
            WoWMock.runSlashCommand("add 67890")
            WoWMock.runSlashCommand("clear")
            assert.are.equal(0, #TakeItOffDB.itemIDs)
        end)

    end)

    describe("Debug command", function()

        it("should toggle warning frame visibility", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()
            assert.is_false(frame:IsShown())

            WoWMock.runSlashCommand("debug")
            assert.is_true(frame:IsShown())

            WoWMock.runSlashCommand("debug")
            assert.is_false(frame:IsShown())
        end)

        it("should show equipped items info", function()
            loadAddon()
            WoWMock.equipItem(15, 19019)
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("debug")
            local foundEquipped = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("Equipped items") then
                    foundEquipped = true
                    break
                end
            end
            assert.is_true(foundEquipped)
        end)

        it("should show watched items info", function()
            loadAddon()
            WoWMock.runSlashCommand("add 12345")
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("debug")
            local foundWatched = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("Watched items") then
                    foundWatched = true
                    break
                end
            end
            assert.is_true(foundWatched)
        end)

    end)

    describe("Equipment detection", function()

        it("should show warning when watched item is equipped", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()

            -- Add item to watch list
            WoWMock.runSlashCommand("add 12345")
            assert.is_false(frame:IsShown())

            -- Equip the item (slot 15 = back/cloak)
            WoWMock.equipItem(15, 12345)
            WoWMock.fireEvent("PLAYER_EQUIPMENT_CHANGED", 15, false)

            assert.is_true(frame:IsShown())
        end)

        it("should hide warning when watched item is unequipped", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()

            -- Add and equip item
            WoWMock.runSlashCommand("add 12345")
            WoWMock.equipItem(15, 12345)
            WoWMock.fireEvent("PLAYER_EQUIPMENT_CHANGED", 15, false)
            assert.is_true(frame:IsShown())

            -- Unequip the item
            WoWMock.unequipItem(15)
            WoWMock.fireEvent("PLAYER_EQUIPMENT_CHANGED", 15, false)

            assert.is_false(frame:IsShown())
        end)

        it("should not show warning for non-watched items", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()

            -- Add item to watch list
            WoWMock.runSlashCommand("add 12345")

            -- Equip a different item
            WoWMock.equipItem(15, 99999)
            WoWMock.fireEvent("PLAYER_EQUIPMENT_CHANGED", 15, false)

            assert.is_false(frame:IsShown())
        end)

        it("should detect items in any equipment slot", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()

            WoWMock.runSlashCommand("add 12345")

            -- Test head slot (1)
            WoWMock.equipItem(1, 12345)
            WoWMock.fireEvent("PLAYER_EQUIPMENT_CHANGED", 1, false)
            assert.is_true(frame:IsShown())

            WoWMock.unequipItem(1)
            WoWMock.fireEvent("PLAYER_EQUIPMENT_CHANGED", 1, false)
            assert.is_false(frame:IsShown())

            -- Test trinket slot (13)
            WoWMock.equipItem(13, 12345)
            WoWMock.fireEvent("PLAYER_EQUIPMENT_CHANGED", 13, false)
            assert.is_true(frame:IsShown())
        end)

        it("should check equipment on PLAYER_ENTERING_WORLD", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()

            WoWMock.runSlashCommand("add 12345")
            WoWMock.equipItem(15, 12345)

            -- Simulate entering world
            WoWMock.fireEvent("PLAYER_ENTERING_WORLD", false, false)

            assert.is_true(frame:IsShown())
        end)

    end)

    describe("Warning frame", function()

        it("should have red text color", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()
            local fontString = frame._children[1]
            assert.are.equal(1, fontString._color.r)
            assert.are.equal(0, fontString._color.g)
            assert.are.equal(0, fontString._color.b)
        end)

        it("should display 'TAKE IT OFF' text", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()
            local fontString = frame._children[1]
            assert.are.equal("TAKE IT OFF", fontString:GetText())
        end)

        it("should use large font size", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()
            local fontString = frame._children[1]
            local _, size, _ = fontString:GetFont()
            assert.are.equal(48, size)
        end)

    end)

    describe("Item links", function()

        it("should display item link in add command message", function()
            loadAddon()
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("add 19019")
            local foundLink = false
            for _, msg in ipairs(WoWMock.printOutput) do
                -- Check for item link format |Hitem:
                if msg:find("|Hitem:19019") and msg:find("Added item") then
                    foundLink = true
                    break
                end
            end
            assert.is_true(foundLink)
        end)

        it("should display item link in remove command message", function()
            loadAddon()
            WoWMock.runSlashCommand("add 19019")
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("remove 19019")
            local foundLink = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("|Hitem:19019") and msg:find("Removed item") then
                    foundLink = true
                    break
                end
            end
            assert.is_true(foundLink)
        end)

        it("should display item link in list command output", function()
            loadAddon()
            WoWMock.runSlashCommand("add 19019")
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("list")
            local foundLink = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("|Hitem:19019") then
                    foundLink = true
                    break
                end
            end
            assert.is_true(foundLink)
        end)

        it("should display item link in debug command output", function()
            loadAddon()
            -- Equip an item
            WoWMock.equipItem(15, 19019)
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("debug")
            local foundLink = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("|Hitem:19019") and msg:find("Slot") then
                    foundLink = true
                    break
                end
            end
            assert.is_true(foundLink)
        end)

        it("should fall back to item name when link is unavailable", function()
            loadAddon()
            -- Simulate item link not being cached
            WoWMock.setItemLinkAvailable(false)
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("add 19019")
            local foundName = false
            local foundLink = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("Test Item 19019") and msg:find("Added item") then
                    foundName = true
                end
                if msg:find("|Hitem:") then
                    foundLink = true
                end
            end
            assert.is_true(foundName)
            assert.is_false(foundLink)
        end)

        it("should fall back to 'Unknown Item' when item info is completely unavailable", function()
            loadAddon()
            -- Simulate item not being cached at all (GetItemInfo returns nil)
            WoWMock.setItemInfoAvailable(false)
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("add 99999")
            local foundUnknown = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("Unknown Item") and msg:find("Added item") then
                    foundUnknown = true
                    break
                end
            end
            assert.is_true(foundUnknown)
        end)

        it("should use item link format with brackets", function()
            loadAddon()
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("add 12345")
            local foundBrackets = false
            for _, msg in ipairs(WoWMock.printOutput) do
                -- Item links have [Item Name] format
                if msg:find("%[Test Item 12345%]") then
                    foundBrackets = true
                    break
                end
            end
            assert.is_true(foundBrackets)
        end)

    end)

    describe("Addon namespace", function()

        it("should expose addon table globally", function()
            loadAddon()
            assert.is_not_nil(TakeItOffAddon)
        end)

        it("should expose GetItemLinkOrName function", function()
            loadAddon()
            assert.is_not_nil(TakeItOffAddon.GetItemLinkOrName)
            assert.are.equal("function", type(TakeItOffAddon.GetItemLinkOrName))
        end)

        it("should expose CheckEquippedItems function", function()
            loadAddon()
            assert.is_not_nil(TakeItOffAddon.CheckEquippedItems)
            assert.are.equal("function", type(TakeItOffAddon.CheckEquippedItems))
        end)

    end)

    describe("Options slash command", function()

        it("should respond to options command", function()
            local addonTable = loadAddonWithSettings()
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("options")
            -- Should either open settings or print a message (no error)
            -- Since we don't have a full UI, just verify no crash occurred
            assert.is_true(true)
        end)

        it("should show options in help output", function()
            loadAddon()
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("help")
            local foundOptions = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("options") then
                    foundOptions = true
                    break
                end
            end
            assert.is_true(foundOptions)
        end)

    end)

    describe("Settings panel", function()

        it("should create settings panel on load", function()
            loadAddonWithSettings()
            local panel = WoWMock.getSettingsPanel()
            assert.is_not_nil(panel)
        end)

        it("should register with Blizzard settings API", function()
            loadAddonWithSettings()
            local categories = WoWMock.getSettingsCategories()
            assert.is_true(#categories > 0)
        end)

        it("should expose OpenSettings function", function()
            local addonTable = loadAddonWithSettings()
            assert.is_not_nil(addonTable.OpenSettings)
            assert.are.equal("function", type(addonTable.OpenSettings))
        end)

        it("should expose AddItemToWatchList function", function()
            local addonTable = loadAddonWithSettings()
            assert.is_not_nil(addonTable.AddItemToWatchList)
            assert.are.equal("function", type(addonTable.AddItemToWatchList))
        end)

        it("should expose RemoveItemFromWatchList function", function()
            local addonTable = loadAddonWithSettings()
            assert.is_not_nil(addonTable.RemoveItemFromWatchList)
            assert.are.equal("function", type(addonTable.RemoveItemFromWatchList))
        end)

    end)

    describe("Settings watch list management", function()

        it("should add item via AddItemToWatchList", function()
            local addonTable = loadAddonWithSettings()
            local result = addonTable.AddItemToWatchList(12345)
            assert.is_true(result)
            assert.are.equal(1, #TakeItOffDB.itemIDs)
            assert.are.equal(12345, TakeItOffDB.itemIDs[1])
        end)

        it("should not add duplicate items via AddItemToWatchList", function()
            local addonTable = loadAddonWithSettings()
            addonTable.AddItemToWatchList(12345)
            local result = addonTable.AddItemToWatchList(12345)
            assert.is_false(result)
            assert.are.equal(1, #TakeItOffDB.itemIDs)
        end)

        it("should remove item via RemoveItemFromWatchList", function()
            local addonTable = loadAddonWithSettings()
            addonTable.AddItemToWatchList(12345)
            local result = addonTable.RemoveItemFromWatchList(12345)
            assert.is_true(result)
            assert.are.equal(0, #TakeItOffDB.itemIDs)
        end)

        it("should return false when removing non-existent item", function()
            local addonTable = loadAddonWithSettings()
            local result = addonTable.RemoveItemFromWatchList(99999)
            assert.is_false(result)
        end)

        it("should print message when adding item", function()
            local addonTable = loadAddonWithSettings()
            WoWMock.clearPrintOutput()
            addonTable.AddItemToWatchList(12345)
            local foundMessage = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("Added item") then
                    foundMessage = true
                    break
                end
            end
            assert.is_true(foundMessage)
        end)

        it("should print message when removing item", function()
            local addonTable = loadAddonWithSettings()
            addonTable.AddItemToWatchList(12345)
            WoWMock.clearPrintOutput()
            addonTable.RemoveItemFromWatchList(12345)
            local foundMessage = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("Removed item") then
                    foundMessage = true
                    break
                end
            end
            assert.is_true(foundMessage)
        end)

        it("should trigger equipment check when adding item", function()
            local addonTable = loadAddonWithSettings()
            local frame = WoWMock.getWarningFrame()

            -- Equip an item first
            WoWMock.equipItem(15, 12345)

            -- Add to watch list via settings API
            addonTable.AddItemToWatchList(12345)

            -- Warning should be shown
            assert.is_true(frame:IsShown())
        end)

        it("should trigger equipment check when removing item", function()
            local addonTable = loadAddonWithSettings()
            local frame = WoWMock.getWarningFrame()

            -- Add and equip item
            WoWMock.equipItem(15, 12345)
            addonTable.AddItemToWatchList(12345)
            assert.is_true(frame:IsShown())

            -- Remove from watch list
            addonTable.RemoveItemFromWatchList(12345)

            -- Warning should be hidden
            assert.is_false(frame:IsShown())
        end)

    end)

    describe("Drop zone", function()

        it("should create drop zone frame", function()
            loadAddonWithSettings()
            local dropZone = WoWMock.frames["TakeItOffDropZone"]
            assert.is_not_nil(dropZone)
        end)

    end)

    describe("Custom warning text", function()

        it("should initialize with default warning text", function()
            loadAddon()
            assert.is_not_nil(TakeItOffDB.warningText)
            assert.are.equal("TAKE IT OFF", TakeItOffDB.warningText)
        end)

        it("should display default warning text on frame", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()
            local fontString = frame._children[1]
            assert.are.equal("TAKE IT OFF", fontString:GetText())
        end)

        it("should expose SetWarningText function", function()
            loadAddon()
            assert.is_not_nil(TakeItOffAddon.SetWarningText)
            assert.are.equal("function", type(TakeItOffAddon.SetWarningText))
        end)

        it("should expose GetWarningText function", function()
            loadAddon()
            assert.is_not_nil(TakeItOffAddon.GetWarningText)
            assert.are.equal("function", type(TakeItOffAddon.GetWarningText))
        end)

        it("should expose GetDefaultWarningText function", function()
            loadAddon()
            assert.is_not_nil(TakeItOffAddon.GetDefaultWarningText)
            assert.are.equal("function", type(TakeItOffAddon.GetDefaultWarningText))
        end)

        it("should return default text from GetDefaultWarningText", function()
            loadAddon()
            assert.are.equal("TAKE IT OFF", TakeItOffAddon.GetDefaultWarningText())
        end)

        it("should set custom warning text via SetWarningText", function()
            loadAddon()
            TakeItOffAddon.SetWarningText("REMOVE NOW!")
            assert.are.equal("REMOVE NOW!", TakeItOffDB.warningText)
        end)

        it("should update frame text when SetWarningText is called", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()
            local fontString = frame._children[1]
            TakeItOffAddon.SetWarningText("CUSTOM TEXT")
            assert.are.equal("CUSTOM TEXT", fontString:GetText())
        end)

        it("should return custom text from GetWarningText", function()
            loadAddon()
            TakeItOffAddon.SetWarningText("MY TEXT")
            assert.are.equal("MY TEXT", TakeItOffAddon.GetWarningText())
        end)

        it("should reset to default when empty string is passed", function()
            loadAddon()
            TakeItOffAddon.SetWarningText("CUSTOM")
            TakeItOffAddon.SetWarningText("")
            assert.are.equal("TAKE IT OFF", TakeItOffDB.warningText)
        end)

        it("should reset to default when nil is passed", function()
            loadAddon()
            TakeItOffAddon.SetWarningText("CUSTOM")
            TakeItOffAddon.SetWarningText(nil)
            assert.are.equal("TAKE IT OFF", TakeItOffDB.warningText)
        end)

        it("should set warning text via slash command", function()
            loadAddon()
            WoWMock.runSlashCommand("text DANGER!")
            assert.are.equal("DANGER!", TakeItOffDB.warningText)
        end)

        it("should print confirmation when setting text via slash command", function()
            loadAddon()
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("text NEW TEXT")
            local foundMessage = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("Warning text set to") and msg:find("NEW TEXT") then
                    foundMessage = true
                    break
                end
            end
            assert.is_true(foundMessage)
        end)

        it("should show current text when text command has no argument", function()
            loadAddon()
            TakeItOffAddon.SetWarningText("CURRENT TEXT")
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("text")
            local foundCurrent = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("Current warning text") and msg:find("CURRENT TEXT") then
                    foundCurrent = true
                    break
                end
            end
            assert.is_true(foundCurrent)
        end)

        it("should reset text via resettext slash command", function()
            loadAddon()
            TakeItOffAddon.SetWarningText("CUSTOM")
            WoWMock.runSlashCommand("resettext")
            assert.are.equal("TAKE IT OFF", TakeItOffDB.warningText)
        end)

        it("should print confirmation when resetting text", function()
            loadAddon()
            TakeItOffAddon.SetWarningText("CUSTOM")
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("resettext")
            local foundMessage = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("reset to default") and msg:find("TAKE IT OFF") then
                    foundMessage = true
                    break
                end
            end
            assert.is_true(foundMessage)
        end)

        it("should show text command in help output", function()
            loadAddon()
            WoWMock.clearPrintOutput()
            WoWMock.runSlashCommand("help")
            local foundText = false
            local foundResetText = false
            for _, msg in ipairs(WoWMock.printOutput) do
                if msg:find("/tio text") then
                    foundText = true
                end
                if msg:find("/tio resettext") then
                    foundResetText = true
                end
            end
            assert.is_true(foundText)
            assert.is_true(foundResetText)
        end)

        it("should persist custom text between checks", function()
            loadAddon()
            TakeItOffAddon.SetWarningText("PERSISTENT")

            -- Add item and equip it
            WoWMock.runSlashCommand("add 12345")
            WoWMock.equipItem(15, 12345)
            WoWMock.fireEvent("PLAYER_EQUIPMENT_CHANGED", 15, false)

            local frame = WoWMock.getWarningFrame()
            local fontString = frame._children[1]
            -- Text should still be custom after equipment check
            assert.are.equal("PERSISTENT", fontString:GetText())
        end)

    end)

    describe("Warning text settings UI", function()

        it("should create warning text input frame", function()
            loadAddonWithSettings()
            local inputFrame = WoWMock.frames["TakeItOffWarningTextFrame"]
            assert.is_not_nil(inputFrame)
        end)

        it("should create warning text EditBox", function()
            loadAddonWithSettings()
            local editBox = WoWMock.frames["TakeItOffWarningTextInput"]
            assert.is_not_nil(editBox)
        end)

    end)

end)
