GuusLegacyManager = GuusLegacyManager or {}
GuusLegacyManager_Config = GuusLegacyManager_Config or {}
GuusLegacyManager_Config.minimap = GuusLegacyManager_Config.minimap or { minimapPos = 220 }

-- Configuration
local config = {
    Debug = false,
    WindowWidth = 800,
    WindowHeight = 450,
    ButtonHeight = 30,
    ButtonWidth = 100,
    NameWidth = 250,
    RoleButtonWidth = 60,
    RaidStatusWidth = 300,
    RaidButtonWidth = 35,
    RaidButtonHeight = 20,
    LegacyOnlyWidth = 600,
    HideRaidTracking = false
}



local LDB = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

local function ShowGLMWindow()
    if gui and gui:IsShown() then
        gui:Hide()
    else
        -- Always update raid info when opening the window
        if GetRaidLockouts then GetRaidLockouts() end
        if gui then
            gui:Show()
            if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] ShowGLMWindow: gui shown") end
        else
            if GuusLegacyManager.CreateGUI then
                GuusLegacyManager.CreateGUI()
                if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] ShowGLMWindow: CreateGUI called") end
            end
        end
    end
end

local glmLDB = LDB:NewDataObject("GuusLegacyManager", {
    type = "launcher",
    text = "GLM",
    icon = "Interface\\GROUPFRAME\\UI-Group-LeaderIcon",
    OnClick = function(self, button)
        if button == "RightButton" then
            if SlashCmdList and SlashCmdList["GUUSLEGACYMANAGER"] then
                SlashCmdList["GUUSLEGACYMANAGER"]("resetraids")
                if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Minimap icon: /legacy resetraids triggered") end
            end
        else
            if gui and gui:IsShown() then
                gui:Hide()
                if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Minimap icon: window closed") end
            else
                if SlashCmdList and SlashCmdList["GUUSLEGACYMANAGER"] then
                    SlashCmdList["GUUSLEGACYMANAGER"]("")
                    if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Minimap icon: window opened") end
                end
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("GuusLegacyManager")
        tooltip:AddLine("Click to open/close the window.")
        tooltip:AddLine("Right-click for /legacy resetraids")
    end
})

    -- Register minimap icon after PLAYER_LOGIN
    local glmEventFrame = CreateFrame("Frame")
    glmEventFrame:RegisterEvent("PLAYER_LOGIN")
    glmEventFrame:SetScript("OnEvent", function()
        if DBIcon and glmLDB then
            DBIcon:Register("GuusLegacyManager", glmLDB, GuusLegacyManager_Config.minimap)
            DBIcon:Show("GuusLegacyManager")
        else
            -- Fallback: create a simple minimap icon for Vanilla WoW
            if not GuusLegacyManager_MinimapIcon then
                local iconFrame = CreateFrame("Button", "GuusLegacyManager_MinimapIcon", Minimap)
                iconFrame:SetWidth(32)
                iconFrame:SetHeight(32)
                iconFrame:SetFrameStrata("MEDIUM")
                iconFrame:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
                local icon = iconFrame:CreateTexture(nil, "ARTWORK")
                icon:SetAllPoints()
                icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                iconFrame.icon = icon
                iconFrame:SetScript("OnClick", function()
                    if GuusLegacyManager.CreateGUI then
                        GuusLegacyManager.CreateGUI()
                    end
                end)
                iconFrame:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:SetText("GuusLegacyManager", 1, 1, 1)
                    GameTooltip:AddLine("Click to open/close the window.", 0.7, 0.7, 0.7)
                    GameTooltip:Show()
                end)
                iconFrame:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end
        end
    end)




-- Load saved configuration
if GuusLegacyManager_Config.HideRaidTracking ~= nil then
    config.HideRaidTracking = GuusLegacyManager_Config.HideRaidTracking
end
if GuusLegacyManager_Config.Debug ~= nil then
    config.Debug = GuusLegacyManager_Config.Debug
end

gui = nil
local characterButtons = {}
local RefreshCharacterButtons  -- Forward declaration

