#!/usr/bin/env julia
using Logging, LoggingExtras
using Base.Filesystem
using Dates

name = nameof(@__MODULE__)

juliapackages::Vector{String} = ["LoggingExtras"]
dependencies::Vector{String} = []
optionals::Vector{String} = []

function getflags()
  return [
    (["?", "-?", "--?", "-h", "--help"],
      :(println(@doc name);
      exit())
    ),
    (["-v", "--verbose"],
      :(state.loglvl = Logging.Debug)
    ),
    (["-l", "--log"],
      :(state.logtofile = true)
    )]
end

function getflags(behaviour)
  return append!(getflags(), behaviour)
end

function checkdependencies(deps::Vector{String})
  for dep in deps
    if isnothing(Sys.which(dep))
      @warn string("Missing ", dep)
    else
      @info string("Has ", dep)
    end
  end
end

function getflagparse(behaviour::Vector{Tuple{Vector{String},Expr}})::Function
  flagparse = function (state)
    for (flagvector, action) in behaviour
      if !isempty(ARGS)
        if ARGS[1] in flagvector
          @debug string("got flag ", ARGS[1], " do action: ", action)
          popfirst!(ARGS)
          eval(action)
          flagparse(state)
        end
      end
    end
    return state
  end
  return flagparse
end

function init()
  return init(getflags())
end

function init(flags)
  state = states()
  flagparse = getflagparse(getflags(flags))
  global state = flagparse(state)

  if state.logtofile
    logfile = string("log_", splitext(basename(PROGRAM_FILE))[1], "_", Dates.format(Dates.now(), "yyyy-mm-dd-HH-MM-SS"), ".txt")
    logger = TeeLogger(ConsoleLogger(stderr, state.loglvl), FileLogger(logfile))
  else
    logger = ConsoleLogger(stderr, state.loglvl)
  end
  global_logger(logger)

  statistics()

  checkdependencies(dependencies)
  if state.demandoptionals
    checkdependencies(optionals)
  end

  return state
end

function checkjuliapackages(deps)
  pkgs = Pkg.project().dependencies
  for dep in deps
    if haskey(pkgs, dep)
      @info string("Has package ", dep)
    else
      @warn string("Missing package ", dep)
    end
  end
end

function checkdependencies(deps)
  for dep in deps
    if isnothing(Sys.which(dep))
      @warn string("Missing ", dep)
    else
      @info string("Has ", dep)
    end
  end
end

function statistics()
  file = joinpath(homedir(), ".local", "state", "juliascripts.log")
  counter = 1
  if isfile(file)
    contents = readlines(file)
    filter = startswith.(contents, string(name))
    if 1 in filter
      counter = parse(Int, split(contents[filter][1])[2]) + 1
      replace!(contents, contents[filter][1] => (string(name, " ", counter)))
    else
      push!(contents, string(name, " ", counter))
    end
    write(file, join(contents, "\r\n"))
  else
    touch(file)
    write(file, string(name, " ", counter, "\r\n"))
  end
  @info string(ENV["USER"], " running ", name, " for the ", counter, " time")
end
