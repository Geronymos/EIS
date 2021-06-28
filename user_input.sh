function keymap() {
    key="$1"

    # esc to normal mode
    [ $key == $'\E' ] && mode=0
    case $mode in 
    0) # normal mode
        case $key in
        # vim or arrow keys
        h|$'\E[D')
            (($col > 0)) && ((col-=1)) ;;
        j|$'\E[B'|$'\n')
            (($row < $(echo "$content" | wc -l)-1)) && ((row+=1)) ;;
        k|$'\E[A')
            (($row > 0)) && ((row-=1)) ;;
        l|$'\E[C')
            ((col+=1)) ;;
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
        $'\E[D'|$'\E[B'|$'\E[A'|$'\E[C')
            keymap $'\E' $key i ;;
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
        h|$'\E[D'|j|$'\E[B'|$'\n'|k|$'\E[A'|l|$'\E[C')
            tmp_row=$from_row
            tmp_col=$from_col
            keymap $'\E' $key v
            from_row=$tmp_row
            from_col=$tmp_col
            ;;
        :)
            read -p "$(printf "\e[36m\ue0b1\e[m :")" cmd
            modification=$(echo "$selection" | sh -c "$cmd")
            content=$( echo "$content" | replace_at $from_row $from_col $row $col "$modification" )
            ;;
        esac

        selection=$(echo "$content" | select_at $from_row $from_col $row $col )
        ;;
    esac
    (( $# > 1)) && shift && keymap $@
}