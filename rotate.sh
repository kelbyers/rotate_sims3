#!/bin/bash

PATH=/bin:/usr/bin

while getopts :1 c; do
	case $c in
	1) ONCE=y ; break ;;
	esac
done
shift $((OPTIND-1))

BASE=$(cygpath "${1-FdL.sims3}")
DIR=$(dirname "$BASE")
BASE=$(basename "$BASE")
EXT=${BASE##*.}
ROOT=${BASE%.${EXT}}
ROOT="${ROOT%-save}"
RE='(.*[^0-9])( - [0-9]+)*'
[[ $ROOT =~ $RE ]]
ROOT=${BASH_REMATCH[1]}
NONE=${XNONE-0}

declare -A DIRLIST
declare -a BLIST
declare DBL DDL BT DIR NEWEST IDX

cd "$DIR"

function EXIT {
	declare RC=$1
	if (( RC != 0 )); then
		read -p "EXITING with RC=$RC"
	fi
	exit $RC
}

function rotate {
	declare SRC="$1"
	declare DEST="$2"
	declare MAX NEXT TRIES=3 NOW
	declare BT=$(stat -c %W "$SRC")
	
	printf "%s - " $(date +%T)
	if [[ -d $DEST ]]; then
		echo "\`$DEST\' exists - aborting"
		EXIT 1
	fi
	while (( TRIES )); do
		NOW=$(date +%s)
		if (( ($NOW - $BT) < 60 )); then
			printf "(waiting"
			while (( ($NOW - $BT) < 60 )); do
				printf "."
				sleep 10
				(( NOW = $NOW + 10 ))
			done
			printf ") - "
		fi
		$D mv -v "${SRC}" "$DEST"
		(( $? )) && (( TRIES -= 1 )) || break
		(( TRIES )) && sleep $(( (4 - TRIES) * 5 ))
	done
	if (( $TRIES == 0 )); then
		echo "\`mv -v \"${SRC}\" \"$DEST\"\' failed - aborting"
		EXIT 1
	fi
}

urlencode() {
    # urlencode <string>

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%s' "$c" | xxd -p -c1 |
                   while read c; do printf '%%%s' "$c"; done ;;
        esac
    done
}

urldecode() {
    # urldecode <string>

    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

echo "Rotating for ${ROOT}..."
while true; do
	unset DIRLIST BLIST IDX NEWEST
	declare -A DIRLIST
	declare -a BLIST
	DDL=$(find . -type d -name "${ROOT}.${EXT}" -o -name "${ROOT}[0-9].${EXT}" -o -name "${ROOT}.${EXT}.backup" | while read DBL; do
			BT=$(stat -c %W "$DBL")
			urlencode "${DBL#./}"
			echo ":${BT}"
		done)
	
	for DBL in $DDL; do
		BT=${DBL#*:}
		DIR=${DBL%:*}
		DIRLIST[$BT]=$(urldecode "$DIR")
	done
	$DBG
	BLIST=( $(printf "%d\n" ${!DIRLIST[@]} | sort) )
	IDX=${#BLIST[@]}
	NEWEST=${BLIST[${IDX}-1]}
	unset BLIST[${IDX}-1]
	for BT in ${BLIST[@]}; do
		rotate "${DIRLIST[$BT]}" "${ROOT} - $(date -d@$BT +'%Y%m%d-%H%M%S').${EXT}"
		NONE=0
	done
	if [[ "${DIRLIST[$NEWEST]}" != "${ROOT}.${EXT}" ]]; then
		rotate "${DIRLIST[$NEWEST]}" "${ROOT}.${EXT}"
		NONE=0
	fi
	(( NONE += 1 ))
	if (( NONE > 5 )); then
		printf "%s - none\n" $(date +%T)
		NONE=0
	fi
	[[ $ONCE = "y" ]] && exit 0
	sleep 57
done
