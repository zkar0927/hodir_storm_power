local ADDON = CreateFrame("Frame", "HodirStormPower", UIParent)

ADDON:SetScript("OnEvent", function(self, event, ...)
  return self[event](self, event, ...)
end)

ADDON:RegisterEvent("PLAYER_LOGIN")

local function GetAllRaidMembers()

  local _, _, _, _, maxPlayers = GetInstanceInfo()
  local numPlayers = GetNumGroupMembers()

  local max = numPlayers

  if maxPlayers ~= 0 then
    max = (numPlayers > maxPlayers) and maxPlayers or numPlayers
  end

  local everyone = ""
  for i = 1, max do
    local unit = "raid" .. i
    everyone = everyone .. UnitName(unit) .. "\n"
  end

  return everyone
end

local function ClickPopulateFromRaid()
  ADDON.configFrame.editBox:SetText(GetAllRaidMembers())
end

local function ClickSave()
  HodirStormPowerDB.priorityList = strsplittable("\n", ADDON.configFrame.editBox:GetText())
end

local function PopulateEditBox()
  local string = ""
  for k, v in pairs(HodirStormPowerDB.priorityList) do
    string = string .. v .. "\n"
  end

  ADDON.configFrame.editBox:SetText(string)
end

local function CreateConfigFrame()
  local configFrameName = "HodirStormPowerConfig"
  local frame = CreateFrame("Frame", configFrameName, UIParent, "BackdropTemplate")
  ADDON.configFrame = frame
  frame:SetPoint("CENTER")
  frame:SetSize(300, 500)
  frame:SetBackdrop(BACKDROP_TUTORIAL_16_16)

  -- Make the frame movable
  frame:SetMovable(true)
  frame:SetScript("OnMouseDown", function(self, button)
    self:StartMoving()
  end)
  frame:SetScript("OnMouseUp", function(self, button)
    self:StopMovingOrSizing()
  end)

  frame.closeButton = CreateFrame("Button", configFrameName .. "CloseButton", frame, "UIPanelCloseButton")
  frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

  -- button to pull in raid members in a list
  frame.populateButton = CreateFrame("Button", configFrameName .. "PopulateButton", frame, "UIPanelButtonTemplate")
  frame.populateButton:SetPoint("BOTTOMLEFT", 10, 7)
  frame.populateButton:SetSize(100, 40)
  frame.populateButton:SetText("Populate\nFrom Raid")
  frame.populateButton:SetScript("OnClick", function() ClickPopulateFromRaid() end)

  -- button to lock in config
  frame.saveButton = CreateFrame("Button", configFrameName .. "SaveButton", frame, "UIPanelButtonTemplate")
  frame.saveButton:SetPoint("BOTTOMRIGHT", -10, 7)
  frame.saveButton:SetSize(100, 40)
  frame.saveButton:SetText("Save")
  frame.saveButton:SetScript("OnClick", function() ClickSave() end)

  -- Create Header
  frame.header = CreateFrame("Frame", configFrameName .. "-Header", frame, "BackdropTemplate")
  local header = frame.header
  header:SetBackdrop(BACKDROP_DATA)
  header:SetBackdropColor(0, 1, 0, 1)
  header:SetSize(0, 0)
  header.text = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  header.text:SetAllPoints(header)
  header.text:SetJustifyH("CENTER")
  header.text:SetText("Storm Power Priority")
  header:SetPoint("TOPLEFT", frame, 10, -7)
  header:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -30, -25)

  frame.editBox = CreateFrame("EditBox", configFrameName .. "-EditBox", frame) --, "SearchBoxTemplate")
  frame.editBox:SetMultiLine(true)
  frame.editBox:SetAutoFocus(false)
  frame.editBox:SetSize(100, 100)
  frame.editBox:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 6, -8)
  frame.editBox:SetPoint("BOTTOMRIGHT")
  frame.editBox:SetFontObject("GameFontHighlight")
  frame.editBox:SetTextInsets(2, 1, 2, 2)
  frame.editBox:SetIgnoreParentAlpha(true)
  frame.editBox:SetScript("OnShow", function() PopulateEditBox() end)
  PopulateEditBox()

end

