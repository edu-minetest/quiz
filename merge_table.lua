-- merge src value to target table
local function merge(target, src)
  if not target then target = {} end
  if not src then return target end
  for k,v in pairs(src) do
    local value = target[k]
    if type(v) == "table" then
      if type(value) ~= "table" then
        value = {}
        target[k] = value
      end
      merge(value, v)
    else
      target[k] = v
    end
  end
  return target
end

return merge
