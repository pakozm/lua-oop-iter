local oopiter = require "oop-iter"
local iterator = oopiter.iterator
--
iterator.test()
-- reduce
assert( iterator(ipairs({4,2,1,10})):reduce(math.min, math.huge) == 1 )
assert( iterator(string.gmatch("01101",".")):reduce(function(acc,v)return acc*2+v end, 0) == 13 )
-- map
assert(iterator(ipairs({1,2,3,4})):map(function(i,v) return v*2 end):concat(" ") == "2 4 6 8")
-- filter
assert( iterator(ipairs{1,2,3,4,5,6,7}):filter(function(i,v) return v%2==0 end):map(function(i,v)return v end):concat(" ") == "2 4 6")

local t = { Lemon = "sour", Cake = "nice", }
local expected = {
  ["lemon is slightly SOUR"]=0,
  ["cake is slightly NICE"]=0,
}
for ingredient, modifier, taste in iterator(pairs(t)):map(function(a, b)
    return a:lower(),"slightly",b:upper()
                                                         end) do
  local str = ingredient .." is ".. modifier .. " " .. taste
  assert(expected[str] == 0)
  expected[str] = expected[str] + 1
end

local t = { Lemon = "sour", Cake = "nice", }
local expected = {
  ["cake is very NICE"]=0,
  ["Cake is slightly nice"]=0,
  ["lemon is very SOUR"]=0,
  ["Lemon is slightly sour"]=0,
}
for ingredient, modifier, taste in iterator(pairs(t)):map(function(a, b)
    coroutine.yield(a:lower(),"very",b:upper())
    return a, "slightly", b
                                                         end) do
  local str = ingredient .." is ".. modifier .. " " .. taste
  assert(expected[str]==0)
  expected[str] = expected[str] + 1
end

local idx=1
local expected={2,4,6}
for v in iterator(ipairs{1,2,3,4,5,6,7}):filter(function(key,value) return value%2==0 end) do
  assert(v == expected[idx])
  idx=idx+1
end

for k,v in iterator{1,2,3} do assert(k==v) end

assert( iterator.range(1,100):head() == 1)

assert( iterator.range(1,100):nth(30) == 30)

for a,b in iterator.zip( iterator.range(2,100),
                         iterator.range(1,100):tail() ) do
  assert(a == b)
end

for k,v in iterator.duplicate(100):take(10):enumerate() do
  assert(k>=1 and k<=10 and v==100)
end

for k,v in iterator.tabulate(function(x) return 2*x + 1 end):take(10):enumerate() do
  assert(v == (2*(k-1) + 1))
end

for k,v in iterator.tabulate(function(x) return 2*x + 1 end):drop(10):take(10):enumerate() do
  assert(v == (2*(k+9) + 1))
end

for a,b in iterator.zip(iterator.range(10):split(function(x) return x < 5 end)) do
  assert( (b-a) == 4 )
end

assert(iterator.range(11,20):index(15) == 5)

for k in iterator{1,2,3,4,5,1,2,3,4,5,1,2,3,4,5}:select(2):indices(3) do
  assert(k == 3 or k == 8 or k == 13)
end

for line in iterator{ "one", "two", "one_two", "three", "one_four" }:select(2):grep("^one_") do
  assert(line:match("^one"))
end

assert( iterator{1,2,3,4,10,2,4,1}:select(2):max() == 10)

assert( iterator{1,2,3,4,10,2,4,1}:select(2):min() == 1)
