-- Mock WoW API for testing
-- This file simulates the WoW environment for unit testing

local WoWMock = {}

-- Storage for mock data
WoWMock.equippedItems = {}
WoWMock.frames = {}
WoWMock.events = {}
WoWMock.slashCommands = {}
WoWMock.itemLinkAvailable = true  -- Controls whether GetItemLink returns a link or nil
WoWMock.itemInfoAvailable = true  -- Controls whether GetItemInfo returns any data at all
WoWMock.cursorInfo = nil  -- For drag-and-drop testing
WoWMock.settingsCategories = {}  -- For settings API testing
WoWMock.timerCallbacks = {}  -- For C_Timer.After callbacks

-- Reset all mock state
function WoWMock.reset()
    WoWMock.equippedItems = {}
    WoWMock.frames = {}
    WoWMock.events = {}
    WoWMock.slashCommands = {}
    WoWMock.printOutput = {}
    WoWMock.itemLinkAvailable = true
    WoWMock.itemInfoAvailable = true
    WoWMock.cursorInfo = nil
    WoWMock.settingsCategories = {}
    WoWMock.timerCallbacks = {}
    _G.TakeItOffDB = nil
    _G.TakeItOffAddon = nil
    _G.SlashCmdList = {}
    _G.SLASH_TAKEITOFF1 = nil
    _G.SLASH_TAKEITOFF2 = nil
end

-- Mock frame object
local function createMockFrame(frameType, name, parent, template)
    local frame = {
        _name = name,
        _shown = false,
        _scripts = {},
        _events = {},
        _children = {},
        _points = {},
        _size = { width = 0, height = 0 },
        _strata = "MEDIUM",
        _backdrop = nil,
        _backdropColor = nil,
        _backdropBorderColor = nil,
        _parent = parent,
        _template = template,
        name = name,  -- For settings panel compatibility
    }

    function frame:SetSize(w, h)
        self._size = { width = w, height = h }
    end

    function frame:SetPoint(...)
        table.insert(self._points, {...})
    end

    function frame:SetAllPoints(relativeTo)
        -- Mock implementation - sets all points to match parent or specified frame
    end

    function frame:SetFrameStrata(strata)
        self._strata = strata
    end

    function frame:Show()
        self._shown = true
    end

    function frame:Hide()
        self._shown = false
    end

    function frame:IsShown()
        return self._shown
    end

    function frame:SetScript(scriptType, handler)
        self._scripts[scriptType] = handler
    end

    function frame:GetScript(scriptType)
        return self._scripts[scriptType]
    end

    function frame:RegisterEvent(event)
        self._events[event] = true
        if not WoWMock.events[event] then
            WoWMock.events[event] = {}
        end
        table.insert(WoWMock.events[event], frame)
    end

    function frame:UnregisterEvent(event)
        self._events[event] = nil
    end

    function frame:CreateFontString(name, layer, template)
        local fontString = {
            _text = "",
            _color = { r = 1, g = 1, b = 1, a = 1 },
            _font = { path = "", size = 12, flags = "" },
            _points = {},
            _width = nil,
            _justifyH = "CENTER",
        }

        function fontString:SetPoint(...)
            table.insert(self._points, {...})
        end

        function fontString:SetText(text)
            self._text = text
        end

        function fontString:GetText()
            return self._text
        end

        function fontString:SetTextColor(r, g, b, a)
            self._color = { r = r, g = g, b = b, a = a or 1 }
        end

        function fontString:SetFont(path, size, flags)
            self._font = { path = path, size = size, flags = flags or "" }
        end

        function fontString:GetFont()
            return self._font.path, self._font.size, self._font.flags
        end

        function fontString:SetWidth(width)
            self._width = width
        end

        function fontString:SetJustifyH(justify)
            self._justifyH = justify
        end

        table.insert(frame._children, fontString)
        return fontString
    end

    function frame:CreateTexture(name, layer)
        local texture = {
            _texture = nil,
            _color = nil,
            _points = {},
            _size = { width = 0, height = 0 },
        }

        function texture:SetAllPoints()
            -- Mock implementation
        end

        function texture:SetPoint(...)
            table.insert(self._points, {...})
        end

        function texture:SetSize(w, h)
            self._size = { width = w, height = h }
        end

        function texture:SetTexture(tex)
            self._texture = tex
        end

        function texture:SetColorTexture(r, g, b, a)
            self._color = { r = r, g = g, b = b, a = a or 1 }
        end

        table.insert(frame._children, texture)
        return texture
    end

    function frame:SetBackdrop(backdrop)
        self._backdrop = backdrop
    end

    function frame:SetBackdropColor(r, g, b, a)
        self._backdropColor = { r = r, g = g, b = b, a = a or 1 }
    end

    function frame:SetBackdropBorderColor(r, g, b, a)
        self._backdropBorderColor = { r = r, g = g, b = b, a = a or 1 }
    end

    function frame:SetScrollChild(child)
        self._scrollChild = child
    end

    function frame:SetHeight(h)
        self._size.height = h
    end

    function frame:SetWidth(w)
        self._size.width = w
    end

    function frame:SetText(text)
        self._text = text
    end

    function frame:GetText()
        return self._text or ""
    end

    -- EditBox specific methods
    function frame:SetFontObject(fontObject)
        self._fontObject = fontObject
    end

    function frame:SetAutoFocus(autoFocus)
        self._autoFocus = autoFocus
    end

    function frame:SetMaxLetters(maxLetters)
        self._maxLetters = maxLetters
    end

    function frame:ClearFocus()
        self._hasFocus = false
    end

    function frame:SetFocus()
        self._hasFocus = true
    end

    function frame:HasFocus()
        return self._hasFocus or false
    end

    if name then
        WoWMock.frames[name] = frame
    end

    return frame
