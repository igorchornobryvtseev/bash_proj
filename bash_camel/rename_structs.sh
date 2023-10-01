#!/bin/bash

# How to use:
#
# Manual:
#   ./rename_structs.sh --dir ~/proj/portfolio/host --find-not-t
#   ./rename_structs.sh --dir ~/proj/portfolio/host --pairs slist_pairs.txt
#   ./rename_structs.sh --dir ~/proj/portfolio/host --pairs slist_pairs.txt --replace
#
# Automatic:
#   ./rename_structs.sh --dir ~/proj/portfolio/host --auto slist_auto.txt --find-t
#   ./rename_structs.sh --dir ~/proj/portfolio/host --auto slist_auto.txt | sort -u
#   ./rename_structs.sh --dir ~/proj/portfolio/host --auto slist_auto.txt --replace

start_dir=""
pairs_file=""
auto_file=""
do_find_not_t=0
do_find_t=0
do_replace=0

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dir)          start_dir="$2";  shift ;;
        --pairs)        pairs_file="$2"; shift ;;
        --auto)         auto_file="$2";  shift ;;
        --find-not-t)   do_find_not_t=1        ;;
        --find-t)       do_find_t=1            ;;
        --replace)      do_replace=1           ;;
        *) echo "Unknown option: $1";   exit 1 ;;
    esac
    shift
done

# find structures that cannot be handled automatically. Manually create pairs-file
if [ $do_find_not_t -eq 1 ]; then
    echo "*** Not T_ structs:"
    grep -wrI --include="*.h" T_NetworkPacket $start_dir | sed 's/T_NetworkPacket//' | grep -v '\bT_' | sed 's/^.*((packed)) //'
    exit 0
fi

# reas pairs-file with 2 space-delimited columns {old, new}
if [ ! -z "$pairs_file" ]; then
    # read 2- columns file
    while read line; do
        old_name=$(echo $line | awk '{print $1}')
        new_name=$(echo $line | awk '{print $2}')
        printf "%-60s %s\n" $old_name $new_name

        # find files
        file_list=$(grep -wrlI --include="*.h" --include="*.cpp" $old_name $start_dir)

        # do replace or just show file name
        for src_file in ${file_list[@]}; do
            if [ $do_replace -eq 1 ]; then
                sed -i "s/\b$old_name\b/$new_name/g" $src_file
            else
                echo $src_file
            fi
        done
    done < $pairs_file
    exit 0
fi

function name2camel () {
    echo "$1" | sed -r 's/(_)([a-zA-Z0-9])([a-zA-Z0-9]*)/\U\2\L\3/g' | sed 's/^T/N_/'
}

if [ ! -z "$auto_file" ]; then

    # find T_CAPS structures
    if [ $do_find_t -eq 1 ]; then
        grep -wrI --include="*.h" T_NetworkPacket $start_dir | sed 's/T_NetworkPacket//' | grep -o '\bT_[_a-zA-Z0-9]*\b' | sort -u > $auto_file

        # show found names and new names
        echo "*** T_ structs:"
        readarray -t struct_arr < $auto_file
        for old_name in ${struct_arr[@]}; do
            new_name=$(name2camel $old_name)
            printf "%-60s %s\n" $old_name $new_name
        done
        echo "number of candidates: ${#struct_arr[@]}"
        exit 0
    fi

    if [ ! -f $auto_file ]; then
        echo "no such file $auto_file"
        exit 1
    fi

    # replace T_CAPS to T_Camel automatically
    readarray -t struct_arr < $auto_file

    for old_name in ${struct_arr[@]}; do
        new_name=$(name2camel $old_name)

        # find src files
        file_list=$(grep -wrlI --include="*.h" --include="*.cpp" $old_name $start_dir)

        # do replace or just show src file name
        for src_file in ${file_list[@]}; do
            if [ $do_replace -eq 1 ]; then
                sed -i "s/\b$old_name\b/$new_name/g" $src_file
            else
                echo $src_file
            fi
        done
    done

    echo "number of candidates: ${#struct_arr[@]}"
    exit 0
fi
