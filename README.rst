strslice
===========
This is an implementation of string slices that works on a common underlying
string shared through a reference instead of copying parts of the string.
This has the benefit of not requiring the time and memory of copying parts
of the string over and over. The only thing that get's copied is the
reference of the underlying string, and two new indices for the start and
stop of the string slice. This means that by changing the original string,
any string slice that was created from it will be updated as well. The
benefit of using string slices comes when copying parts of the string to
pass on, for example in a combinatorial parser.

This file is automatically generated from the documentation found in
strslice.nim. Use ``nim doc strslice.nim`` to get the full documentation.
