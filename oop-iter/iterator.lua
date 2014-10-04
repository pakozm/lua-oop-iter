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

-- Detect if APRIL-ANN is available.
local type = type
local aprilann_available = (aprilann ~= nil)
if aprilann_available then type = luatype or type end
--
local class = class or require "oop-iter.class"

--------------------------------
-- iterator module definition --
--------------------------------
local iterator,iterator_methods = class("iterator")
iterator._NAME = "iterator"
iterator._VERSION = "0.1"

local concat = table.concat
local insert = table.insert
local pack = table.pack
local remove = table.remove
local unpack = table.unpack
local wrap = coroutine.wrap
local yield = coroutine.yield

local function filter(func, f, s, v)
  return function(s, v)
    local tmp = pack(f(s, v))
    while tmp[1] ~= nil and not func(unpack(tmp)) do
      v = tmp[1]
      tmp = pack(f(s, v))
    end
    return unpack(tmp)
  end, s, v
end

-- FROM: http://www.corsix.org/content/mapping-and-lua-iterators
local function map(func, f, s, v)
  local done
  local function maybeyield(...)
    if ... ~= nil then
      yield(...)
    end
  end
  local function domap(...)
    v = ...
    if v ~= nil then
      return maybeyield(func(...))
    else
      done = true
    end
  end
  return wrap(function()
      repeat
        local tmp = pack(f(s,v))
        v = tmp[1]
        domap(unpack(tmp))
      until done
  end), s, v
end

local function reduce(func, initial_value, f, s, v)
  assert(initial_value ~= nil,
	 "reduce: needs an initial_value as second argument")
  local accum = initial_value
  local tmp = pack(f(s, v))
  while tmp[1] ~= nil do
    accum = func(accum, unpack(tmp))
    tmp = pack(f(s, tmp[1]))
  end
  return accum
end

local function apply(func, f, s, v)
  if not func then func = function() end end
  local tmp = pack(f(s,v))
  while tmp[1] ~= nil do
    func(unpack(tmp))
    tmp = pack(f(s,tmp[1]))
  end
end

--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------

function iterator:constructor(f, s, v)
  self.f,self.s,self.v = f,s,v
end

function iterator_methods:get() return self.f,self.s,self.v end

function iterator_methods:step()
  local tmp = pack( self.f(self.s, self.v) )
  self.v = tmp[1]
  return unpack(tmp)
end

function iterator.meta_instance:__call() return self:step() end

function iterator_methods:map(func)
  return iterator(map(func, self:get()))
end

function iterator_methods:filter(func)
  return iterator(filter(func, self:get()))
end

function iterator_methods:apply(func)
  apply(func, self:get())
end

function iterator_methods:reduce(func, initial_value)
  return reduce(func, initial_value, self:get())
end

function iterator_methods:enumerate()
  local id = 0
  return self:map(function(...)
      id = id + 1
      return id, ...
  end)
end

function iterator_methods:call(funcname, ...)
  local func_args = pack(...)
  return self:map(function(...)
      local arg    = pack(...)
      local result = {}
      for i=1,#arg do
        local t = pack(arg[i][funcname](arg[i],unpack(func_args)))
        for j=1,#t do insert(result, t[j]) end
      end
      return unpack(result)
  end)
end

function iterator_methods:iterate(iterator_func)
  return self:map(function(...)
      local f,s,v = iterator_func(...)
      local tmp   = pack(f(s,v))
      while tmp[1] ~= nil do
        yield(unpack(tmp))
        tmp = pack(f(s,tmp[1]))
      end
  end)
end

function iterator_methods:concat(sep1,sep2)
  local sep1,sep2 = sep1 or "",sep2 or sep1 or ""
  local t = {}
  self:apply(function(...)
      local arg = pack(...)
      insert(t, string.format("%s", concat(arg, sep1)))
  end)
  return concat(t, sep2)
end

function iterator_methods:field(...)
  local f,s,v = self:get()
  local arg   = pack(...)
  return iterator(function(s)
      local tmp = pack(f(s,v))
      if tmp[1] == nil then return nil end
      v = tmp[1]
      local ret = { }
      for i=1,#tmp do
        for j=1,#arg do
          insert(ret, tmp[i][arg[j]])
        end
      end
      return unpack(ret)
		  end,
    s,v)
end

function iterator_methods:select(...)
  local f,s,v = self:get()
  local arg   = pack(...)
  for i=1,#arg do arg[i]=tonumber(arg[i]) assert(arg[i],"select: expected a number") end
  return iterator(function(s)
      local tmp = pack(f(s,v))
      if tmp[1] == nil then return nil end
      v = tmp[1]
      local selected = {}
      for i=1,#arg do selected[i] = tmp[arg[i]] end
      return unpack(selected)
		  end,
    s,v)
end

function iterator_methods:table()
  local t = {}
  local idx = 1
  self:apply(function(...)
      local v = pack(...)
      local k = remove(v, 1)
      if #v == 0 then
        k,v = idx,k
      elseif #v == 1 then
        v = v[1]
      end
      t[k] = v
      idx = idx + 1
  end)
  return t
end

-- In APRIL-ANN this module is defined at global environment
if aprilann_available then
  _G.apply = apply
  _G.iterator = iterator
  _G.iterable_filter = filter
  _G.iterable_map = map
  _G.reduce = reduce
end

-- UNIT TEST
function iterator.test()
  for k,v in filter(function(k,v) return v % 2 == 0 end, ipairs{1,2,3,4}) do
    assert(v % 2 == 0)
  end
  for k,v in map(function(k,v) return k,k+v end, ipairs{1,2,3,4}) do
    assert(v == 2*k)
  end
  local r = reduce(function(acc,a,b,c) return acc+a+b+c end, 0, map(function(k,v) return k,v,v end, ipairs{1,2,3,4}))
  assert(r == 3 + 6 + 9 + 12)
  apply(function(a,b,c) assert(a==b and b==c) end,
    map(function(k,v) return k,v,v end, ipairs{1,2,3,4}))
end

return iterator
