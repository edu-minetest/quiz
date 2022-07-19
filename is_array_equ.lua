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

return arrayEqual
