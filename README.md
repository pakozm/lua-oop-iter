Lua OOP-Iter
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
file for an example of this module.

### Description 

The class module implements OOP for Lua in a similar way as luabind does for C++
classes in [APRIL-ANN toolkit](https://github.com/pakozm/april-ann). So, the
class module functions are compatible with it. The OOP is implemented by
defining several tables for each desired class. Every class has a name, which
allow to store it into a weak table in order to retrieve the class by its name
in any moment. A class is defined by doing:

```Lua
class_table, methods_table = class('myClassName', parent_class_table)
```
  
Two tables are returned as result of this call, the `class_table` which allows to
construct instances by using the `class_table` as a function (it has implemented
the `__call` metamethod), and a `methods_table` where instance methods must be
defined. Class methods will be defined into `class_table`, and special names
constructor/destructor allow to define the behavior of the object at these
specific stages. So, the first is to define a constructor and a destructor
(NOTE: none of them are necessary):

```Lua
class_table:constructor(whatever) self.blah = whatever end
class_table:destructor() free_resource(self.blah) end
```
  
In the same way, instance methods will be defined in `methos_table`:
  
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

Looking inside the architecture, the class function defines the following
hierarchy of tables:

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

### Reference
  
The following public functions are available:

#### object  = class(name, parent_class)

Creates a class table with a given class_name. It receives an optional parent
class to implement simple heritance. It returns the class table; another table
which will contain the methods of the object. Constructor and destructor methods
will be declared into the class table as `class_name:constructor(...)` and
`class_name:destructor()`.

#### boolean = class.is_a(object, class_table)

Predicate which returns true if a given object instance is a subclass of a given
Lua class table.
  
#### super_class_table = class.super(class_table)

Returns the super class table of a given derived class table. Throws an error if
the given class has not a super class.
  
#### class_table = class.of(object)

Returns the class table of the given object instance.

#### value = class.consult(class_table, key)

Returns the value associated with the given key at the given class_table. Throws
an error if the 1st parameter is not a class table.

#### value = class_table .. key

Equivalent to previous one.

#### value = class.consult_metamethod(class_table, key)

Returns the value associated with the given key at the given class_table
meta_instance. Throws an error if the 1st parameter is not a class table.

#### value = class.call(class_table, method, ...)

Calls a method in a given class_table using the given vararg arguments. It
throws an error if the 1st parameter is not a class table or if the given method
doesn't exist.
  
#### class.extend(class_table, key, value)

Extends the given class table with the addition of a new key=value pair into
the object instance table. It throws an error if the 1st parameter is not a
class table.

#### class.extend_metamethod(class_table, key, value)

Extends the given class table with the addition of a new key=value pair into the
object `meta_instance` table, where metamethods are stored. It throws an error
if the 1st parameter is not a class table. Be careful, several metamethods
(`__index`, `__gc`) and keys (`id`, `cls`) are defined by default in order to
implement OOP, overwritten them will produce unexpected errors. The call will
throw an error if you try to overwrite any of them. However, `__tostring`
metamethod is also defined but it is totally safe to overwrite it.
 
#### boolean = class.is_derived(object)

Returns true/false if the given instance object is an instance of a derived
class.
  
#### class_table = class.find(class_name)

Returns the class table associated with the given class_name.
