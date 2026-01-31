-- Unit tests for TakeItOff addon
-- Run with: busted tests/TakeItOff_spec.lua

local WoWMock = require("tests.wow_api_mock")

-- Helper to load the addon
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

    describe("Test command", function()

        it("should toggle warning frame visibility", function()
            loadAddon()
            local frame = WoWMock.getWarningFrame()
            assert.is_false(frame:IsShown())

            WoWMock.runSlashCommand("test")
            assert.is_true(frame:IsShown())

            WoWMock.runSlashCommand("test")
            assert.is_false(frame:IsShown())
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

end)
