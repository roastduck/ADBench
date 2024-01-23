export llvm_path=/home/rd/src/Enzyme_experiments
export clang_enzyme_path=/home/chenyidong/parallel-ad-minibench/enzyme
set -ex
${llvm_path}/llvm-project-12.0.1.src/build/bin/clang++  -DOMP=1  ba.cpp \
-Xclang -load -Xclang ${clang_enzyme_path}/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
-O2  -o omp_ba  -std=c++20 -g -Wall -I  ${llvm_path}/llvm-project-12.0.1.src/build/projects/openmp/runtime/src \
-fopenmp 

OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
./omp_ba

#srun --exclusive -N 1 --pty 