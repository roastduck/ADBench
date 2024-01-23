#!/usr/bin/bash

set -x
export llvm_path=/home/rd/src/Enzyme_experiments
# core=64
# corelist=FFFFFFFFFFFFFFFF
# suffix="${core}core"
# OMP_NUM_THREADS=${core}   OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
# taskset ${corelist}  srun --exclusive -N 1 --pty ./omp_ba
# mv results_omp.json results_omp_${core}.json 

# core=16
# corelist=FFFF
# suffix="${core}core"
# OMP_NUM_THREADS=${core}   OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
# taskset ${corelist}  srun --exclusive -N 1 --pty ./omp_ba
# mv results_omp.json results_omp_${core}.json 

# core=4
# corelist=F
# suffix="${core}core"
# OMP_NUM_THREADS=${core}   OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
# taskset ${corelist}  srun --exclusive -N 1 --pty ./omp_ba
# mv results_omp.json results_omp_${core}.json 




core=256
corelist=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
suffix="${core}core"
OMP_NUM_THREADS=${core}   OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
taskset ${corelist}  srun --exclusive -N 1 --pty ./omp_ba
mv results_omp.json results_omp_${core}.json 