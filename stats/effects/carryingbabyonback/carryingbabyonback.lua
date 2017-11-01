function init()
  --self.isCrouching = false

  --setFacingDirection(mcontroller.facingDirection())
  
  if storage.babyGrowthSpurt == nil then
    storage.babyGrowthSpurt = world.day() + 3
  end
end

function update(dt)
  storage.babyTimer = storage.babyTimer + dt

  if world.day() >= storage.babyGrowthSpurt and not storage.fullyGrown then
    if npc then 
      world.spawnNpc(entity.position(), npc.species(), npc.npcType(), 1) -- level 1
    end
    
    if player then
      world.spawnNpc(entity.position(), player.species(), "villager", 1) -- level 1
    end
    
    storage.fullyGrown = true
  end
  
  --setFacingDirection(mcontroller.facingDirection())
  
  --if not self.isCrouching and mcontroller.crouching() then
    --self.isCrouching = true
  
    --animator.translateTransformationGroup("body", {0.0, -0.625})
    
    --animator.burstParticleEmitter("emotehappy")
  --end
  
  --if self.isCrouching and not mcontroller.crouching() then
    --self.isCrouching = false
    
    --animator.resetTransformationGroup("body")
  --end
end

function setFacingDirection(direction)
  if direction < 0 then
    animator.setGlobalTag("facingDirection", "left")
  else 
    animator.setGlobalTag("facingDirection", "right")
  end
end