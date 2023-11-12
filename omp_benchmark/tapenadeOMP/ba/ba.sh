#!/bin/bash

set -ex

folder_path1="/home/chenyidong/ADBench/data/ba"  
output_path=/home/chenyidong/output

export OMP_NUM_THREADS=256
function run() {
    local data_path="$1"
    echo  $data_path
    for file in $data_path/*.txt; do
    echo $file
        if [ -f "$file" ]; then
            
            OMP_PROC_BIND=true OMP_WAIT_POLICY=active \
                srun -N 1 --pty buildomp/omp BA Tapenade.dll $file ${output_path}/ba_omp/  0.5 3 3 60 


            srun -N 1 --pty buildserial/serial BA Tapenade.dll $file ${output_path}/ba_serial/ 0.5 3  3 60 

        fi
    done
}



cd buildserial

cmake  .. 
make 

cd ..
cd buildomp
cmake  -DOMP=1 .. 
make 

cd  ..
run "$folder_path1"
