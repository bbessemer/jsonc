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

serialize = (object, classname, classdefs) ->
  bytes = []

  write_i32 = (i32) ->
    bytes.push(i32 & 0xff)
    bytes.push((i32 & 0xff00) >>> 8)
    bytes.push((i32 & 0xff0000) >>> 16)
    bytes.push((i32 & 0xff000000) >>> 24)

  write_i16 = (i16) ->
    bytes.push(i16 & 0xff)
    bytes.push((i16 & 0xff00) >>> 8)

  write_i8 = (i8) -> bytes.push(i8 & 0xff)

  write_f32 = (float) ->
    sign = if float < 0
      float *= -1
      -0x80000000|0
    else 0
    log = Math.floor(Math.log2(float))
    [mantissa, exponent] = switch
      when log < -126 then [(float * Math.pow(2, 23 + 126)) & 0x007fffff, 0]
      when log is Infinity then [0, 255]
      when log is NaN then [1, 255]
      else [(float * Math.pow(2, 23 - log)) | 0, log + 127]
    write_i32(sign | (exponent << 23) | mantissa)
###
  write_f64 = (float) ->
    sign = if float < 0
      float *= -1
      -0x80000000|0
    else 0
    log = Math.floor(Math.log2(float))
    [mantissa, exponent] = switch
      when log < -1022 then [(float * Math.pow(2, 1022)), 0]
      when log is Infinity then [1.0, 0x7ff]
      when log is NaN then [1.5, 0x7ff]
      else [(float * Math.pow(2, -log)), log + 1023]
    write_i32(sign | (exponent << 23) | mantissa)
###

  writeArray = (array, writer, maxlen) -> writer(array[i]) for i in [0..maxlen]

  writeType = (item, type) ->
    [type, arraylen] = type.match(/\[([0-9]*)\]/) ? [type, 0]
    writer = switch type
      when 'i32', 'int' then write_i32
      when 'u16', 'unsigned short' then write_i16
      when 'i16', 'short' then write_i16
      when 'u8', 'char', 'unsigned char' then write_i8
      when 'i8', 'signed char' then write_i8
      when 'f32', 'float' then write_f32
      when 'f64', 'double' then write_f64
      else ((item) -> writeClass(item, classdefs[type]))
    if (arraylen) then writeArray(item, writer, arraylen) else writer(item)

  writeClass = (item, classdef) ->
    writeType(item[key], type) for key, type of classdef

  writeType(object, classname)
  return new Uint8Array(bytes)
