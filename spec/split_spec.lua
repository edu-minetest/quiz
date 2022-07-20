local split = require("split")

-- Tests
describe("split.str", function()
  it("splitString with default delimiter and limiter from string", function()
    local r = split.str('abs = "hi worlds"  good better,    list="list sth"')
    assert.is_same({
      'abs="hi worlds"',
      "good", "better,",
      'list="list sth"',
    }, r)
  end)

  it("splitString with ',' delimiter from string", function()
    local r = split.str('abs = "hi worlds", good better,    list="list sth"', ",")
    assert.is_same({
      'abs = "hi worlds"',
      " good better",
      '    list="list sth"',
    }, r)
  end)
end)

describe("split.keyValue", function()
  it("split to key/value with default delimiter from string", function()
    local r = split.keyValue("  ab  =   'hi word'   ")
    assert.is_same({ ab = 'hi word' }, r)
  end)
end)

describe("split.table", function()
  it("split to table with default delimiter from string", function()
    local r = split.table("  ab  =   'hi word'  list3 'simple thing' better = \"hello\" ")
    assert.is_same({ ab = 'hi word', "list3",  'simple thing', better = "hello"}, r)
  end)
end)
