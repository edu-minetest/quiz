local function arrayEqual(a1, a2)
  -- Check length, or else the loop isn't valid.
  if #a1 ~= #a2 then
    return false
  end

  -- Check each element.
  for i, v in ipairs(a1) do
    if v ~= a2[i] then
      return false
    end
  end

  -- We've checked everything.
  return true
end

local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

local function find(tbl, val)
  for i, value in ipairs(tbl) do
    if value == val then
        return i
    end
  end
end

return {
  equal = arrayEqual,
  shuffle = shuffle,
  find = find,
}
