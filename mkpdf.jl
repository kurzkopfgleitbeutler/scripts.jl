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

- PDFs generated with an OCR layer aren't sized down, which quadruples file size
""" name

dependencies = ["gm"]
optionals = ["org.kde.okular", "tesseract", "gs"]

mutable struct states
  demandoptionals::Bool
  loglvl::LogLevel
  logtofile::Bool
  format::paperFormat
  pdfname::String
  trim::Bool
  ocr::Bool
  states() = new(true, Logging.Warn, false, a4portrait, "", false, false)
end

state = init(getflags([
  (["-o", "--ocr"],
    :(state.ocr = true)
  ),
  (["-t", "--trim"],
    :(state.trim = true)
  ),
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

function stripfile(file::AbstractString)::IO
  tmpio = IOBuffer()
  open(file) do io
    for line in eachline(io, keep=true)
      if length(strip(line)) > 0
        print(tmpio, line)
      end
    end
  end
  return tmpio
end

function converttopdf(files::Vector{String}, outfile::String)
  infiles = filter(endswith(r".png|.PNG"), filter(isfile, files))
  state.pdfname = string(outfile, ".pdf")

  trim = []
  if state.trim
    trim = ["-fuzz", "80%", "-trim"]
  end

  format = []
  if state.format == a5landscape || state.format == a5portrait
    # "-gravity", "NorthWest", "-density", "300x300", "-units", "PixelsPerInch",
    format = ["-crop", string(trunc(Int, state.format.width / 25.4 * 300), "x", trunc(Int, state.format.height / 25.4 * 300))]
  elseif state.format == a6portrait
    format = ["-crop", string(trunc(Int, state.format.height / 25.4 * 300), "x", trunc(Int, state.format.width / 25.4 * 300))]
  end

  if state.ocr
    tmpocrfile = string(outfile, "_ocr")

    p = pipeline(`gm convert $format $trim $infiles TIFF:-`, `tesseract - "$tmpocrfile" -l deu+eng quiet pdf hocr txt`)
    @debug string("Generate files ", tmpocrfile, ".pdf, ", tmpocrfile, ".hocr, and ", tmpocrfile, ".txt") p
    run(p)

    @debug string("Remove empty lines from ", tmpocrfile, ".txt and write result to ", outfile, ".txt")
    write(string(outfile, ".txt"), String(take!(stripfile(string(tmpocrfile, ".txt")))))
    @debug string("Remove file ", tmpocrfile, ".txt")
    rm("$(tmpocrfile).txt")

    p2 = Cmd(`/usr/bin/gs -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -dSubsetFonts=true -dNOPAUSE -dBATCH -dQUIET -sOutputFile="$(outfile)_ocr2.pdf" "$(tmpocrfile).pdf"`)
    @debug string("Route file ", outfile, ".pdf through ghostscript for optimization and write to ", tmpocrfile, "_ocr2.pdf") p2
    run(p2)
    @debug string("Remove file ", tmpocrfile, ".pdf")
    rm("$(tmpocrfile).pdf")

    @debug string("Rename ", outfile, "_ocr2.pdf to \"", state.pdfname, "\"")
    mv("$(outfile)_ocr2.pdf", state.pdfname)

  else
    command = `gm convert $format -geometry 50% -strip -colors 6 $trim $infiles $(state.pdfname)`
    @debug string("Convert images ", infiles, " to \"", state.pdfname, "\"") command
    run(command)
  end
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

  if isfile(state.pdfname) & !isnothing(Sys.which("org.kde.okular"))
    @info "opening $(state.pdfname) in okular.."
    run(`org.kde.okular $(state.pdfname)`, wait=false)
  end

end

main()

end