-- Function to get raid lockout status
local function GetRaidLockouts()
    local raidStatus = {}
    local raids = {
        {name = "ZG", match = "Zul'Gurub", maxPlayers = 20},
        {name = "MC", match = "Molten Core", maxPlayers = 40},
        {name = "BWL", match = "Blackwing Lair", maxPlayers = 40},
        {name = "AQ20", match = "Ruins of Ahn'Qiraj", maxPlayers = 20},
        {name = "AQ40", match = "Temple of Ahn'Qiraj", maxPlayers = 40},
        {name = "Naxx", match = "Naxxramas", maxPlayers = 40}
    }

    -- Initialize all raids as available first
    for i = 1, table.getn(raids) do
        raidStatus[raids[i].name] = false
    end

    local numSavedInstances = GetNumSavedInstances()
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Number of saved instances: " .. tostring(numSavedInstances))
    end

    for j = 1, numSavedInstances do
        local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(j)

        -- Log all raw values for investigation
        if config.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("[GLM RAW] instanceName=" .. tostring(instanceName)
                .. " | instanceID=" .. tostring(instanceID)
                .. " | instanceReset=" .. tostring(instanceReset)
                .. " | instanceDifficulty=" .. tostring(instanceDifficulty)
                .. " | locked=" .. tostring(locked)
                .. " | extended=" .. tostring(extended)
                .. " | instanceIDMostSig=" .. tostring(instanceIDMostSig)
                .. " | isRaid=" .. tostring(isRaid)
                .. " | maxPlayers=" .. tostring(maxPlayers)
                .. " | difficultyName=" .. tostring(difficultyName)
                .. " | numEncounters=" .. tostring(numEncounters)
                .. " | encounterProgress=" .. tostring(encounterProgress))

            local lockedText = locked and "LOCKED" or "AVAILABLE"
            DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Instance: " .. tostring(instanceName) .. " | ID: " .. tostring(instanceID) .. " | Locked: " .. lockedText .. " | isRaid: " .. tostring(isRaid) .. " | maxPlayers: " .. tostring(maxPlayers))
        end

        -- Check if this instance matches any of our tracked raids by name
        for i = 1, table.getn(raids) do
            local raid = raids[i]
            if instanceName and string.lower(instanceName) == string.lower(raid.match) then
                if config.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Found tracked raid: " .. raid.name .. " (Name: " .. raid.match .. ") | Marked as LOCKED (instance present)")
                end
                raidStatus[raid.name] = true -- Mark as locked if present in saved instances
                break
            end
        end
    end

    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Final raidStatus table:")
        for raidName, isLocked in pairs(raidStatus) do
            local statusText = isLocked and "LOCKED" or "AVAILABLE"
            DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] " .. raidName .. ": " .. statusText)
        end
    end

    return raidStatus
end

