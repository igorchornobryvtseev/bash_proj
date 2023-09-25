#!/bin/bash

# Copy all git modified files to *.BAK

src_list=$(git status| grep modified | sed 's/\s*modified:\s*//')
dst_list=()
for src_path in $src_list; do
    dst_path=${src_path}.BAK
    cp -p ${src_path} ${dst_path}
    dst_list+=${dst_path}
done

exit 0

for src_path in $src_list; do
    ls -la $src_path
done

for dst_path in $dst_list; do
    echo ${dst_path}
done
