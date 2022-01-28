#!/bin/sh

colchar="\(\x1B\[[0-9;]*[a-zA-Z]\)"

# https://stackoverflow.com/questions/29613304/is-it-possible-to-escape-regex-metacharacters-reliably-with-sed
# SYNOPSIS
#   quoteRe <text>
function quoteRe() { sed -e 's/[^^]/[&]/g; s/\^/\\^/g; $!a\'$'\n''\\n' <<<"$1" | tr -d '\n'; }


# SYNOPSIS
#  quoteSubst <text>
function quoteSubst() {
  IFS= read -d '' -r < <(sed -e ':a' -e '$!{N;ba' -e '}' -e 's/[&/\]/\\&/g; s/\n/\\&/g' <<<"$1")
  printf %s "${REPLY%$'\n'}"
}

function replace_at() {
    rp_from_row=$1
    rp_from_col=$2
    rp_row=$3
    rp_col=$4
    rp_text=$(quoteSubst "$5")
    (( $rp_from_row == $rp_row )) && rcol=$(($rp_col - $rp_from_col)) || rcol=$rp_col
    cat /dev/stdin | sed -z "s/\(\([^\n]*\n\)\{$rp_from_row\}\(\($colchar*.\)\)\{$rp_from_col\}\)\([^\n]*\n\)\{$(($rp_row - $rp_from_row))\}\($colchar*.\)\{$rcol\}\(.*\)/\1$rp_text\9/"
}

function select_at() {
    sl_from_row=$1
    sl_from_col=$2
    sl_row=$3
    sl_col="$4"
    (( $sl_from_row == $sl_row )) && rcol=$(($sl_col - $sl_from_col)) || rcol=$sl_col
    cat /dev/stdin | sed -z "s/\(\([^\n]*\n\)\{$sl_from_row\}\($colchar*.\)\{$sl_from_col\}\)\(\(\($colchar*[^\n]\)*\n\)\{$(($sl_row - $sl_from_row))\}\($colchar*.\)\{$rcol\}\)\(.*\)/\5/"
}

function hl_at() {
    hl_from_row=$1
    hl_from_col=$2
    hl_row=$3
    hl_col="$4"
    text=$(cat /dev/stdin)
    lasthighlight=$(
        echo "$text" | 
        sed "$(($hl_row+1))q;d" |                                   
        sed "s/^\(\(\($colchar\)*.\)\{$(($hl_col+1))\}\).*/\1/" |       
        grep -Po '(\x1B\[[0-9;]*[a-zA-Z])(?!.*(\x1B\[[0-9;]*[a-zA-Z]))' 
    )
    echo "$text" | replace_at $@ "$(echo "$text" | select_at $@ | sed "s/$colchar*/&$(tput rev)/g; s/$/&$(tput sgr0)/" | sed -z "s/$/$lasthighlight/")"
}