-- Function to add current character to saved list
local function AddCurrentCharacter()
    local playerName = UnitName("player")
    local playerRealm = GetRealmName()
    local className = UnitClass("player")
    local faction = UnitFactionGroup("player")
    local level = UnitLevel("player")
    
    -- Validate that we have all required data before proceeding
    if not playerName or not playerRealm or not className or not faction or not level or level == 0 then
        if config.Debug then 
            DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] AddCurrentCharacter: Missing player data, skipping save. playerName=" .. tostring(playerName) .. ", playerRealm=" .. tostring(playerRealm) .. ", className=" .. tostring(className) .. ", faction=" .. tostring(faction) .. ", level=" .. tostring(level))
        end
        return
    end
    
    local fullName = playerName .. "-" .. playerRealm

    if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] AddCurrentCharacter: playerName=" .. tostring(playerName) .. ", playerRealm=" .. tostring(playerRealm) .. ", className=" .. tostring(className) .. ", faction=" .. tostring(faction) .. ", level=" .. tostring(level)) end

    -- Get current raid lockout status
    local raidLockouts = GetRaidLockouts()

    -- Debug output to see what game detects
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Detected raid lockouts:")
        for raidName, isLocked in pairs(raidLockouts) do
            local statusText = isLocked and "LOCKED" or "AVAILABLE"
            DEFAULT_CHAT_FRAME:AddMessage("  " .. raidName .. ": " .. statusText)
        end
    end

    -- Check if character already exists
    local existingChar = GuusLegacyManager[fullName]
    local existingRaidStatus = {}
    local existingManualStatus = {}

    -- Preserve existing manual overrides, but update with detected lockouts
    if existingChar and existingChar.raidStatus then
        existingRaidStatus = existingChar.raidStatus
    end
    if existingChar and existingChar.manualRaidStatus then
        existingManualStatus = existingChar.manualRaidStatus
    end

    -- Merge detected lockouts with existing manual settings
    for raidName, isLocked in pairs(raidLockouts) do
        local oldStatus = existingRaidStatus[raidName]
        local wasManual = existingManualStatus[raidName]
        if isLocked then
            existingRaidStatus[raidName] = true
            existingManualStatus[raidName] = false
        else
            existingRaidStatus[raidName] = false
            existingManualStatus[raidName] = false
        end
    local oldText = oldStatus and "USED" or "AVAILABLE"
    local newText = existingRaidStatus[raidName] and "USED" or "AVAILABLE"
    local manualText = wasManual and " (was manual)" or " (was auto)"
    if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] " .. raidName .. ": " .. oldText .. manualText .. " -> " .. newText .. " (auto)") end
    end

    -- Store character info
    GuusLegacyManager[fullName] = {
        name = playerName,
        realm = playerRealm,
        class = className,
        faction = faction,
        level = level,
        lastSeen = date("%Y-%m-%d %H:%M:%S"),
        raidStatus = existingRaidStatus,
        manualRaidStatus = existingManualStatus,
    }

    if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Added character " .. fullName) end
end

-- Function to clean up invalid character data
local function ValidateAndCleanCharacterData()
    for fullName, charData in pairs(GuusLegacyManager) do
        local needsUpdate = false
        
        -- Fix missing or invalid faction data
        if not charData.faction or (charData.faction ~= "Alliance" and charData.faction ~= "Horde") then
            if config.Debug then 
                DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Fixing invalid faction for " .. fullName .. ": " .. tostring(charData.faction))
            end
            -- Don't guess faction, leave it as unknown until player logs in again
            charData.faction = "Unknown"
            needsUpdate = true
        end
        
        -- Fix missing or invalid level data
        if not charData.level or charData.level == 0 then
            if config.Debug then 
                DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Fixing invalid level for " .. fullName .. ": " .. tostring(charData.level))
            end
            -- Set to 1 as minimum valid level
            charData.level = 1
            needsUpdate = true
        end
        
        if needsUpdate and config.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Updated character data for " .. fullName)
        end
    end
end

-- Function to safely add character when data is ready
local function TryAddCurrentCharacter()
    local playerName = UnitName("player")
    local playerRealm = GetRealmName()
    local className = UnitClass("player")
    local faction = UnitFactionGroup("player")
    local level = UnitLevel("player")
    
    -- Check if all data is available and valid
    if playerName and playerRealm and className and faction and level and level > 0 then
        if config.Debug then 
            DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Player data ready, adding character")
        end
        ValidateAndCleanCharacterData()
        AddCurrentCharacter()
        return true
    else
        if config.Debug then 
            DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Player data not ready: name=" .. tostring(playerName) .. " realm=" .. tostring(playerRealm) .. " class=" .. tostring(className) .. " faction=" .. tostring(faction) .. " level=" .. tostring(level))
        end
        return false
    end
end

