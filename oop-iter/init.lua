--[[
  Copyright (c) 2014 Francisco Zamora-Martinez (pakozm@gmail.com)
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
]]

local class = require "oop-iter.class"
local iterator = require "oop-iter.iterator"

-- auxiliary function for bind
local function merge_unpack(t1, t2, i, j, n, m)
  i,j = i or 1, j or 1
  n,m = n or t1.n, m or t2.n
  if i <= n then
    if t1[i] ~= nil then
      return t1[i],merge_unpack(t1, t2, i+1, j, n, m)
    else
      return t2[j],merge_unpack(t1, t2, i+1, j+1, n, m)
    end
  elseif j <= m then
    return t2[j],merge_unpack(t1, t2, i, j+1, n, m)
  end
end

-- allow to bind arguments to any Lua function (only variadic arguments)
local function bind(func, ...)
  local args = table.pack(...)
  return function(...)
    return func(merge_unpack(args, table.pack(...)))
  end
end

-- log addition
local function logadd(a,b)
  if a > b then
    return a + math.log(1 + math.exp(b-a))
  else
    return b + math.log(1 + math.exp(a-b))
  end
end

-- auxiliary function for fast development of reductions
local function lnot(a)
  assert(a, "Needs one argument")
  return not a
end
-- auxiliary function for fast development of reductions
local function lor(a,b)
  assert(a and b, "Needs two arguments")
  return a or b
end

-- auxiliary function for fast development of reductions
local function land(a,b)
  assert(a and b, "Needs two arguments")
  return a and b
end

-- auxiliary function for fast development of reductions
local function ge(a,b)
  assert(a and b, "Needs two arguments")
  return a>=b
end

-- auxiliary function for fast development of reductions
local function gt(a,b)
  assert(a and b, "Needs two arguments")
  return a>b
end

-- auxiliary function for fast development of reductions
local function le(a,b)
  assert(a and b, "Needs two arguments")
  return a<=b
end

-- auxiliary function for fast development of reductions
local function lt(a,b)
  assert(a and b, "Needs two arguments")
  return a<b
end

-- auxiliary function for fast development of reductions
local function eq(a,b)
  assert(a and b, "Needs two arguments")
  return a==b
end

-- auxiliary function for fast development of reductions
local function add(a,b)
  assert(a and b, "Needs two arguments")
  return a+b
end

-- auxiliary function for fast development of reductions
local function sub(a,b)
  assert(a and b, "Needs two arguments")
  return a-b
end

-- auxiliary function for fast development of reductions
local function mul(a,b)
  assert(a and b, "Needs two arguments")
  return a*b
end

-- auxiliary function for fast development of reductions
local function div(a,b)
  assert(a and b, "Needs two arguments")
  return a/b
end

local function clamp(value,lower,upper)
  assert(value and lower and upper, "Needs three arguments")
  assert(lower<=upper) -- sanity check
  return math.max(lower,math.min(value,upper))
end

-- computes the sign of a number
local function sign(v)
  assert(v, "Needs one argument")
  return (v>0 and 1) or (v<0 and -1) or 0
end

local oopiter = {
  _NAME = "lua-oop-iter",
  _VERSION = "0.3",
  class = class,
  iterator = iterator,
  -- useful functions
  bind = bind,
  logadd = logadd,
  lnot = lnot,
  lor = lor,
  land = land,
  ge = ge,
  gt = gt,
  le = le,
  lt = lt,
  eq = eq,
  add = add,
  sub = sub,
  mul = mul,
  div = div,
  clamp = clamp,
  sign = sign,
}

return oopiter
