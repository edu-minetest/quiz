-- merge defaults value to target table
local function defaults(target, default)
  if not target then target = {} end
  if not default then return target end
  for k,v in pairs(default) do
    local value = target[k]
    if type(v) == "table" then
      if type(value) ~= "table" then
        value = {}
        target[k] = value
      end
      defaults(value, v)
    else
      if (value == nil) then target[k] = v end
    end
  end
  return target
end

return defaults
