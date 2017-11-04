--- Actor Module.
-- @module actor
actor = {}

actor.data = {
  count = 0,
  list  = {}
}

--- Returns the enabled status of the actor module.
-- @return boolean
actor.isEnabled = function()
  return self.sexboundConfig.actor.enabled
end

--- Clears all actor data and resets the associated global animator tags.
actor.clearActors = function()
  actor.resetAllGlobalTags()

  actor.data.count = 0
  
  actor.data.list  = {}
end

--- Checks if actor data contains any actors.
-- @return boolean
actor.hasActors = function()
  if (actor.data.count > 0) then return true else return false end
end

--- Checks if actor data contains at least one player.
-- @return boolean
actor.hasPlayer = function()
  local result = false

  helper.each(actor.data.list, function(k, v)
    if (v.type ~= nil and v.type == "player") then 
      result = true
      return result
    end
  end)
  
  return result
end

--- Processes gender value.
-- @param gender male, female, or something else (future)
actor.validateGender = function(gender)
  local validatedGender = helper.find(self.sexboundConfig.sex.supportedPlayerGenders, function(v)
    if (gender == v) then return v end
  end)
  
  if not validatedGender then
    return self.sexboundConfig.sex.defaultPlayerGender -- default is 'male'
  else return validatedGender end
end

--- Processes species value.
-- @param species name of species
actor.validateSpecies = function(species)
  local validatedSpecies = helper.find(self.sexboundConfig.sex.supportedPlayerSpecies, function(v)
   if (species == v) then return v end
  end)
  
  if not validatedSpecies then
    return self.sexboundConfig.sex.defaultPlayerSpecies -- default is 'human'
  else return validatedSpecies end
end

