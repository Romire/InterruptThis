local addonName = ...

local frame = CreateFrame("Frame")

InterruptThisDB = InterruptThisDB or {}

local DEFAULTS = {
    screenAlert = true,
    buttonGlow = true,
    soundEnabled = true,
    debugEnabled = false,
}

local function ApplyDefaults()
    for key, value in pairs(DEFAULTS) do
        if InterruptThisDB[key] == nil then
            InterruptThisDB[key] = value
        end
    end
end

ApplyDefaults()

local debugEnabled = InterruptThisDB.debugEnabled

local INTERRUPT_SPELLS = {
    PALADIN = { spellID = 96231, name = "Rebuke" },
    WARRIOR = { spellID = 6552, name = "Pummel" },
    ROGUE = { spellID = 1766, name = "Kick" },
    DEATHKNIGHT = { spellID = 47528, name = "Mind Freeze" },
    DEMONHUNTER = { spellID = 183752, name = "Disrupt" },
    MONK = { spellID = 116705, name = "Spear Hand Strike" },
    DRUID = { spellID = 106839, name = "Skull Bash" },
    SHAMAN = { spellID = 57994, name = "Wind Shear" },
    MAGE = { spellID = 2139, name = "Counterspell" },
    PRIEST = { spellID = 15487, name = "Silence" },
    WARLOCK = { spellID = 19647, name = "Spell Lock" },
    HUNTER = { spellID = 147362, name = "Counter Shot" },
    EVOKER = { spellID = 351338, name = "Quell" },
}

local playerClass
local interruptInfo
local interruptSlots = {}
local RefreshInterruptButton

local function RefreshInterruptInfo()
    local _, classToken = UnitClass("player")
    playerClass = classToken
    interruptInfo = INTERRUPT_SPELLS[playerClass]
    interruptSlots = {}

    if interruptInfo and C_ActionBar and C_ActionBar.FindSpellActionButtons then
        local slots = C_ActionBar.FindSpellActionButtons(interruptInfo.spellID)

        if slots then
            for _, slot in ipairs(slots) do
                table.insert(interruptSlots, slot)
            end
        end
    end

    C_Timer.After(0, RefreshInterruptButton)
end

local function GetInterruptStatusText()
    if not interruptInfo then
        return "No standard interrupt configured for class " .. tostring(playerClass)
    end

    local slotText = "not found on action bars"

    if #interruptSlots > 0 then
        slotText = table.concat(interruptSlots, ", ")
    end

    return interruptInfo.name
        .. " (spellID " .. interruptInfo.spellID .. ")"
        .. " | action slot(s): " .. slotText
end

-- Custom interrupt action button glow
local interruptButton
local glowFrame
local glowPulse

local function HideInterruptGlow()
    if glowPulse then
        glowPulse:Stop()
    end

    if glowFrame then
        glowFrame:SetAlpha(0)
        glowFrame:Hide()
    end
end

local function FindButtonForActionSlot(slot)
    if not slot then
        return nil
    end

    -- Prefer ElvUI buttons first.
    for bar = 1, 15 do
        for i = 1, 12 do
            local button = _G["ElvUI_Bar" .. bar .. "Button" .. i]

            if button and button.action == slot then
                return button
            end
        end
    end

    -- Then search loaded action button frames.
    local current = EnumerateFrames()

    while current do
        if current.action == slot and current.IsVisible and current:GetObjectType() == "CheckButton" then
            return current
        end

        current = EnumerateFrames(current)
    end

    -- Stock Blizzard fallbacks.
    local stockPrefixes = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
        "MultiBar5Button",
        "MultiBar6Button",
        "MultiBar7Button",
    }

    for _, prefix in ipairs(stockPrefixes) do
        for i = 1, 12 do
            local button = _G[prefix .. i]

            if button and button.action == slot then
                return button
            end
        end
    end

    return nil
end

