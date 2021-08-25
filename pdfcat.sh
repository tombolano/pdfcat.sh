#!/bin/bash

# -----------------------------------------------------------------------------
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# -----------------------------------------------------------------------------

# set -eux

# check for required commands
if ! command -v pdflatex &> /dev/null; then
	echo "Error: pdflatex not found" >&2
	exit 1
fi

if ! command -v latexmk &> /dev/null; then
	echo "Error: latexmk not found" >&2
	exit 1
fi


# check if the script is being sourced
[ "$0" = "$BASH_SOURCE" ] && _sourced=false || _sourced=true


# options
compilationdir=""
compilationdirremove=true
contentsname=""
defaultpdfpagesoptions="pages=-"
hyperrefoptions="colorlinks,linkcolor=blue"
generatetoc=false
geometryoptions=""
inputpreamble=""
inputbegin=""
inputaftertoc=""
inputend=""
outputfile="out.pdf"
pdfminorversion=7


# define variables and functions
declare -a _pdffiles
declare -a _pdfoptions
declare -A _secindex
declare -A _subsecindex
declare -A _subsubsecindex


function clearstate ()
{
	_pdffiles=()
	_pdfoptions=()
	_secindex=()
	_subsecindex=()
	_subsubsecindex=()
}

# Add a PDF file and its corresponding options
function addpdf ()
{
	# file
	_pdffiles+=("$1")

	# options
	local pdfopt=""
	[ $# -gt 1 ] && pdfopt="$2" || pdfopt="$defaultpdfpagesoptions"
	_pdfoptions+=("$pdfopt")
}

# Add a section
function addsection ()
{
	_secindex[${#_pdffiles[@]}]="$1"
}

# Add a subsection
function addsubsection ()
{
	_subsecindex[${#_pdffiles[@]}]="$1"
}

# Add a subsubsection
function addsubsubsection ()
{
	_subsubsecindex[${#_pdffiles[@]}]="$1"
}

# Show the help string
function showhelp ()
{
	local normal=$(tput sgr0)
	local bold=$(tput bold)
	local ul=$(tput smul)

	if [ -t 1 ] && [ "$bold" ]; then
		local bold_begin=$bold
		local bold_end=$normal
	else
		local bold_begin=""
		local bold_end=""
	fi

	
	if [ -t 1 ] && [ "$ul" ]; then
		local ul_begin=$ul
		local ul_end=$normal
	else
		local ul_begin="<"
		local ul_end=">"
	fi

	echo \
"${bold_begin}USAGE${bold_end}
	pdfcat.sh can be used as a command line program:

		pdfcat.sh ${ul_begin}options${ul_end}
	
	or it can be also used by sourcing it into a bash script with:

		. pdfcat.sh
	
	and using the functions provided (see the ${bold_begin}SOURCED USAGE${bold_end} section).

${bold_begin}DESCRIPTION${bold_end}
	pdfcat.sh is a bash script to concatenate PDFs using LaTeX with the
	'pdfpages' package (see https://www.ctan.org/pkg/pdfpages), while also
	allowing to specify sections and subsections, and to create a table of
	contents in the resulting PDF.

	This script requires the following utilities:
	* pdflatex (with the packages geometry, hyperref, inputenc, and pdfpages).
	* latexmk.
	* GNU coretutils.

	See also the pdfjam shell script (https://github.com/DavidFirth/pdfjam).

${bold_begin}OPTIONS${bold_end}
	-h, --help
		Show this help.

	-o, --output ${ul_begin}filename${ul_end}
		Set ouput PDF filename. Shorthand for -O outputfile ${ul_begin}filename${ul_end}.
		If not set it will default to out.pdf.
	
	-O, --option ${ul_begin}name${ul_end} ${ul_begin}value${ul_end}
		Set an option to a given value. See the ${bold_begin}CONFIGURATION OPTIONS${bold_end}
		section for the available options.

	-p, --pdf ${ul_begin}file${ul_end} [ ${ul_begin}options${ul_end} ]
		Add a PDF file with the corresponding options for \includecommand.
		If options are not specified, the default options specified in the
		${bold_begin}defaultpdfpagesoptions${bold_end} option will be used.
	
	-0, --section ${ul_begin}name${ul_end}
		Add a section.
	
	-1, --subsection ${ul_begin}name${ul_end}
		Add a subsection.

	-2, --subsubsection ${ul_begin}name${ul_end}
		Add a subsubsection.

	Options -p, -0, -1, and -2, can be specified multiple times.

${bold_begin}CONFIGURATION OPTIONS${bold_end}
	The available configuration options are:

	* ${bold_begin}compilationdir${bold_end}: Directory for generating and compiling the tex file. The default is
	  to create a temporary directory with mktemp.
	* ${bold_begin}compilationdirremove${bold_end}: Remove compilation directory at exit. Default: true.
	* ${bold_begin}contentsname${bold_end}: Name for the table of contents section.
	* ${bold_begin}defaultpdfpagesoptions${bold_end}: pdfpages package \includecommand options. Default: 'pages=-'.
	* ${bold_begin}generatetoc${bold_end}: Generate a table of contents. Default: false.
	* ${bold_begin}geometryoptions${bold_end}: Geometry package options.
	* ${bold_begin}hyperrefoptions${bold_end}: Hyperref package options. Default: 'colorlinks,linkcolor=blue'.
	* ${bold_begin}inputpreamble${bold_end}: LaTeX code to add at the preamble.
	* ${bold_begin}inputbegin${bold_end}: LaTeX code to add at the beginning of the document.
	* ${bold_begin}inputaftertoc${bold_end}: LaTeX code to add at the document after the table of content.
	* ${bold_begin}inputend${bold_end}: LaTeX code to add at the end of the document.
	* ${bold_begin}outputfile${bold_end}: Output filename. Default: out.pdf.
	* ${bold_begin}pdfminorversion${bold_end}: PDF minor version. Default: 7.

	The ${bold_begin}input*${bold_end} options also allow specifying a filename, for this, start
	the option with '@' and set the rest with the name of the file.

${bold_begin}SOURCED USAGE${bold_end}
	pdfcat.sh also allows sourcing it into a bash script. The functionality
	provided is the same as in command line. When sourced, pdfcat.sh provides
	the following functions:

	* addpdf ${ul_begin}file${ul_end} [ ${ul_begin}options${ul_end} ]
		Add a PDF file with the corresponding options for \includecommand.
		Equivalent to the command line -p or --pdf options.

	* addsection ${ul_begin}name${ul_end}
		Add a section. Equivalent to the command line -0 or --section options.

	* addsubsection ${ul_begin}name${ul_end}
		Add a subsection. Equivalent to the command line -1 or --subsection options.

	* addsubsubsection ${ul_begin}name${ul_end}
		Add a subsection. Equivalent to the command line -2 or --subsubsection options.

	* genpdf
		Generate the output PDF file.

	The PDF configuration options are available directly as variables. For
	example, to change the ${bold_begin}defaultpdfpagesoptions${bold_end} to 'pages=1', it can be done
	with the following bash line:

		defaultpdfpagesoptions='pages=1'

${bold_begin}EXAMPLES${bold_end}
	Consider that we have two PDFs, A1.pdf and A2.pdf, which belong to some
	topic A, and other two PDFs, B1.pdf and B2.pdf, which belong to some other
	topic B. We could generate a PDF document with two sections (A and B), and
	two subsections in each section, one for each PDF in each section. To do
	so we would call pdfcat.sh as follows:

		pdfcat.sh -O outputfile \"my_pdf.pdf\" -O generatetoc true \\
		          -0 \"A\" -1 \"My PDF A1\" -p A1.pdf -1 \"My PDF A2\" -p A2.pdf \\
		          -0 \"B\" -1 \"My PDF B1\" -p B1.pdf -1 \"My PDF B2\" -p B2.pdf
	
	If we source pdfcat.sh into a bash script we could do as follows:

		#!/bin/bash
		. pdfcat.sh
		
		outputfile=\"my_pdf.pdf\"
		generatetoc=true
		
		addsection \"A\"
		addsubsection \"My PDF A1\"
		addpdf \"A1.pdf\"
		addsubsection \"My PDF A2\"
		addpdf \"A2.pdf\"

		addsection \"B\"
		addsubsection \"My PDF B1\"
		addpdf \"B1.pdf\"
		addsubsection \"My PDF B2\"
		addpdf \"B2.pdf\"

		genpdf

${bold_begin}LIMITATIONS${bold_end}
	Limitations from the pdfpages package:
	* All pages in the output PDF will have the same size and orientation.
	* All kinds of links will get lost during inclusion.
	
	See the documentation of the pdfpages package for more information."
}


# Adds LaTeX code to a file
# Input parameters
# $1: file to insert the LaTeX code.
# $2: tex code. If it starts with "@" then it is taken as a file and an input
#     command is inserted instead. If is empty the function has no effect.
function _addlatexinput ()
{
	if [ "${2:0:1}" == "@" ]; then
		echo '\input{\detokenize{'$(realpath "${2:1}")'}}' >> "$1" 
	elif [ "$2" ]; then
		echo "$2" >> "$1"
	fi
}


# Generate the output PDF file
function genpdf ()
{
	echo "Generating PDF..."

	# check PDF files
	if [ ${#_pdffiles[@]} -eq 0 ]; then
		echo "Error: no PDF files specified" >&2
		exit 1
	fi

	for (( ii=0; ii < ${#_pdffiles[@]}; ii++ )); do
		if [ ! -f "${_pdffiles[$ii]}" ]; then
			echo "Error: file '${_pdffiles[$ii]}' does not exist" >&2
			exit 1
		fi
	done

	# check input* options for files
	for var in "inputpreamble" "inputbegin" "inputend"; do
		if [ "${!var:0:1}" == "@" ] && [ ! -f "${!var:1}" ]; then
			echo "Error: file '${!var:1}' does not exist" >&2
			exit 1
		fi
	done

	local dir="$compilationdir"
	if [ -z "$dir" ]; then
		# create temporary folder
		local dir=$(mktemp -d)
		if [ $? -ne 0 ]; then
			echo "Error creating temp directory" >&2
			exit 1
		fi
	elif [ ! -d "$dir" ]; then
		mkdir -p "$dir"
		if [ $? -ne 0 ]; then
			echo "Error creating directory '$dir'" >&2
			exit 1
		fi
	fi

	# latex file
	local output_tex="$dir/${outputfile/.pdf/}.tex"
	echo '' > "$output_tex"
	
	# build latex file
	echo '\documentclass{article}' >> "$output_tex"
	echo '\usepackage[utf8]{inputenc}' >> "$output_tex"
	echo '\usepackage['$hyperrefoptions']{hyperref}' >> "$output_tex"
	echo '\usepackage['$geometryoptions']{geometry}' >> "$output_tex"
	echo '\usepackage{pdfpages}' >> "$output_tex"
	echo '\pdfminorversion='$pdfminorversion >> "$output_tex"

	if [ "$contentsname" ]; then
		echo '\renewcommand{\contentsname}{'$contentsname'}' >> "$output_tex"
	fi

	# insert inputpreamble
	_addlatexinput "$output_tex" "$inputpreamble"
	
	echo '' >> "$output_tex"
	echo '\begin{document}' >> "$output_tex"

	# inputbegin
	_addlatexinput "$output_tex" "$inputbegin"
	
	if [ "$generatetoc" == true ] || [ "$generatetoc" -eq 1 ]; then
		echo '\phantomsection' >> "$output_tex"
		echo '\addcontentsline{toc}{section}{\contentsname}' >> "$output_tex"
		echo '\tableofcontents' >> "$output_tex"
	fi

	# inputaftertoc
	_addlatexinput "$output_tex" "$inputaftertoc"

	echo '\newgeometry{top=0pt}  % Remove top margin' >> "$output_tex"
	
	for (( ii=0; ii < ${#_pdffiles[@]}; ii++ )) do
		echo '' >> "$output_tex"
		echo '\phantomsection' >> "$output_tex"

		if [ "${_secindex[$ii]}" ]; then
			echo '\addcontentsline{toc}{section}{'"${_secindex[$ii]}"'}' >> "$output_tex"
		fi;

		if [ "${_subsecindex[$ii]}" ]; then
			echo '\addcontentsline{toc}{subsection}{'"${_subsecindex[$ii]}"'}' >> "$output_tex"
		fi;

		if [ "${_subsubsecindex[$ii]}" ]; then
			echo '\addcontentsline{toc}{subsubsection}{'"${_subsubsecindex[$ii]}"'}' >> "$output_tex"
		fi;

		echo '\includepdf['${_pdfoptions[$ii]}']{\detokenize{'$(realpath "${_pdffiles[$ii]}")'}}' >> "$output_tex"
	done;
	
	echo '\restoregeometry{}  % Restore original top margin' >> "$output_tex"

	# inputend
	_addlatexinput "$output_tex" "$inputend"

	echo '' >> "$output_tex"
	echo '\end{document}' >> "$output_tex"

	# Compile latex document
	latexmk -pdf -cd "$output_tex"

	local returnval=0
	if [ $? -ne 0 ]; then
		echo "Error creating the PDF" >&2
		returnval=1
		
	else
		cp "${output_tex/.tex/.pdf}" .
		echo "Done"
	fi

	if [ "$compilationdirremove" = true ] || \
	   [ "$compilationdirremove" = 1 ]; then
		rm -r $dir
	fi

	return $returnval
}


# call clearstate to initialize array variables
clearstate

# if script is being sourced return here
if $_sourced; then
	return
fi


# if no parameters are provided show help and exit
if [ $# -eq 0 ]; then
	showhelp
	exit 0
fi


# parse command line options
declare -A _optdict
_optdict[-0]=section
_optdict[--section]=section
_optdict[-1]=subsection
_optdict[--subsection]=subsection
_optdict[-2]=subsection
_optdict[--subsubsection]=subsubsection

while [ $# -gt 0 ]; do
	case "$1" in
		-h | --help ) showhelp; exit 0;;
		${!_optdict[@]} )
			if [ $# -ge 2 ]; then 
				add${_optdict[$1]} "$2"
				shift
			else
				echo "Error: argument for option $1 is missing" >&2
				exit 1
			fi;;
		-p | --pdf )
			if [ $# -ge 3 ] && [ ${3:0:1} != '-' ]; then
				addpdf "$2" "$3"
				shift 2
			elif [ $# -ge 2 ]; then 
				addpdf "$2"
				shift
			else
				echo "Error: argument for option $1 is missing" >&2
				exit 1
			fi;;
		-O | --option )
			if [ $# -ge 3 ] && [ ${3:0:1} != '-' ]; then
				declare "$2"="$3"
				shift 2
			else
				echo "Error: option $1 needs two arguments" >&2
				exit 1
			fi;;
		-o | --output )
			if [ $# -ge 2 ]; then 
				outputfile="$2"
				shift
			else
				echo "Error: argument for option $1 is missing" >&2
				exit 1
			fi;;
		-* ) echo "Error: unsupported option $1" >&2; exit 1;;
	esac
	shift
done


# generate pdf
genpdf
