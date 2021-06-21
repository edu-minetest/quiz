local MOD_NAME = play_challenge.MOD_NAME

-- valueType: int, string, float
local function getPlayerAttr(attrs, attrName, valueType, sep)
  if not valueType then valueType = "int" end
  if not sep then sep = "." end
  attrName = MOD_NAME .. sep .. attrName
  local result = attrs["get_"..valueType](attrs, attrName)
  -- print('TCL:: ~ file: quizzes.lua ~ line 34 ~ getPlayerAttr result', attrName, result);
  return result
end

local function setPlayerAttr(attrs, attrName, value, valueType, sep)
  if not valueType then valueType = "int" end
  if not sep then sep = "." end
  attrName = MOD_NAME .. sep .. attrName
  return attrs["set_"..valueType](attrs, attrName, value)
end

return {
  get = getPlayerAttr,
  set = setPlayerAttr,
  getQuiz = function(attrs, attrName, valueType)
    return getPlayerAttr(attrs, attrName, valueType, ":")
  end,
  setQuiz = function(attrs, attrName, value, valueType)
    return setPlayerAttr(attrs, attrName, value, valueType, ":")
  end
}