local function BuildGlowForButton(button)
    HideInterruptGlow()
    interruptButton = button

    if not button then
        return
    end

    if not glowFrame then
        glowFrame = CreateFrame("Frame", nil, UIParent)
        glowFrame:SetFrameStrata("DIALOG")
        glowFrame:SetFrameLevel(200)
        glowFrame:EnableMouse(false)

        -- Four bright border textures rather than relying on a Blizzard button texture.
        local top = glowFrame:CreateTexture(nil, "OVERLAY")
        top:SetColorTexture(1, 0.82, 0.1, 1)
        top:SetPoint("TOPLEFT")
        top:SetPoint("TOPRIGHT")
        top:SetHeight(4)

        local bottom = glowFrame:CreateTexture(nil, "OVERLAY")
        bottom:SetColorTexture(1, 0.82, 0.1, 1)
        bottom:SetPoint("BOTTOMLEFT")
        bottom:SetPoint("BOTTOMRIGHT")
        bottom:SetHeight(4)

        local left = glowFrame:CreateTexture(nil, "OVERLAY")
        left:SetColorTexture(1, 0.82, 0.1, 1)
        left:SetPoint("TOPLEFT")
        left:SetPoint("BOTTOMLEFT")
        left:SetWidth(4)

        local right = glowFrame:CreateTexture(nil, "OVERLAY")
        right:SetColorTexture(1, 0.82, 0.1, 1)
        right:SetPoint("TOPRIGHT")
        right:SetPoint("BOTTOMRIGHT")
        right:SetWidth(4)

        -- Soft outer halo.
        local halo = glowFrame:CreateTexture(nil, "BACKGROUND")
        halo:SetColorTexture(1, 0.65, 0.05, 0.25)
        halo:SetPoint("TOPLEFT", -6, 6)
        halo:SetPoint("BOTTOMRIGHT", 6, -6)

        glowFrame.top = top
        glowFrame.bottom = bottom
        glowFrame.left = left
        glowFrame.right = right
        glowFrame.halo = halo

        glowPulse = glowFrame:CreateAnimationGroup()

        local fadeOut = glowPulse:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0.35)
        fadeOut:SetDuration(0.35)
        fadeOut:SetOrder(1)
        fadeOut:SetSmoothing("IN_OUT")

        local fadeIn = glowPulse:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0.35)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.35)
        fadeIn:SetOrder(2)
        fadeIn:SetSmoothing("IN_OUT")

        glowPulse:SetLooping("REPEAT")
    end

    glowFrame:ClearAllPoints()
    glowFrame:SetPoint("TOPLEFT", button, "TOPLEFT", -5, 5)
    glowFrame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 5, -5)

    glowFrame:SetAlpha(0)
    glowFrame:Hide()
end

RefreshInterruptButton = function()
    HideInterruptGlow()
    interruptButton = nil

    if #interruptSlots == 0 then
        return
    end

    local button = FindButtonForActionSlot(interruptSlots[1])
    BuildGlowForButton(button)
end

local function ApplySecretGlow(notInterruptible)
    if not InterruptThisDB.buttonGlow then
        HideInterruptGlow()
        return
    end

    if not glowFrame or not interruptButton then
        return
    end

    glowFrame:Show()

    -- Secret-safe visibility:
    -- true  = cannot interrupt = alpha 0
    -- false = can interrupt    = alpha 1
    glowFrame:SetAlphaFromBoolean(notInterruptible, 0, 1)

    -- Start the pulse unconditionally. The secret-safe alpha still decides
    -- whether the player can actually see it.
    if glowPulse and not glowPulse:IsPlaying() then
        glowPulse:Play()
    end
end

-- Main warning container
local warningFrame = CreateFrame("Frame", nil, UIParent)
warningFrame:SetSize(420, 70)
warningFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
warningFrame:SetAlpha(0)
warningFrame:Hide()

local alert = warningFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
alert:SetPoint("TOP", warningFrame, "TOP", 0, 0)
alert:SetText("INTERRUPT NOW!")
alert:SetTextColor(1, 0.15, 0.15)

local spellText = warningFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
spellText:SetPoint("TOP", alert, "BOTTOM", 0, -8)
spellText:SetText("Interruptible Cast")
spellText:SetTextColor(1, 1, 1)

local function DebugPrint(message)
    if debugEnabled then
        print("|cff66ccffInterruptThis DEBUG:|r " .. message)
    end
end

local function ResetAlert()
    warningFrame:SetAlpha(0)
    warningFrame:Hide()
    HideInterruptGlow()
end

local function TargetIsHostile()
    if not UnitExists("target") then
        return false
    end

    if UnitIsUnit("target", "player") then
        return false
    end

    return UnitCanAttack("player", "target") == true
end

