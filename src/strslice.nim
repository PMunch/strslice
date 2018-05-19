## This is an implementation of string slices that works on a common underlying
## string shared through a reference instead of copying parts of the string.
## This has the benefit of not requiring the time and memory of copying parts
## of the string over and over. The only thing that get's copied is the
## reference of the underlying string, and two new indices for the start and
## stop of the string slice. This means that by changing the original string,
## any string slice that was created from it will be updated as well. The
## benefit of using string slices comes when copying parts of the string to
## pass on, for example in a combinatorial parser.
import strutils

type
  StringSlice* = ref object
    str: ref string
    start: int
    stop: int

proc `$`*(str: StringSlice): string =
  ## Converts a string slice to a string
  if str == nil or str.str == nil: nil
  else: str.str[str.start .. str.stop]

proc newStringSlice*(str: string): StringSlice {.noInit.} =
  ## Create a new string slice that references the string. This creates a new
  ## reference to the string, so any changes to the underlying string will be
  ## visible in all slices made from this string.
  new result
  new result.str
  result.str[] = str
  result.start = 0
  result.stop = str.len-1

converter toStringSlice*(str: string): StringSlice {.noInit.} =
  ## Automatic converter to create a string slice from a string
  newStringSlice(str)

proc `[]`*(str: StringSlice,
           slc: HSlice[int, int or BackwardsIndex]): StringSlice {.noInit.} =
  ## Grab a slice of a string slice. This returns a new string slice that
  ## references the same underlying string.
  if slc.a < 0:
    raise newException(IndexError, "index out of bounds")
  new result
  result.str = str.str
  result.start = str.start + slc.a
  when slc.b is BackwardsIndex:
    if slc.b.int > str.len + 1:
      raise newException(RangeError, "value out of range: " &
        $(str.len + 1 - slc.b.int))
    result.stop = str.stop - slc.b.int + 1
  else:
    if slc.b + 1 < slc.a or slc.b > str.high:
      raise newException(IndexError, "index out of bounds")
    result.stop = str.start + slc.b

proc high*(str: StringSlice): int =
  ## Get the highest index of a string slice
  str.stop - str.start

proc len*(str: StringSlice): int =
  ## Get the length of a string slice
  str.high + 1

proc `&`*(sl1, sl2: StringSlice): StringSlice {.noInit.} =
  ## Concatenate two string slices like the regular `&` operator does for
  ## strings. WARNING: This creates a new underlying string.
  newStringSlice($sl1 & $sl2)

proc startsWith*[T: StringSlice or string](str: StringSlice, sub: T): bool =
  ## Compares a string slice with a string or another string slice of shorter or
  ## equal length. Returns true if the first string slice starts with the next.
  if sub.len > str.len: return false
  when T is StringSlice:
    for i in sub.start..sub.stop:
      if str.str[i + str.start - sub.start] != sub.str[i]: return false
  else:
    for idx, c in sub:
      if str.str[idx + str.start] != c: return false
  return true

proc `==`*[T: StringSlice or string](str: StringSlice, cmp: T): bool =
  ## Compare a string slice to a string or another string slice. Returns true
  ## if they are both identical.
  if cmp.isNil():        return false
  if str.len != cmp.len: return false
  when T is StringSlice:
    for i in cmp.start..cmp.stop:
      if str.str[i + str.start - cmp.start] != cmp.str[i]: return false
    return true
  else:
    return str.startsWith(cmp)

import strutils

proc find*(a: SkipTable, s: StringSlice, sub: string,
  start: Natural = 0, last: Natural = 0): int =
  ## Finds a string in a string slice. Calls the similar procedure from
  ## ``strutils`` but with updated start and last references.
  max(-1,
    strutils.find(a, s.str[], sub, start + s.start, last + s.stop) - s.start
  )

proc find*(s: StringSlice, sub: char,
  start: Natural = 0, last: Natural = 0): int =
  ## Finds a string in a string slice. Calls the similar procedure from
  ## ``strutils`` but with updated start and last references.
  max(-1,
    strutils.find(s.str[], sub, start + s.start, last + s.stop) - s.start
  )

proc find*(s: StringSlice, sub: string,
  start: Natural = 0, last: Natural = 0): int =
  ## Finds a string in a string slice. Calls the similar procedure from
  ## ``strutils`` but with updated start and last references.
  max(-1,
    strutils.find(s.str[], sub, start + s.start, last + s.stop) - s.start
  )

proc find*(s: StringSlice, sub: StringSlice,
  start: Natural = 0, last: Natural = 0): int =
  ## Finds a string slice in another string slice. This should be really fast
  ## when both string slices are from the same base string, as it will compare
  ## only the indices. Otherwise it will convert the string slice to find into
  ## a regular string and call the normal find operation.
  if s.str == sub.str:
    if sub.start + start >= s.start and min(sub.stop, last) <= s.stop:
      sub.start - s.start
    else:
      -1
  else:
    s.find($sub, start, last)

proc strip*(s: StringSlice, first = true, last = true): StringSlice {.noInit.} =
  ## Strips whitespace from both sides (controllable with the ``first`` and
  ## ``last`` arguments) of the string slice and returns a new string slice
  ## with the same underlying string.
  new result
  result.str = s.str
  result.start = s.start
  result.stop = s.stop
  if first:
    for i in result.start..result.stop:
      if not (result.str[i] in Whitespace): break
      result.start += 1
  if last:
    for i in countdown(result.stop, result.start):
      if not (result.str[i] in Whitespace): break
      result.stop -= 1

iterator items*(a: StringSlice): char =
  ## Iterate over each character in a string slice
  for i in a.start..a.stop:
    yield a.str[i]

when isMainModule:
  let
    s1 = "Hello world"
    s2 = newStringSlice("Hello world")
    s3 = s2[6 .. ^1]
    s4 = s2[2 .. ^1]

  echo s1.find("world")
  echo s2.find("world")
  echo s3.find("world")
  echo s2.find(s3)
  echo s3.find(s4)
