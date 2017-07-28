# JSONC

`jsonc` stands for either ‘JSON with classes’ or ‘JSON compiler’ depending on
your mood, and it functions as both: a binary format for JSON objects based on
external class definitions (which are themselves JavaScript objects), and a
compiler and parser to serialize and deserialize objects to and from this
format. `jsonc` is lightweight, fast (once JavaScript optimizations have been
applied allowing it to compete with the browser's native JSON parser), and
interoperable with server-side C/C++ code.

## Why use JSONC?

  * **Smaller transmission size**—As a binary format, JSONC is naturally
    smaller than the text-based JSON. Although a JSONC file *plus its class
    definitions* (which must be encoded in text-based JSON) are normally larger
    than the equivalent text-based JSON, the far more common use case for JSON
    in modern applications is to receive numerous pieces of data (e.g., from
    an API) with essentially the same shape. JSON is inefficient because it has
    to transmit shape information (which, more often than not, is already known
    by the client) as well as actual data—and, being designed for human
    readability, it doesn't transmit *any* information particularly efficiently.
    JSONC allows shape data to be transmitted once per class of object to be
    received, perhaps even embedded in the application code, and an unlimited
    number of API requests to be made without having to retransmit that
    information.

  * **Interoperability with C/C++ on the server**—A JSONC object has a binary
    layout identical to the equivalent tightly-packed C structure or C++ object
    on little-endian architectures (which is essentially every system currently
    in use, unless you have an ancient Mac or an IBM mainframe). Server-side
    software written in native languages like C, C++, or Rust can simply dump
    internal data structures to the network without a wasteful JSON generation
    step.

  * **Light weight**—less than 5 KB minified.

## JSONC class definition format

JSONC class definitions have the same shape as an object of the class they're
defining, but with type names in place of values. They closely resemble
TypeScript class definitions formatted as JSON objects. All class definitions
should be attached to a single JavaScript object with the class names as keys.
For example:

```javascript
{
  "Foo": {
    "bar": "Bar",
    "primitive1": "int",
    "primitive2": "char[8]"
  },

  "Bar": {
    "field1": "i16",
    "field2": "i16"
  }
}
```

That would be equivalent to the following C struct definitions:

```c
struct Bar {
  short field1;
  short field2;
};

struct Foo {
  struct Bar bar;
  int primitive1;
  char primitive2[8];
}
```

In addition to user-defined class types, fields of JSONC classes can also have
any of the standard primitive types, or be fixed-size arrays of any one type.
Primitive types can be referred to by the familiar C/Java convention  (`byte`,
`short`, `int`—plus `unsigned` variants—`float`, and `double`), or the more
clear and succinct [Rust convention](https://doc.rust-lang.org/1.6.0/book/primitive-types.html)
(`i8`, `u8`, `i16`, `u16`, `i32`, `f32`, and `f64`). Arrays of a type `T` are
represented as `T[n]`, where n is the length of the array. The `char` type is
identical to `u8`, except that arrays of `char`s will be parsed as UTF-8
strings instead of raw arrays of bytes, which makes `char` (the singular type)
semantically equivalent to `char[1]`, whereas `u8` and `u8[1]` are distinct,
although of the same size.

Variable-size arrays, or arrays combining more than one type, are not currently
permitted, although the former may be added in a future version. 64-bit integers
and 32-bit unsigned integers are also not permitted, as they do not exist in
JavaScript.

*Note: `f64` serialization is currently broken, although parsing works fine.*

## API

In the browser, JSONC adds a global `JSONC` object which has two methods
(TypeScript definitions follow; they should be fairly self-explanatory):

```typescript
parse: (bytes: Uint8Array, classname: string, classdefs: object) => object
serialize: (obj: object, classname: string, classdefs: object) => Uint8Array
```

`classname` represents the name of the class of the object to be parsed
or serialized. See above for information on the structure of `classdefs`.
