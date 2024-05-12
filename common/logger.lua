local function Logger(context, name)
  return {
    info = function(self, message, ...)
      print(('[INFO] [%s] [%s] ' .. message):format(context, name, ...))
    end,
    error = function(self, message, ...)
      print(('[ERROR] [%s] [%s] ' .. message):format(context, name, ...))
    end
  }
end

return Logger