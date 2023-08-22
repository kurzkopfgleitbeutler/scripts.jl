#!/usr/bin/env julia
module sfh
include("util.jl")
using AnyAscii

@doc """
$name - safe file handles - make filenames safe, remove characters that can lead to problems.

# Options

- ? -? --? -h --help Show this screen.
- -v --verbose       Show on terminal what's happening during execution.
- -l --log           Write log to file. [Default: Yes]

# Usage

$name [OPTIONS]

# Known Limitations
""" name

push!(juliapackages, "AnyAscii")

mutable struct states
  demandoptionals::Bool
  loglvl::LogLevel
  logtofile::Bool
  confirm::Bool
  states() = new(false, Logging.Warn, true, true)
end

state = init(getflags((["-y", "--yes"],
  :(state.confirm = false))
))

function process(collection::Vector{String})
  res = anyascii.(collection)
  # filter!(isascii, collection)
  res = lowercase.(res)
  res = replace.(res,
    r"\s+" => "_",
    # "_+_" => "_plus_",
    "+" => "plus",
    # "_&_" => "_and_",
    "&" => "and",
    "!" => "",
    "?" => "",
    r"[(){},;'\[\]]" => ""
  )
  return res
end

function main()
  # If walking subdirs, files need to be renamed separately from and before directories.

  entries = readdir()
  files = filter(isfile, entries)
  # dirs = process(filter(isdir, entries))

  processed = process(files)
  newfiles = []

  for file in processed
    fh, ext = splitext(file)
    if length(fh) > 1
      if startswith(fh, ".")
        file = string(".", replace(fh, "." => ""))
      else
        file = replace(fh, "." => "")
      end
    end
    file = string(file, ext)
    push!(newfiles, file)
  end


  mapping::Vector{Pair{String,String}} = []
  for (i, file) in enumerate(files)
    if !(file == newfiles[i])
      push!(mapping, file => newfiles[i])
    end
  end
  @info mapping

  if state.confirm
    show(stdout, "text/plain", mapping)
    println()
    println("Do you want to perform these renaming actions?")
    confirm = readline(stdin)

    if !occursin(r"yes|y", confirm)
      println("Aborting..")
      exit()
    end
  end

  for (from, to) in mapping
    mv(from, to)
  end

end
main()
end
@time eval(sfh)
