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

function render() {
    lastcolor=0
    
    clear
    echo "$content" |
    sed -e $(($row+1))"s/./$(printf "\\033[30;47m")&$(tput sgr0)/$(($col+1))" | 
    highlight -O ansi --force --syntax-by-name=$filename | 
    nl | 
    sed -e $(($row+1))"s/./$col/" |
    head -$(($row+$height/2)) |
    tail -$(($height))
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
    if ($normal_mode);
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
            show_lines=$((!$show_lines)) ;;
        q)
            exit 0 ;;
        esac
    else
        case $key in
        i)
            normal_mode=true
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
    status "\ufae6 $(($row))x$col" 45
    status "\uf80b Key $key " 46
    status " " 1
done