-- Always add current character to the list on login
local addCharOnLoginFrame = CreateFrame("Frame")
addCharOnLoginFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
addCharOnLoginFrame:RegisterEvent("PLAYER_LOGIN")
addCharOnLoginFrame:SetScript("OnEvent", function(self, event)
    if config.Debug then 
        DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Event fired: " .. tostring(event)) 
    end
    
    -- Try to add character immediately, then retry if needed
    if not TryAddCurrentCharacter() then
        -- If data not ready, keep trying with increasing delays
        local attempts = 0
        local function RetryAddCharacter()
            attempts = attempts + 1
            if TryAddCurrentCharacter() then
                if config.Debug then 
                    DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Character added after " .. attempts .. " attempts")
                end
                return
            elseif attempts < 10 then -- Try for up to 10 attempts (20 seconds max)
                C_Timer.After(2, RetryAddCharacter)
            else
                if config.Debug then 
                    DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Failed to add character after " .. attempts .. " attempts")
                end
            end
        end
        C_Timer.After(2, RetryAddCharacter)
    end
end)

-- Save current character on logout
local function SaveCharacterOnLogout()
    AddCurrentCharacter()
end

local saveCharFrame = CreateFrame("Frame")
saveCharFrame:RegisterEvent("PLAYER_LOGOUT")
saveCharFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
saveCharFrame:SetScript("OnEvent", SaveCharacterOnLogout)

-- Function to execute legacy command
local function ExecuteLegacyCommand(characterName, role, spec)
    local command = ".z addlegacy \"" .. characterName .. "\" " .. role
    if spec and type(spec) == "string" and spec ~= "" then
        command = command .. " " .. string.lower(spec)
    end

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
    return classRoles[class] or {"mdps"}
end

-- Function to toggle raid status manually
local function ToggleRaidStatus(fullName, raidName)
    if not GuusLegacyManager[fullName] then
        return
    end

    -- Initialize raid status if it doesn't exist
    if not GuusLegacyManager[fullName].raidStatus then
        GuusLegacyManager[fullName].raidStatus = {}
    end

    -- Initialize manual tracking if it doesn't exist
    if not GuusLegacyManager[fullName].manualRaidStatus then
        GuusLegacyManager[fullName].manualRaidStatus = {}
    end

    -- Toggle the status
    local currentStatus = GuusLegacyManager[fullName].raidStatus[raidName] or false
    GuusLegacyManager[fullName].raidStatus[raidName] = not currentStatus

    -- Mark this as manually set
    GuusLegacyManager[fullName].manualRaidStatus[raidName] = true

    local statusText = GuusLegacyManager[fullName].raidStatus[raidName] and "USED" or "AVAILABLE"
    if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager:|r " .. GuusLegacyManager[fullName].name .. " - " .. raidName .. " marked as " .. statusText .. " (Manual)") end

    -- Note: GUI will refresh when you close and reopen it

    -- Refresh the GUI if it's open (will be set after CreateCharacterButtons is defined)
    if RefreshCharacterButtons then
        RefreshCharacterButtons()
    end
end

