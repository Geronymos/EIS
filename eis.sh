#!/bin/bash
filename=$1
content=$(cat "$1")
max_lines=$(wc -l < "$1")
row=0
col=0

selection=""
from_row=0
from_col=0
show_lines=false
rcol=0
cmd=""
# modes: 0 normal 1 cmd 2 insert 3 visual 
mode=0
lastcolor=0

# Black|Red|Green|Yellow|Blue|Magenta|Cyan|White
# 40   |41 |42   |43    |44  |45     |46  |47

# git diff --unified=0 
# echo "tefoost hefoollo " | grep -Po '(foo)+(?!.*(foo)+)'  
# echo $(which highlight>/dev/null && echo hi) 

source ./text_manipulation.sh
source ./user_input.sh

function render() {
    lastcolor=0
    
    width=$(tput cols)
    height=$(($(tput lines)-3))

    clear
    
    echo "$content" | highlight -O ansi --force --syntax-by-name="$filename" | 
    sed -z "s/\n\($colchar*\n\)/\n \1/g" | # fill empty line with space so cursor was something to grab to
    ( (( $mode < 3 )) && hl_at $row $col $row $((col+1)) || cat ) |
    ( (( $mode == 3 )) && hl_at $from_row $from_col $row $col || cat ) | 
    nl -v0 | 
    sed -e $(($row+1))"s/./$col/" |
    head -$(($row+($height/2))) |
    tail -$(($height)) | 
    # sed "s/\(\x1B\[\)\([0-9;]*[a-zA-Z]\)/\1\2$(tput smul)\2$(tput rmul)/g" | # debug color
    cat
}

function status() {
    [ $lastcolor != 0 ] && printf "\e[$(($lastcolor-10));$2m\ue0b0\e[0m"
    printf "\e[1;37;$2m $1 \e[0m"
    lastcolor=$2
}


render
# from https://stackoverflow.com/questions/10679188/casing-arrow-keys-in-bash#11759139
while read -sN1 key
do
    read -sN1 -t 0.0001 k1
    read -sN1 -t 0.0001 k2
    read -sN1 -t 0.0001 k3
    key+=${k1}${k2}${k3}

    keymap "$key"

    render
    status "\uf115 $filename" 42
    status "\ue0a0 $(git branch)" 44
    case $mode in
    0)
        status "NORMAL" 41 ;;
    2)
        status "INSERT" 40 ;;
    3)
        status "VISUAL" 42 ;;
    esac
    status "\ufae6 $(($row))x$col" 45
    status "\uf80b Key $(echo $key | sed "s/\($(echo $'\E')\)\?\($(echo $'^')\)\?//")" 46
    status " " 1
    # echo "$modification"
    # echo "$selection"
    # echo "$selection_hl"
done
