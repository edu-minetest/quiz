local function remove_dup_str(s)
  local result = ""
  -- keeps track of visited characters
  local counter = {}
  local i = 1
  while i <= #s do
    local x = s:sub(i,i)
    if counter[x] == nil then
      result = result .. x
      -- mark current character as visited
      counter[x] = true
    end
    i = i + 1
  end
  return result
end

local function parse_charset(s)
  local result = ""
  local i = 1
  while i <= #s do
    local c = s:sub(i,i)
    if string.find(c, "%d") then
      local next_c = s:sub(i+1,i+1)
      local to_c = s:sub(i+2,i+2)
      if next_c == "-" and string.find(to_c, "%d") then

        local n_from = tonumber(c)
        local n_to = tonumber(to_c)
        if n_from > n_to then
          local t = n_from
          n_from = n_to
          n_to = t
        end
        for j = n_from, n_to do
          result = result .. j
        end
        i = i + 2
      else
        result = result .. c
      end
    else
      result = result .. c
    end
    i = i + 1
  end
  return result
end

local compile

local function veryIntExpr(s)
  local v = compile(s)()
  local i, frac = math.modf(v)

  if frac ~= 0 then
    local ix = s:find("/")
    if ix then
      local leftStr = s:sub(1, ix-1)
      local left = loadstring("return " .. leftStr)()
      local rightStr = s:sub(ix+1)
      local right = loadstring("return " .. rightStr)()
      local mod = left % right

      return "(" .. leftStr .. "+" .. right-mod  .. ")/" .. rightStr
    end
  end
  return s
end

local function parse(s, onlyInt)
  local result = ""
  local i = 1
  while i <= #s do
    local c = s:sub(i,i)
    if c == "n" then
      result = result .. math.random(0, 9)
    elseif c == "N" then
      result = result .. math.random(1, 9)
    elseif c == "[" then
      local t = ""
      repeat
        i = i + 1
        c = s:sub(i,i)
        if c ~= "]" then t = t .. c end
      until c == "]" or i > #s
      if #t > 0 then
        local charset = parse_charset(t)
        local ix = math.random(1, #charset)
        result = result .. charset:sub(ix, ix)
      end
    elseif string.find(c, "[%+-*/()^%d.]") then
      result = result .. c
    end
    i = i + 1
  end
  if onlyInt then
    result = veryIntExpr(result)
  end
  return result
end

function compile(s)
  local fn = loadstring("return " .. s)
  return fn
end

local function execute(s, useMod)
  local v = compile(s)()
  local i, frac = math.modf(v)

  if useMod == true and frac ~= 0 then
    -- is it decimal?
    -- the div operator must be last one!
    local ix = s:find("/")
    if ix then
      local left = s:sub(1, ix-1)
      left = loadstring("return " .. left)()
      local right = s:sub(ix+1)
      right = loadstring("return " .. right)()
      return {i, left % right}
    end
  end

  return v
end


return {
  remove_dup_str = remove_dup_str,
  parse_charset = parse_charset,
  parse = parse,
  compile = compile,
  execute = execute,
}