-- Function to create character buttons
-- ...existing code...
local function CreateCharacterButtons()
    if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] CreateCharacterButtons called!") end
    local charCount = 0
    for fullName, charData in pairs(GuusLegacyManager) do
        charCount = charCount + 1
        if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Character: " .. tostring(fullName) .. " name=" .. tostring(charData.name) .. " class=" .. tostring(charData.class) .. " level=" .. tostring(charData.level)) end
    end
    if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] Total characters: " .. tostring(charCount)) end
    -- Clear existing buttons
    for i, button in ipairs(characterButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    characterButtons = {}

    -- Get sorted character list
    local sortedChars = {}
    for fullName, charData in pairs(GuusLegacyManager) do
        table.insert(sortedChars, {fullName = fullName, data = charData})
    end

    -- Sort by character name
    table.sort(sortedChars, function(a, b)
        return a.data.name < b.data.name
    end)
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("GLM DEBUG: sortedChars count: " .. tostring(table.getn(sortedChars)))
        for i, charInfo in ipairs(sortedChars) do
            DEFAULT_CHAT_FRAME:AddMessage("  sorted: " .. tostring(charInfo.fullName) .. " -> " .. tostring(charInfo.data.name or "nil"))
        end
    end
    
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
        local yOffset = -70 - (i - 1) * (config.ButtonHeight + 5)
        
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
        local faction = charInfo.data.faction or "Unknown"
        local level = charInfo.data.level or 0
        local factionPrefix = (faction == "Alliance") and "A" or (faction == "Horde") and "H" or "?"
        local nameText = factionPrefix .. " " .. charInfo.data.name .. " (" .. charInfo.data.class .. " Lv" .. tostring(level) .. ")"

        local textElement = nameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        textElement:SetPoint("LEFT", nameFrame, "LEFT", 8, 0)
        textElement:SetText(nameText)
        textElement:SetTextColor(1, 1, 1)
        textElement:SetJustifyH("LEFT")

        table.insert(characterButtons, nameFrame)

        -- Get full character key for lookup and saving
        local fullName = charInfo.fullName

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

            -- Mage now gets a simple button like other classes
                button:SetScript("OnClick", function()
                        if charInfo.data.class == "Paladin" and (role.command == "mdps" or role.command == "tank") then
                            StaticPopupDialogs["GLM_PALADIN_SPEC"] = {
                                text = "Select Paladin spec:",
                                button1 = "Might",
                                button2 = "Magic",
                                OnAccept = function()
                                    ExecuteLegacyCommand(charInfo.data.name, role.command, "might")
                                end,
                                OnCancel = function()
                                    ExecuteLegacyCommand(charInfo.data.name, role.command, "magic")
                                end,
                                timeout = 0,
                                whileDead = true,
                                hideOnEscape = true,
                                preferredIndex = 3,
                            }
                            StaticPopup_Show("GLM_PALADIN_SPEC")
                        elseif charInfo.data.class == "Mage" and role.command == "rdps" then
                                if not GLM_MageSpecFrame then
                                    GLM_MageSpecFrame = CreateFrame("Frame", "GLM_MageSpecFrame", UIParent)
                                    GLM_MageSpecFrame:SetWidth(260)
                                    GLM_MageSpecFrame:SetHeight(110)
                                    GLM_MageSpecFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                                    GLM_MageSpecFrame:SetFrameStrata("DIALOG")
                                    GLM_MageSpecFrame:SetBackdrop({
                                        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                                        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                                        tile = true, tileSize = 32, edgeSize = 32,
                                        insets = { left = 11, right = 12, top = 12, bottom = 11 }
                                    })
                                    GLM_MageSpecFrame:EnableMouse(true)
                                    GLM_MageSpecFrame:SetMovable(true)
                                    GLM_MageSpecFrame:RegisterForDrag("LeftButton")
                                    GLM_MageSpecFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
                                    GLM_MageSpecFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

                                    local title = GLM_MageSpecFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                                    title:SetPoint("TOP", GLM_MageSpecFrame, "TOP", 0, -10)
                                    title:SetText("Select Mage Spec")

                                    local frostBtn = CreateFrame("Button", nil, GLM_MageSpecFrame, "UIPanelButtonTemplate")
                                    frostBtn:SetWidth(70)
                                    frostBtn:SetHeight(24)
                                    frostBtn:SetPoint("BOTTOMLEFT", GLM_MageSpecFrame, "BOTTOMLEFT", 15, 15)
                                    frostBtn:SetText("Frost")
                                    frostBtn:SetScript("OnClick", function()
                                        ExecuteLegacyCommand(charInfo.data.name, role.command, "frost")
                                        GLM_MageSpecFrame:Hide()
                                    end)

                                    local fireBtn = CreateFrame("Button", nil, GLM_MageSpecFrame, "UIPanelButtonTemplate")
                                    fireBtn:SetWidth(70)
                                    fireBtn:SetHeight(24)
                                    fireBtn:SetPoint("BOTTOM", GLM_MageSpecFrame, "BOTTOM", 0, 15)
                                    fireBtn:SetText("Fire")
                                    fireBtn:SetScript("OnClick", function()
                                        ExecuteLegacyCommand(charInfo.data.name, role.command, "fire")
                                        GLM_MageSpecFrame:Hide()
                                    end)

                                    local arcaneBtn = CreateFrame("Button", nil, GLM_MageSpecFrame, "UIPanelButtonTemplate")
                                    arcaneBtn:SetWidth(70)
                                    arcaneBtn:SetHeight(24)
                                    arcaneBtn:SetPoint("BOTTOMRIGHT", GLM_MageSpecFrame, "BOTTOMRIGHT", -15, 15)
                                    arcaneBtn:SetText("Arcane")
                                    arcaneBtn:SetScript("OnClick", function()
                                        ExecuteLegacyCommand(charInfo.data.name, role.command, "arcane")
                                        GLM_MageSpecFrame:Hide()
                                    end)

                                    local closeBtn = CreateFrame("Button", nil, GLM_MageSpecFrame, "UIPanelCloseButton")
                                    closeBtn:SetPoint("TOPRIGHT", GLM_MageSpecFrame, "TOPRIGHT", -5, -5)
                                    closeBtn:SetScript("OnClick", function() GLM_MageSpecFrame:Hide() end)
                                end
                                GLM_MageSpecFrame:Show()
                        else
                            ExecuteLegacyCommand(charInfo.data.name, role.command)
                        end
                end)

            table.insert(characterButtons, button)
            -- ...existing code...
        end
        
        -- Calculate fixed position for raid status (aligned for all characters)
        local raidStatusStartX = config.NameWidth + 10 + (4 * (config.RoleButtonWidth + 2)) + 10  -- Fixed position after max possible role buttons

        -- Only show raid tracking if not hidden
        if not config.HideRaidTracking then
            -- Create manual raid status buttons
            local raids = {"ZG", "MC", "BWL", "AQ20", "AQ40", "Naxx"}
            for j = 1, table.getn(raids) do
                local raidName = raids[j]
                local isLocked = false
                -- Check if character has raid status data
                if charInfo.data.raidStatus and charInfo.data.raidStatus[raidName] ~= nil then
                    isLocked = charInfo.data.raidStatus[raidName]
                end
                -- Create raid button
                local raidButton = CreateFrame("Button", "GuusLegacyRaidBtn" .. i .. "_" .. j, gui)
                raidButton:SetWidth(config.RaidButtonWidth)
                raidButton:SetHeight(config.ButtonHeight) -- Match legacy button height
                raidButton:SetPoint("TOPLEFT", gui, "TOPLEFT", raidStatusStartX + (j - 1) * (config.RaidButtonWidth + 2), yOffset)
                -- Button background
                raidButton:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 16,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                -- Set color based on status
                if isLocked then
                    raidButton:SetBackdropColor(0.8, 0.2, 0.2, 0.8)  -- Red for used
                    raidButton:SetBackdropBorderColor(1.0, 0.3, 0.3, 0.8)
                else
                    raidButton:SetBackdropColor(0.2, 0.8, 0.2, 0.8)  -- Green for available
                    raidButton:SetBackdropBorderColor(0.3, 1.0, 0.3, 0.8)
                end
                -- Hover effects
                raidButton:SetScript("OnEnter", function()
                    if isLocked then
                        raidButton:SetBackdropColor(0.9, 0.3, 0.3, 0.9)
                    else
                        raidButton:SetBackdropColor(0.3, 0.9, 0.3, 0.9)
                    end
                    -- Show tooltip
                    GameTooltip:SetOwner(raidButton, "ANCHOR_TOP")
                    GameTooltip:SetText(raidName .. " - " .. charInfo.data.name, 1, 1, 1)
                    local statusText = isLocked and "|cffff0000USED|r" or "|cff00ff00AVAILABLE|r"
                    GameTooltip:AddLine("Status: " .. statusText, 0.7, 0.7, 0.7)
                    -- Check if this was manually set
                    local isManual = charInfo.data.manualRaidStatus and charInfo.data.manualRaidStatus[raidName]
                    if isManual then
                        GameTooltip:AddLine("|cffffff00Manually set|r", 0.7, 0.7, 0.7)
                    else
                        GameTooltip:AddLine("Auto-detected: " .. charInfo.data.lastSeen, 0.7, 0.7, 0.7)
                    end
                    GameTooltip:AddLine("Click to toggle", 1, 1, 0)
                    GameTooltip:Show()
                end)
                raidButton:SetScript("OnLeave", function()
                    if isLocked then
                        raidButton:SetBackdropColor(0.8, 0.2, 0.2, 0.8)
                    else
                        raidButton:SetBackdropColor(0.2, 0.8, 0.2, 0.8)
                    end
                    GameTooltip:Hide()
                end)
                -- Button text
                local buttonText = raidButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                buttonText:SetPoint("CENTER", raidButton, "CENTER", 0, 0)
                buttonText:SetText(raidName)
                buttonText:SetTextColor(1, 1, 1)
                buttonText:SetJustifyH("CENTER")
                buttonText:SetJustifyV("MIDDLE")
                -- Click handler to toggle status
                raidButton:SetScript("OnClick", function()
                    ToggleRaidStatus(charInfo.fullName, raidName)
                end)
                table.insert(characterButtons, raidButton)
            end
        end
    end
end

-- Function to refresh character buttons (defined after CreateCharacterButtons)
RefreshCharacterButtons = function()
    if gui and gui:IsVisible() then
        CreateCharacterButtons()
    end
end

-- Function to create the main GUI
local function CreateGUI()
    if gui then
        gui:Show()
            RefreshCharacterButtons() -- Always refresh character info when shown
        return
    end

    -- Main frame
    gui = CreateFrame("Frame", "GuusLegacyManagerGUI", UIParent)
    if config.Debug then DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] gui frame created: " .. tostring(gui)) end
    if config.HideRaidTracking then
        gui:SetWidth(config.LegacyOnlyWidth)
    else
        gui:SetWidth(config.WindowWidth)
    end
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
    
    -- Subtitle with legend
    local subtitle = gui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", gui, "TOP", 0, -35)
    subtitle:SetText("|cff00ff00Raid status Autoupdates on character login. When hiring companions you can also manually set the status.|r\n|cffff0000(addon cannot read raid status across characters)|r")
    subtitle:Show()
    
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
    
    -- Add Hide Raid Tracking checkbox
    local hideRaidCheck = CreateFrame("CheckButton", "GLMHideRaidTrackingCheck", gui, "UICheckButtonTemplate")
    hideRaidCheck:SetPoint("TOPLEFT", gui, "TOPLEFT", 8, -8)
    hideRaidCheck:SetChecked(config.HideRaidTracking)
    getglobal(hideRaidCheck:GetName() .. "Text"):SetText("Hide Raid Tracking")
    hideRaidCheck:SetScript("OnClick", function(self)
        local checkBtn = self or GLMHideRaidTrackingCheck
        local checked = false
        if checkBtn and checkBtn.GetChecked then
            checked = checkBtn:GetChecked() and true or false
            config.HideRaidTracking = checked
        else
            config.HideRaidTracking = false
        end
        GuusLegacyManager_Config.HideRaidTracking = config.HideRaidTracking
        if config.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] HideRaidTracking checkbox value: " .. tostring(checked))
            DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] HideRaidTracking config value: " .. tostring(config.HideRaidTracking))
            DEFAULT_CHAT_FRAME:AddMessage("[GLM DEBUG] HideRaidTracking SavedVariable value: " .. tostring(GuusLegacyManager_Config.HideRaidTracking))
        end
        if gui then
            if config.HideRaidTracking then
                gui:SetWidth(config.LegacyOnlyWidth)
                subtitle:Hide()
            else
                gui:SetWidth(config.WindowWidth)
                subtitle:Show()
            end
        end
        CreateCharacterButtons()
    end)



    -- Ensure config is saved before logout or reload
    local function SaveConfigOnLogout()
        GuusLegacyManager_Config.HideRaidTracking = config.HideRaidTracking
        GuusLegacyManager_Config.Debug = config.Debug
    end

    local logoutFrame = CreateFrame("Frame")
    logoutFrame:RegisterEvent("PLAYER_LOGOUT")
    logoutFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
    logoutFrame:SetScript("OnEvent", SaveConfigOnLogout)

