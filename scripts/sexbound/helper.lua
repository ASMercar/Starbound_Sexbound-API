---Helper Module.
-- @module helper
helper = {}

require "/scripts/util.lua"

---Wrapper function for util.clamp
-- @param value Numerical value to operate on
-- @param min Minimum value to return
-- @param max Maximum value to return
helper.clamp = function(value, min, max)
  return util.clamp(value, min, max)
end

--- Counts elements in table and returns the value.
-- @param t List of elements.
helper.count = function(t)
  if not t then return nil end
  
  local count = 0
  
  helper.each(t, function(k, v)
    count = count + 1
  end)
  
  return count
end

---Wrapper function for util.each
-- @param t Data as table
-- @param callback Callback function. Takes arguments k = key and v = value.
helper.each = function(t, callback)
  return util.each(t, callback)
end

---Wrapper function for util.find
-- @param t Data as table
-- @param predicate
-- @param index
helper.find = function(t, predicate, index)
  return util.find(t, predicate, index)
end

---Wrapper function for util.mergeTable
-- @param t1 Data for table 1
-- @param t2 Data for table 2
helper.mergeTable = function(t1, t2)
  return util.mergeTable(t1, t2)
end

--- Sends a radio message to all players in the world.
-- @param messageId the message id as a string value
-- @param text the message to send as a string value
helper.radioAllPlayers = function(messageId, text)
  helper.each(world.players(), function(k, v)
    helper.radioPlayer(v, messageId, text)
  end)
end

--- Sends a radio message to all other players in the world.
-- @param playerId the specific player id to target
-- @param messageId the message id as a string value
-- @param text the message to send as a string value
helper.radioAllOtherPlayers = function(playerId, messageId, text)
  helper.each(world.players(), function(k, v)
    if playerId ~= v then
      helper.radioPlayer(v, messageId, text)
    end
  end)
end

--- Sends a radio message to a specific player in the world.
-- @param playerId the specific player id to target
-- @param messageId the message id as a string value
-- @param text the message to send as a string value
helper.radioPlayer = function(playerId, messageId, text)
  world.sendEntityMessage(playerId, "queueRadioMessage", {
    messageId = messageId,
    unique    = false,
    text      = text
  })
end

---Wrapper function for util.randomChoice
-- @param options table
helper.randomChoice = function(options)
  return util.randomChoice(options)
end

---Wrapper function for util.randomDirection
helper.randomDirection = function()
  return util.randomDirection()
end

---Wrapper function for util.randomInRange
-- @param numberRange Range of numbers
helper.randomInRange = function(numberRange)
  return util.randomInRange(numberRange)
end

---Wrapper function for util.randomIntInRange
-- @param numberRange Range of numbers
helper.randomIntInRange = function(numberRange)
  return util.randomIntInRange(numberRange)
end

---Wrapper function for util.replaceTag
-- @param data Data to scan for tags
-- @param tagName String The name of the tagName
-- @param tagValue String value to assign to the tag
helper.replaceTag = function(data, tagName, tagValue)
  return util.replaceTag(data, tagName, tagValue)
end

---Creates and stores a new message.
-- @param message reference name of the message.
helper.resetMessenger = function(message)
  self.messenger[message] = {promise = nil, busy = false}
end

---Handles sending a message to a specified entity.
-- @param entityId String: A remote entity id or unique id.
-- @param message String: The message to send the remote entity.
-- @param args Table: Arguments to send to th remote entity.
-- @param wait Boolean: true = wait for response before sending again. false = send without waiting
helper.sendMessage = function(entityId, message, args, wait)
  if (self.messenger == nil) then self.messenger = {} end

  if (wait == nil) then wait = false end

  -- Prepare new message to store data
  if (self.messenger[message] == nil) then
    helper.resetMessenger(message)
  end
  
  -- If not already busy then send message
  if not (self.messenger[message].busy) then
    self.messenger[message].promise = world.sendEntityMessage(entityId, message, args)
    
    self.messenger[message].busy = wait
  end
end

---Handles response from the source entity.
-- @param message String: The message to send the remote entity.
-- @param callback
helper.updateMessage = function(message, callback)
  if (self.messenger == nil) then self.messenger = {} end

  if (self.messenger[message] == nil) then return end

  local promise = self.messenger[message].promise

  if (promise and promise:finished()) then
    local result = promise:result()
    
    helper.resetMessenger(message)
    
    callback(result)
  end
end

helper.parsePortraitData = function(species, gender, data)
  local identity = {
    bodyDirectives = "",
    emoteDirectives = "",
    facialHairDirectives = "",
    facialHairFolder = "",
    facialHairGroup = "",
    facialHairType = "",
    facialMaskDirectives = "",
    facialMaskFolder = "",
    facialMaskGroup = "",
    facialMaskType = "",
    hairFolder = "hair",
    hairGroup = "hair",
    hairType = "1",
    hairDirectives = ""
  }

  identity.gender = gender
  
  local genderNumber = 1
  
  if gender == "female" then
    genderNumber = 2
  end
  
  identity.species = species
  
  local speciesConfig = nil
  
  if not pcall(function()
    speciesConfig = root.assetJson("/species/" .. species .. ".species")
    identity.facialHairGroup = speciesConfig.genders[ genderNumber ].facialHairGroup
    identity.facialMaskGroup = speciesConfig.genders[ genderNumber ].facialMaskGroup
  end) then
    sb.logInfo("Could not find species config file.")
  end
  
  helper.each(data, function(k, v)
    -- Try to find facial mask
    if identity.facialMaskGroup ~= nil and identity.facialMaskGroup ~= "" and string.find(v.image, "/" .. identity.facialMaskGroup) ~= nil then
      identity.facialMaskFolder, identity.facialMaskType  = string.match(v.image, '^.*/(' .. identity.facialMaskGroup .. '.*)/(.*)%.png:.-$')
      identity.facialMaskDirectives = helper.filterReplace(v.image)
    end
    
    -- Try to find facial hair
    if identity.facialHairGroup ~= nil and identity.facialHairGroup ~= "" and string.find(v.image, "/" .. identity.facialHairGroup) ~= nil then
      identity.facialHairFolder, identity.facialHairType  = string.match(v.image, '^.*/(' .. identity.facialHairGroup .. '.*)/(.*)%.png:.-$')
      identity.facialHairDirectives = helper.filterReplace(v.image)
    end
    
    -- Try to find body identity
    if (string.find(v.image, "body.png") ~= nil) then
      identity.bodyDirectives = string.match(v.image, '%?replace.*')
    end
  
    -- Try to find emote identity
    if (string.find(v.image, "emote.png") ~= nil) then
      identity.emoteDirectives = helper.filterReplace(v.image)
    end
    
    -- Try to find hair identity
    if (string.find(v.image, "/hair") ~= nil) then
      identity.hairFolder, identity.hairType = string.match(v.image, '^.*/(hair.*)/(.*)%.png:.-$')
      
      identity.hairDirectives = helper.filterReplace(v.image)
    end
  end)

  return identity
end

helper.filterReplace = function(image)
  if (string.find(image, "?addmask")) then
    if (string.match(image, '^.*(%?replace.*%?replace.*)%?addmask.-$')) then
      return string.match(image, '^.*(%?replace.*%?replace.*)%?addmask.-$')
    else
      return string.match(image, '^.*(%?replace.*)%?addmask.-$')
    end
  else
    if (string.match(image, '^.*(%?replace.*%?replace.*)')) then
      return string.match(image, '^.*(%?replace.*%?replace.*)')
    else
      return string.match(image, '^.*(%?replace.*)')
    end
  end
  
  return ""
end
