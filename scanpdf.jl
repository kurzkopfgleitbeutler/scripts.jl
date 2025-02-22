#!/usr/bin/env julia
module scanpdf
include("util.jl")

@doc """
$name - scan from the command line

# Options

- ? -? --? -h --help Show this screen.
- -v --verbose       Show on terminal what's happening during execution.
- -l --log           Write log to file.

## Paper Formats

- -a4 -a4p --a4portrait		(default)
- -a5 -a5l --a5landscape
-     -a5p --a5portrait
- -a6 -a6p --a6portrait

# Usage

$name [OPTIONS] [target device] filename [file names]

# Known Limitations
""" name

# push!(juliapackages, "")
# dependencies = [""]
optionals = ["mkpdf"]

mutable struct states
  demandoptionals::Bool
  loglvl::LogLevel
  logtofile::Bool
  scanner::String
  format::paperFormat
  pages::Integer
  pdfname::String
  states() = new(true, Logging.Warn, false, "", a4portrait, 1, "")
end

state = init(getflags([
  (["-a4", "-a4p", "--a4portrait"],
    :(state.format = a4portrait)
  ),
  (["-a5p", "--a5portrait"],
    :(state.format = a5portrait)
  ),
  (["-a5", "-a5l", "--a5landscape"],
    :(state.format = a5landscape)
  ),
  (["-a6", "-a6p", "--a6portrait"],
    :(state.format = a6portrait)
  )
]))

# functions...
function setscanner()
  @info "Finding scanner.."
  file = joinpath("/tmp", "scanpdf-scanner.txt")
  if isfile(file)
    state.scanner = readlines(file)[1]
    @debug "Get scanner address from temporary file" state.scanner
  else
    @debug "Find scanner address"
    scanners = split(readchomp(`scanimage --list-devices`), "\n", keepempty=false)
    filter = contains.(scanners, "Canon LiDE 100 flatbed scanner")
    state.scanner = split(scanners[filter][1], r"`|'")[2]
    @debug "and write it to temporary file" state.scanner
    touch(file)
    write(file, state.scanner)
  end
end

function anykey(message="press any key for next page..")
  println(message)
  setraw!(raw) = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, raw)
  setraw!(true)
  read(stdin, 1)
  setraw!(false)
end

function main()

  setscanner()

  println("Scan how many pages?")
  pages = tryparse(Int, readline())

  println("Filename?")
  state.pdfname = readline()

  if !isdir(state.pdfname)
    mkdir(state.pdfname)
  end
  cd(state.pdfname)

  for i = 1:pages
    println("Scanning page $i of $pages.. ")
    scan = `scanimage \
      --device-name=$(state.scanner) \
      --format=png \
      -l 2mm \
      -t 2mm \
      -x $(state.format.width) \
      -y $(state.format.height) \
      --mode Color \
      --resolution 300dpi \
      --output-file=$(state.pdfname)-$(i).png`
    @debug scan
    run(scan, wait=true)
    if i < pages
      anykey()
    end
  end

  @info "creating $(state.pdfname).pdf.."
  run(`mkpdf`, wait=false)
  cd("..")

end
main()
end
@time eval(scanpdf)