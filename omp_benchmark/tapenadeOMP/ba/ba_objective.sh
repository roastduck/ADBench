#!/bin/bash

set -ex

folder_path1="/home/chenyidong/ADBench/data/ba"  
output_path=/home/chenyidong/output/baObj


function run() {
    local data_path="$1"
    echo  $data_path
    for file in $data_path/*.txt; do
    echo $file
        if [ -f "$file" ]; then
            
            OMP_NUM_THREADS=256 OMP_PROC_BIND=true OMP_WAIT_POLICY=active \
                srun -N 1 --pty buildompobj/omp BA Tapenade.dll $file ${output_path}/ba_omp/  0.5 1000 1000 60 


            srun -N 1 --pty  buildserialobj/serial BA Tapenade.dll $file ${output_path}/ba_serial/ 0.5 1000  1000 60 

        fi
    done
}



cd  buildserialobj

cmake  -DOBJONLY=1 .. 
make 

cd ..
cd buildompobj
cmake  -DOMP=1 -DOBJONLY=1 .. 
make 

cd  ..
run "$folder_path1"
