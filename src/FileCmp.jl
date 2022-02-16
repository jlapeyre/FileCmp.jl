module FileCmp

export filecmp

"""
    Info

Information on result of `filecmp(path1, path2; info=true)`, which compares
the files `path1` and `path2` byte by byte.

# Fields
- _byte_index::Int : `0` if no differing bytes were found.
                      Otherwise the first index at which differing bytes were found.
- _size_cmp::Int :  `cmp(filesize(f1), filesize(f2))`

- _bytes_read::Int : number of bytes read from each file (not the sum from both files).

In particular, the files are the same, that is have exactly the same content, if and only if
both `_byte_index` and `_size_cmp` are equal to zero.
"""
struct Info
    _byte_index::Int
    _size_cmp::Int
    _bytes_read::Int
end

"""
    files_equal(info::Info)

Return `true` if the files compared to produce `info` are the same.

The following is always true:
`filecmp(p1, p2; info=false) == files_equal(filecmp(p1, p2; info=true))`
"""
files_equal(info::Info) = info._byte_index == 0 && info._size_cmp == 0


"""
    got_eof(info::Info)::Int

Return `-1` if first file is a prefix of the second one. That is,
an EOF occured on the first file, but not the second, and all compared bytes were equal.
Return `1` if the reverse happened. Otherwise, return `0`.
"""
function got_eof(info::Info)
    info._byte_index == 0 || return 0
    return info._size_cmp
end

"""
    bytes_read(info::Info)

The number of bytes read from each file before either differing bytes were found,
or EOF on one or both files.
"""
bytes_read(info::Info) = info.bytes_read


# Return 0 if buffers are equal when truncated to the same length,
# else the number of the index at which they differ.
# This is only used to find the differing byte index once it is
# determined that they differ.

function _where_memcmp(buf1, buf2, n::Integer)
    @assert n >= 0
    m = min(n, length(buf1), length(buf2))
    ii = 1
    while true
        @inbounds buf1[ii] != buf2[ii] && break
        ii += 1
        ii > m && break
    end
    return ii > m ? 0 : ii
end

# Base._memcmp is faster
function _memcmp(buf1, buf2, n::Integer)
    m = min(n, length(buf1), length(buf2))
    c = 0
    @inbounds for i in 1:m
        c += buf1[i] != buf2[i]
    end
    return c
end


"""
    filecmp(path1::AbstractString, path2::AbstractString, bufsize=0; info=Val(false); limit=0)
    filecmp(io1::IO, io2::IO, bufsize=0; info=Val(false), limit=0)

Determine if files at `path1` and `path2` have the same content and optionally return
information on how they differ.
For `info==false` the return type is `Bool`.
In this case, return `true` if files at `path1` and `path2` are equal byte by byte
and `false` otherwise.
For `info==true` the return type is `FileCmp.Info`, which records at which byte
index, if any, the files differ, and a comparison of the sizes of the files.
(See [`FileCmp.Info`](@ref)).

If `path1` or `path2` does not exist an exception is thrown.

The keyword argument `info` may be one of `true`, `false`, `Val(true)`, or `Val(false)`.
The first two are more convenient. The latter two allow the return type to be inferred.

If `limit` is greater than zero, then read at most `limit` bytes.

The files are read into buffers of `bufsize` bytes. If `bufsize=0`, then a default is used.
"""
function filecmp(io1::IO, io2::IO, _bufsize::Integer=0; info=Val(false), limit::Integer=0)
    _bufsize < 0 && throw(ArgumentError("bufsize cannot be less than zero. got " * _bufsize))
    bufsize = iszero(_bufsize) ? 65536 : Int(_bufsize)
    buf1 = Vector{UInt8}(undef, bufsize)
    buf2 = similar(buf1)
    count, n1, n2 = 0, 0, 0
    remaining = limit
    while !(eof(io1) || eof(io2))
        nb = remaining > 0 ? remaining : length(buf1)
        n1 = readbytes!(io1, buf1, nb)
        n2 = readbytes!(io2, buf2, nb)
        n = min(n1, n2)
        if limit > 0
            remaining -= n
        end
#        ret = _memcmp(buf1, buf2, n)
        ret = Base._memcmp(buf1, buf2, n)
        if ret != 0
            ! _is_true(info) && return false
            n_last = _where_memcmp(buf1, buf2, n)
            count += n_last
            return Info(count, cmp(n1, n2), count)
        end
        count += n
        if limit > 0 && remaining <= 0
            break
        end
    end
    _info = Info(0, cmp(n1, n2), count)
    return _is_true(info) ? _info : files_equal(_info)
end

_is_true(x::Bool) = x
_is_true(::Val{true}) = true
_is_true(::Val{false}) = false

# systemerror varies with Julia versions, so we do our own for more compatibility
throw_filenotfound(path) = throw(SystemError(path, Cint(2)))

function filecmp(path1::AbstractString, path2::AbstractString, bufsize=0; info::Union{Bool,Val{true},Val{false}}=Val(false),
                 limit::Integer=0)
    stat1, stat2 = stat(path1), stat(path2)
    isfile(stat1) || throw_filenotfound(path1)
    isfile(stat2) || throw_filenotfound(path2)
    filesize(stat1) != filesize(stat2) && ! _is_true(info) && limit == 0 && return false
    stat1 == stat2 && return _is_true(info) ? Info(0, 0, 0) : true # same file
    open(path1, "r") do file1
        open(path2, "r") do file2
            return filecmp(file1, file2, bufsize; info=info, limit=limit)
        end
    end
end

end # module FileCmp
