--- constants
local TRUE = {
  ['1'] = true,
  ['t'] = true,
  ['T'] = true,
  ['true'] = true,
  ['TRUE'] = true,
  ['True'] = true,
  ['ok'] = true,
  ['Ok'] = true,
  ['OK'] = true,
  ['on'] = true,
  ['On'] = true,
  ['ON'] = true,
};


--- toboolean
-- @param str
-- @return bool
-- @return err
local function toBoolean( str )
  -- assert( type( str ) == 'string', 'str must be string' )

  if TRUE[str] == true then
      return true
  else
      return false
  end
end

return toBoolean
