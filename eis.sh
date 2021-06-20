#!/bin/sh
filename=$1
content=$(cat "$1")
max_lines=$(wc -l < "$1")
row=0
col=0

selection=""
from_row=0
from_col=0
show_lines=false
cmd=""
# modes: 0 normal 1 cmd 2 insert 3 visual 
mode=0
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
# echo $(which highlight>/dev/null && echo hi) 

colchar="\x1B\[[0-9;]*[a-zA-Z]"

function render() {
    lastcolor=0
    

    clear
    highlighted=$(echo "$content" | highlight -O ansi --force --syntax-by-name="$filename")
    lasthighlight=$(
        echo "$highlighted" | 
        sed "$((row+1))q;d" |                                   # get row line
        sed "s/^\(\(\($colchar\)*.\)\{$(($col+1))\}\).*/\1/" |       # get string up to col
        grep -Po '(\x1B\[[0-9;]*[a-zA-Z])(?!.*(\x1B\[[0-9;]*[a-zA-Z]))'                            # get last occurance of color
    )

    echo "$highlighted" | 
    sed -e "s/$/ /" | # fill empty line with space so cursor was something to grab to
    # place cursor (replace col char with optional color at row with itself reversed, ended with reset and original highlight)
    sed -e "$(($row+1))s/\($colchar\)*\(.\)/$lasthighlight$(tput rev)\2$(tput sgr0)$lasthighlight/$(($col+1))" |  
    nl | 
    sed -e $(($row+1))"s/./$col/" |
    head -$(($row+$height/2)) |
    tail -$(($height)) | 
    # sed "s/\(\x1B\[\)\([0-9;]*[a-zA-Z]\)/\1\2$(tput smul)\2$(tput rmul)/g" | # debug color
    cat
}

function status() {
    [ $lastcolor != 0 ] && printf "\e[$(($lastcolor-10));$2m\ue0b0\e[0m"
    printf "\e[1;37;$2m $1 \e[0m"
    lastcolor=$2
}

function keymap() {
    key="$1"

    # esc to normal mode
    [ $key == $'\E' ] && mode=0
    case $mode in 
    0) # normal mode
        case $key in
        # vim or arrow keys
        h|$'\E[D')
            col=$(($col-1)) ;;
        j|$'\E[B'|$'\n')
            row=$(($row+1)) ;;
        k|$'\E[A')
            row=$(($row-1)) ;;
        l|$'\E[C')
            col=$(($col+1)) ;;
        i)
            mode=2 ;;
        v)
            from_col=$col
            from_row=$row
            mode=3 ;;
        :)
            mode=1 ;;
        w)
            echo "$content" > "$filename" ;;
        q)
            exit 0 ;;
        esac ;;
    2) # insert mode
        case $key in
        # arrow keys
        $'\E[D')
            col=$(($col-1)) ;;
        $'\E[B')
            row=$(($row+1)) ;;
        $'\E[A')
            row=$(($row-1)) ;;
        $'\E[C')
            col=$(($col+1)) ;;
        $'\n') # enter
            content=$(echo "$content" | sed "$(($row+1))s/./&\n/$(($col))")
            row=$(($row+1))
            col=0
            ;;
        $'\E[3~') # delete
            content=$(echo "$content" | sed "$(($row+1))s/\(.\{$(($col))\}\).\(.*\)/\1\2/")
            ;;
        $'\177') # backspace
            content=$(echo "$content" | sed "$(($row+1))s/\(.\{$(($col-1))\}\).\(.*\)/\1\2/")
            col=$(($col-1))
            ;;
        *)
            content=$(echo "$content" | sed "$(($row+1))s/.\{$(($col))\}/&$key/")
            col=$(($col+1))
            ;;
        esac ;;
    3) # visual mode
        case $key in
        # vim or arrow keys
        h|$'\E[D')
            col=$(($col-1)) ;;
        j|$'\E[B'|$'\n')
            row=$(($row+1)) ;;
        k|$'\E[A')
            row=$(($row-1)) ;;
        l|$'\E[C')
            col=$(($col+1)) ;;
        :)
            # mode=1 
            echo "Rcol $rcol"
            read -p "$(printf "\e[36m\ue0b1\e[m :")" cmd
            modification=$(echo "$selection" | sh -c "$cmd")
            echo "$modification"
            # escape charapters that would be mistaken by sed https://stackoverflow.com/questions/29613304/is-it-possible-to-escape-regex-metacharacters-reliably-with-sed
            IFS= read -d '' -r < <(sed -e ':a' -e '$!{N;ba' -e '}' -e 's/[&/\]/\\&/g; s/\n/\\&/g' <<<"$modification")
            replaceEscaped=${REPLY%$'\n'}
            # content=$(sed ':a;N;$!ba;'"s/\(.*\n\)\{$(($from_row +1))\}.\{$from_col\}\(\(.*\n\)\{$(($row + 1))\}.\{$col\}\)/\3/g")
            content=$( echo "$content" | sed -z "s/\(\([^\n]*\n\)\{$(($from_row))\}.\{$from_col\}\)\(\([^\n]*\n\)\{$(($row - $from_row))\}.\{$rcol\}\)\(.*\)/\1$replaceEscaped\5/" )
            ;;
        esac
        # selection=$(echo "$content" | sed -n "$(($from_row+1)),$(($row+1))p" | sed -e "1s/.\{$from_col\}//;$(($row - $from_row +1))s/\(.\{$col\}\).*/\1/")
        # cat tests/test.txt | sed ':a;N;$!ba;'"s/\(.*\n\)\{1\}.\{2\}\(\(.*\n\)\{1\}.\{1\}\)/\3/"
        # selection=$(echo "$content" | sed ':a;N;$!ba;'"s/\(.*\n\)\{$(($from_row +1))\}.\{$from_col\}\(\(.*\n\)\{$(($row + 1))\}.\{$col\}\)/\3/g")
        # selection=$(echo "$content" | sed -n "$(($from_row+1)),$(($row +1))p" | sed -z "s/.\{$from_col\}\(\(.*\)\n.\{$col\}\).*/\1/")

        # sed -z "s/\(\([^\n]*\n\)\{$from_row\}.\{$from_col\}\)\(\([^\n]*\n\)\{$rrow\}.\{$rcol\}\)\(.*\)/\3/" # \3 for match, \1text\5 for replace
        [ $from_row == $row ] && rcol=$(($col - $from_col)) || rcol=$col
        selection=$(echo "$content" | sed -z "s/\(\([^\n]*\n\)\{$(($from_row))\}.\{$from_col\}\)\(\([^\n]*\n\)\{$(($row - $from_row))\}.\{$rcol\}\)\(.*\)/\3/" )
        ;;
    esac
}

# from https://stackoverflow.com/questions/10679188/casing-arrow-keys-in-bash#11759139
while read -sN1 key
do
    read -sN1 -t 0.0001 k1
    read -sN1 -t 0.0001 k2
    read -sN1 -t 0.0001 k3
    key+=${k1}${k2}${k3}

    width=$(tput cols)
    height=$(($(tput lines)-3))

    keymap "$key"

    render
    status "\uf115 $filename" 42
    status "\ue0a0 $(git branch)" 44
    case $mode in
    0)
        status "NORMAL" 41 ;;
    2)
        status "INSERT" 40 ;;
    esac
    status "\ufae6 $(($row))x$col" 45
    status "\uf80b Key $(echo $key | sed "s/\($(echo $'\E')\)\?\($(echo $'^')\)\?//")" 46
    status " " 1
    echo "$modification"
    echo "$selection"
done
