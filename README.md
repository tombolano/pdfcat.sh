# pdfcat.sh

pdfcat<span>.sh</span> is a bash script to concatenate PDFs using LaTeX with the pdfpages package (see https://www.ctan.org/pkg/pdfpages), while also allowing to specify sections and subsections, and to create a table of contents in the resulting PDF.

This script requires the following utilities:

- pdflatex (with the packages geometry, hyperref, inputenc, and pdfpages).
- latexmk.
- GNU coretutils.

See also the pdfjam shell script (https://github.com/DavidFirth/pdfjam).


## Usage

pdfcat<span>.sh</span> can be used as a command line program:

    pdfcat.sh options

or it can be also used by sourcing it into a bash script with:

    . pdfcat.sh

and using the functions provided (see the **Sourced usage** section).


## Options

- `-h, --help`
Show the help message.

- `-o, --output <filename>`
Set ouput PDF filename. Shorthand for `-O outputfile <filename>`.
If not set it will default to out.pdf.

- `-O, --option <name> <value>`
Set an option to a given value. See the **Configuration options** section for the available options.

- `-p, --pdf <file> [ <options> ]`
Add a PDF file with the corresponding options for `\includepdf`. If options are not specified, the default options specified in the `defaultpdfpagesoptions` option will be used.

- `-0, --section <name>`
Add a section.

- `-1, --subsection <name>`
Add a subsection.

- `-2, --subsubsection <name>`
Add a subsubsection.

Options `-O`, `-p`, `-0`, `-1`, and `-2` can be specified multiple times.

## Configuration options

The available configuration options are:

- `compilationdir`: Directory for generating and compiling the tex file. The default is to create a temporary directory with `mktemp`.
- `compilationdirremove`: Remove compilation directory at exit. Default: `true`.
- `contentsname`: Name for the table of contents section.
- `defaultpdfpagesoptions`: pdfpages package `\includepdf` command options. Default: `'pages=-'`.
- `generatetoc`: Generate a table of contents. Default: `false`.
- `geometryoptions`: Geometry package options.
- `hyperrefoptions`: Hyperref package options. Default: `'colorlinks,linkcolor=blue'`.
- `inputpreamble`: LaTeX code to add at the preamble.
- `inputbegin`: LaTeX code to add at the beginning of the document.
- `inputaftertoc`: LaTeX code to add at the document after the table of content.
- `inputend`: LaTeX code to add at the end of the document.
- `outputfile`: Output filename. Default: `'out.pdf'`.
- `pdfminorversion`: PDF minor version. Default: 7.

The `input*` options also allow specifying a filename, for this, start the option with the character `@` and set the rest with the name of the file.


## Sourced usage

pdfcat<span>.sh</span> also allows sourcing it into a bash script. The functionality provided is the same as in command line. When sourced, pdfcat<span>.sh</span> provides the following functions:

- `addpdf <file> [ <options> ]`
Add a PDF file with its options for `includecommand`. Equivalent to the command line `-p` or `--pdf` options.

- `addsection <name>`
Add a section. Equivalent to the command line `-0` or `--section` options.

- `addsubsection <name>`
Add a subsection. Equivalent to the command line `-1` or `--subsection` options.

- `addsubsubsection <name>`
Add a subsection. Equivalent to the command line `-2` or `--subsubsection` options.

- `genpdf`
Generate the output PDF file.

The PDF configuration options are available directly as variables. For example, to change the `defaultpdfpagesoptions` to `'pages=1'`, it can be done with the following bash line:

```bash
defaultpdfpagesoptions='pages=1'
```

## Examples

Consider that we have two PDFs, A1.pdf and A2.pdf, which belong to some topic A, and other two PDFs, B1.pdf and B2.pdf, which belong to some other topic B. We could generate a PDF document with two sections (A and B), and two subsections in each section, one for each PDF in each section. To do so we would call pdfcat.sh as follows:

```bash
pdfcat.sh -O outputfile "my_pdf.pdf" -O generatetoc true \
          -0 "A" -1 "My PDF A1" -p A1.pdf -1 "My PDF A2" -p A2.pdf \
          -0 "B" -1 "My PDF B1" -p B1.pdf -1 "My PDF B2" -p B2.pdf
```

If we source pdfcat<span>.sh</span> into a bash script we could do as follows:

```bash
#!/bin/bash
. pdfcat.sh

outputfile="my_pdf.pdf"
generatetoc=true

addsection "A"
addsubsection "My PDF A1"
addpdf "A1.pdf"
addsubsection "My PDF A2"
addpdf "A2.pdf"

addsection "B"
addsubsection "My PDF B1"
addpdf "B1.pdf"
addsubsection "My PDF B2"
addpdf "B2.pdf"

genpdf
```

## Limitations

Limitations from the pdfpages package:

- All pages in the output PDF will have the same size and orientation.
- All kinds of links will get lost during inclusion.

See the documentation of the pdfpages package for more information.
