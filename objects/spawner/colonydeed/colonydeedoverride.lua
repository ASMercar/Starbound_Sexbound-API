-- Override the init function. First defined by 'colonydeed.lua'
sexbound_oldInit = init
function init()
  sexbound_oldInit() -- Call the old init function. 
  
  message.setHandler("transform-into-object", function(_, _, args)
    if storage and storage.occupier then
      for i,tenant in ipairs(storage.occupier.tenants) do
        if tenant.uniqueId == args.uniqueId then
          storage.occupier.tenants[i].transformIntoObject = true
          
          world.sendEntityMessage(args.uniqueId, "se-unload", nil)
        end
      end
    end

    return true
  end)
  
  message.setHandler("transform-into-npc", function(_, _, args)
    if storage and storage.occupier then
      for i,tenant in ipairs(storage.occupier.tenants) do
        if tenant.uniqueId == args.uniqueId then
          storage.occupier.tenants[i].transformIntoObject = false
        end
      end
    end
    
    return true
  end)
end

-- Override the anyTenantsDead function. First defined by 'colonydeed.lua'
sexbound_oldAnyTenantsDead = anyTenantsDead
function anyTenantsDead()
  for _,tenant in ipairs(storage.occupier.tenants) do
    if not isTransformedIntoObject(tenant) then
      return sexbound_oldAnyTenantsDead()
    end
  end
  return false
end

function isTransformedIntoObject(tenant)
  if tenant.transformIntoObject == nil then return false end
  
  if tenant.transformIntoObject then return true end
  
  return false
end