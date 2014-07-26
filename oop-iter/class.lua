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

------------------------------------------------------------
-- private functions

-- local type = luatype

local function set_parent(child,parent)
  setmetatable(getmetatable(child).__index, parent)
end

-- precondition: standard Lua type implementation
local function is_table(t)
  return type(t) == "table"
end

-- precondition: none
local function has_class_instance_index_metamethod(t)
  return is_table(t) and t.meta_instance and t.meta_instance.__index
end

-- precondition: none
local function has_instance_index_metamethod(t)
  return getmetatable(t) and getmetatable(t).__index
end

local function has_metainstance(t)
  return is_table(t) and t.meta_instance
end

-- returns true if the given table is a class table (not instance)
local function is_class(t)
  return is_table(t) and t.meta_instance and t.meta_instance.id ~= nil
end

local function is_object(t)
  
end

-------------------------------------------------------------
-- class definition

local class = {
  _NAME = "class",
  _VERSION = "0.1",
}

-- Predicate which returns true if a given object instance is a subclass of a
-- given Lua table (it works for Lua class(...) and C++ binding)
function class.isa(object_instance, base_class_table)
  assert(class.of(object_instance),
         "Needs an object as 1st parameter")
  assert(is_class(base_class_table),
         "Needs a class table as 2nd parameter")
  local base_class_meta = (base_class_table.meta_instance or {}).__index
  local object_table    = object_instance
  local _isa            = false
  while ( not _isa and object_table and
          getmetatable(object_table) ) do
    local t = has_instance_index_metamethod(object_table)
    _isa = rawequal(t,base_class_meta)
    object_table = t
  end
  return _isa
end

-- returns the super class of a given class table
function class.super(class_table, methodname, ...)
  assert(is_class(class_table),
         "Needs a class table as 1st parameter")
  return assert( (getmetatable(class_table) or {}).parent,
                 "The given object hasn't a super-class" )
end

function class.of(t)
  return (getmetatable(t) or {}).cls
end

-- precondition: none
function class.consult(class_table, key)
  return assert(has_class_instance_index_metamethod(class_table),
                "The given object is not a class")[key]
end

function class.call(class_table, method, ...)
  return class.consult(class_table, method)(...)
end

-- precondition: none
function class.extend(class_table, key, value)
  assert(has_class_instance_index_metamethod(class_table),
         "The given object is not a class")[key] = value
end

-- precondition: t is a class instance
function class.is_derived(t)
  return getmetatable((getmetatable(t) or { __index={} }).__index)
end

-- makes a wrapper around an object, delegating the function calls to the given
-- object if they are not implemented in the given wrapper table
function class.wrapper(obj,wrapper)
  local wrapper = wrapper or {}
  local current = obj
  while class.of(current) do
    -- and not rawequal(getmetatable(current).__index,current) do
    current = instance_index_metamethod(current)
    for i,v in pairs(current) do
      if wrapper[i] == nil then
	if type(v) == "function" then
	  wrapper[i] =
	    function(first, ...)
	      if rawequal(first,wrapper) then
		return obj[i](obj, ...)
	      else
		return obj[i](...)
	      end
	    end -- function
        elseif getmetatable(v) and getmetatable(v).__call then
          error("Not implemented wrapper for callable tables")
	else -- if type(v) == "function"
	  wrapper[i] = v
	end -- if type(v) == "function" ... else
      end -- if wrapper[i] == nil
    end -- for
  end -- while
  if class.of(wrapper) then
    if class.is_derived(wrapper) then
      error("class_wrapper not works with derived or nil_safe objects")
    else
      set_parent(wrapper,getmetatable(obj))
    end
  else
    wrapper = class.instance(wrapper, class.of(obj))
  end
  return wrapper
end

-- Converts a Lua table in an instance of the given class.
class.instance = function(obj, class)
  setmetatable(obj, assert(has_metainstance(class),
                           "2nd argument needs to be a class table"))
  return obj
end

-- Convert a table in a class, and it receives an optional parent class to
-- implement simple heritance. It returns the class table; another table which
-- will contain the methods of the object; and the metatable of the class, so in
-- the metatable could be defined __call constructor or __gc destructor, etc..
local class_call = function(self, classname, parentclass)
  local current = {}
  -- local current = get_table_from_dotted_string(classname, true)
  -- if type(parentclass) == "string" then
  -- parentclass = get_table_from_dotted_string(parentclass)
  -- end
  assert(parentclass==nil or is_class(parentclass),
	 "The parentclass must be defined by 'class' function")
  -- local t = string.tokenize(classname,".")
  --
  local meta_instance = {
    id         = classname,
    cls        = current,
    __tostring = function(self) return "instance of " .. classname end,
    __index    = { }
  }
  local class_metatable = {
    id         = classname .. " class",
    parent     = parentclass,
    __tostring = function() return "class ".. classname .. " class" end,
    __concat   = function(a,b)
      assert(type(b) == "string", "Needs a string as second argument")
      return class_get(a,b)
    end,
    --    __index    = function(t,k)
    --      local aux = rawget(t,k)
    --      if aux then return aux else return t.meta_instance.__index[k] end
    --    end,
  }
  if parentclass then
    setmetatable(meta_instance.__index, parentclass.meta_instance)
  end
  -- 
  current.meta_instance = meta_instance
  setmetatable(current, class_metatable)
  return current, current.meta_instance.__index, class_metatable
end

--
setmetatable(class, { __call = class_call })

return class
