local oopiter = require "oop-iter"
local class = oopiter.class
local c,o,m = class("hola")

function m:__call(n) return class.instance({ n=n }, self) end
function o:print() print(self.n) end

local c2,o2,m2 = class("hola2", c)

function m2:__call(n) local obj = c(n) return class.instance(obj, self) end
function o2:print()
  print("I am hola2")
  class.call(class.super(c2),"print",self)
end

local c3,o3,m3 = class("hola3", c2)

function m3:__call(n) local obj = c2(n) return class.instance(obj, self) end

t1 = c(10)
t2 = c2(33)
t3 = c3(100)

t1:print()
t2:print()
t3:print()

print("isa(t1,c) = ", class.isa(t1,c))
print("isa(t1,c2) = ", class.isa(t1,c2))
print("isa(t2,c) = ", class.isa(t2,c))
print("isa(t2,c2) = ", class.isa(t2,c2))

print("of(t1) = ", class.of(t1))
print("of(t2) = ", class.of(t2))

class.extend(c2, "ext", 120)
print("t2.ext = ", t2.ext)

print("is_derived(t1) = ", class.is_derived(t1))
print("is_derived(t2) = ", class.is_derived(t2))