-- Secret-safe normal cast update.
-- We DO NOT compare, negate, tostring, or otherwise inspect notInterruptible.
-- WoW passes it directly into SetAlphaFromBoolean().
local function UpdateNormalCast()
    if not TargetIsHostile() then
        ResetAlert()
        return
    end

    local _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")

    if InterruptThisDB.screenAlert then
        warningFrame:Show()
        spellText:SetText("Interruptible Cast")

        -- notInterruptible true  = alpha 0
        -- notInterruptible false = alpha 1
        warningFrame:SetAlphaFromBoolean(notInterruptible, 0, 1)
    else
        warningFrame:SetAlpha(0)
        warningFrame:Hide()
    end

    ApplySecretGlow(notInterruptible)

    DebugPrint("Normal cast visual + interrupt glow updated through secret-safe boolean pipeline.")
    if interruptInfo then
        DebugPrint("Configured interrupt: " .. interruptInfo.name .. " | slot(s): "
            .. (#interruptSlots > 0 and table.concat(interruptSlots, ", ") or "not found"))
    end
end

-- Secret-safe channel update.
local function UpdateChannel()
    if not TargetIsHostile() then
        ResetAlert()
        return
    end

    local _, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")

    if InterruptThisDB.screenAlert then
        warningFrame:Show()
        spellText:SetText("Interruptible Channel")

        -- notInterruptible true  = alpha 0
        -- notInterruptible false = alpha 1
        warningFrame:SetAlphaFromBoolean(notInterruptible, 0, 1)
    else
        warningFrame:SetAlpha(0)
        warningFrame:Hide()
    end

    ApplySecretGlow(notInterruptible)

    DebugPrint("Channel visual + interrupt glow updated through secret-safe boolean pipeline.")
    if interruptInfo then
        DebugPrint("Configured interrupt: " .. interruptInfo.name .. " | slot(s): "
            .. (#interruptSlots > 0 and table.concat(interruptSlots, ", ") or "not found"))
    end
end


-- Small preview sound. Live interrupt-triggered audio remains intentionally
-- disabled until we have a secret-safe trigger that cannot false-positive.
local function PlayAlertSoundPreview()
    if not InterruptThisDB.soundEnabled then
        print("|cffffff00InterruptThis:|r Alert sound is muted in settings.")
        return
    end

    local soundID

    if SOUNDKIT then
        soundID = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.READY_CHECK
    end

    if soundID then
        PlaySound(soundID, "SFX")
    else
        -- Fallback to the classic ready-check SoundKitID.
        PlaySound(8960, "SFX")
    end
end

local settingsCategory

local function RegisterSettings()
    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        return
    end

    local category, layout = Settings.RegisterVerticalLayoutCategory("InterruptThis")
    settingsCategory = category

    if layout and CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Alerts"))
    end

    local function AddCheckbox(key, label, description, defaultValue, callback)
        local setting = Settings.RegisterAddOnSetting(
            category,
            "InterruptThis_" .. key,
            key,
            InterruptThisDB,
            type(defaultValue),
            label,
            defaultValue
        )

        if callback then
            setting:SetValueChangedCallback(function(_, value)
                callback(value)
            end)
        end

        Settings.CreateCheckbox(category, setting, description)
        return setting
    end

    AddCheckbox(
        "screenAlert",
        "Show screen warning",
        "Shows INTERRUPT NOW! when your current hostile target is casting an interruptible spell.",
        true
    )

    AddCheckbox(
        "buttonGlow",
        "Glow interrupt button",
        "Highlights the detected interrupt ability on your action bar when the current cast is interruptible.",
        true,
        function(value)
            if not value then
                HideInterruptGlow()
            end
        end
    )

    AddCheckbox(
        "soundEnabled",
        "Enable alert sound",
        "Controls the alert sound preference. In v0.4.0, use /it soundtest to preview it. Live combat sound is temporarily held back until it can use the same secret-safe accuracy as the visual warning.",
        true
    )

    if layout and CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Diagnostics"))
    end

    AddCheckbox(
        "debugEnabled",
        "Enable debug messages",
        "Prints cast, interrupt and action-bar diagnostics to chat. Recommended off for normal play.",
        false,
        function(value)
            debugEnabled = value
        end
    )

    Settings.RegisterAddOnCategory(category)
end

RegisterSettings()

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("SPELLS_CHANGED")

frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")

frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
frame:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

frame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID, castBarID)

    if event == "PLAYER_LOGIN" then
        ApplyDefaults()
        debugEnabled = InterruptThisDB.debugEnabled
        RefreshInterruptInfo()

        print("|cff00ff00InterruptThis v0.4.0 loaded.|r")
        print("|cffffff00Settings + alert polish build active.|r")
        print("|cff66ccffInterruptThis:|r " .. GetInterruptStatusText())
        print("|cffffff00Type /it help for commands. Settings are under Options > AddOns > InterruptThis.|r")
        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        ResetAlert()
        DebugPrint("Target changed. State reset.")
        return
    end

    if event == "ACTIONBAR_SLOT_CHANGED" or event == "SPELLS_CHANGED" then
        RefreshInterruptInfo()
        DebugPrint("Interrupt/action bar information refreshed.")
        return
    end

    if unit ~= "target" then
        return
    end

    if not TargetIsHostile() then
        ResetAlert()
        return
    end

    if event == "UNIT_SPELLCAST_START" then
        DebugPrint("CAST START | spellID=" .. tostring(spellID))
        C_Timer.After(0, UpdateNormalCast)
        return
    end

    if event == "UNIT_SPELLCAST_CHANNEL_START" then
        DebugPrint("CHANNEL START | spellID=" .. tostring(spellID))
        C_Timer.After(0, UpdateChannel)
        return
    end

    -- If WoW reports that interruptibility changed mid-cast,
    -- simply refresh the visual using the current secret boolean.
    if event == "UNIT_SPELLCAST_INTERRUPTIBLE"
        or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then

        DebugPrint(event .. " received. Refreshing visual.")

        C_Timer.After(0, function()
            -- We can safely choose which API to query from the existence
            -- of the spellcast events rather than inspecting secret data.
            -- Try the normal cast first; if WoW has no normal cast this
            -- callback may be superseded by the next channel event.
            UpdateNormalCast()
        end)

        return
    end

    if event == "UNIT_SPELLCAST_STOP"
        or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_INTERRUPTED"
        or event == "UNIT_SPELLCAST_CHANNEL_STOP" then

        ResetAlert()
        DebugPrint(event .. " | spellID=" .. tostring(spellID) .. " | State reset.")
        return
    end
end)


local function PrintQASummary()
    print("|cff00ff00InterruptThis QA:|r")
    print("Class: " .. tostring(playerClass or "UNKNOWN"))
    print(GetInterruptStatusText())

    if interruptButton then
        print("Interrupt button: " .. tostring(interruptButton:GetName() or "<unnamed>"))
    else
        print("Interrupt button: NOT FOUND")
    end

    if glowFrame then
        print("Custom glow frame: READY")
    else
        print("Custom glow frame: NOT READY")
    end

    print("Debug: " .. (InterruptThisDB.debugEnabled and "ON" or "OFF"))
end

SLASH_INTERRUPTTHIS1 = "/interruptthis"
SLASH_INTERRUPTTHIS2 = "/it"

SlashCmdList["INTERRUPTTHIS"] = function(message)
    message = string.lower(message or "")

    if message == "test" then
        warningFrame:SetAlpha(1)
        warningFrame:Show()
        spellText:SetText("Test Spell")

        print("|cff00ff00InterruptThis:|r Test alert shown.")

        C_Timer.After(3, function()
            ResetAlert()
        end)

    elseif message == "qa" then
        RefreshInterruptInfo()

        C_Timer.After(0.1, function()
            PrintQASummary()
        end)

    elseif message == "status" then
        RefreshInterruptInfo()
        print("|cff00ff00InterruptThis status:|r")
        print("Class: " .. tostring(playerClass))
        print(GetInterruptStatusText())

        if interruptButton then
            print("Glow button frame: " .. tostring(interruptButton:GetName() or "<unnamed LibActionButton>"))
        else
            print("Glow button frame: NOT FOUND")
        end

        if glowFrame then
            print("Custom glow frame: READY")
        else
            print("Custom glow frame: NOT READY")
        end

    elseif message == "glowtest" then
        RefreshInterruptInfo()

        C_Timer.After(0.1, function()
            if glowFrame and interruptButton then
                glowFrame:SetAlpha(1)
                glowFrame:Show()

                if glowPulse and not glowPulse:IsPlaying() then
                    glowPulse:Play()
                end

                print("|cff00ff00InterruptThis:|r Custom interrupt glow test shown.")

                C_Timer.After(3, function()
                    HideInterruptGlow()
                end)
            else
                print("|cffff3333InterruptThis:|r Could not find the interrupt button or build the glow frame.")
            end
        end)

    elseif message == "soundtest" then
        PlayAlertSoundPreview()

    elseif message == "settings" then
        if settingsCategory and Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(settingsCategory:GetID())
        else
            print("|cffffff00InterruptThis:|r Open Options > AddOns > InterruptThis.")
        end

    elseif message == "debug" then
        debugEnabled = not debugEnabled
        InterruptThisDB.debugEnabled = debugEnabled

        if debugEnabled then
            print("|cff00ff00InterruptThis:|r Debug messages enabled.")
        else
            print("|cffffff00InterruptThis:|r Debug messages disabled.")
        end

    elseif message == "help" then
        print("|cff00ff00InterruptThis commands:|r")
        print("/it test - Shows a test screen warning")
        print("/it glowtest - Shows the interrupt-button glow for 3 seconds")
        print("/it soundtest - Plays the configured alert sound preview")
        print("/it settings - Opens the InterruptThis settings panel")
        print("/it status - Shows detected class, interrupt, slot and button frame")
        print("/it qa - Prints a compact QA summary")
        print("/it debug - Toggles debug chat messages")

    else
        print("|cff00ff00InterruptThis commands:|r")
        print("/it help - Shows all commands")
        print("/it settings - Opens the settings panel")
        print("/it test - Shows a test screen warning")
        print("/it glowtest - Shows the interrupt-button glow for 3 seconds")
        print("/it soundtest - Plays the alert sound preview")
        print("/it status - Shows detected class, interrupt, slot and button frame")
        print("/it qa - Prints a compact QA summary")
        print("/it debug - Toggles debug chat messages")
    end
end
