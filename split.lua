local function trim(s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

local function unquote(s)
  local quote = s:sub(1,1)
  if (quote == '"' or quote == "'") then
    s = s:sub(2, #s-1)
  end
  return s
end

local function skipDelimiter(text, i, delimiter)
  local c = text:sub(i,i)
  if c == delimiter then
    repeat
      i = i + 1
      c = text:sub(i,i)
    until i >= #text or c ~= delimiter
    return i, c
  end
end

local function splitString(text, delimiter, limiter)
  if not delimiter then delimiter = " " end
  if not limiter then limiter = "=" end
  local line = ''
  local quote
  local result = {}
  local i = 1
  while i  <= #text do
    local c = text:sub(i,i)
    if c == quote then
      quote = nil
    elseif quote == nil and (c == '"' or c == "'") then
      quote = c
    end
    if quote or c ~= delimiter then
      line = line .. c
    else
      local lineDone = false
      if not quote then
        -- try to skip delimiters around limiter
        local j, nextc = skipDelimiter(text, i, delimiter)
        if nextc == limiter then
          line = line .. nextc
          j = j + 1
          nextc = text:sub(j,j)
          if nextc == delimiter then
            j = skipDelimiter(text, j, delimiter)
          end
          i = j - 1
          lineDone = true
        end
      end
      if not lineDone then
        if line ~= "" then table.insert(result, line) end
        line = ''
      end
    end
    i = i + 1
  end
  if line ~= "" then table.insert(result, line) end
  return result
end

-- local testResult = splitString('abs = "hi worlds" good better,    list="list sth"', " ")
-- local dump = require("pl.pretty").dump
-- print(dump(testResult))

local function splitKeyValue(text, delimiter)
  if not delimiter then delimiter = "=" end
  local list = splitString(text, delimiter)
  if (#list >= 2) then
    local result = {}
    local i = 1
    repeat
      local key = trim(list[i])
      local value = trim(list[i+1])
      result[key] = unquote(value)
      i = i + 2
    until i >= #list
    return result
  end
end

-- print(dump(splitKeyValue("  ab  =   'hi word'   ")))

local function splitTable(text, delimiter, kvDelimter)
  local list = splitString(text, delimiter, kvDelimter)
  local result = {}

  for ix, item in pairs(list) do
    local val = splitKeyValue(item, kvDelimter)
    if val then
      for k,v in pairs(val) do
        result[k] = v
      end
    else
      table.insert(result, unquote(item))
    end
  end

  return result
end

-- print(dump(splitTable("  ab  =   'hi word'  list3 'simple thing' better = \"hello\" ")))

return {
  str = splitString,
  keyValue = splitKeyValue,
  table = splitTable,
}

