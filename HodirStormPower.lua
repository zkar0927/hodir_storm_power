local ADDON = CreateFrame("Frame", "HodirStormPower", UIParent)

ADDON:SetScript("OnEvent", function(self, event, ...)
  return self[event](self, event, ...)
end)

ADDON:RegisterEvent("PLAYER_LOGIN")

function ADDON.PLAYER_LOGIN()
  if not ADDON.initialized then
    ADDON.initialized = true

    ADDON:RegisterEvent("ENCOUNTER_START")
    ADDON:RegisterEvent("ENCOUNTER_END")

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

  local priorityTargets = { "High Prio", "MediumPrio", "LowPrio" }

  local playersToMark = {}
  local count = 0

  for i, playerName in ipairs(priorityTargets) do
    if UnitExists(playerName) then

      local spellName = "Storm Power"
      local foundName = AuraUtil.FindAuraByName(spellName, playerName)

      if foundName == nil then
        -- This person does not have the buff and will be marked
        playersToMark[playerName] = 0

        -- Only mark the top X
        count = count + 1
        if count >= 2 then break end
      end
    end
  end

  return playersToMark
end

local function GetMarkedPlayers()
  local marks = { [1] = "", [2] = "", [3] = "", [4] = "", [5] = "", [6] = "", [7] = "", [8] = "" }

  local _, _, _, _, maxPlayers = GetInstanceInfo()
  local numPlayers = GetNumGroupMembers()

  -- Only look through the max number of players per raid size
  -- Ex: if there are 12 people in a 10man raid, only look through the first 10
  -- However, if there are 8, just look through those 8
  local max = numPlayers
  if maxPlayers ~= 0 then
    max = (numPlayers > maxPlayers) and maxPlayers or numPlayers
  end

  -- Loop through every person in raid and find which raid marker they have
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

  -- Will hold the marks available to be (re)used
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

  -- throttle to 1Hz
  local now = GetTime()
  if now < (ADDON.lastUpdateMarkTime + 1) then
    return
  end
  ADDON.lastUpdateMarkTime = now

  -- Only look for auras applied to raid units
  if string.find(unitTarget, "raid") ~= nil then
    UpdateMarks()
  end
end
