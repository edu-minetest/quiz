local array = require("array")

-- Tests
describe("array.equal", function()
  it("test two array whether is the same", function()
    local r = {5,6,7,9}
    assert.True(array.equal(r, {5,6,7,9}))
    assert.False(array.equal(r, {6,6,7,9}))
    assert.False(array.equal(r, {5,6,7,9,10}))
  end)
end)

describe("array.shuffle", function()
  it("shuffle an array", function()
    local r = {5,6,7,9}
    local r2 = {5,6,7,9}
    array.shuffle(r2)
    assert.is_not.same(r, r2)
    table.sort(r2)
    assert.is.same(r, r2)
  end)
end)

describe("array.find", function()
  it("find value in an array", function()
    local r = {5,6,7,9}
    assert.is_equal(3, array.find(r, 7))
    assert.is_equal(4, array.find(r, 9))
    assert.is_nil(array.find(r, 10))
  end)
end)
