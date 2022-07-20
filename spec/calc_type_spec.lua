
-- Look for required things in
-- package.path = "./?.lua;" .. package.path

bit = require("bit")

local calc = require("calc_type")
-- assert = require("luassert")

-- Tests
describe("calc_type.remove_dup_str", function()
  it("remove duplicates from string", function()
    local r = calc.remove_dup_str("Jaj1jAka2sJA3848771239")
      assert.equals("Jaj1Ak2s38479", r)
  end)

end)

describe("calc_type.parse_charset", function()
  it("charset:digit with duplication", function()
    local r = calc.parse_charset("012383*^")
    assert.equals("012383*^", r)
  end)

  it("charset:digit range", function()
    local r = calc.parse_charset("1-390")
    assert.equals("12390", r)
  end)
  it("charset:digit range reverse", function()
    local r = calc.parse_charset("3-190")
    assert.equals("12390", r)
  end)
end)

describe("calc_type.parse", function()
  for i = 1, 100 do
    it("parse calc type number:" .. i , function()
      local r = calc.parse("NNnn")
      assert.matches("^[123456789][123456789]%d%d$", r)
    end)
    it("parse calc type:" .. i , function()
      local r = calc.parse("Nn[*/]N")
      assert.matches("^[123456789]%d[*/][123456789]$", r)
    end)
    it("parse complex calc type:" .. i , function()
      local r = calc.parse("(N + Nn)[+-*/]N - N")
      assert.matches("^[(][123456789]%+[123456789]%d[)][%+-*/][123456789]%-[123456789]$", r)
    end)
  end
end)

describe("calc_type.execute", function()
  it("execute expression:" , function()
    local r = calc.execute("12+3^2")
    assert.equals(21, r)
  end)

  it("execute div integer expression:" , function()
    local r = calc.execute("(13+3)/3", true)
    assert.equals(5, r[1])
    assert.equals(1, r[2])
  end)
end)

describe("calc_type", function()
  for i = 1, 100 do
    it("generated expression result is integer only:" .. i , function()
      local exprInt = calc.parse("Nn/N", true)
      -- local expr = calc.parse("Nn/N")
      local r,d = calc.execute(exprInt)
      assert.is_number(r)
      assert.is_nil(d)
      r,d = math.modf(r)
      assert.equals(0, d)
    end)
  end
end)
