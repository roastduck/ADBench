#!/usr/bin/sh
#  run this file under omp_benchmark/gmm,please modify this file
#  result will be saved to results.json

set -ex
/path/to/your/llvm-project-12.0.1.src/build/bin/clang++  gmm.cpp \
-Xclang -load -Xclang /path/to/your/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
-O2  -o omp_gmm  -std=c++20 -g -Wall -I /path/to/your/llvm-project-12.0.1.src/build/projects/openmp/runtime/src \
-fopenmp 

OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=/path/to/your/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
srun -N 1 --pty ./omp_gmm