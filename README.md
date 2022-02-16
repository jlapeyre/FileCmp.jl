# FileCmp

[![Build Status](https://github.com/jlapeyre/FileCmp.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/FileCmp.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/FileCmp.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/FileCmp.jl)


`FileCmp` provides the function `filecmp`, which returns `true` if two files are equal byte by byte.

This code is adapted from an example in [this Discourse post](https://discourse.julialang.org/t/how-to-obtain-the-result-of-a-diff-between-2-files-in-a-loop/23784/3).

Only `filecmp` is exported.

#### function `filecmp`

`filecmp` is similar to the Python function
[`filecmp.cmp`](https://docs.python.org/3/library/filecmp.html)
but provides more information, as does the Unix/Linux/GNU
command [`cmp`](https://www.gnu.org/software/diffutils/).

```
    filecmp(path1::AbstractString, path2::AbstractString; info=Val(false); limit=0)
    filecmp(io1::IO, io2::IO; info=Val(false); limit=0)
```

Return `true` if `path1` and `path2` are equal byte by byte. Otherwise return `false`.
If either file does not exist an exception is thrown. If `info` is `true`, then
return an instance of `FileCmp.Info` instead of `Bool`.
The keyword argument `info` may be one of `true`, `false`, `Val(true)`, or
`Val(false)`. The latter two are supported in case the application requires
the return type to be inferrable.

If `limit` is greater than zero, then read at most `limit` bytes.

The files are read into buffers of `bufsize` bytes. If `bufsize=0`, then a default is used.


#### function `files_equal`

```
    FileCmp.files_equal(info::FileCmp.Info)
```

Return `true` if the files compared to produce `info` are the byte-for-byte equal.

The following is always true:
`filecmp(p1, p2; info=false) == files_equal(filecmp(p1, p2; info=true))`


#### function `got_eof`

    got_eof(info::FileCmp.Info)::Int

Return `-1` if first file is a prefix of the second one. That is,
an EOF occured on the first file, but not the second, and all compared bytes were equal.
Return `1` if the reverse happened. Otherwise, return `0`.


#### function `bytes_read`

    bytes_read(info::Info)

The number of bytes read from each file before either differing bytes were found,
or EOF on one or both files.
