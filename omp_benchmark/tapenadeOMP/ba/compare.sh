#!/bin/bash

set -ex

folder_path1="/home/chenyidong/ADBench/data/ba"  
output_path=/home/chenyidong/output/ba_omp

 
function run() {
    local data_path="$1"
    echo  $data_path
    files=$(ls $data_path)
    for file in $files; do
    echo $file
     
            python compare.py --path  ${output_path}/  --file $file
 
       
    done
}




run "$folder_path1"