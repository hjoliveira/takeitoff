-- Mock WoW API for testing
-- This file simulates the WoW environment for unit testing

local WoWMock = {}

-- Storage for mock data
WoWMock.equippedItems = {}
WoWMock.frames = {}
WoWMock.events = {}
WoWMock.slashCommands = {}

-- Reset all mock state
function WoWMock.reset()
    WoWMock.equippedItems = {}
    WoWMock.frames = {}
    WoWMock.events = {}
    WoWMock.slashCommands = {}
    WoWMock.printOutput = {}
    _G.TakeItOffDB = nil
    _G.SlashCmdList = {}
    _G.SLASH_TAKEITOFF1 = nil
    _G.SLASH_TAKEITOFF2 = nil
end

-- Mock frame object
local function createMockFrame(frameType, name, parent)
    local frame = {
        _name = name,
        _shown = false,
        _scripts = {},
        _events = {},
        _children = {},
        _points = {},
        _size = { width = 0, height = 0 },
        _strata = "MEDIUM",
    }

    function frame:SetSize(w, h)
        self._size = { width = w, height = h }
    end

    function frame:SetPoint(...)
        table.insert(self._points, {...})
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

        table.insert(frame._children, fontString)
        return fontString
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
        return createMockFrame(frameType, name, parent)
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
        GetItemLink = function(itemID)
            -- Return a simulated item link format
            return "|cffffffff|Hitem:" .. tostring(itemID) .. "::::::::::::|h[Test Item " .. tostring(itemID) .. "]|h|r"
        end
    }

    -- Print function (capture output)
    WoWMock.printOutput = {}
    _G.print = function(...)
        local args = {...}
        local str = table.concat(args, " ")
        table.insert(WoWMock.printOutput, str)
    end

    -- Slash command infrastructure
    _G.SlashCmdList = {}
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

return WoWMock
