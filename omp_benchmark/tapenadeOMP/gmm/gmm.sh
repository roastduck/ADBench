#!/bin/bash

set -ex

data1="1k"
data2="10k"
folder_path="/home/chenyidong/ADBench/data/gmm"   
output_path=/home/chenyidong/output
export OMP_NUM_THREADS=256

function run() {
    local data_path="$1"
    local data="$2"
    echo  $data_path
    for file in $data_path/$data/*.txt; do
    echo $file
        if [ -f "$file" ]; then
            
            OMP_PROC_BIND=true OMP_WAIT_POLICY=active \
                srun -N 1 --pty buildomp/omp GMM Tapenade.dll $file ${output_path}/gmm_omp/${data}/  0.5 100 100 60 


            srun -N 1 --pty buildserial/serial GMM Tapenade.dll $file ${output_path}/gmm_serial/${data}/ 0.5 100  100 60 

        fi
    done
}


cd buildomp
cmake  -DOMP=1 .. 
make VERBOSE=1
cd ..

cd buildserial
cmake  .. 
make 

cd ..
run "$folder_path"  "$data1"
run "$folder_path"  "$data2"