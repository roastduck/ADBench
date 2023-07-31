#!/usr/bin/sh
#  run this file under omp_benchmark/gmm,please modify this file
#  result will be saved to results.json
#  there will be a lot of warnings printed, just ignore them
#  if first time failed, just run sh hand.sh again

set -ex
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/your/Adept-2/adept2/install/lib

/path/to/your/llvm-project-12.0.1.src/build/bin/clang++  hand.cpp \
-Xclang -load -Xclang /path/to/your/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
-O2  -o omp_hand_simple  -std=c++20 -g -Wall -I /path/to/your/llvm-project-12.0.1.src/build/projects/openmp/runtime/src \
-fopenmp  -I/path/to/your/Adept-2/adept2/install/include  \
-I/path/to/your/ADFirstAidKit  -L/path/to/your/Adept-2/adept2/install/lib  \
-L/path/to/your/ADFirstAidKit -I/path/to/your/Adept-2/adept2/install/lib -ladept -laidkid

OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=/path/to/your/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
srun -N 1 --pty ./omp_hand_simple