local Logger = require("common.logger")
local Utils = require("common.utils")

local Core = {}
Core.__index = Core

--- Core options
--- @tparam name The entity named
--- @tparam entity The entity
--- @treturn self
function Core.new(options)
  local self = setmetatable({}, Core)
  self.name = options.name
  self.log = Logger('core', options.name)
  -- require(string.format('modules.%s.entity', options.name))
  self.entity = options.entity
  return self
end

--- Core:createOne request
--- @tparam[opt] payload An item to create
--- @treturn Item
function Core:createOne(request)
  self.log:info('[CREATE_ONE] [ %s ] payload=%o', self.name, request.payload)
  local is_exist = self.entity:findOneBy(request.payload)
  if is_exist then
    self.log:error('[CREATE_ONE] [ %s ], the entity already exist payload=%o ', self.name, request.payload)
    -- throw new Conflict(`already-exists-${this.name}`)
  end
  return self.entity:save(request.payload)
end

--- Core:createMany request
--- @tparam[opt] payload An array of items to create
--- @treturn [results]
  --- @treturn [results.created_entities] An array of items
  --- @treturn [results.existing_entities] An array of items
function Core:createMany(request)
  self.log:info('[CREATE_MANY] [ %s ] payload=%o', self.name, request.payload)
  local where = request.payload
  local results = { created_entities = {}, existing_entities = {} }
  local entities = self.entity:find({ where = where })

  if #entities > 0 then
    self.log:error('[CREATE_MANY] [ %s ], entities already exist existing_entities=%o', self.name, entities)
    results.existing_entities = entities
  end

  results.created_entities = {}
  for _, entity in ipairs(request.payload) do
    local found = false
    for _, existingEntity in ipairs(entities) do
      if entity == existingEntity then
        found = true
        break
      end
    end
    if not found then
      table.insert(results.created_entities, entity)
    end
  end

  return results
end

--- Core:read request
--- @tparam [query]
--- @tparam [query.filters]
--- @tparam[opt] [query.options] fields
--- @treturn item || nil
function Core:read(request)
  local where = request.query and request.query.filters or {}
  local options = request.query and request.query.options or {}
  self.log:info('[READ] [ %s ] where=%o', self.name, where)
  return self.entity:findOneBy(Utils.mergeTables(where, options))
end

--- Core:list request
--- @tparam [query]
--- @tparam[opt] [query.filters] key of entity || 
  --- @tparam[opt] $in (string || integer)[]
  --- @tparam[opt] $eq string || integer || Date
  --- @tparam[opt] $exists boolean
  --- @tparam[opt] $gt integer || Date
  --- @tparam[opt] $gte integer || Date
  --- @tparam[opt] $lt integer || Date
  --- @tparam[opt] $lte integer || Date
  --- @tparam[opt] $or Array of [key in Entity] Entity[key] || query.filters
--- @tparam[opt] [query.options] fields
--- @tparam[opt] [query.options.fields] string
--- @tparam[opt] [query.options.skip] integer
--- @tparam[opt] [query.options.limit] integer
--- @tparam[opt] [query.options.page] integer
--- @tparam[opt] [query.options.sort] "ASC" || "DESC" || "asc" || "desc" || 1 || -1
--- @treturn [results]
  --- @treturn [results.count] integer
  --- @treturn [results.data] An array of items
  --- @treturn [results.options]
    --- @treturn [results.options.fields] string
    --- @treturn [results.options.skip] integer
    --- @treturn [results.options.limit] integer
    --- @treturn [results.options.page] integer
  --- @treturn [results.pagination]
    --- @treturn [results.pagination.current_page] integer
    --- @treturn [results.pagination.total_pages] integer
function Core:list(request)
  local filters = request.query and request.query.filters or {}
  local options = request.query and request.query.options or {}
  local where = Utils.parseQueryToSQL(filters)
  local fields = options.fields or '*'
  local page = options.page or 1
  local take = options.limit or 15
  local order = options.sort or ''
  local skip = (page - 1) * take
  self.log:info('[LIST] [ %s ] request=%o', self.name, request)
  local selected_fields = fields and #fields > 0 and fields or '*'
  local query_count = ('SELECT COUNT(1) AS cnt FROM %s %s'):format(self.name, where)
  local query_find = ('SELECT %s FROM %s %s%s LIMIT %d OFFSET %d'):format(selected_fields, self.name, where, order ~= '' and (' ORDER BY ' .. order) or '', take, skip)
  self.log:info('[LIST] [ %s ] query_count=%s query_find=%s', self.name, query_count, query_find)
  local count, data = self.entity:query(query_count), self.entity:query(query_find)
  local total_pages = math.ceil(count[0].cnt / take)
  return {
    count = count[0].cnt,
    data = data,
    options = {
      skip = skip,
      limit = take,
      sort = order,
    },
    pagination = {
      current_page = page,
      total_pages = total_pages,
    },
  }