end

-- Install global WoW API mocks
function WoWMock.install()
    -- Global frame parent
    _G.UIParent = createMockFrame("Frame", "UIParent", nil)

    -- CreateFrame
    _G.CreateFrame = function(frameType, name, parent, template)
        return createMockFrame(frameType, name, parent, template)
    end

    -- GetInventoryItemID
    _G.GetInventoryItemID = function(unit, slotID)
        if unit == "player" then
            return WoWMock.equippedItems[slotID]
        end
        return nil
    end

    -- C_Item API
    _G.C_Item = {
        GetItemNameByID = function(itemID)
            return "Test Item " .. tostring(itemID)
        end,
        GetItemLink = function(itemLocation)
            -- Note: C_Item.GetItemLink takes ItemLocation, not itemID
            -- This is here for backwards compatibility in mocks
            return nil
        end
    }

    -- GetItemInfo - returns item name, link, and other info for an item ID
    _G.GetItemInfo = function(itemID)
        -- Return nil for both if item info is not available (simulates completely uncached item)
        if not WoWMock.itemInfoAvailable then
            return nil, nil
        end
        local itemName = "Test Item " .. tostring(itemID)
        -- Return nil for link if item link is not available (simulates partially cached item)
        if not WoWMock.itemLinkAvailable then
            return itemName, nil
        end
        -- Return a simulated item link format
        local itemLink = "|cffffffff|Hitem:" .. tostring(itemID) .. "::::::::::::|h[" .. itemName .. "]|h|r"
        -- Return more complete item info (10 return values for testing)
        local itemTexture = "Interface\\Icons\\INV_Misc_Gear_01"
        return itemName, itemLink, 1, 1, 1, "Armor", "Cloth", 1, "", itemTexture
    end

    -- Print function (capture output)
    WoWMock.printOutput = {}
    _G.print = function(...)
        local args = {...}
        local str = table.concat(args, " ")
        table.insert(WoWMock.printOutput, str)
    end

    -- Slash command infrastructure
    _G.SlashCmdList = {}

    -- C_Timer API for delayed callbacks
    _G.C_Timer = {
        After = function(delay, callback)
            table.insert(WoWMock.timerCallbacks, callback)
            -- Execute immediately in tests for simplicity
            callback()
        end
    }

    -- Cursor functions for drag-and-drop
    _G.GetCursorInfo = function()
        if WoWMock.cursorInfo then
            return WoWMock.cursorInfo.infoType, WoWMock.cursorInfo.itemID, WoWMock.cursorInfo.itemLink
        end
        return nil
    end

    _G.ClearCursor = function()
        WoWMock.cursorInfo = nil
    end

    -- Settings API (Dragonflight+)
    _G.Settings = {
        RegisterCanvasLayoutCategory = function(panel, name)
            local category = {
                _panel = panel,
                _name = name,
                _id = #WoWMock.settingsCategories + 1,
                GetID = function(self)
                    return self._id
                end
            }
            table.insert(WoWMock.settingsCategories, category)
            return category
        end,
        RegisterAddOnCategory = function(category)
            -- Mock implementation - category is already registered
        end,
        OpenToCategory = function(categoryID)
            -- Mock implementation - would open settings to category
        end
    }

    -- InterfaceOptions fallback (pre-Dragonflight)
    _G.InterfaceOptions_AddCategory = function(panel)
        -- Mock implementation
    end

    _G.InterfaceOptionsFrame_OpenToCategory = function(panel)
        -- Mock implementation
    end

    -- Font objects for EditBox
    _G.GameFontHighlight = {}
    _G.GameFontNormal = {}
    _G.GameFontNormalLarge = {}
    _G.GameFontHighlightSmall = {}
