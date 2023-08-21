#!/usr/bin/env julia
module mkpdf
include("util.jl")

@doc """
$name - create PDF from PNG images

# Options

- ? -? --? -h --help Show this screen.
- -v --verbose       Show on terminal what's happening during execution.
- -l --log           Write log to file.
- -t --trim          Trim page margins.
- -o --ocr           Also produce OCR files.

# Usage

$name [OPTIONS] [DIR | IMGS]

# Known Limitations
""" name

dependencies = ["gm"]
optionals = ["okular", "tesseract"]

mutable struct states
  demandoptionals::Bool
  loglvl::LogLevel
  logtofile::Bool
  pdfname::String
  trim::Bool
  ocr::Bool
  states() = new(true, Logging.Warn, false, "", false, false)
end

state = init(getflags([
  (["-o", "--ocr"],
    :(state.ocr = true)
  ),
  (["-t", "--trim"],
    :(state.trim = true)
  )
]))

function converttopdf(files::Vector{String}, outfile::String)
  infiles = filter(endswith(r".png|.PNG"), filter(isfile, files))
  state.pdfname = string(outfile, ".pdf")

  command = `gm convert -geometry 50% -strip -colors 6 $infiles $(state.pdfname)`
  @debug command
  run(command)
end

function main()

  if isempty(ARGS)
    @debug "call without arguments, convert all PNGs in working dir, use name of working dir"
    converttopdf(readdir(), basename(pwd()))

  elseif length(ARGS) == 1
    arg = ARGS[1]
    if isdir(arg)
      @debug "call on single directory (eg from dired). get output name from deepest directory name"
      cd(arg)
      converttopdf(readdir(pwd()), basename(rstrip(arg, '/')))

    elseif arg == "-"
      @debug "call on files from stdin, use name of first png file"
      # infiles = string.(split(readline(stdin)))
      infiles = basename.(readlines(stdin))
      outname = splitext(filter(endswith(r".png|.PNG"), filter(isfile, infiles))[1])[1]
      converttopdf(infiles, outname)

    elseif isfile(arg)
      @debug "call on single file, strip filename extension"
      converttopdf([arg], splitext(basename(arg))[1])

    end
  else
    if 1 in isdir.(ARGS)
      @debug "call on at least one directory and other stuff. error out because this is not supposed to happen"
      error("No support for converting a directory AND separate files into a PDF")

    else
      @debug "call on multiple files, use name of first file, strip extension"
      converttopdf(ARGS, splitext(basename(ARGS[1]))[1])

    end
  end

  if isfile(state.pdfname) & !isnothing(Sys.which("okular"))
    @info "opening $(state.pdfname) in okular.."
    run(`okular $(state.pdfname)`, wait=false)
  end

end

main()

end