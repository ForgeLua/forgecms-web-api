local Utils = {}

function Utils.parseQueryToSQL(filters)
  if not filters then return '' end
  local conditions = {}
  for key, filter in pairs(filters) do
    if type(filter) == "table" then
      if key == "$or" and type(filter) == "table" then
        table.insert(conditions, Utils.parseOrOperator(filter))
      elseif type(filter) == "table" then
        table.insert(conditions, Utils.parseRegularOperator(key, filter))
      end
    else
      table.insert(conditions, '"' .. key .. '" = \'' .. tostring(filter) .. '\'')
    end
  end
  local where_clause = table.concat(conditions, ' AND ')
  return where_clause ~= '' and 'WHERE ' .. where_clause or ''
end

function Utils.parseOrOperator(filters)
  local orConditions = {}
  for _, filter in ipairs(filters) do
    local conditions = {}
    for key, item in pairs(filter) do
      if type(item) == "table" then
        table.insert(conditions, Utils.parseRegularOperator(key, item))
      else
        table.insert(conditions, '"' .. key .. '" = \'' .. tostring(item) .. '\'')
      end
    end
    table.insert(orConditions, '(' .. table.concat(conditions, ' AND ') .. ')')
  end
  return '(' .. table.concat(orConditions, ' OR ') .. ')'
end

function Utils.parseRegularOperator(key, filters)
  local conditions = {}
  if filters['$in'] then
    local inCondition = '"' .. key .. '" IN ('
    for _, id in ipairs(filters['$in']) do
      inCondition = inCondition .. '\'' .. tostring(id) .. '\', '
    end
    inCondition = string.sub(inCondition, 1, -3) .. ')'
    table.insert(conditions, inCondition)
  end
  if filters['$eq'] then table.insert(conditions, '"' .. key .. '" = \'' .. tostring(filters['$eq']) .. '\'') end
  if filters['$gt'] then table.insert(conditions, '"' .. key .. '" > ' .. tostring(filters['$gt'])) end
  if filters['$lt'] then table.insert(conditions, '"' .. key .. '" < ' .. tostring(filters['$lt'])) end
  if filters['$gte'] then table.insert(conditions, '"' .. key .. '" >= ' .. tostring(filters['$gte'])) end
  if filters['$lte'] then table.insert(conditions, '"' .. key .. '" <= ' .. tostring(filters['$lte'])) end
  if filters['$exists'] then
    local existsCondition = '"' .. key .. '" ' .. (filters['$exists'] and 'IS NOT NULL' or 'IS NULL')
    table.insert(conditions, existsCondition)
  end
  return table.concat(conditions, ' AND ')
end

return Utils
