--- Sex Talk Module.
-- @module sextalk
sextalk = {}

require "/scripts/sexbound/helper.lua"

--- Initializes the sextalk module.
sextalk.init = function ()
  -- Handle request for current dialog
  message.setHandler("requestDialog", function()
    return sextalk.getCurrentDialog()
  end)
  
  -- Load the dialog config file
  self.dialog = root.assetJson(self.sexboundConfig.sextalk.dialog)

  self.currentDialog = "*Silent*"
  
  local animationState = animator.animationState("sex")
  
  -- Select initial dialog
  sextalk.selectNext(animationState)
end

--- Returns the currently selected dialog.
--@return string: current dialog text
sextalk.getCurrentDialog = function()
  return self.currentDialog
end

--- Returns the current method used to select dialog.
--@return string: method name
sextalk.getMethod = function()
  return self.sexboundConfig.sextalk.method
end

--- Returns the current mode used to select dialog.
--@return string: mode name
sextalk.getMode = function()
  return self.sexboundConfig.sextalk.mode
end

--- Returns the trigger used to select dialog from dialog file.
-- @return string: trigger name
sextalk.getTrigger = function()
  return self.sexboundConfig.sextalk.trigger
end

--- Returns the enabled status of the sex talk module.
-- @return boolean enabled
sextalk.isEnabled = function()
  return self.sexboundConfig.sextalk.enabled
end

--- Private: Selects and set a new random dialog.
--@param choices from dialog config
local function selectRandom(choices)
  if not sextalk.isEnabled() then return nil end

  local currentDialog = sextalk.getCurrentDialog()
  local selection = ""
  
  if not isEmpty(choices) then
    -- Try not to repeat the last dialog
    for i=1,5 do
      selection = helper.randomChoice(choices)
      
      if (selection ~= currentDialog) then
        break
      end
    end
  else
    selection = "*Speechless*"
  end
  
  return selection
end

--- Returns the current dialog.
--@param state The state to retrieve the dialog.
sextalk.selectNext = function(state)
  if not sextalk.isEnabled() then return nil end
  
  -- If state not found in the dialog file
  if (self.dialog[state] == nil) then return self.currentDialog end
  
  local actors = sex.getActors()

  local actor1Species = "default"
  local actor2Species = "default"
  
  local actor1PossessivePronouns = {firstPerson = "MY", secondPerson = "", thirdPerson = ""}
  
  local actor2PossessivePronouns = {firstPerson = "MY", secondPerson = "", thirdPerson = ""}
  
  local actor1Name    = ""
  local actor2Name    = ""
  local NPCName       = "^green;" .. sextalk.assignNPCName(actors) .. "^white;"
  local NPCPossessivePronouns = sextalk.assignNPCPossessivePronouns(actors)
  
  local dialogPool = {}
  
  -- Append actor 1 (default species) vs actor 2 (default species)
  util.appendLists(dialogPool, self.dialog[state].default.default)
  
  if actors and actors[1] and actors[1].species then
    actor1Species = actors[1].species
    
    actor1Name    = "^green;" .. sextalk.assignActorName(actors[1]) .. "^white;"

    actor1PossessivePronouns = sextalk.assignActorPossessivePronouns(actors[1])
  end
  
  if actors and actors[2] and actors[2].species then
    actor2Species = actors[2].species
    
    actor2Name = "^green;" .. sextalk.assignActorName(actors[2]) .. "^white;"
    
    actor2PossessivePronouns = sextalk.assignActorPossessivePronouns(actors[2])
    
    -- Append actor 1 (default species) vs actor 2 (specific species)
    if self.dialog[state].default and self.dialog[state].default[actor2Species] then
      util.appendLists(dialogPool, self.dialog[state].default[actor2Species])
    end
    
    -- Append actor 1 (specific species) vs actor 2 (specific species)
    if self.dialog[state][actor1Species] and self.dialog[state][actor1Species][actor2Species] then
      util.appendLists(dialogPool, self.dialog[state][actor1Species][actor2Species])
    end
  end
  
  if actors and actors[2] and actors[2].storage and actors[2].storage.pregnant and actors[2].storage.pregnant.isPregnant then
    if self.dialog[state] and self.dialog[state].default.default_pregnant then
      util.appendLists(dialogPool, self.dialog[state].default.default_pregnant)
    end
  
    if self.dialog[state] and self.dialog[state][actor1Species] and self.dialog[state][actor1Species].default_pregnant then
      util.appendLists(dialogPool, self.dialog[state][actor1Species].default_pregnant)
    end
    
    if self.dialog[state] and self.dialog[state][actor1Species] and self.dialog[state][actor1Species][actors[2].species .. "_pregnant"] then
      util.appendLists(dialogPool, self.dialog[state][actor1Species][actors[2].species .. "_pregnant"])
    end
  end
  
  local selection = selectRandom(dialogPool)
  
  selection = util.replaceTag(selection, "actor1PossessivePronoun1", actor1PossessivePronouns.firstPerson)
  selection = util.replaceTag(selection, "actor1PossessivePronoun2", actor1PossessivePronouns.secondPerson)
  selection = util.replaceTag(selection, "actor1PossessivePronoun3", actor1PossessivePronouns.thirdPerson)
  selection = util.replaceTag(selection, "actor2PossessivePronoun1", actor2PossessivePronouns.firstPerson)
  selection = util.replaceTag(selection, "actor2PossessivePronoun2", actor2PossessivePronouns.secondPerson)
  selection = util.replaceTag(selection, "actor2PossessivePronoun3", actor2PossessivePronouns.thirdPerson)
  
  selection = util.replaceTag(selection, "actor1Name", actor1Name)
  selection = util.replaceTag(selection, "actor2Name", actor2Name)
  
  selection = util.replaceTag(selection, "NPCName", NPCName)
  
  selection = util.replaceTag(selection, "NPCPossessivePronoun1", NPCPossessivePronouns.firstPerson)
  selection = util.replaceTag(selection, "NPCPossessivePronoun2", NPCPossessivePronouns.secondPerson)
  selection = util.replaceTag(selection, "NPCPossessivePronoun3", NPCPossessivePronouns.thirdPerson)
  
  sextalk.setCurrentDialog(selection)
  
  -- Select and return a random dialog choice.
  return selection
