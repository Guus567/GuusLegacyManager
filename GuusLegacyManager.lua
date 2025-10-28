-- GuusLegacyManager - Character Legacy Command Manager
-- Clean, minimal interface for character selection

-- Initialize saved variables for character storage
GuusLegacyManager_Characters = GuusLegacyManager_Characters or {}

-- Configuration
local config = {
    Debug = false,
    WindowWidth = 580,
    WindowHeight = 450,
    ButtonHeight = 30,
    ButtonWidth = 100,
    NameWidth = 250,
    RoleButtonWidth = 60
}

-- GUI variables
local gui = nil
local characterButtons = {}

-- Function to add current character to saved list
local function AddCurrentCharacter()
    local playerName = UnitName("player")
    local playerRealm = GetRealmName()
    local fullName = playerName .. "-" .. playerRealm
    
    -- Store character info
    GuusLegacyManager_Characters[fullName] = {
        name = playerName,
        realm = playerRealm,
        class = UnitClass("player"), 
        faction = UnitFactionGroup("player"),
        level = UnitLevel("player"),
        lastSeen = date("%Y-%m-%d %H:%M:%S")
    }
    
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("GuusLegacyManager: Added character " .. fullName)
    end
end

-- Function to execute legacy command
local function ExecuteLegacyCommand(characterName, role)
    local command = ".z addlegacy \"" .. characterName .. "\" " .. role
    
    -- Send the command
    SendChatMessage(command, "SAY")
    
    -- Notify user
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager:|r Executed: " .. command)
end

-- Function to get available roles for a class
local function GetAvailableRoles(class)
    local classRoles = {
        ["Warrior"] = {"tank", "mdps"},
        ["Paladin"] = {"tank", "healer", "mdps"},
        ["Hunter"] = {"rdps"},
        ["Rogue"] = {"mdps"},
        ["Priest"] = {"healer", "rdps"},
        ["Shaman"] = {"healer", "mdps", "rdps", "tank"},
        ["Mage"] = {"rdps"},
        ["Warlock"] = {"rdps"},
        ["Druid"] = {"tank", "healer", "mdps", "rdps"}
    }
    
    return classRoles[class] or {"mdps"} -- Default to mdps if class not found
end

