#!/usr/bin/env bash

function drawgoal(){
    clear
echo "Goal:
* Win the game by removing $goal tiles from the board.
* Combinations with $mintiles or more connected tiles
with the same color can be removed.
* All tiles above an empty area left by removing a
block will drop down.
* Empty columns will be filled by the columns to the
right of it."
    read -s -n 1
    clear; drawboard
}

function drawhelp(){
echo "samegame [-gh] [-cdefghjmnrstv value]

  -c,--columns     integer representing the nr of columns (minimum:2)
  -d,--ntiles      integer representing the number of dropping tiles in flood game
  -e,--emptyrows   integer representing the nr of empty rows in flood game
  -f,--dropfreq    integer representing the frequency of blocks dropping in flood game
  -g,--gameversion list available game versions
  -h,--help        display this help text
  -j,--jokerfreq   integer representing the frequency of joker rewards in flood game
  -m,--minsize     integer representing the minimum nr of connected tiles
                   required for removal
  -n,--ncolors     integer in set [2-8] representing the nr of colors
  -r,--rows        integer representing the nr of rows (minimum:2)
  -s,--seed        integer seed for the pseudo-random number generator
  -t,--tileset     string in the set {colors,letters,chars}
  -v,--version     integer or string indicating the game version"
}

function drawkeybindings(){
clear
echo "Key bindings:
 | Key             | Action                     |
 |-----------------|----------------------------|
 | space,enter,tab | remove blocks              |
 | h,left          | move cursor left           |
 | l,right         | move cursor right          |
 | j,down          | move cursor down           |
 | k,up            | move cursor up             |
 | H               | move cursor to left edge   |
 | L               | move cursor to right edge  |
 | J               | move cursor to bottom edge |
 | K               | move cursor to top edge    |
 | n               | new game                   |
 | r               | replay current game        |
 | v               | change game version        |
 | s               | change setting             |
 | z               | redraw board               |
 | q               | quit game                  |
 | u               | use joker                  |
 | x               | pass turn (flood game)     |
 | i               | show game info             |
 | ?               | display key bindings       |"
    read -s -n 1
    clear; drawboard
}

animationpauze=0.2
tileset=colors

declare -A columnsaffected newchecktiles options
#declare -A options1=([ncolumns]="nr columns" [nrows]="nr rows" [mintiles]="minimum connected tiles" [ncolors]="nr colors")
declare -A options1=([nemptyrows]="nr empty rows" [ndroppingblocks]="nr dropping tiles" [dropfrequency]="drop frequency" [jokerfrequency]="joker frequency")
#options=(ncolumns "nr columns" nrows "nr rows" mintiles "minimum connected tiles" ncolors "nr colors" \
#    nemptyrows "nr empty rows" ndroppingblocks "nr dropping tiles" dropfrequency "drop frequency" jokerfrequency "joker frequency")
games=("chain shot" "same game" "match-3" "flood")
jokers=("bomb" "bomb row" "bomb column")
gameind=0

