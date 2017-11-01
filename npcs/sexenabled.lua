require "/scripts/vec2.lua"
require "/scripts/sexbound/helper.lua"
require "/scripts/sexbound/pregnant.lua"

se = {}

-- Override init
sexbound_oldInit = init
init = function()
  sexbound_oldInit()
  
  se.initMessageHandlers()
  
  pregnant.init()

  self.lustConfig = { damageSourceKind = "lust" }
  
  -- Restore NPC (Tenant)
  if se.hasRespawner() and se.findEntityWithUid(storage.respawner) then
    world.sendEntityMessage(storage.respawner, "transform-into-npc", {uniqueId = entity.uniqueId()})
  end
  
  -- Restore NPC (Companion)
  if se.hasOwnerUuid() and se.findEntityWithUid(storage.ownerUuid) then
    world.sendEntityMessage(storage.ownerUuid, "transform-into-npc", {uniqueId = entity.uniqueId()})
  end
end

-- Override update
sexbound_oldUpdate = update
update = function(dt)
  sexbound_oldUpdate(dt) -- Run the previous version of the function.
  
  se.updateStorage()
  
  se.updateBirthday()
  
  -- Transform into object when status property 'lust' is true
  if (status.statusProperty("lust") == true) then
    status.setStatusProperty("lust", false)
    
    se.transformIntoObject()
  end
  
  -- Handle sex request when status property 'havingSex' is true
  if (status.statusProperty("havingSex") == true) then
    status.setStatusProperty("havingSex", false)
    
    se.handleSexRequest()
  end
  
  -- Updates any current pregnancy
  pregnant.update()
end

se.updateBirthday = function()
  local birthday = status.statusProperty("sexboundBirthday")
  
  if birthday and birthday ~= "default" then
    local babyname, babyGender = "", ""
  
    if npc then
      local babyName   = npc.humanoidIdentity().name
      local babyGender = npc.humanoidIdentity().gender
    end
    
    if (babyGender == "male") then
      babyGender = "^blue;boy^reset;"
    end
    
    if (babyGender == "female") then
      babyGender = "^pink;girl^reset;"
    end
    
    local text = "^green;" .. status.statusProperty("sexboundBirthday").motherName .. "^reset; just gave birth to baby " .. babyGender .. " named ^green;" .. babyName .. "^reset;!"
    
    helper.radioAllPlayers("npcgivingbirth", text) -- Tell all players the news
    
    status.setStatusProperty("sexboundBirthday", "default") -- clear it afterwards
  end
end

--- Restore the NPCs storage parameters
se.updateStorage = function()
  local prevStorage = status.statusProperty("sexboundPrevStorage")
  
  if prevStorage and prevStorage ~= "default" then
    storage = helper.mergeTable(storage, prevStorage)

    status.setStatusProperty("sexboundPrevStorage", "default") -- clear it afterwards
  end
end

se.initMessageHandlers = function()
  message.setHandler("become-pregnant", function(_, _, args)
    storage.pregnant = args
  end)
  
  message.setHandler("se-unload", function(_, _, args)
    se.unloadNPC()
  end)
end

se.handleSexRequest = function(args)
  local position = vec2.floor(entity.position())
  position[2] = position[2] - 3 -- (3 * 8 = 24)
  
  local entityId = world.objectAt(position)

  if (entityId ~= nil) then
    se.sendMessage(entityId, "setup-actor")
  end
end

se.transformIntoObject = function(args)
  -- Attempt to override default lustConfig options
  if (status.statusProperty("lustConfigOverride") ~= "default") then
    self.lustConfig = helper.mergeTable(self.lustConfig, status.statusProperty("lustConfigOverride"))
  end
  
  -- Create an object that resembles the npc at the position
  local position = vec2.floor(entity.position())
  position[2] = position[2] - 2
  
  self.newUniqueId = sb.makeUuid()

  if world.placeObject("sexnode", position, mcontroller.facingDirection(), {uniqueId = self.newUniqueId}) then
    --sb.logInfo(sb.printJson(storage))
  
    -- Check for respawner (tenant)
    if se.hasRespawner() or se.hasOwnerUuid() then
      if se.hasRespawner() and se.findEntityWithUid(storage.respawner) then
        se.sendMessage(self.newUniqueId, "store-actor")
        world.sendEntityMessage(storage.respawner, "transform-into-object", {uniqueId = entity.uniqueId()})
      end
      
      -- Check for crew member
      if se.hasOwnerUuid() and se.findEntityWithUid(storage.ownerUuid) then
        se.splashDamage()
        --world.sendEntityMessage(storage.ownerUuid, "transform-into-object", {uniqueId = entity.uniqueId()})
      end
    else
      se.sendMessage(self.newUniqueId, "store-actor")
      se.unloadNPC()
    end
  else
    se.splashDamage()
  end
end

se.splashDamage = function()
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = 0,
    damageSourceKind = self.lustConfig.damageSourceKind,
    sourceEntityId   = entity.id()
  })
end

se.findEntityWithUid = function(uniqueId)
  if world.findUniqueEntity(uniqueId):result() then return true end
  return false
end

se.hasOwnerUuid = function()
  if storage and storage.ownerUuid then return true end
  return false
end

se.hasRespawner = function()
  if storage and storage.respawner then return true end
  return false
end

se.sendMessage = function(uniqueId, message)
  local data = {
    entityType = entity.entityType(),
    id         = entity.id(),
    identity   = npc.humanoidIdentity(),
    gender     = npc.humanoidIdentity().gender,
    species    = npc.humanoidIdentity().species,
    level      = npc.level(),
    seed       = npc.seed(),
    type       = npc.npcType(),
    uniqueId   = entity.uniqueId()
  }

  -- Preserve storage information
  if (storage) then
    data.storage = storage
  end
  
  -- Send the identifying information to the object to be stored.
  helper.sendMessage(uniqueId, message, data, false)
end

se.tryToSetUniqueId = function(uniqueId, callback)
  if not self.findUniqueId then
    self.findUniqueId = world.findUniqueEntity(uniqueId)
  else
    if (self.findUniqueId:finished()) then
      if not self.findUniqueId:result() then
        if (callback ~= nil) then
          callback(uniqueId)
        end
      end
      
      self.findUniqueId = nil
    end
  end
end

se.unloadNPC = function()
  npc.setDropPools({}) -- prevent loot drop
  
  npc.setDeathParticleBurst(nil) -- prevent death particle effect
  
  npc.setPersistent(false)

  -- Kill the NPC
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = status.resourceMax("health"),
    damageSourceKind = self.lustConfig.damageSourceKind,
    sourceEntityId   = entity.id()
  })
  
  --self.forceDie = true
end