end

    -- Expose CreateGUI globally for minimap icon
    GuusLegacyManager.CreateGUI = CreateGUI

-- Slash command handler
local function SlashCommandHandler(msg)
    local command = string.lower(msg or "")

    if command == "show" or command == "menu" or command == "" then
        AddCurrentCharacter()  -- Always add current character when opening
        CreateGUI()
        if gui then
            RefreshCharacterButtons() -- Always refresh after opening from slash
        end
        return
    end

    -- If the command is not recognized, open the GUI anyway (for icon click fallback)
    if msg == nil or msg == "" then
        AddCurrentCharacter()
        CreateGUI()
        if gui then
            RefreshCharacterButtons()
        end
        return
    end

    if command == "refresh" then
        -- Update raid lockouts for ALL characters
        for fullName, charData in pairs(GuusLegacyManager) do
            if fullName == (UnitName("player") .. "-" .. GetRealmName()) then
                -- Only update lockouts for the current character (API limitation)
                AddCurrentCharacter()
            end
        end
        if gui and gui:IsVisible() then
            CreateCharacterButtons()
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager:|r Character list and raid info refreshed!")
    elseif command == "list" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager:|r Saved Characters:")
        local count = 0
        for fullName, charData in pairs(GuusLegacyManager) do
            count = count + 1
            local factionPrefix = (charData.faction == "Alliance") and "A" or (charData.faction == "Horde") and "H" or "?"
            local charInfo = "  " .. factionPrefix .. " " .. charData.name .. " (" .. charData.class .. " Lv" .. charData.level .. ") - " .. charData.lastSeen
            
            -- Add raid status if available
            if charData.raidStatus then
                local raids = {"ZG", "MC", "BWL", "AQ20", "AQ40", "Naxx"}
                local raidStatusText = " - Raids: "
                for j = 1, table.getn(raids) do
                    local raidName = raids[j]
                    local isLocked = charData.raidStatus[raidName]
                    local statusColor = isLocked and "|cffff0000" or "|cff00ff00"
                    raidStatusText = raidStatusText .. statusColor .. raidName .. "|r"
                    if j < table.getn(raids) then
                        raidStatusText = raidStatusText .. " "
                    end
                end
                charInfo = charInfo .. raidStatusText
            end
            
            DEFAULT_CHAT_FRAME:AddMessage(charInfo)
        end
        if count == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("  No characters saved yet. Log in with different characters to build the list.")
        end
    elseif command == "clear" then
        GuusLegacyManager = {}
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager:|r Character list cleared!")
        if gui and gui:IsVisible() then
            CreateCharacterButtons()
        end
    elseif command == "resetraids" then
        -- Reset all raid statuses to available
        for fullName, charData in pairs(GuusLegacyManager) do
            if charData.raidStatus then
                for raidName, _ in pairs(charData.raidStatus) do
                    charData.raidStatus[raidName] = false
                end
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager:|r All raid statuses reset to available!")
        if gui and gui:IsVisible() then
            CreateCharacterButtons()
        end
    elseif command == "debug" then
        config.Debug = not config.Debug
        GuusLegacyManager_Config.Debug = config.Debug
        local status = config.Debug and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager:|r Debug mode " .. status)
    -- Companion configuration commands
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusLegacyManager Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /legacy - Open character selection window")
        DEFAULT_CHAT_FRAME:AddMessage("  /legacy list - Show all saved characters")
        DEFAULT_CHAT_FRAME:AddMessage("  /legacy refresh - Refresh character list")
        DEFAULT_CHAT_FRAME:AddMessage("  /legacy resetraids - Reset all raids to available")
        DEFAULT_CHAT_FRAME:AddMessage("  /legacy clear - Clear all saved characters")
        DEFAULT_CHAT_FRAME:AddMessage("  /legacy debug - Toggle debug mode on/off")

    end
end


SLASH_GUUSLEGACYMANAGER1 = "/legacy"
SLASH_GUUSLEGACYMANAGER2 = "/glm"
SlashCmdList["GUUSLEGACYMANAGER"] = SlashCommandHandler
