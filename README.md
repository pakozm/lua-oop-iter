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

Basic functions
---------------

Besides classes and iterator objects, this module incorporates basic but
useful functional extensions.

### Bind function

`function = oopiter.bind(func, v1, v2, ..., vn)`

Allow to curry any Lua function, as long as it receives positional arguments.
Thid `bind` function receives a function as first argument and a following
variadic list with `n` arguments. Any of this `n` arguments can be `nil`.

```
> p2 = bind(math.pow, nil, 2)
> print( p2(4) )
16
```

### Addition function

`boolean = oopiter.add(a,b)`

### Substraction function

`boolean = oopiter.sub(a,b)`

### Multiplication function

`boolean = oopiter.mul(a,b)`

### Division function

`boolean = oopiter.div(a,b)`

### Log addition

`number = oopiter.logadd(a,b)`

Computes the log addition operation.

### Clamp function

`number = oopiter.clamp(value, lower, upper)`

Clamps the given value to be in the given range `[lower,upper]`.

### Sign function

`number = oopiter.sign(a)`

Returns `1`, `0` or `-1` depending in the sign of `a`.

### Not function

`boolean = oopiter.lnot(a)`

### Or function

`boolean = oopiter.lor(a,b)`

### And function

`boolean = oopiter.land(a,b)`

### Greater or equal function

`boolean = oopiter.ge(a,b)`

### Greater than function

`boolean = oopiter.gt(a,b)`

### Less or equal function

`boolean = oopiter.le(a,b)`

### Less than function

`boolean = oopiter.lt(a,b)`

### Equals function

`boolean = oopiter.eq(a,b)`



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

#### Simple inheritance

Simple inheritance has been implemented by defining a metatable for the
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
class to implement simple inheritance. It returns the class table; another table
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

Returns the class table of the given object instance. In case the given
parameter is a Lua value but not an object, it returns `nil`. So, this method
can be used also to ask if a Lua value is or not an object.

```Lua
> cls1,cls1_methods = class("cls1")
> o = cls1()
> = ( class.of(o) == cls1 )
true
> = class.of( {} )
nil
> = class.of( 5 )
nil
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

Iterator module
---------------

See
[test-iterator.lua](https://github.com/pakozm/lua-oop-iter/blob/master/test-iterator.lua)
file for an example (unit tests) of this module.

Another interesting functional library is
[Lua Functional Library](http://rtsisyk.github.io/luafun/index.html). This
documentation and some of our API has been inspired by it.

### Description 

The iterator module implements basic functional programming extensions for Lua.
It is used in [APRIL-ANN toolkit](https://github.com/pakozm/april-ann), but it
has been deployed independently of APRIL-ANN to allow the Lua community to use
it. Iterators in Lua are instantiated by three parameters, where the last two
are optional. The first parameter is an iterator function, and it is the most
important. The other two are necessary if you want to implement **pure
functional** iterators, putting the iterator function state outside of the
function, allowing to make copies of the iterator and more sophisticated stuff.

In its basis, the iterator module allows to do some things like:

```Lua
> iterator{ 4, 3, 2, 1 }:apply(print)
4
3
2
1
> iterator{ a=1, b=2, c=3 }:apply(print)
1
2
3
> iterator.range(10):apply(print)
1
2
3
4
5
6
7
8
9
10
> iterator.zip(iterator.range(21,30), iterator{10,9,8,7,6,5,4,3,2,1}):apply(print)
21	10
22	9
23	8
24	7
25	6
26	5
27	4
28	3
29	2
30	1
```

The iterator is a class which captures the three iterator parameters and allow
to perform multiple operations on it. Every operation returns a shallow copy of
the iterator or a result, but it can be cloned if necessary. Cloning iterators
doesn't work if it is not a **pure functional** iterator.

### Generators reference

#### Constructor: iterator(f,s,v) or iterator(t)

The constructor of the class receives a Lua iterator tripplete or a table. When
a Lua iterator tripplete is given, it is captured and stored internally in the
constructed object:

```Lua
> -- the following is a different implementation of ipairs iterator
> it = iterator(function(s,i) return s[i+1] and i+1,s[i+1] end,{4,3,2,1},0)
> it:apply(print)
1	4
2	3
3	2
4	1
> -- you can use directly the ipairs or pairs iterators
> iterator(pairs{ a=4, b=1, c=2, e=10 }):apply(print)
b	1
a	4
e	10
c	2
```

If a table is given, constructor automatically decides to use `ipairs()` or
`pairs()` function depending in the value of `#t == 0`. If `true`, it is
supposed to be a pure dictionary table, and it will be traversed using
`pairs()`. If `false`, it is supposed to be a pure array table, and it will be
traversed using `ipairs()`. In any case, the keys will be removed from results
list.

