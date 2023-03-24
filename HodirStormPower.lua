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

function UpdateMarks()
  -- Throttle to only run every X sec
  local now = GetTime()
  if (now - 1) < ADDON.lastUpdateMarkTime then
    return
  end
  ADDON.lastUpdateMarkTime = now


  -- Put raid members in this table in priority order (highest prio first)
  local priorityTargets = { "HighestPrio", "Put", "Raid", "Members", "Here", "LowestPrio" }

  local markIndex = 1

  for i, v in pairs(priorityTargets) do

    local spellName = "Storm Power"
    local name = AuraUtil.FindAuraByName(spellName, v)

    if name ~= nil then
      -- Remove the marker, this person has the buff already
      SetRaidTarget(v, 0)
    else
      SetRaidTarget(v, markIndex)
      markIndex = markIndex + 1

      -- Mark the top 5 highest prio targets only
      if markIndex > 5 then
        break
      end
    end
  end
end

function ADDON.UNIT_AURA(self, event, unitTarget)

  -- Only look for auras applied to raid units
  if string.find(unitTarget, "raid") ~= nil then
    UpdateMarks()
  end
end
