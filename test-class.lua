local oopiter = require "oop-iter"
local class = oopiter.class

------------------------------------------------------------------------------

-- myClass1
local myClass1,myClass1Methods = class("myClass1")
function myClass1:constructor(n) self.n = n end
function myClass1:destructor() print("I am myClass1 destructor: " .. tostring(self) .. " " .. (self.n or "nil")) end
function myClass1Methods:print() print(self.n) end

-- myClass2
local myClass2,myClass2Methods = class("myClass2", myClass1)
function myClass2:constructor(...) myClass1.constructor(self,...) end
function myClass2Methods:print()
  print("I am myClass2")
  local super_print = myClass1.."print"
  super_print(self)
  class.call(class.super(myClass2),"print",self)
end

-- myClass3
local myClass3,myClass3Methods = class("myClass3", myClass2)
function myClass3:constructor(...) myClass2.constructor(self,...) end

------------------------------------------------------------------------------

local t1 = myClass1(10)
local t2 = myClass2(33)
local t3 = myClass3(100)

t1:print()
t2:print()
t3:print()

assert(class.is_a(t1, myClass1))
assert(not class.is_a(t1, myClass2))
assert(not class.is_a(t1, myClass3))
assert(class.is_a(t2, myClass1))
assert(class.is_a(t2, myClass2))
assert(not class.is_a(t2, myClass3))
assert(class.is_a(t3, myClass1))
assert(class.is_a(t3, myClass2))
assert(class.is_a(t3, myClass3))

print("is_a(t1,myClass1) = ", class.is_a(t1, myClass1))
print("is_a(t1,myClass2) = ", class.is_a(t1, myClass2))
print("is_a(t1,myClass3) = ", class.is_a(t1, myClass3))
print("is_a(t2,myClass1) = ", class.is_a(t2, myClass1))
print("is_a(t2,myClass2) = ", class.is_a(t2, myClass2))
print("is_a(t2,myClass3) = ", class.is_a(t2, myClass3))
print("is_a(t3,myClass1) = ", class.is_a(t3, myClass1))
print("is_a(t3,myClass2) = ", class.is_a(t3, myClass2))
print("is_a(t3,myClass3) = ", class.is_a(t3, myClass3))

assert(class.of(t1), myClass1)
assert(class.of(t2), myClass2)
assert(class.of(t3), myClass3)

print("of(t1) = ", class.of(t1))
print("of(t2) = ", class.of(t2))
print("of(t3) = ", class.of(t3))

class.extend(myClass2, "ext", 120)
assert(t2.ext == 120)

print("t2.ext = ", t2.ext)

assert(not class.is_derived(t1))
assert(class.is_derived(t2))
assert(class.is_derived(t3))

print("is_derived(t1) = ", class.is_derived(t1))
print("is_derived(t2) = ", class.is_derived(t2))
print("is_derived(t2) = ", class.is_derived(t3))
