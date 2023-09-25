#!/bin/bash

arr=("aa" "bb")
arr+=("cc")
echo "dim=${#arr[@]}"
for elem in ${arr[@]}; do
    echo $elem
done

exit 1

# Convert all structure names from one header file: 
#   T_CFM_DEBUG_PARAMS -> T_CfmDebugParams
#   T_lldp_leg         -> T_LldpLeg
#
# How to use:
# 1. generate list of struct names, show new names: ./caps2camel.sh --header ~/proj/portfolio/host/inc/cfm.h --list ~/cpp/bash_camel/cfm.h.txt
# 2. dry-run: search in project source files:       ./caps2camel.sh --list ~/cpp/bash_camel/cfm.h.txt --dir ~/proj/portfolio/host | sort -u
# 4. do replace:                                    ./caps2camel.sh --list ~/cpp/bash_camel/cfm.h.txt --dir ~/proj/portfolio/host --replace

function name2camel () {
    echo "$1" | sed -r 's/(_)([a-zA-Z0-9])([a-zA-Z0-9]*)/\U\2\L\3/g' | sed 's/^T/T_/'
}

header_file=""
struct_list=""
start_dir=""
do_replace=0

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--header)  header_file="$2"; shift ;;
        -l|--list)    struct_list="$2"; shift ;;
        -d|--dir)     start_dir="$2";   shift ;;
        -r|--replace) do_replace=1            ;;
        *) echo "Unknown argument: $1" ;;
    esac
    shift
done

## 1. prepare
if [ ! -z "$header_file" ]; then
    [ -f $header_file ] || { echo "no such file $header_file"; exit 1; }

    # generate list of struct names
    grep "^struct\|^union" $header_file | grep -o '\bT_[_a-zA-Z0-9]*\b' > $struct_list

    # show old and new names
    readarray -t struct_arr < $struct_list
    for struct_name in ${struct_arr[@]}; do
        # convert struct name to camel case
        new_name=$(name2camel $struct_name)
        printf "%-60s %s\n" $struct_name $new_name
    done
    echo "number of candidates: ${#struct_arr[@]}"

    exit 0
fi

## 2. replace
if [ -z "$struct_list" ] || [ -z "$start_dir" ]; then
    echo "should not be empty: struct_list=$struct_list start_dir=$start_dir"
    exit 1
fi
[ -f $struct_list ] || { echo "no such file $struct_list"; exit 1; }
[ -d $start_dir ] || { echo "no such directory $start_dir"; exit 1; }

readarray -t struct_arr < $struct_list

for struct_name in ${struct_arr[@]}; do
    # convert struct name to camel case
    new_name=$(name2camel $struct_name)

    # find files
    file_list=$(grep -wrlI $struct_name $start_dir)

    # do replace or just show file name
    for src_file in ${file_list[@]}; do
        if [ $do_replace -eq 1 ]; then
            sed -i "s/\b$struct_name\b/$new_name/g" $src_file
        else
            echo $src_file
        fi
    done
done