end

sextalk.assignActorName = function(actor)
  if actor.type == "player" then
    return "YOU"
  end

  if actor.identity and actor.identity.name then
    return actor.identity.name
  end
  
  return "UNKNOWN"
end

sextalk.assignNPCName = function(actors)
  local NPCName = "UNKNOWN"
  
  util.each(actors, function(k, v)
    if v.type ~= "player" and v.identity and v.identity.name then
      NPCName = v.identity.name
    end
  end)
  
  return NPCName
end

sextalk.assignNPCPossessivePronouns = function(actors)
  local pronouns = {firstPerson = "MY", secondPerson = "", thirdPerson = ""}
  
  util.each(actors, function(k, v)
    if v.type ~= "player" then
      pronouns = sextalk.assignActorPossessivePronouns(v)
    end
  end)
  
  return pronouns
end

sextalk.assignActorPossessivePronouns = function(actor)
  local pronouns = {firstPerson = "MY", secondPerson = "", thirdPerson = ""}

  if actor.type == "player" then
    pronouns.secondPerson = "YOUR"
  end
  
  if actor.gender == "male" or actor.gender == "female" then
    if actor.gender == "male" then
      pronouns.thirdPerson = "HIS"
    end
    
    if actor.gender == "female" then
      pronouns.thirdPerson = "HER"
    end
  else
    pronouns.thirdPerson = "THIER"
  end

  return pronouns
end

---Outputs the dialog via the entity's say function.
--@param state The state to retrieve the dialog.
sextalk.sayNext = function(state)
  if not sextalk.isEnabled() then return nil end

  local currentDialog = sextalk.selectNext(state)
  
  local method = sextalk.getMethod()
  
  if (method == "chatbubblePortrait") then
    object.sayPortrait( currentDialog, portrait.getCurrentPortrait() )
  end
  
  if (method == "chatbubble") then
    object.say(currentDialog)
  end
end

--- Sets the currentDialog.
--@param newDialog String: Dialog text.
sextalk.setCurrentDialog = function(newDialog)
  -- Set the previous dialog before setting a new dialog
  self.previousDialog = self.currentDialog

  self.currentDialog = newDialog
  
  return self.currentDialog
end
