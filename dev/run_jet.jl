##
## This code is intended to be the same (stay in sync with) the jet_test.jl in the test suite. But
## it is sometimes more convenient to run it outside the test suite.
##
## Before using, activate an environment with required packages (the current directory has such an
## environment.)
## Usage:
## include("runjet.jl")
## (reports, filtered_reports) = run_reports()
## See the docstring below for `run_reports`

using FileCmp
using JET

const package_to_analyze = FileCmp

## Ignore these errors. The first string in the pair is
## the report message. The second is the file it occurs in.
## Not very precise, but ok for now.
const SKIP_MATCHES = [
    #  ("type Nothing has no field den", "parameters.jl"),
    ("invalid builtin function call", "FileCmp.jl"),
]

## Skip reports for which return true
const SKIP_REP_TESTS = [
    rep -> rep isa JET.UncaughtExceptionReport,
]

##
## JET. Static analysis of the package
##

function analyze_package(package_name=package_to_analyze)
    result = report_package(
        string(package_name); report_pass=JET.BasicPass(), ignored_modules=( # TODO fix issues with these modules or report them upstrem
        #                AnyFrameModule(Base),
    )
    )
    reports = JET.get_reports(result)
    return reports
end

"""
    match_report(package, report::InferenceErrorReport, msg::String, file::String)

Return `true` if the message is `msg` and the first file in the stack trace is `file`.

`file` should be given relative to the `src` directory of `package`.
"""
function match_report(package, report, msg::String, file::String)
    hasproperty(report, :msg) || return false
    report.msg != msg && return false
    filepath = joinpath(dirname(pathof(package)), file)
    report_filepath = string(report.vst[1].file)
    return report_filepath == filepath
end

function match_reports(package, report, match_data::Vector)
    for (msg, file) in match_data
        match_report(package, report, msg, file) && return true
    end
    return false
end

function do_rep_skip_test(rep, skip_rep_tests=SKIP_REP_TESTS)
    for rep_test in skip_rep_tests
        rep_test(rep) && return true
    end
    return false
end

# Filter out reports that we don't consider failures.
# We could flag some that could be fixed as broken tests.
# This could be more fine grained.

function filter_reports(reports, package)
    somereports = empty(reports)
    for rep in reports
        do_rep_skip_test(rep) && continue
        match_reports(package, rep, SKIP_MATCHES) && continue
        push!(somereports, rep)
    end
    return somereports
end

# print just some of the report
function print_report(report)
    hasproperty(report, :msg) && println(report.msg)
    return hasproperty(report, :vst) && println(report.vst)
end

function run_reports()
    reports = analyze_package(package_to_analyze)
    somereports = filter_reports(reports, package_to_analyze)
    @show somereports
    number_of_ignored_jet_reports = length(reports) - length(somereports)
    @info string(number_of_ignored_jet_reports, " reports ignored.")
    @info string(length(somereports), " reports not ignored.")
    for (i, rep) in enumerate(somereports)
        println("Report $i");
        print_report(rep)
        println("Done Report $i\n\n");
    end
    return (somereports, reports)
end
