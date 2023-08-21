#!/usr/bin/env julia
module install
using Base.Filesystem

name = nameof(@__MODULE__)
@doc """
$name - install julia scripts on system

# Usage

$name [file names]
""" name

prefix = "/usr/local/bin/"
apps = []

util = joinpath(prefix, "util.jl")
command = `sudo install -o root -g root -m 0755 -v util.jl $util`
res = read(command, String)
@info command res

for app in apps
  if isfile(app)
    target = joinpath(prefix, splitext(app)[1])
    command = `sudo install -o root -g root -m 0755 -v $app $target`
    res = read(command, String)
    @info command res
  end
end

end