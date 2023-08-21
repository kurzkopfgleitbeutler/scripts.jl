#!/usr/bin/env julia
module gib
include("util.jl")

@doc """
$name - easily share files between kdeconnect-enabled devices

# Options

- ? -? --? -h --help Show this screen.
- -v --verbose       Show on terminal what's happening during execution.
- -l --log           Write log to file.

# Usage

$name [OPTIONS] [target device] filename [file names]

# Known Limitations

- Can not send directories
- If sending several files, first file can not have the same name as any of the available receiving devices
""" name

dependencies = ["kdeconnect-cli", "rofi"]

mutable struct states
  demandoptionals::Bool
  loglvl::LogLevel
  logtofile::Bool
  states() = new(false, Logging.Warn, false)
end

state = init()
function main()

  # sender -> message -> receiver

  if length(ARGS) == 0
    @info "No cli args. Show help page."
    println(@doc name)
    exit()
  end

  if length(ARGS) == 1
    @info "1 cli arg, use as file to send. Pick receiving device."
    receivingDevice = readchomp(pipeline(`kdeconnect-cli --list-available --name-only`, `rofi -threads 0 -dmenu -i -auto-select -p "Send to which device?"`))

  elseif length(ARGS) >= 2
    @info ">1 cli args. Check if first argument is an available device."
    availableDevices = readchomp(`kdeconnect-cli --list-available --name-only`)
    @info "available devices" availableDevices

    if contains(availableDevices, ARGS[1])
      @info "Use first argument as device."
      receivingDevice = ARGS[1]

    else
      @info "First argument is not in list of available devices. Pick receiving device."
      receivingDevice = readchomp(pipeline(`kdeconnect-cli --list-available --name-only`, `rofi -threads 0 -dmenu -i -auto-select -p "Send to which device?"`))
    end
  end
  @info "picked device" receivingDevice

  files = realpath.(filter(isfile, ARGS))
  if !isempty(files)
    command = `kdeconnect-cli --name "$receivingDevice" --share "$files"`
    @info command
    run(command)
  else
    @warn "No files in selection."
  end

end
main()
end
@time eval(gib)