function updatescore(){
    local n=${#oktiles[@]}
    if [ "${games[gameind]}" == "match-3" ]; then
        score=$((score+n*(ncolors-2)))
    else
        #will have a stronger preference for larger combinations than n^2-3n+4
        score=$((score+n*(n-1)))
    fi
}

while [ $# -gt 0 ]; do
    case "$1" in
        '-h'|'--help') drawhelp; exit;;
        '-t'|'--tileset')
            if [[ "$2" =~ ^colors?$ ]]; then
                tileset=colors
            elif [[ "$2" =~ ^letters?$ ]]; then
                tileset=letters
            elif [[ "$2" =~ ^char(acter|)s?$ ]]; then
                tileset=chars
            else
                echo "invalid input for tileset (colors|letters|chars): $2"
                exit 1
            fi
            shift 2;;
        '-m'|'--minsize') mintiles="$2"; shift 2;;
        '-r'|'--rows') nrows="$2"; shift 2;;
        '-c'|'--columns') ncolumns="$2"; shift 2;;
        '-n'|'--ncolors') ncolors="$2"; shift 2;;
        '-d'|'--ntiles') ndroppingblocks="$2"; shift 2;;
        '-e'|'--emptyrows') nemptyrows="$2"; shift 2;;
        '-f'|'--dropfreq') dropfrequency="$2"; shift 2;;
        '-j'|'--jokerfreq') dropfrequency="$2"; shift 2;;
        '-s'|'--seed') seed="$2"; shift 2;;
        '-v'|'--version')
            if [[ "$2" =~ ^[0-9]+$ ]] && [ $2 -lt ${#games[@]} ]; then
                gameind=$2
            else
                for ((i=0; i<${#games[@]}; i++)); do [ "$2" == "${games[i]}" ] && gameind=$i && break; done
                [ $i -eq ${#games[@]} ] && echo "invalid input for game version: $2" && exit 1
            fi
            shift 2;;
        '-g'|'--gameversions') for i in "${games[@]}"; do txt+="$i\n"; done; echo -e "${txt%\\n}"; exit;;
        *) echo "unknown input: $1"; exit 1;;
    esac
done

function setdefaults(){
    options=([ncolumns]="nr columns" [nrows]="nr rows" [mintiles]="minimum connected tiles" [ncolors]="nr colors")
    if [ "${games[gameind]}" == "chain shot" ]; then
        : ${ncolumns:=20}; : ${nrows:=10}; : ${mintiles:=2}; : ${ncolors:=4}
        : ${nemptyrows:=0}; : ${ndroppingblocks:=0}; : ${dropfrequency:=0}; : ${jokerfrequency:=0}
        score=0; njokers=0
    elif [ "${games[gameind]}" == "same game" ]; then
        : ${ncolumns:=25}; : ${nrows:=15}; : ${mintiles:=2}; : ${ncolors:=5}
        : ${nemptyrows:=0}; : ${ndroppingblocks:=0}; : ${dropfrequency:=0}; : ${jokerfrequency:=0}
        score=0; njokers=0
    elif [ "${games[gameind]}" == "flood" ]; then
        : ${ncolumns:=13}; : ${nrows:=13}; : ${mintiles:=2}; : ${ncolors:=4}
        : ${nemptyrows:=$(((nrows+5)/5))}; : ${ndroppingblocks:=$((mintiles-ncolors+8))}
        : ${dropfrequency:=1}; : ${jokerfrequency:=300}
        score=0; njokers=0
        for i in ${!options1[@]}; do options[$i]=${options1[$i]}; done
    elif [ "${games[gameind]}" == "match-3" ]; then
        : ${ncolumns:=13}; : ${nrows:=12}; : ${mintiles:=3}
        : ${nemptyrows:=0}; : ${ndroppingblocks:=0}; : ${dropfrequency:=0}; : ${jokerfrequency:=0}
        if [ "$level" == 0 ]; then
            ((level++)); nlevels=12
            ncolors=3; score=0; njokers=0; goal=$((nrows*ncolumns-(3*ncolors-6)*ncolors))
            scoreprevious=0
        elif [ "$1" == next ]; then
            #if ((goal<nrows*ncolumns)); then # increase nr colors when target reaches full board
            if ((level%4!=0)); then # increase nr colors when 4 levels have been completed
                goal=$((goal+ncolors))
            else
                if ((ncolors<${#tiles[@]}-1)); then
                    ((ncolors++))
                    goal=$((nrows*ncolumns-(3*ncolors-6)*ncolors)) #goal=$((nrows*ncolumns-(2*ncolors-3)*ncolors)) #goal=$((nrows*ncolumns-(4*ncolors-9)*ncolors))
                fi
            fi
            ((level++))
            njokers=$((njokers+jokerbonus))
            scoreprevious=$score; njokersprevious=$njokers
        else
            score=$scoreprevious; njokers=${njokersprevious:-0}
        fi
    fi
}

function createboard(){
    [[ "${games[gameind]}" =~ ("chain shot"|"samegame") ]] && goal=$((nrows*ncolumns))
    nfields=$((ncolumns*nrows))
    [ $# -gt 0 ] && seed="$1" || seed=$((RANDOM))
    RANDOM="$seed"
    [ "${games[gameind]}" == flood ] && [ "$nemptyrows" -ge $nrows ] && nemptyrows=$((nrows-1))
    isok=0 # take 10 attempts at creating a board
    board=()
    for ((i=0; i<nemptyrows*ncolumns; i++)); do board+=(8); done
    for ((j=0; j<10; j++)); do
        for ((i=nemptyrows*ncolumns; i<nfields; i++)); do
            board[i]=$((RANDOM%ncolors))
        done
        checkboard
        [ $isok -eq 1 ] && break
        seed=$((RANDOM));ss RANDOM="$seed"
    done
    column=$((ncolumns/2)); row=$((nrows/2)); tile=$((ncolumns*row+column))
    turn=0; ntiles=0; status=1; jokerbonus=0
    clear
    [ $isok -eq 0 ] && printf "failed creating a board" && exit 1
    drawboard
}

function drawboard(){
    line=
    for ((i=0; i<nrows; i++)); do
        line+=" ${board[@]:ncolumns*i:ncolumns} \e[0m\n"
    done
    [ $tileset == colors ] && padding="  " || padding=
    for ((i=0; i<ncolors; i++)); do
        line=${line//$i /${tiles[i]}$padding}
    done
    line=${line//8 /${tiles[8]}$padding}
    stty -echo; tput civis
    [[ "${games[gameind]}" =~ match ]] && local txt="level:$level/$nlevels blocks:$ntiles/$goal" || local txt="\e[Kblocks:$ntiles"
    if [[ "${games[gameind]}" =~ (match|flood) ]]; then
        [ "$status" == 1 ] && [ "$isok" == 0 ] && local havejoker="\e[0;1;5m" || local havejoker=
        txt+=" ${havejoker}jokers:$njokers"
    fi
    tput 'cup' 0 0; printf "${line}\e[2m $txt\n\e[0;2m turn:$turn score:$score ?:keys\n \"${games[gameind]}\" seed:$seed\e[0m"
    [ $tileset == colors ] && local x=(2*ncolumns-18)/2 || local x=(ncolumns-18)/2
    if [ $status == next ]; then
        if [[ "${games[gameind]}" =~ match ]] && [ "$level" -eq 12 ]; then
            tput 'cup' $((nrows/2-1)) $((x>0?x:0)); printf "\e[1;5;33;40m VICTORIOUS! *(^o^)* \e[0m"
            [[ "${games[gameind]}" =~ match ]] && tput 'cup' $((nrows/2)) $((x>0?x:0)) && printf "\e[1;5;33;40m  MATCH-3 CONQUERED  \e[0m"
            level=0
        else
            tput 'cup' $((nrows/2-1)) $((x>0?x:0)); printf "\e[1;5;33;40m Congratulations!!! \e[0m"
            [[ "${games[gameind]}" =~ match ]] && tput 'cup' $((nrows/2)) $((x>0?x:0)) && printf "\e[1;5;33;40m     joker: +$jokerbonus      \e[0m"
        fi
    elif [ $status == same ]; then
        tput 'cup' $((nrows/2-1)) $(((x>0?x:0)+1)); printf "\e[1;31;40m No more moves!!! \e[0m"
    elif [ $status == flooded ]; then
        tput 'cup' $((nrows/2-1)) $(((x>0?x:0)+1)); printf "\e[1;31;40m Board overflowed \e[0m"
    fi
}

function findblock(){
    oktiles=()
    local checkedtiles=()
    local tilevalue=${board[$1]}
    [ $tilevalue -eq 8 ] && return
    checktiles=($1)
    while [ ${#checktiles[@]} -gt 0 ]; do
        for i in ${checktiles[@]}; do
            [[ " ${checkedtiles[@]} " =~ " $i " ]] && continue
            checkedtiles+=($i)
            if [ ${board[i]} == $tilevalue ]; then
                oktiles+=($i)
                ((i%ncolumns!=0)) && newchecktiles[$((i-1))]=1
                ((i%ncolumns!=ncolumns-1)) && newchecktiles[$((i+1))]=1
                ((i/ncolumns!=0)) && newchecktiles[$((i-ncolumns))]=1
                ((i/ncolumns!=nrows-1)) && newchecktiles[$((i+ncolumns))]=1
            fi
        done
        checktiles=(${!newchecktiles[@]})
        unset newchecktiles
    done
}

function removeblock(){
    [ $# -eq 0 ] && updatescore
    local ntilesprev=$ntiles; ntiles=$((ntiles+${#oktiles[@]}))
    ((jokerfrequency>0 && ntiles/jokerfrequency!=ntilesprev/jokerfrequency )) && ((njokers++))
    ((turn++))
    unset columnsaffected
    for i in ${oktiles[@]}; do
        board[i]=8
        columnsaffected[$((i%ncolumns))]=1
    done
    drawboard
    rmcolumns=()
    for i in ${!columnsaffected[@]}; do
        j=$((ncolumns*(nrows-1)+i))
        while (( board[j]!=8 && j>0 )); do
            j=$((j-ncolumns))
            removecolumn=0
        done
        k=$((j-ncolumns))
        while [ $k -ge 0 ]; do
            if [ ${board[k]} != 8 ]; then
                board[j]=${board[k]}
                j=$((j-ncolumns))
                removecolumn=0
            fi
            k=$((k-ncolumns))
        done
        while [ $j -ge 0 ]; do
            board[j]=8
            j=$((j-ncolumns))
        done
        [ "$removecolumn" == 0 ] || rmcolumns+=($i)
        unset removecolumn
    done
    [ ${#rmcolumns[@]} -eq 0 ] && sleep $animationpauze && drawboard || removecolumns
    checkstatus; drawboard; [ "$status" == 1 ] || return
    ((ndroppingblocks>0&&dropfrequency>0&&turn%dropfrequency==0)) && droptiles
    checkstatus; drawboard
}

function removecolumns(){
    local min=$ncolumns
    for i in ${rmcolumns[@]}; do
        min=$((i<min?i:min))
    done
    local columnsremove=" ${rmcolumns[@]} "
    for ((i=0; i<nrows; i++)); do
        k=$((min+1))
        for ((j=min; j<ncolumns-${#rmcolumns[@]}; j++)); do
            while [[ "$columnsremove" =~ " $k " ]]; do
                ((k++))
            done
            [ $k -lt $ncolumns ] && board[ncolumns*i+j]=${board[ncolumns*i+k]}
            ((k++))
        done
        while [ $j -lt $ncolumns ]; do
            board[ncolumns*i+j]=8
            ((j++))
        done
    done
    unset rmcolumns
    sleep $animationpauze; drawboard
}

function checkboard(){
    isok=0
    for ((ii=nrows; ii>0; ii--)); do
        for ((jj=0; jj<ncolumns; jj++)); do
            findblock $((ncolumns*(ii-1)+jj))
            [ ${#oktiles[@]} -ge $mintiles ] && isok=1 && break 2
        done
    done
}

function checkstatus(){
    if [[ "${board[@]//8}" =~ [0-7] ]]; then
        [ "$status" == 1 ] && checkboard
        if [ $isok -eq 0 ]; then
            if [ ! -z $goal ] && [ $ntiles -ge $goal ]; then
                status=next
                ((jokerbonus++))
            elif [ "$njokers" == 0 -a "${games[gameind]}" != flood ]; then
                status=same
            else
                isok=1
            fi
        fi
    else
        status=next
        jokerbonus=$((jokerbonus+2))
    fi
}

function usejoker(){
    [ $njokers -gt 0 ] || return
    jokertype=0
    oktiles=()
    while :; do
        tput 'cup' $nrows 0; printf "\e[K joker:<\e[7m${jokers[jokertype]}\e[0m>"
        read -s -n 1 jokeraction
        case "$jokeraction" in
            h|D) jokertype=$((jokertype==0?${#jokers[@]}-1:jokertype-1));;
            l|C) jokertype=$((jokertype==${#jokers[@]}-1?0:jokertype+1));;
            q|Q) drawboard; return;;
            j|J|'') jokertype=${jokers[jokertype]}; break;;
        esac
    done
    if [ "$jokertype" == "bomb" ]; then
        tput 'cup' $nrows 0; printf "\e[K joker: \e[7mselecting bomb\e[0m"
        while :; do
            setcursor set $row $column
            read -s -n 1 jokeraction
            setcursor unset $row $column
            case "$jokeraction" in
                h|D) column=$((column==0?ncolumns-1:column-1));;
                l|C) column=$((column==ncolumns-1?0:column+1));;
                j|B) row=$((row==nrows-1?0:row+1));;
                k|A) row=$((row==0?nrows-1:row-1));;
                H) column=0;;
                L) column=$((ncolumns-1));;
                J) row=$((nrows-1));;
                K) row=0;;
                q|Q) break;;
                '') radius=2
                    for ((i=row>radius?-radius:-row; i<=radius && i<nrows-row; i++)); do
                        local k=$((i>0?radius-i:radius+i))
                        for ((j=column>k?-k:-column; j<=k && j<ncolumns-column; j++)); do
                            local t=$((ncolumns*(row+i)+column+j))
                            [ ${board[t]} == 8 ] || oktiles+=($t)
                        done
                    done
                    ((njokers--));
                    removeblock 0
                    break
                    ;;
            esac
        done
    elif [ "$jokertype" == "bomb row" ]; then
        jokerind=$((nrows-1))
        while :; do
            tput 'cup' $jokerind 0; printf ">"
            read -s -n 1 jokeraction
            tput 'cup' $jokerind 0; printf " "
            case "$jokeraction" in
                j|B) jokerind=$((jokerind==nrows-1?0:jokerind+1));;
                k|A) jokerind=$((jokerind==0?nrows-1:jokerind-1));;
                J) jokerind=$((nrows-1));;
                K) jokerind=0;;
                q|Q) break;;
                '') for ((i=0; i<ncolumns; i++)); do oktiles+=($((ncolumns*jokerind+i))); done; ((njokers--)); removeblock 0; break;;
            esac
        done
    elif [ "$jokertype" == "bomb column" ]; then
        jokerind=0
        tput 'cup' $nrows 0; printf "\e[K"
        while :; do
            if [ "$tileset" == colors ]; then
                local x=$((2*jokerind+1)) arrow="^^" empty="  "
            else
                local x=$((jokerind+1)) arrow="^" empty=" "
            fi
            tput 'cup' $nrows $x; printf "$arrow"
            read -s -n 1 jokeraction
            tput 'cup' $nrows $x; printf "$empty"
            case "$jokeraction" in
                h|D) jokerind=$((jokerind==0?ncolumns-1:jokerind-1));;
                l|C) jokerind=$((jokerind==ncolumns-1?0:jokerind+1));;
                H) jokerind=0;;
                L) jokerind=$((ncolumns-1));;
                q|Q) drawboard; break;;
                '') for ((i=0; i<nrows; i++)); do oktiles+=($((ncolumns*i+jokerind))); done; ((njokers--)); removeblock 0; break;;
            esac
        done
    fi
    ((turn++))
}

function droptiles(){
    [ $nemptyrows -gt 0 ] || return
    local availablecolumns=() filled=()
    spaces="${board[@]}"; spaces=${spaces//[^8]}
    local limit=$((ndroppingblocks<${#spaces}?ndroppingblocks:${#spaces}))
    for ((i=0; i<nrows; i++)); do
        local availablecolumns=()
        for ((j=ncolumns*i; j<ncolumns*(i+1); j++)); do [ ${board[j]} -eq 8 ] && availablecolumns+=($j); done
        for ((j=0; j<(ndroppingblocks<${#availablecolumns[@]}?ndroppingblocks:${#availablecolumns[@]}); j++)); do
            while :; do
                local k=${availablecolumns[$((RANDOM%${#availablecolumns[@]}))]}
                [ ${board[k]} -eq 8 ] && board[k]=$((RANDOM%ncolors)) && filled+=($k) && break
            done
            [ ${#filled[@]} -eq $limit ] && break 2
        done
    done
    [ ${#spaces} -lt $ndroppingblocks ] && status=flooded && return
    if [ ${#spaces} -eq $ndroppingblocks ]; then
        checkboard
        [ $isok -eq 0 ] && status=flooded && return
    else
        drawboard; sleep $animationpauze
        for ((i=ndroppingblocks-1; i>=0; i--)); do
            for ((j=filled[i]+ncolumns; j<nfields; j=j+ncolumns)); do
                [ ${board[j]} -eq 8 ] || break
            done
            ((j>filled[i]+ncolumns)) && board[j-ncolumns]=${board[filled[i]]} && board[${filled[i]}]=8
        done
        rmcolumns=()
        for ((i=nfields-1; i>=nfields-ncolumns; i--)); do
            [ ${board[i]} -eq 8 ] || break
        done
        for ((j=i; j>=nfields-ncolumns; j--)); do
            [ ${board[j]} -eq 8 ] && rmcolumns+=($((j%ncolumns)))
        done
    fi
    drawboard
    [ ${#rmcolumns[@]} -gt 0 ] && removecolumns
}

function changesetting(){
    unset skip
    : {settingind:=0} 
    local settings=("seed" "${options[@]}" "tile set")
    local l=0; for i in "${settings[@]}"; do l=$((l>=${#i}?l:${#i})); done
    clear
    if [ $# -eq 0 ]; then
        while :; do
            tput 'cup' 0 0; printf "\e[2mx:cancel\n\e[0msetting: %-${l}s" "${settings[settingind]}"
            read -s -n 1 action
            case "$action" in
                [hHD]) settingind=$((settingind==0?${#settings[@]}-1:settingind-1));;
                [lLC]) settingind=$((settingind<${#settings[@]}-1?settingind+1:0));;
                [qQxX]) clear; drawboard; return;;
                [jJ]|'') break;;
            esac
        done
        setting="${settings[settingind]}"
    else
        setting=$1
    fi
    if [ "$setting" == "tile set" ]; then
        local tilesetchoices=('[colors]letters chars ' ' colors[letters]chars ' ' colors letters[chars]')
        case $tileset  in
            colors) tilesetchoice=0;;
            letters) tilesetchoice=1;;
            chars) tilesetchoice=2;;
        esac
        while :; do
            tput 'cup' 0 0; printf "\e[2mx:cancel\e[0m\ntileset:${tilesetchoices[tilesetchoice]}"
            read -s -n 1 action
            case "$action" in
                [hHD]) tilesetchoice=$((tilesetchoice==0?2:tilesetchoice-1));;
                [lLC]) tilesetchoice=$((tilesetchoice==2?0:tilesetchoice+1));;
                [qQxX]) break;;
                ''|j|J|B)
                    case $tilesetchoice  in
                        0) tileset=colors;;
                        1) tileset=letters;;
                        2) tileset=chars;;
                    esac
                    break;;
            esac
        done
        clear
        checksettings
        drawboard
    elif [ "$setting" == seed ]; then
        clear
        stty echo
        tput cnorm; read -p "seed: " seed
        createboard "$seed"
    else
        stty echo
        while :; do
            [ -z $skip ] && clear || break
            printf "\e[2mx:cancel\e[0m\n"
            tput cnorm; read -p "$setting: " input
            if [[ "$input" =~ ^[xXqQ]$ ]]; then
                drawboard
                break
            elif [[ "$input" =~ ^[\ ]*[0-9]+[\ ]*$ ]]; then
                case "$setting" in
                    "nr columns") ncolumns=$input;;
                    "nr rows") nrows=$input;;
                    "nr colors") ncolors=$((input<=8?input:8));;
                    "minimum connected tiles") mintiles=$input;;
                    "nr empty rows") nemptyrows=$input;;
                    "nr dropping tiles") ndroppingblocks=$input;;
                    "drop frequency") dropfrequency=$input;;
                    "joker frequency") jokerfrequency=$input;;
                esac
                level=0
                checksettings
                if [ $settingok -eq 1 ] && [ -z $skip ]; then
                    skip=1 # prevent loops
                    setdefaults
                    createboard
                    return
                fi
            fi
        done
    fi
}

function checksettings(){
    settingok=1
    for setting in "${!options[@]}"; do
        if [[ "${!setting}" =~ ^[0-9]+$ ]] && [ "${!setting}" -ge 0 ]; then
            case $setting in
                mintiles) (("${!setting}"<2)) && settingok=0 && break;;
                ncolors) (( "${!setting}"<2 && "${!setting}">8 )) && settingok=0 && break;;
                nrows) ((`tput lines`<nrows+3)) && settingok=0 && break;;
                ncolumns) 
                    if [ $tileset == colors ]; then
                        tiles=( "\e[41m" "\e[42m" "\e[103m" "\e[44m" "\e[45m" "\e[106m" "\e[100m" "\e[104m" "\e[40m" )
                        ((`tput cols`<2*ncolumns+1)) && settingok=0 && break
                    elif [ $tileset == letters ]; then
                        tiles=( "A" "B" "C" "D" "E" "F" "G" "H" " " )
                        ((`tput cols`<ncolumns)) && settingok=0 && break
                    else
                        tiles=( "*" "+" "=" "~" "#" "@" "&" "^" " " )
                        ((`tput cols`<ncolumns)) && settingok=0 && break
                    fi;;
            esac
        else
            settingok=0; break
        fi
    done
    if [ $settingok -eq 0 ]; then
        changesetting "${options[$setting]}"
    fi
}

function changegame(){
    version=$gameind
    clear
    while :; do
        tput 'cup' 0 0; printf "x:cancel\e[0m\n\e[Kgame version:<\e[7m${games[version]}\e[0m>"
        read -s -n 1 action
        case "$action" in
            [hHD]) version=$((version==0?${#games[@]}-1:version-1));;
            [lLC]) version=$((version<${#games[@]}-1?version+1:0));;
            [qQxX]) break;;
            ''|j|J|B)
                gameind=$version
                level=0
                unset ncolumns nrows mintiles ncolors score njokers goal nemptyrows ndroppingblocks dropfrequency jokerfrequency
                setdefaults
                createboard
                break;;
        esac
    done
    drawboard
}

function setcursor(){
    local t=$((ncolumns*$2+$3))
    [ $tileset == colors ] && tput 'cup' $2 $((2*$3+1)) || tput 'cup' $2 $(($3+1))
    if [ $tileset == colors ]; then
        [[ ${board[t]} =~ [25] ]] && cursor="\e[1;30m><\e[0m" || cursor="\e[1;97m><\e[0m"
        [ $1 == set ] && printf "${tiles[board[t]]}$cursor" || printf "${tiles[board[t]]}\e[1;30m  \e[0m"
    else
        [ $1 == set ] && printf "\e[1;4m${tiles[board[t]]}\e[0m" || printf "${tiles[board[t]]}"
    fi
}

trap 'tput "cup" $((nrows+2)) 0; echo -e "\e[0m"; stty echo; tput cnorm; exit' EXIT INT

stty -echo; tput civis

level=0
setdefaults
checksettings
createboard

while :; do

    tile=$((ncolumns*row+column))
    [ "$status" == 1 ] && setcursor set $row $column
    read -s -n 1 action
    setcursor unset $row $column

    case $action in
        h|D) [ $status == 1 ] && column=$((column==0?ncolumns-1:column-1));;
        l|C) [ $status == 1 ] && column=$((column==ncolumns-1?0:column+1));;
        j|B) [ $status == 1 ] && row=$((row==nrows-1?0:row+1));;
        k|A) [ $status == 1 ] && row=$((row==0?nrows-1:row-1));;
        H) [ $status == 1 ] && column=0;;
        L) [ $status == 1 ] && column=$((ncolumns-1));;
        J) [ $status == 1 ] && row=$((nrows-1));;
        K) [ $status == 1 ] && row=0;;
        n|N) setdefaults "$status"; createboard;;
        r|R) createboard "$seed";;
        v|V) changegame;;
        s|S) changesetting;;
        x|X) 
            if [ "${games[gameind]}" == "flood" ] && ((ndroppingblocks>0&&dropfrequency>0)); then
                (( ++turn && jokerfrequency>0 && turn%jokerfrequency==0 )) && ((njokers++))
                (( turn%dropfrequency==0 )) && droptiles && checkstatus
                drawboard
            fi;;
        z|Z) drawboard;;
        q|Q) break;;
        i|I) drawgoal;;
        u|U) usejoker;;
        '?') drawkeybindings;;
        '') if [ "$status" == 1 ]; then
                findblock $tile; [ ${#oktiles[@]} -ge $mintiles ] && removeblock
            else
                setdefaults "$status"; createboard
            fi;;
    esac

done

