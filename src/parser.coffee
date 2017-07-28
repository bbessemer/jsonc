###
# Copyright (c) 2017 The Start Cup, LLC. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
###

parse = (bytes, classname, classdefs) ->
  i = 0

  parse_i32 = ->
    bytes[i++] | bytes[i++] << 8 | bytes[i++] << 16 | bytes[i++] << 24

  parse_u16 = -> bytes[i++] | bytes[i++] << 8
  parse_i16 = -> if (x = parse_i16()) > 0x7fff then x | 0xffff0000 else x
  parse_u8 = -> bytes[i++]
  parse_i8 = -> if (x = parse_i8()) > 0x7f then x | 0xffffff00 else x

  parse_f32 = ->
    integer = parse_i32()
    sign = if (integer & 0x80000000) then -1.0 else 1.0
    exponent = (integer & 0x7f800000) >>> 23
    mantissa = integer & 0x007fffff
    sign * (switch exponent
      when 0 then Math.pow(2, -149) * mantissa
      when 0xff
        if mantissa is 0 then Infinity else NaN
      else Math.pow(2, exponent - 150) * (mantissa | 0x00800000))

  parse_f64 = ->
    int_lo = parse_i32()
    int_hi = parse_i32()
    sign = if (int_hi & 0x80000000) then -1.0 else 1.0
    exponent = (int_hi & 0x7ff00000) >>> 20
    mantissa = int_lo + (int_hi & 0x000fffff) * Math.pow(2, 32)
    sign * (switch exponent
      when 0 then Math.pow(2, -1074) * mantissa
      when 0x7ff
        if mantissa is 0.0 then Infinity else NaN
      else Math.pow(2, exponent - 1075) * (mantissa + Math.pow(2, 52)))

  parseArray = (reader, length) -> reader() for j in [0..length]

  parseType = (type) ->
    [type, arraylen] = type.match(/\[([0-9]*)\]/) ? [type, 0]
    reader = switch type
      when 'i32', 'int' then parse_i32
      when 'u16', 'unsigned short' then parse_u16
      when 'i16', 'short' then parse_i16
      when 'u8', 'char', 'unsigned char' then parse_u8
      when 'i8', 'signed char' then parse_i8
      when 'f32', 'float' then parse_f32
      when 'f64', 'double' then parse_f64
      else (() -> parseClass classdefs[type])
    if (arraylen) then parseArray(reader, arraylen) else reader()

  parseClass = (classdef) ->
    obj = {}
    obj[key] = parseType(type) for key, type of classdef
    return obj

  return parseType(classname)

module.exports = parse
