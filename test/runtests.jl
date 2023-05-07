using FileCmp
using FileCmp: Info, files_equal, got_eof, bytes_read
using Test

include("aqua_test.jl")
if VERSION >= v"1.7"
    include("jet_test.jl")
end

@testset "FileCmp.jl" begin
    write_file = function(fname::String, data)
        open(fname, "w") do io
            write(io, data)
        end
    end
    dir = mktempdir()
    nbytes = 1000
    nbytes_trunc = 500
    v1 = rand(UInt8, nbytes)
    path = fname -> joinpath(dir, fname)
    write_file(path("test1"), v1)
    write_file(path("test2"), @view v1[1:nbytes_trunc])
    v2 = rand(UInt8, nbytes)
    write_file(path("test3"), v2)
    cp(path("test1"), path("test4"))
    v3 = rand(UInt8, nbytes_trunc)
    write_file(path("test5"), v3)

    @test filecmp(path("test1"), path("test1"))
    _info = filecmp(path("test1"), path("test1"); info=true)
    @test files_equal(_info)
    @test got_eof(_info) == 0
    @test bytes_read(_info) == 0  # files are the same
    @test ! filecmp(path("test1"), path("test2"))

    _info = filecmp(path("test1"), path("test2"); info=true)
    @test isa(_info, Info)
    @test _info._byte_index == 0
    @test _info._size_cmp == 1
    @test got_eof(_info) == 1
    @test bytes_read(_info) == nbytes_trunc
    @test filecmp(path("test1"), path("test2"); limit=filesize(path("test2")))
    @test ! filecmp(path("test1"), path("test2"); limit=(filesize(path("test2")) + 1))

    @test ! filecmp(path("test1"), path("test3"))

    _info = filecmp(path("test1"), path("test3"); info=true)
    @test isa(_info, Info)
    @test _info._byte_index != 0
    @test _info._size_cmp == 0
    @test ! files_equal(_info)
    @test got_eof(_info) == 0
    @test filecmp(path("test1"), path("test4"))
    @test files_equal(filecmp(path("test1"), path("test4"); info=true))
    @test ! filecmp(path("test1"), path("test5"))


    _info = filecmp(path("test1"), path("test5"); info=true)
    @test isa(_info, Info)
    @test _info._byte_index != 0
    @test _info._size_cmp == 1
    @test ! files_equal(_info)
    @test got_eof(_info) == 0

    @test_throws SystemError filecmp("sdfsdf", "sdfdd")
    @test_throws SystemError filecmp("sdfsdf", path("test1"))
    @test_throws SystemError filecmp(path("test1"), "sdfd")
end