end

--- Core:updateOne request
--- @tparam payload An item to update
--- @tparam[opt] [query]
--- @tparam[opt] [query.options]
  --- @tparam[opt] data any
  --- @tparam[opt] listeners boolean
  --- @tparam[opt] transaction boolean
  --- @tparam[opt] chunk integer
  --- @tparam[opt] reload boolean
--- @treturn Item
function Core:updateOne(request)
  self.log:info('[UPDATE_ONE] [ %s ] payload=%o opts=%o', request.payload, request.query and request.query.options)
  local updatable_entity = self.entity:findOneBy(request.payload)

  if not updatable_entity then
    self.log:error('[UPDATE_ONE] [ %s ], the entity does not exist entity_to_update=%o ', self.name, request.payload)
    -- throw new NotFound(`do-not-exist-${this.name}`)
  end
  return self.entity:save(request.payload, request.query and request.query.options)
end

--- Core:updateMany request
--- @tparam payload An array of items
--- @tparam[opt] [query]
--- @tparam[opt] [query.options]
  --- @tparam[opt] data any
  --- @tparam[opt] listeners boolean
  --- @tparam[opt] transaction boolean
  --- @tparam[opt] chunk integer
  --- @tparam[opt] reload boolean
--- @treturn [results]
--- @treturn [results.missing_entities] An array of items
--- @treturn [results.upserted_entities] An array of items
function Core:updateMany(request)
  self.log:info('[UPDATE_MANY] [ %s ] payload=%o opts=%o', self.name, request.payload, request.query and request.query.options)
  local where = request.payload
  local results = { missing_entities = {}, upserted_entities = {} }
  local updatableEntities = self.entity:find({ where = where })
  local existingEntitiesToUpdate = {}
  for _, entity in ipairs(request.payload) do
    for _, updatableEntity in ipairs(updatableEntities) do
      if entity == updatableEntity then
        table.insert(existingEntitiesToUpdate, entity)
        break
      end
    end
  end

  if #existingEntitiesToUpdate ~= #request.payload then
    results.missing_entities = {}
    for _, entity in ipairs(request.payload) do
      local found = false
      for _, updatableEntity in ipairs(updatableEntities) do
        if entity == updatableEntity then
          found = true
          break
        end
      end
      if not found then
        table.insert(results.missing_entities, entity)
      end
    end
  else
    results.upserted_entities = self.entity:save(existingEntitiesToUpdate, request.query and request.query.options)
    for _, entityToUpdate in ipairs(request.payload) do
      local found = false
      for _, updatableEntity in ipairs(updatableEntities) do
        if entityToUpdate == updatableEntity then
          found = true
          break
        end
      end
      if not found then
        self.log:error('[UPDATE_MANY] [ %s ], the entity does not exist entity_to_update=%o ', self.name, entityToUpdate)
        table.insert(results.missing_entities, entityToUpdate)
      end
    end
  end
  return results
end

--- Core:removeOne request
--- @tparam payload An item
--- @tparam[opt] [query]
--- @tparam[opt] [query.options]
  --- @tparam[opt] data any
  --- @tparam[opt] listeners boolean
  --- @tparam[opt] transaction boolean
  --- @tparam[opt] chunk integer
--- @treturn Item
function Core:removeOne(request)
  self.log:info('[REMOVE_ONE] [ %s ] payload=%o opts=%o', self.name, request.payload, request.query and request.query.options)
  return self.entity:remove(request.payload, request.query and request.query.options)
end

--- Core:removeMany request
--- @tparam payload An array of items
--- @tparam[opt] [query]
--- @tparam[opt] [query.options]
  --- @tparam[opt] data any
  --- @tparam[opt] listeners boolean
  --- @tparam[opt] transaction boolean
  --- @tparam[opt] chunk integer
--- @treturn An array of items
function Core:removeMany(request)
  self.log:info('[REMOVE_MANY] [ %s ] payload=%o opts=%o', self.name, request.payload, request.query and request.query.options)
  return self.entity:remove(request.payload, request.query and request.query.options)
end

return Core
