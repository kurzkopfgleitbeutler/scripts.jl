#!/usr/bin/env julia
module install
using Base.Filesystem
using Pkg

name = nameof(@__MODULE__)
@doc """
$name - install julia scripts on system

# Usage

$name [file names]
""" name

dependencies = ["LoggingExtras", "AnyAscii"]
for dep in dependencies
	Pkg.add(dep)
end

prefix = "/usr/local/bin/"
if isempty(ARGS)
  apps = ["gib.jl", "mkpdf.jl", "sfh.jl"]
else
  apps = ARGS
end

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