--- Resets an specified actor.
-- @param args The actor's identity data.
-- @param actorNumber The actor's index in the actor data list.
actor.resetActor = function(args, actorNumber)
  local defaultPath = "/artwork/humanoid/default.png:default"
  
  local directives = {}
  directives.body = args.identity.bodyDirectives or ""
  directives.hair = args.identity.hairDirectives or ""
  directives.facialHair = args.identity.facialHairDirectives or ""
  directives.facialMask = args.identity.facialMaskDirectives or ""
  
  local gender  = actor.validateGender(args.gender)
  
  local species = actor.validateSpecies(args.species)

  local parts = {}
  
  local positionName = ""

  local pregnantConfig = nil
  
  local role    = "actor" .. actorNumber
  
  if (animator.animationState("sex") == "idle") then
    positionName = "idle"
  else
    positionName = position.selectedSexPosition().animationState
  end

  -- Set moan based on actor 2 gender
  if actor.data.count == 2 and actorNumber == 2 then 
    sex.setMoanGender(gender)
  end
  
  -- Ensure required identity values have a value
  args.identity.hairFolder       = args.identity.hairFolder       or args.identity.hairGroup
  args.identity.facialHairFolder = args.identity.facialHairFolder or args.identity.facialHairGroup
  args.identity.facialMaskFolder = args.identity.facialMaskFolder or args.identity.facialMaskGroup
  args.identity.hairType         = args.identity.hairType         or "1"
  args.identity.facialHairType   = args.identity.facialHairType   or "1"
  args.identity.facialMaskType   = args.identity.facialMaskType   or "1"

  parts.climax = "/artwork/humanoid/climax/climax-" .. positionName .. ".png:climax"

  if emote.data.list[actorNumber] then
    parts.emote = "/humanoid/" .. species .. "/emote.png:" .. emote.data.list[actorNumber]
  else
    parts.emote = defaultPath
  end
  
  if args.storage then
    pregnantConfig = args.storage.pregnant
  end
  
  local showPregnant = false
  
  -- Show pregnant player
  if args.type ~= "player" and self.sexboundConfig.pregnant.showPregnantOther then
    showPregnant = true
  else
    if self.sexboundConfig.pregnant.showPregnantPlayer then
      showPregnant = true
    end
  end
  
  if showPregnant and pregnantConfig and pregnantConfig.isPregnant then
    parts.body = "/artwork/humanoid/" .. role .. "/" .. species  .. "/body_" .. gender .. "_pregnant.png:" .. positionName
  else
    parts.body = "/artwork/humanoid/" .. role .. "/" .. species  .. "/body_" .. gender .. ".png:" .. positionName
  end
  
  parts.head = "/artwork/humanoid/" .. role .. "/" .. species .. "/head_" .. gender .. ".png:normal" .. directives.body .. directives.hair
  
  parts.armFront = "/artwork/humanoid/" .. role .. "/" .. species .. "/arm_front.png:" .. positionName
  
  parts.armBack  = "/artwork/humanoid/" .. role .. "/" .. species .. "/arm_back.png:" .. positionName
  
  if args.identity.facialHairType ~= "" then
    parts.facialHair = "/humanoid/" .. species .. "/" .. args.identity.facialHairFolder .. "/" .. args.identity.facialHairType .. ".png:normal" .. directives.facialHair
  else
    parts.facialHair = defaultPath
  end
  
  if args.identity.facialMaskType ~= "" then
    parts.facialMask = "/humanoid/" .. species .. "/" .. args.identity.facialMaskFolder .. "/" .. args.identity.facialMaskType .. ".png:normal" .. directives.facialMask
  else
    parts.facialMask = defaultPath
  end
  
  if args.identity.hairType ~= nil then
    parts.hair = "/humanoid/" .. species .. "/" .. args.identity.hairFolder .. "/" .. args.identity.hairType .. ".png:normal" .. directives.body .. directives.hair
  else
    parts.hair = defaultPath
  end
  
  animator.setGlobalTag("part-" .. role .. "-body",        parts.body)
  animator.setGlobalTag("part-" .. role .. "-climax",      parts.climax)
  animator.setGlobalTag("part-" .. role .. "-emote",       parts.emote)
  animator.setGlobalTag("part-" .. role .. "-head",        parts.head)
  animator.setGlobalTag("part-" .. role .. "-arm-front",   parts.armFront)
  animator.setGlobalTag("part-" .. role .. "-arm-back",    parts.armBack)
  animator.setGlobalTag("part-" .. role .. "-facial-hair", parts.facialHair)
  animator.setGlobalTag("part-" .. role .. "-facial-mask", parts.facialMask)
  animator.setGlobalTag("part-" .. role .. "-hair",        parts.hair)
  
  animator.setGlobalTag(role .. "-bodyDirectives",   args.identity.bodyDirectives)
  animator.setGlobalTag(role .. "-hairDirectives",   args.identity.hairDirectives)
end

--- Resets all actors found in the actor data list.
actor.resetAllActors = function()
  -- Reset actors' global animator tags
  actor.resetAllGlobalTags()
  
  helper.each(actor.data.list, function(k, v)
    actor.resetActor(v, k)
  end)
end

--- Resets all global animator tags for all actors.
actor.resetAllGlobalTags = function()
  helper.each(actor.data.list, function(k, v)
    local role = "actor" .. k
    local default = "/artwork/default.png:default"
    
    animator.setGlobalTag("part-" .. role .. "-arm-back",    default)
    animator.setGlobalTag("part-" .. role .. "-arm-front",   default)
    animator.setGlobalTag("part-" .. role .. "-body",        default)
    animator.setGlobalTag("part-" .. role .. "-emote",       default)
    animator.setGlobalTag("part-" .. role .. "-head",        default)
    animator.setGlobalTag("part-" .. role .. "-hair",        default)
    animator.setGlobalTag("part-" .. role .. "-facial-hair", default)
    animator.setGlobalTag("part-" .. role .. "-facial-mask", default)
  end)
end

--- Resets all transformations to animated actor parts.
actor.resetTransformationGroups = function()
  helper.each(actor.data.list, function(k1, v1)
    helper.each({"ArmBack", "ArmFront", "Body", "Climax", "Emote", "FacialHair", "FacialMask", "Hair", "Head"}, function(k2, v2)
      if animator.hasTransformationGroup("actor" .. k1 .. v2) then
        animator.resetTransformationGroup("actor" .. k1 .. v2)
      end
    end)
  end)