-- Function to create character buttons
local function CreateCharacterButtons()
    -- Clear existing buttons
    for i, button in ipairs(characterButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    characterButtons = {}
    
    -- Get sorted character list
    local sortedChars = {}
    for fullName, charData in pairs(GuusLegacyManager_Characters) do
        table.insert(sortedChars, {fullName = fullName, data = charData})
    end
    
    -- Sort by character name
    table.sort(sortedChars, function(a, b)
        return a.data.name < b.data.name
    end)
    
    -- Role definitions
    local allRoles = {
        {name = "Tank", color = {0.2, 0.5, 1.0}, command = "tank"},
        {name = "Heal", color = {0.0, 1.0, 0.0}, command = "healer"},
        {name = "RDPS", color = {1.0, 0.5, 0.0}, command = "rdps"},
        {name = "MDPS", color = {1.0, 0.0, 0.0}, command = "mdps"}
    }
    
    -- Create character rows with role buttons
    for i = 1, table.getn(sortedChars) do
        local charInfo = sortedChars[i]
        local yOffset = -50 - (i - 1) * (config.ButtonHeight + 5)
        
        -- Get available roles for this character's class
        local availableRoles = GetAvailableRoles(charInfo.data.class)
        local validRoles = {}
        
        -- Filter roles to only include available ones
        for j = 1, table.getn(allRoles) do
            local role = allRoles[j]
            for k = 1, table.getn(availableRoles) do
                if availableRoles[k] == role.command then
                    table.insert(validRoles, role)
                    break
                end
            end
        end
        
        -- Character name label
        local nameFrame = CreateFrame("Frame", "GuusLegacyName" .. i, gui)
        nameFrame:SetWidth(config.NameWidth)
        nameFrame:SetHeight(config.ButtonHeight)
        nameFrame:SetPoint("TOPLEFT", gui, "TOPLEFT", 10, yOffset)
        
        -- Name label background
        nameFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        nameFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        nameFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
        
        -- Character info text
        local factionPrefix = (charInfo.data.faction == "Alliance") and "A" or (charInfo.data.faction == "Horde") and "H" or "?"
        local nameText = factionPrefix .. " " .. charInfo.data.name .. " (" .. charInfo.data.class .. " Lv" .. charInfo.data.level .. ")"
        local textElement = nameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        textElement:SetPoint("LEFT", nameFrame, "LEFT", 8, 0)
        textElement:SetText(nameText)
        textElement:SetTextColor(1, 1, 1)
        textElement:SetJustifyH("LEFT")
        
        table.insert(characterButtons, nameFrame)
        
        -- Create role buttons (only for available roles)
        for j = 1, table.getn(validRoles) do
            local role = validRoles[j]
            local button = CreateFrame("Button", "GuusLegacyRole" .. i .. "_" .. j, gui)
            button:SetWidth(config.RoleButtonWidth)
            button:SetHeight(config.ButtonHeight)
            button:SetPoint("TOPLEFT", nameFrame, "TOPRIGHT", 5 + (j - 1) * (config.RoleButtonWidth + 2), 0)
            
            -- Simple button background without 3D effect
            button:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            button:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
            button:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
            
            -- Hover effect
            button:SetScript("OnEnter", function()
                button:SetBackdropColor(0.3, 0.3, 0.3, 0.9)
            end)
            button:SetScript("OnLeave", function()
                button:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
            end)
            
            -- Button text - properly centered
            local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            buttonText:SetPoint("CENTER", button, "CENTER", 0, 0)
            buttonText:SetText(role.name)
            buttonText:SetTextColor(role.color[1], role.color[2], role.color[3])
            buttonText:SetJustifyH("CENTER")
            buttonText:SetJustifyV("MIDDLE")
            
            -- Button click handler
            button:SetScript("OnClick", function()
                ExecuteLegacyCommand(charInfo.data.name, role.command)
            end)
            
            table.insert(characterButtons, button)
        end
    end
end

-- Function to create the main GUI
local function CreateGUI()
    if gui then
        gui:Show()
        return
    end
    
    -- Main frame
    gui = CreateFrame("Frame", "GuusLegacyManagerGUI", UIParent)
    gui:SetWidth(config.WindowWidth)
    gui:SetHeight(config.WindowHeight)
    gui:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    gui:SetMovable(true)
    gui:EnableMouse(true)
    
    -- Frame background
    gui:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Title bar
    local title = gui:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", gui, "TOP", 0, -15)
    title:SetText("Guus Legacy Manager")
    
    -- Close button
    local closeBtn = CreateFrame("Button", "GuusLegacyCloseBtn", gui)
    closeBtn:SetWidth(20)
    closeBtn:SetHeight(20)
    closeBtn:SetPoint("TOPRIGHT", gui, "TOPRIGHT", -5, -5)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetScript("OnClick", function() gui:Hide() end)
    
    -- Make frame draggable
    gui:SetScript("OnMouseDown", function() gui:StartMoving() end)
    gui:SetScript("OnMouseUp", function() gui:StopMovingOrSizing() end)
    
    -- Create character buttons
    CreateCharacterButtons()
    
    gui:Show()
end

-- Slash command handler
local function SlashCommandHandler(msg)
    local command = string.lower(msg or "")
    
    if command == "show" or command == "menu" or command == "" then
        AddCurrentCharacter()  -- Always add current character when opening
        CreateGUI()
    elseif command == "refresh" then
        AddCurrentCharacter()
        if gui and gui:IsVisible() then
            CreateCharacterButtons()
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager:|r Character list refreshed!")
    elseif command == "list" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager:|r Saved Characters:")
        local count = 0
        for fullName, charData in pairs(GuusLegacyManager_Characters) do
            count = count + 1
            local factionPrefix = (charData.faction == "Alliance") and "A" or (charData.faction == "Horde") and "H" or "?" DEFAULT_CHAT_FRAME:AddMessage("  " .. factionPrefix .. " " .. charData.name .. " (" .. charData.class .. " Lv" .. charData.level .. ") - " .. charData.lastSeen)
        end
        if count == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("  No characters saved yet. Log in with different characters to build the list.")
        end
    elseif command == "clear" then
        GuusLegacyManager_Characters = {}
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager:|r Character list cleared!")
        if gui and gui:IsVisible() then
            CreateCharacterButtons()
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /legacy - Open character selection window")
        DEFAULT_CHAT_FRAME:AddMessage("  /legacy list - Show all saved characters")
        DEFAULT_CHAT_FRAME:AddMessage("  /legacy refresh - Refresh character list")
        DEFAULT_CHAT_FRAME:AddMessage("  /legacy clear - Clear all saved characters")
    end
end

-- Register slash commands
SLASH_GUUSLEGACYMANAGER1 = "/legacy"
SLASH_GUUSLEGACYMANAGER2 = "/glm"
SlashCmdList["GUUSLEGACYMANAGER"] = SlashCommandHandler

-- Initialize on login
local function OnPlayerLogin()
    AddCurrentCharacter()
    
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("GuusLegacyManager: Loaded successfully!")
        DEFAULT_CHAT_FRAME:AddMessage("GuusLegacyManager: Use /legacy to open character manager")
    end
end

-- Event frame for login detection
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", OnPlayerLogin)

-- Add current character on load
AddCurrentCharacter()
