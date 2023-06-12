#!/bin/bash

# Prints error message if invalid options are used.
die() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Basic usage instructions
usage() {
    echo ""
    echo "<filename>" refers to csv file with the following fields, downloadable from Wanikani Item Inspector.
    echo Reading Brief, Item, Meaning Brief, Item Type, Reading by Type.
    echo Basic use: 6 kanji per sheet "$0 <filename>"
    echo For a4 paper "$0 -p a4 <filename>"
    echo For small kanji: 8 per sheet "$0 -s small <filename>"
    echo For large kanji: 4 per sheet "$0 -s large <filename>"
    echo Kanji size and papersize can be changed together, e.g. "$0 -s small -p a4 <filename>" 
    echo For brush practice sheets, requires HakusyuKaisyoBold true type font - free on the web. "$0 -f <filename>"
    echo ""
    echo "$0 -h -? or --help" print this message.
    echo ""
}

# Make sure there is at least a file name given as an argument, if not print the help message.

if [ $# -lt 1 ]; then
	    usage
	  	exit 1 # error
fi

# Declare variables

FILENAME=
SET= 
PAPER=
COLS=
SIZE=
STYLE=

# Options

while :; do
    case $1 in
        -h|-\?|--help)
            usage    # Display a usage synopsis.
            exit
            ;;
        -f)
            STYLE=-fancy
            ;;
        -p)
            if [ "$2" ]; then
                PAPER=$2
                shift
            else
                die 'ERROR: "-p" requires a paper size, try a4 or letter.'
            fi
            ;;
         -s)
            if [ $2 = large ]; then
                SIZE=-lg
                shift
            elif [ $2 = small ]; then
                COLS=12
                SIZE=-sm
                shift
            else
                COLS=8
                SIZE=""
            fi
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            die 'ERROR: Unknown option.'
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done

# Assigned here to enable option cases to work.

FILENAME=$1
SET="${FILENAME%.[^.]*}"

# copy .tex file to use as a template.

cp ./assets/writing.tex .

# Check if paper size option is used, otherwise set default value.

if [ "$PAPER" ]; then
    echo "$PAPER"
else
    PAPER=letter
fi

# set paper size --- overwrites template

if [ $PAPER = a4 ]; then
 sed -i -e 's/letterpaper/a4paper/' -e 's/-writing\%/-writing-a4\%/' writing.tex
fi

# set small or large character sizes if option is given -- overwrites template which is hard coded with default values

if [ $SIZE = -sm ]; then
 sed -i -e 's/-writing/-writing-sm/' -e 's/size=title/size=fbox/' -e 's/14/10/g' -e 's/42/33/g' -e 's/,7/,10/' -e 's/,8/,11/' -e 's/columns=9/columns=12/' writing.tex
elif [ $SIZE = -lg ]; then
 sed -i -e 's/-writing/-writing-lg/' -e 's/14/18/g' -e 's/42/69/g' -e 's/,7/,4/' -e 's/,8/,5/' -e 's/columns=9/columns=6/' writing.tex
fi

# parse csv file -- substitute commas or semicolons with tabs, delete quotes

parse() {
 sed -e 's_;_\t_g' -e 's_"__g'   
}

# get fields from csv files

getfields() {
awk -F"\t" '{ print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 }'
}

# use external sed file to convert first field from hiragana to katakana if first reading is onyomi

katakana() {
sed -f assets/kana.sed
}

# get first two fields (reading and kanji) and add LaTeX code

addlatex() {
 awk -F"\t" '{ print "\\kana{" $1 "}\\kanji{" $2 " }\\boxes\\blank\\moreboxes" }'
}

# alternate LaTeX for brush practice sheets

addfancylatex() {
 awk -F"\t" '{ print "\\strokes{" $2 "}\\fancykanji{" $2 " }\\boxes\\kana{" $1 " }\\moreboxes" }'
}

# assemble content 

if [ $STYLE = -fancy ]; then
  sed -i -e 's/-writing/-fancy-writing/' writing.tex
#  COMPLETE=$(cat $FILENAME | parse | getfields | katakana | addfancylatex)
  COMPLETE=$(cat $FILENAME | parse | getfields | addfancylatex)
else
#   COMPLETE=$(cat $FILENAME | parse | getfields | katakana | addlatex)
  COMPLETE=$(cat $FILENAME | parse | getfields | addlatex)
fi

# create content.tex file named according to paper size, copy edited template file, compile with xelatex

if [ $PAPER = a4 ]; then
       echo "$COMPLETE" > $SET$STYLE-writing$SIZE-a4-content.tex
       cp writing.tex $SET$STYLE-writing$SIZE-a4.tex
       xelatex $SET$STYLE-writing$SIZE-a4.tex
else
       echo "$COMPLETE" > $SET$STYLE-writing$SIZE-content.tex
       cp writing.tex $SET$STYLE-writing$SIZE.tex
       xelatex $SET$STYLE-writing$SIZE.tex
fi

# clean up the mess

rm ./*.aux
rm ./*.log
rm ./*.tex