local function ShowConfiguration()

  if ADDON.configFrame then
    -- If the frame exists, toggle visibility
    local configFrame = ADDON.configFrame
    if configFrame:IsShown() then
      configFrame:Hide()
    else
      configFrame:Show()
    end
  else
    -- Otherwise, create the initial frame
    CreateConfigFrame()
  end

end

local function SetupSlashHandler()
  -- Configure slash handler
  SlashCmdList.HodirStormPower = function()
    ShowConfiguration()
  end
  SLASH_HodirStormPower1 = "/hodirstormpower"
  SLASH_HodirStormPower2 = "/hsp"
end

function ADDON.PLAYER_LOGIN()
  if not ADDON.initialized then
    ADDON.initialized = true

    ADDON:RegisterEvent("ENCOUNTER_START")
    ADDON:RegisterEvent("ENCOUNTER_END")

    HodirStormPowerDB = HodirStormPowerDB or {}
    HodirStormPowerDB.priorityList = HodirStormPowerDB.priorityList or {}

    SetupSlashHandler()

    ADDON.lastUpdateMarkTime = GetTime()
  end
end

function ADDON.ENCOUNTER_START(self, event, ecounterID, encounterName, difficultyID, groupSize)
  -- Hodir is encounter ID 751
  if encounterID == 751 then
    ADDON:RegisterEvent("UNIT_AURA")
  end
end

function ADDON.ENCOUNTER_END(self, event, ecounterID, encounterName, difficultyID, groupSize)
  -- Hodir is encounter ID 751
  if encounterID == 751 then
    ADDON:UnregisterEvent("UNIT_AURA")
  end
end

local function GetPlayersToMark()

  local playersToMark = {}
  local count = 0

  local priorityTargets = HodirStormPowerDB.priorityList
  for i, playerName in pairs(priorityTargets) do
    if UnitExists(playerName) then

      local spellName = "Storm Power"
      local foundName = AuraUtil.FindAuraByName(spellName, playerName)

      if foundName == nil then
        -- This person does not have the buff and will be marked
        playersToMark[playerName] = 0

        -- Only mark the top X
        count = count + 1
        if count >= 5 then break end
      end
    end
  end

  return playersToMark
end

local function GetMarkedPlayers()
  local marks = { [1] = "", [2] = "", [3] = "", [4] = "", [5] = "", [6] = "", [7] = "", [8] = "" }

  local _, _, _, _, maxPlayers = GetInstanceInfo()
  local numPlayers = GetNumGroupMembers()

  local max = numPlayers
  if maxPlayers ~= 0 then
    max = (numPlayers > maxPlayers) and maxPlayers or numPlayers
  end

  for i = 1, max do
    local unit = "raid" .. i
    local index = GetRaidTargetIndex(unit)
    if index ~= nil then
      marks[index] = UnitName(unit)
    end
  end

  return marks
end

local function UpdateMarks()
  local markedPlayers = GetMarkedPlayers()

  local playersToMark = GetPlayersToMark()

  local availableMarks = {}

  -- Go through all marked players and find any which should no longer be marked
  for markIndex, playerName in pairs(markedPlayers) do
    if playersToMark[playerName] ~= nil then
      -- This is a person who has a mark, and should keep it
      playersToMark[playerName] = markIndex
    else
      -- This player no longer needs their mark
      tinsert(availableMarks, { markIndex, playerName })
    end
  end

  -- Get marks for any players who need them
  for playerName, markIndex in pairs(playersToMark) do
    -- Only mark players who don't have a mark
    if markIndex == 0 then
      local data = tremove(availableMarks)

      SetRaidTarget(playerName, data[1])
    end
  end

  -- These marks are no longer needed and should be cleared
  for _, data in pairs(availableMarks) do
    if data[2] ~= "" then
      SetRaidTarget(data[2], 0)
    end
  end

end

function ADDON.UNIT_AURA(self, event, unitTarget)


  -- Only look for auras applied to raid units
  if string.find(unitTarget, "raid") ~= nil then
    -- throttle to 1Hz
    local now = GetTime()
    if (now - 1) < ADDON.lastUpdateMarkTime then
      return
    end
    ADDON.lastUpdateMarkTime = now

    UpdateMarks()
  end
end
