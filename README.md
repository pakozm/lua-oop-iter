Lua OOP-iter
============

Lua implementation of object oriented programming with enhanced iterator
class. It is extracted from [APRIL-ANN toolkit](https://github.com/pakozm/april-ann).

Basic ussage
------------

From a Lua interpreter or script, after installed the software in the proper Lua
path directories, you can do:

```Lua
> oopiter = require "oop-iter"
> class   = oopiter.class
>
> -- class definition
> myclass,myclass_methods = class('myclass')
> myclass:constructor(n) self.blah = n end
> myclass_methods:get_blah() return self.blah end
>
> -- class instance
> local obj = myclass(10)
> print(obj:get_blah())
10
```

Class module
------------

See
[test-class.lua](https://github.com/pakozm/lua-oop-iter/blob/master/test-class.lua)
file for an example of this module. It can be executed from a terminal:

```
$ lua test-class.lua
10
I am myClass2
33
33
I am myClass2
100
100
is_a(t1,myClass1) = 	true
is_a(t1,myClass2) = 	false
is_a(t1,myClass3) = 	false
is_a(t2,myClass1) = 	true
is_a(t2,myClass2) = 	true
is_a(t2,myClass3) = 	false
is_a(t3,myClass1) = 	true
is_a(t3,myClass2) = 	true
is_a(t3,myClass3) = 	true
of(t1) = 	class myClass1 class
of(t2) = 	class myClass2 class
of(t3) = 	class myClass3 class
t2.ext = 	120
is_derived(t1) = 	false
is_derived(t2) = 	true
is_derived(t2) = 	true
I am myClass1 destructor: instance of myClass3 100
I am myClass1 destructor: instance of myClass2 33
I am myClass1 destructor: instance of myClass1 10
```

### Description 

The class module implements OOP for Lua in a similar way as luabind does for C++
classes in [APRIL-ANN toolkit](https://github.com/pakozm/april-ann). So, the
class module functions are compatible with it. The OOP is implemented by
defining several tables for each desired class. Every class has a name, which
allow to store it into a weak table in order to retrieve the class by its name
in any moment. A class is defined by doing:

```Lua
class_table, methods_table = class('myClassName'[, parent_class_table[, class_table]])
```
  
Two tables are returned as result of this call, the `class_table` which allows to
construct instances by using the `class_table` as a function (it has implemented
the `__call` metamethod), and a `methods_table` where instance methods must be
defined. Class methods will be defined into `class_table`, and special names
constructor/destructor allow to define the behavior of the object at these
specific stages. So, the first is to define a constructor and a destructor
(NOTE: both are optional):

```Lua
class_table:constructor(whatever) self.blah = whatever end
class_table:destructor() free_resource(self.blah) end
```
  
In the same way, instance methods will be defined in `methods_table`:
  
```Lua
methods_table:my_method() return self.blah end
```
  
Additionally, instance metamethods can be defined using the
`class.extend_metamethod` function. Be carefule, `__gc` and `__index`
metamethods are defined by default and them cannot be modified, any change will
produce an unexpected behavior:
  
```Lua
class.extend_metamethod(class_table, "__tostring", function() print("foo") end)
```

Looking with more detail inside the architecture, the `class(...)` function call
defines the following hierarchy of tables:

```Lua
  class_table = {
    constructor = default_constructor, -- it does nothing
    destructor = default_destructor,   -- it does nothing
    -- the meta_instance table contains the metatable of instance objects
    meta_instance = {
      id  = class_name_string,
      cls = class_table_reference,
      __tostring = default_tostring_metamethod, -- it is safe to be overwritten
      __index = methods_table, -- the table where instance methods are defined
      __gc = default_gc_metamethod,
    }
  }

  -- class_table metatable contains:
  {
    id     = class_name .. " class",
    parent = parentclass, -- if given any
    __tostring = default_tostring_metamethod,
    __concat   = default_concat_metamethod,
    __call     = constructor_call,
  }
```

The `class(...)` function call returns first the `class_table` and second the
`class_table.meta_instance.__index` field, letting the user to define class
methods and instance methods there. By default constructor and destructor
functions does nothing, and they are implemented at `class_table.constructor`
and `class_table.destructor` fields. `class_table.meta_instance` table can be
safety modified by calling to `class.extend_metamethod(...)`, or writing
non-safety manual changes into `class_table.meta_instance`.

#### Single hieritance

Single hieritance has been implemented by defining a metatable for the
`class_table.meta_instance.__index` table. Having a class table `myClass1`, you
can define the class `myClass2` as a child of previous one by writing:

```Lua
> -- parent class
> myClass1,myClass1Methods = class("myClass1")
> myClass1:constructor(...) whatever stuff here end
> -- derived or child class
> myClass2,myClass2Methods = class("myClass2", myClass1)
> myClass2:constructor(...) myClass1.constructor(self, ...) more stuff here end
```

Note that parent constructor call is not made by default, and
`myClass2:constructor` calls explicitly `myClass1.constructor` function passing
the `self` reference. In this way, whatever construction stuff done in
`myClass1` will be done for `myClass2`. It is not mandatory to do this, but in
many cases it will be helpful. However, you can build `myClass2` instances in
whatever way you want if the result is compatible with the methods inherited
from `myClass1`.

`myClass2Methods` can overwrite or not methods defined at `myClass1Methods`. Non
overwritten methods will be delegated calling `myClass1` implementation, so be
careful to ensure both objects are compatible.

Destructors are called following the hierarchy, first child destructor and after
the parent class.

### Reference
  
The following public functions are available:

#### object  = class(name[, parent_class[, class_table]])

Creates a class table with a given class_name. It receives an optional parent
class to implement simple heritance. It returns the class table; another table
which will contain the methods of the object. Constructor and destructor methods
will be declared into the class table as `class_name:constructor(...)` and
`class_name:destructor()`. Additionally, a third optional argument is given,
which allows to give a predefined `class_table`, useful is you want to make
global instead of local variables, or to convert into a class an existent table.

```Lua
> -- a simple class with name cls1
> cls1,cls1_methods = class("cls1")
> -- a derived class from cls1
> cls2,cls2_methods = class("cls2")
> -- a nested class defined into cls2 table
> cls2.nested1 = {}
> nested1,nested1_methods = class("cls2.nested1", nil, cls2.nested1)
> -- a derived nested class
> cls2.nested2 = {}
> nested2,nested2_methods = class("cls2.nested2", cls2.nested1, cls2.nested2)
```

A class_name cannot be used two times, that is, a class can't be redefined. If
you need to redefine a class, use `class.forget(class_name)` before. Otherwise
the following error message will be displayed:

```Lua
> class("cls1")
> class("cls1")
./oop-iter/class.lua:40: cls1 class name exists
stack traceback:
	[C]: in function 'assert'
	./oop-iter/class.lua:40: in function 'register_class_table'
	./oop-iter/class.lua:289: in function 'class'
	stdin:1: in main chunk
	[C]: in ?
```

#### boolean = class.is_a(object, class_table)

Predicate which returns true if a given object instance is a subclass of a given
Lua class table.

```Lua
> cls1,cls1_methods = class("cls1")
> cls2,cls2_methods = class("cls2")
> cls3,cls3_methods = class("cls3", cls1)
> cls3 = cls3()
> = class.is_a(o1, cls1)
true
> = class.is_a(o1, cls2)
false
> = class.is_a(o1, cls3)
true
```


#### super_class_table = class.super(class_table)

Returns the super class table of a given derived class table. Throws an error if
the given class has not a super class.

```Lua
> cls1,cls1_methods = class("cls1")
> cls2,cls2_methods = class("cls2", cls1)
> = ( class.super(cls2) == cls1 )
true
```
  
#### class_table = class.of(object)

Returns the class table of the given object instance.

```Lua
> cls1,cls1_methods = class("cls1")
> o = cls1()
> = ( class.of(o) == cls1 )
true
```

#### class.extend(class_table, key, value)

Extends the given class table with the addition of a new key=value pair into
the object instance table. It throws an error if the 1st parameter is not a
class table.

```Lua
> cls1,cls1_methods = class("cls1")
> foo = function() end
> class.extend(cls1, "foo", foo)
> ( cls1_methods.foo == foo )
true
```

#### class.extend_metamethod(class_table, key, value)

Extends the given class table with the addition of a new key=value pair into the
object `meta_instance` table, where metamethods are stored. It throws an error
if the 1st parameter is not a class table. Be careful, several metamethods
(`__index`, `__gc`) and keys (`id`, `cls`) are defined by default in order to
implement OOP, overwritten them will produce unexpected errors. The call will
throw an error if you try to overwrite any of them. However, `__tostring`
metamethod is also defined but it is totally safe to overwrite it.

```Lua
> cls1,cls1_methods = class("cls1")
> foo = function() return "Hello world!" end
> class.extend_metamethod(cls1, "__concat", foo)
> o = cls1()
> = o .. o
Hello world!
```

#### value = class.consult(class_table, key)

Returns the value associated with the given key at the given class_table. Throws
an error if the 1st parameter is not a class table.

```Lua
> cls1,cls1_methods = class("cls1")
> cls1_methods.foo = function() end
> = ( class.consult(cls1, "foo") == cls1_methods.foo )
true
```

#### value = class_table .. key

Equivalent to previous one.

```Lua
> cls1,cls1_methods = class("cls1")
> cls1_methods.foo = function() end
> = ( cls1.."foo" == cls1_methods.foo )
true
```

#### value = class.consult_metamethod(class_table, key)

Returns the value associated with the given key at the given class_table
meta_instance (instance metatable). Throws an error if the 1st parameter is not
a class table.

```Lua
> cls1,cls1_methods = class("cls1")
> foo = function() return "Hello world!" end
> class.extend_metamethod(cls1, "__concat", foo)
> = ( class.consult_metamethod(cls1, "__concat") ==  foo )
true
```

#### value = class.call(class_table, method, ...)

Calls a method in a given class_table using the given vararg arguments. It
throws an error if the 1st parameter is not a class table or if the given method
doesn't exist.

```Lua
> cls1,cls1_methods = class("cls1")
> cls1_methods.foo = function(self) print(self.n) end
> class.call(cls1, "foo", { n=5 })
5
```

#### boolean = class.is_class(class_table)

Returns true/false if the given Lua value is a class table.

```Lua
> cls1,cls1_methods = class("cls1")
> = class.is_class(cls1)
true
```

#### boolean = class.is_derived(object)

Returns true/false if the given instance object is an instance of a derived
class.

```Lua
> cls1,cls1_methods = class("cls1")
> cls2,cls2_methods = class("cls2", cls1)
> o1 = cls1()
> o2 = cls2()
> = class.is_derived(o1)
false
> = class.is_derived(o2)
true
```
  
#### class_table,methods_table = class.find(class_name)

Returns the class table associated with the given class_name.

```Lua
> cls1,cls1_methods = class("cls1")
> aux_cls1,aux_cls1_methods = class.find("cls1")
> = ( cls1 == aux_cls1 and cls1_methods == aux_cls1_methods )
```

#### class.forget(class_name)

Removes the given class_name from the auxiliary table of classes, allowing to
redifine this class. **Notice** that the class can't be removed at all because
your scripts can have taken the class tables as upvalue, and the instantiated
objects will continue working as expected.

```Lua
> cls1 = class("cls1")
> cls1 = class("cls1")
./oop-iter/class.lua:40: cls1 class name exists
stack traceback:
	[C]: in function 'assert'
	./oop-iter/class.lua:40: in function 'register_class_table'
	./oop-iter/class.lua:289: in function 'class'
	stdin:1: in main chunk
	[C]: in ?
> class.forget("cls1")
> second_cls1 = class("cls1")
> = ( cls1 == second_cls1 )
false
```