end

--- Setup new actor.
-- @param args Table of identifiying data
-- @param storeActor True := Store actor data in this object.
actor.setupActor = function(args, storeActor)
  actor.data.count = actor.data.count + 1
  
  actor.data.list[ actor.data.count ] = args
  
  -- Permenantly store first actor if it is an 'npc' entity type
  if (storeActor) then
    storage.npc  = args
    sex.data.npc = args
    actor.data.list[ actor.data.count ].isSexNode = true
    
    local pregnant = actor.data.list[ actor.data.count ].storage.pregant
    
    if pregnant and pregnant.isPregnant then
      storage.pregnant = pregnant
    end
  else
    actor.data.list[ actor.data.count ].isSexNode = false
  end
  
  if actor.data.list[ actor.data.count ].type == "player" then
    world.sendEntityMessage(args.id, "retrieve-storage", {sourceId = entity.id(), actorId = args.id})
  end
  
  if (actor.data.list[ actor.data.count ].identity == nil) then
    local identity = {}
  
    -- Check species is supported
    local species = self.sexboundConfig.sex.defaultPlayerSpecies -- default is 'human'
    -- Check if species is supported by the mod
    species = helper.find(self.sexboundConfig.sex.supportedPlayerSpecies, function(speciesName)
     if (args.species == speciesName) then return args.species end
    end)
    
    local speciesConfig = root.assetJson("/species/" .. species .. ".species")
    
    identity.bodyDirectives = ""
    
    if (speciesConfig.bodyColor[1] ~= "") then
      helper.each(helper.randomChoice(speciesConfig.bodyColor), function(k, v)
        identity.bodyDirectives = identity.bodyDirectives .. "?replace=" .. k .. "=" .. v 
      end)
    end
    
    if (speciesConfig.undyColor[1] ~= "") then
      helper.each(helper.randomChoice(speciesConfig.undyColor), function(k, v)
        identity.bodyDirectives = identity.bodyDirectives .. "?replace=" .. k .. "=" .. v 
      end)
    end
    
    identity.hairDirectives = ""
    
    if (speciesConfig.hairColor[1] ~= "") then
      helper.each(helper.randomChoice(speciesConfig.hairColor), function(k, v)
        identity.hairDirectives = identity.hairDirectives .. "?replace=" .. k .. "=" .. v 
      end)
    end
    
    --identity.facialHairDirectives = identity.bodyDirectives .. identity.hairDirectives
    --identity.facialMaskDirectives = identity.bodyDirectives
    
    local genderCount = 1
    
    if (args.gender == "female") then genderCount = 2 end
    
    local hair = speciesConfig.genders[genderCount].hair
    if not isEmpty(hair) then identity.hairType = helper.randomChoice(hair) end
    
    local facialHair = speciesConfig.genders[genderCount].facialHair
    if not isEmpty(facialHair) then identity.facialHairType = helper.randomChoice(facialHair) end
    
    local facialMask = speciesConfig.genders[genderCount].facialMask
    if not isEmpty(facialMask) then identity.facialMaskType = helper.randomChoice(facialMask) end
    
    actor.data.list[ actor.data.count ].identity = identity
  end
  
  -- Swap roles between male and female by default
  if (actor.data.count == 2) then
    if (actor.data.list[1].gender == "female" and actor.data.list[2].gender == "male") then
     actor.switchRole() -- True to skip reset
    end
  end
  
  -- Reset the actors
  actor.resetAllActors()
end

--- Shifts the actors in actor data list to the right.
-- @param skipReset True := Skip reseting all actors.
actor.switchRole = function(skipReset)
  table.insert(actor.data.list, 1, table.remove(actor.data.list, #actor.data.list)) -- Shift actors
  
  if not skipReset then
    actor.resetAllActors()
  end
end