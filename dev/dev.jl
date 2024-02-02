function make_bin_files(fname, nbytes=2^20)
    write_file = function(fname::String, data)
        open(fname, "w") do io
            write(io, data)
        end
    end
    v1 = rand(UInt8, nbytes)
    v2 = copy(v1)
    v2[end] = v1[end] + 1
    write_file(fname * "1", v1)
    write_file(fname * "2", v2)
    return nothing
end