```Lua
> iterator{ 4, 3, 2, 1 }:apply(print)
4
3
2
1
> iterator{ a=4, b=1, c=2, e=10 }:apply(print)
1
4
10
2
```

**Warning**, if you give the constructor a mixed table (with array part and
  dictionary part) it will be traversed using `ipairs()` method, ignoring the
  dictionary part.

#### iterator.range([start],stop,[step])

Returns an iterator instance which generates a sequence of numbers using the
given `start`, `stop` and `step` parameters. By default `start=1` and `step=1`.

```Lua
> iterator.range(6):apply(print)
1
2
3
4
5
6
> iterator.range(31,40,2):apply(print)
31
33
35
37
39
```

#### iterator.duplicate(...)

Returns an **infinite** iterator which duplicates its given variadic list of
arguments in every iterator result.

```Lua
> iterator.duplicate("a",4,"b"):take(4):apply(print)
a	4	b
a	4	b
a	4	b
a	4	b
```

#### iterator.tabulate(func)

Returns an **infinite** iterator which calls the given function with values
`f(0), f(1), ...`.

```Lua
> iterator.tabulate(function(x) return 2*x+1 end):take(6):apply(print)
1
3
5
7
9
11
```

#### iterator.ones()

Returns an **inifite** list of ones.

#### iterator.zeros()

Returns an **inifite** list of zeros.

#### iterator.zip(i1, i2, ..., iN)

Returns an iterator which concatenates the results of its N given iterators.
All the N arguments must be instances of iterator class. The iterator length
will be the minimum length of the N given iterators.

```Lua
> iterator.zip( iterator.duplicate('a'), iterator.range(10) ):apply(print)
a	1
a	2
a	3
a	4
a	5
a	6
a	7
a	8
a	9
a	10
```

### Slicing

#### ... = it:nth(k)

Returns the value of the iterator at the `k` iteration. The iterator will be
placed at the iteration `k+1`.

```Lua
> = iterator.range(10):nth(4)
4
```

#### ... = it:head()

Equivalent to `it:nth(1)`.

#### it = it:tail()

Skips the head of the iterator and returns itself:

```Lua
function iterator_methods:tail()
  self()
  return self
end
```

#### it = it:take(number or predicate)

If given a number `n`, returns an iterator which processes the first `n`
iterations, ignoring the rest.

```Lua
> iterator.ones():take(4):apply(print)
1
1
1
1
```

If given a predicate function `f`, returns an iterator to the longest prefix
which satisfies the given predicate function.

```Lua
> iterator.range(10):take(function(x) return x < 4 end):apply(print)
1
2
3
```

#### it = it:drop(number or predicate)

If given a number `n`, returns an iterator which drops the first `n` iterations.

```Lua
> iterator.range(10):drop(3):apply(print)
4
5
6
7
8
9
10
```

If given a predicate function `f`, returns an iterator which ignores the longest
prefix which satisfies the given predicate function.

```Lua
> iterator.range(10):drop(function(x) return x < 4 end):apply(print)
4
5
6
7
8
9
10
```

#### left,right = it:split(n)

Returns two iterators, the first taken the first `n` iterations, and the
second one dropping the first `n` iterations. This method requires
**pure functional** iterators to work properly.

```Lua
> left,right = iterator{1, 2, 3, 4, 5}:split(2)
> left:apply(print)
1
2
> right:apply(print)
3
4
5
```

### Selection

#### it = it:select(n1, n2, ...)

Returns an iterator which filters the number of returned values selection the
given positions. It is useful to ignore keys in `ipairs()` or `pairs()`
iterators.

```Lua
> iterator(ipairs{ 4, 3, 2, 1 }):apply(print)
1	4
2	3
3	2
4	1
> iterator(ipairs{ 4, 3, 2, 1 }):select(1):apply(print)
1
2
3
4
> iterator(ipairs{ 4, 3, 2, 1 }):select(2):apply(print)
4
3
2
1
```

#### it = it:field(k1, k2, ...)

Returns an iterator which filters the returned values by accessing to the given
variadic list of keys. It needs that all returned values to be tables.

```Lua
> iterator{ {a=1, b=2, c=3}, {a=4, b=5, c=6} }:field('a','c'):apply(print)
1	3
4	6
```

### Indexing

#### number = it:index(...)

Returns the first iteration number where the iterator values are equals to
the given variadic list of arguments.

