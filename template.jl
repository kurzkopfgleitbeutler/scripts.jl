#!/usr/bin/env julia
module TODO
include("util.jl")

@doc """
$name - TODO

# Options

- ? -? --? -h --help Show this screen.
- -v --verbose       Show on terminal what's happening during execution.
- -l --log           Write log to file.

# Usage

$name [OPTIONS] [target device] filename [file names]

# Known Limitations
""" name

# push!(juliapackages, "")
# dependencies = [""]
# optionals = [""]

mutable struct states
  demandoptionals::Bool
  loglvl::LogLevel
  logtofile::Bool
  states() = new(true, Logging.Warn, false)
end

# state = init(getflags([...]))
state = init()

# functions...

function main()



end
main()
end
@time eval(TODO)