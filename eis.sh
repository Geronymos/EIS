#!/bin/bash

file=$(cat $1)
max_lines=$(wc -l < $1)
row=0
col=0
show_lines=false
cmd=""
normal_mode=1
color=


while read -d'' -s -n1 key
do
    width=$(tput cols)
    height=$(($(tput lines)-3))
    if ($normal_mode);
    then
        case $key in
        k)
            row=$(($row-1))
            ;;
        j)
            row=$(($row+1))
            ;;
        h)
            col=$(($col-1))
            ;;
        l)
            col=$(($col+1))
            ;;
        i)
            show_lines=$((!$show_lines))
            ;;
        q)
            exit 0
            ;;
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
    clear
    cat $1 |
    sed -e $(($row+1))"s/./█/$(($col+1))" | 
    highlight -O ansi --force --syntax-by-name=$1 | 
    nl | 
    head -$(($row+$height/2)) |
    tail -$(($height))
    printf "File: $1, Key: $key, Line, Col $row, $col, Width x height $width x $height, $show_lines, $cmd"
done