end

-- Helper to equip an item in a slot
function WoWMock.equipItem(slotID, itemID)
    WoWMock.equippedItems[slotID] = itemID
end

-- Helper to unequip an item from a slot
function WoWMock.unequipItem(slotID)
    WoWMock.equippedItems[slotID] = nil
end

-- Helper to fire an event
function WoWMock.fireEvent(event, ...)
    local frames = WoWMock.events[event]
    if frames then
        for _, frame in ipairs(frames) do
            local handler = frame:GetScript("OnEvent")
            if handler then
                handler(frame, event, ...)
            end
        end
    end
end

-- Helper to get the warning frame
function WoWMock.getWarningFrame()
    return WoWMock.frames["TakeItOffWarningFrame"]
end

-- Helper to run a slash command
function WoWMock.runSlashCommand(msg)
    if SlashCmdList["TAKEITOFF"] then
        SlashCmdList["TAKEITOFF"](msg)
    end
end

-- Helper to clear print output
function WoWMock.clearPrintOutput()
    WoWMock.printOutput = {}
end

-- Helper to set whether item links are available (simulates cached/uncached items)
function WoWMock.setItemLinkAvailable(available)
    WoWMock.itemLinkAvailable = available
end

-- Helper to set whether item info is available at all (simulates completely uncached items)
function WoWMock.setItemInfoAvailable(available)
    WoWMock.itemInfoAvailable = available
end

-- Helper to set cursor info for drag-and-drop testing
function WoWMock.setCursorItem(itemID, itemLink)
    WoWMock.cursorInfo = {
        infoType = "item",
        itemID = itemID,
        itemLink = itemLink or ("|cffffffff|Hitem:" .. itemID .. "::::::::::::|h[Test Item " .. itemID .. "]|h|r")
    }
end

-- Helper to clear cursor
function WoWMock.clearCursor()
    WoWMock.cursorInfo = nil
end

-- Helper to get the settings panel
function WoWMock.getSettingsPanel()
    return WoWMock.frames["TakeItOffSettingsPanel"]
end

-- Helper to get registered settings categories
function WoWMock.getSettingsCategories()
    return WoWMock.settingsCategories
end

return WoWMock
