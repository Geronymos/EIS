#!/bin/bash
filename=$1
content=$(cat $1)
max_lines=$(wc -l < $1)
row=0
col=0
show_lines=false
cmd=""
normal_mode=1
lastcolor=0

# echo "\ue0b0 \u00b1 \ue0a0 \u27a6 \u2718 \u26a1 \u2699"
#       >       +-      branch ->       x   ⚡      ⚙ 

# Color   FG  BG
# -------+---+---
# Black   30  40  
# Red     31  41
# Green   32  42
# Yellow  33  43
# Blue    34  44
# Megenta 35  45
# Cyan    36  46
# White   37  47

# git diff --unified=0 
# echo "tefoost hefoollo " | grep -Po '(foo)+(?!.*(foo)+)'   

colchar="\x1B\[[0-9;]*[a-zA-Z]"

function render() {
    lastcolor=0
    

    clear
    highlighted=$(echo "$content" | highlight -O ansi --force --syntax-by-name=$filename)
    lasthighlight=$(
        echo "$highlighted" | 
        sed "$((row+1))q;d" |                                   # get row line
        sed "s/^\(\(\($colchar\)*.\)\{$(($col+1))\}\).*/\1/" |       # get string up to col
        grep -Po '(\x1B\[[0-9;]*[a-zA-Z])(?!.*(\x1B\[[0-9;]*[a-zA-Z]))'                            # get last occurance of color
    )

    echo "$highlighted" | 
    sed -e "s/^\($colchar\)*$/ /" | # fill empty line with space so cursor was something to grab to
    # place cursor (replace col char with optional color at row with itself reversed, ended with reset and original highlight)
    sed -e "$(($row+1))s/\($colchar\)*\(.\)/$lasthighlight$(tput rev)\2$(tput sgr0)$lasthighlight/$(($col+1))" |  
    nl | 
    sed -e $(($row+1))"s/./$col/" |
    head -$(($row+$height/2)) |
    tail -$(($height)) | 
    # sed "s/\(\x1B\[\)\([0-9;]*[a-zA-Z]\)/\1\2$(tput smul)\2$(tput rmul)/g" | # debug color
    cat

    echo "$lasthighlight hello"
}

function status() {
    [ $lastcolor != 0 ] && printf "\e[$(($lastcolor-10));$2m\ue0b0\e[0m"
    printf "\e[1;37;$2m $1 \e[0m"
    lastcolor=$2
}

while read -d'' -s -n1 key
do
    width=$(tput cols)
    height=$(($(tput lines)-3))
    if (($normal_mode == 1))
    then
        case $key in
        k)
            row=$(($row-1)) ;;
        j)
            row=$(($row+1)) ;;
        h)
            col=$(($col-1)) ;;
        l)
            col=$(($col+1)) ;;
        i)
            normal_mode=!$normal_mode ;;
        q)
            exit 0 ;;
        esac
    else
        case $key in
        ^)
            normal_mode=1
            cmd=""
            ;;
        *)
            cmd+=$key
            ;;
        esac
    fi
    render
    status "\uf115 $filename" 42
    status "\ue0a0 $(git branch)" 44
    status "$((($normal_mode == 1)) && printf NORMAL || printf INSERT)" "$((($normal_mode == 1)) && printf 41 || printf 40)"
    status "\ufae6 $(($row))x$col" 45
    status "\uf80b Key $key " 46
    status " " 1
done