```Lua
> = iterator.zip( iterator.range(10), iterator.range(11,20) ):index(2,12)
2
```

#### it = it:indices(...)

Returns an iterator to the positions of the caller iterator which are equals
to the given variadic list of arguments.

```Lua
= iterator{ 1, 2, 4, 2, 5, 4, 2, 6 }:indices(2):apply(print)
2
4
7
```

### Filtering

#### it = it:filter(predicate)

Returns a new iterator to those elements which satisfy the given predicate
function.

```Lua
> iterator.range(40):filter(function(x) return x>20 and x<25 end):apply(print)
21
22
23
24
```

#### it = it:grep(regexp)

Returns a new iterator to those elements which satisfy the given Lua regular
expression `regexp`. Only valid for iterators which return *one string value*
per iteration.

```Lua
> iterator{ 'first', 'second', 'fish', 'find', 'third' }:grep('fi'):apply(print)
first
fish
find
```

#### left,right = it:partition(predicate)

Returns two iterators, `left` with the elements which satisfy the given
repdicate, `right` with the elements which not satisfy the predicate.
This method needs **pure functional** iterators to work properly.

```Lua
> iterator.zip( iterator.range(20):partition(function(x) return x%2 == 1 end) ):apply(print)
1	2
3	4
5	6
7	8
9	10
11	12
13	14
15	16
17	18
19	20
```

### Reductions

#### value = it:reduce(function(acc,...) CODE end, start)

Computes a reduction given the function an accumulator `acc` (first argument),
and the list of results produced by the iterator. The `start` argument is used
to initialize `acc=start`, so an empty iterator will return `start` as value.

```Lua
> = iterator.range(20):reduce(function(acc,x) return acc+x end, 0)
210
```

#### n = it:size()

Returns the length of the iterator.

#### number = it:sum()

Returns the sum of all the elements. The iterator must return one number every
time it is called.

#### number = it:prod()

Returns the product of all the elements. The iterator must return one number
every time it is called.

#### number = it:max()

Returns the maximum of all elements. The iterator must return one number every
time it is called.

#### number = it:min()

Returns the minimum of all elements. The iterator must return one number every
time it is called.

#### t = it:table()

Returns a table with all the iterator results. The returned table will be
enumerated from 1 to `it:size()` if only one value is returned in every
iteration, otherwise, the first result of every iteration will be taken as key
of the table.

```Lua
> = table.concat(iterator.range(20):table(), " ")
1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
```

#### str = it:concat( [sep1 [, sep2] ] )

Returns a string with the concatenation of all the elements. `sep1=sep2=""` by
default. If `sep1` is given, but not `sep2`, therfore `sep2=sep1`. Elements
in every iteration will be separated by `sep1`, elements between iterations
will be separated by `sep2`.

```Lua
> = iterator.zip( iterator.duplicate('a'), iterator.range(10) ):concat()
a1a2a3a4a5a6a7a8a9a10
> = iterator.zip( iterator.duplicate('a'), iterator.range(10) ):concat(" ")
a 1 a 2 a 3 a 4 a 5 a 6 a 7 a 8 a 9 a 10
> = iterator.zip( iterator.duplicate('a'), iterator.range(10) ):concat(" ", "\n")
a 1
a 2
a 3
a 4
a 5
a 6
a 7
a 8
a 9
a 10
```

### Transformations

#### it = it:map(func)

Returns an iterator where all the elements are being mapped with the result
returned by `func`.

```Lua
> iterator.range(10):map(function(x) return 2*x end):apply(print)
2
4
6
8
10
12
14
16
18
20
```

#### it = it:enumerate()

Returns an iterator where all the elements had been enumerated with a new first
column of data, starting at 1.

```Lua
> iterator.zip( iterator{"first","second","third"}, iterator{"a","b","c"} ):enumerate():apply(print)
1	first	a
2	second	b
3	third	c
```

### Other

#### it:apply(function)

Applies the given function to all iterator elements.

```Lua
> iterator.range(10):apply(function(x) print(2*x) end)
2
4
6
8
10
12
14
16
18
20
```

#### ... = it:step()

Performs one iteration step, returning result values list.

#### f,s,v = it:get()

Returns the underlying Lua iterator tripplete.

#### for a,b,c,... in it do CODE end

It is possible to use this iterators as standard Lua function iterators in
generic Lua for loops.

```Lua
> for v in iterator{1,2,3} do print(2*v) end
2
4
6
```

#### other_it = it:clone()

Returns a clone (deep copy) of the caller iterator. To work properly,
this method needs **pure functional** iterators. Be careful, this method makes
a copy of the Lua iterator functions and its upvalues.
