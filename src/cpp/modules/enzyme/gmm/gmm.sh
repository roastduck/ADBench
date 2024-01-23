#!/usr/bin/sh
#  run this file under omp_benchmark/gmm,please modify this file
#  result will be saved to results.json
set -ex
export llvm_path=/home/rd/src/Enzyme_experiments
export clang_enzyme_path=/home/chenyidong/parallel-ad-minibench/enzyme
export OMP_NUM_THREADS=256


${llvm_path}/llvm-project-12.0.1.src/build/bin/clang++  -DOMP=1  -Wall gmm.cpp \
-Xclang -load -Xclang ${clang_enzyme_path}/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
-O2  -o omp_gmm  -std=c++20 -g -Wall -I ${llvm_path}/llvm-project-12.0.1.src/build/projects/openmp/runtime/src -fopenmp 


${llvm_path}/llvm-project-12.0.1.src/build/bin/clang++  -DOMP=1  -Wall -DOBJECTIVE gmm.cpp \
-Xclang -load -Xclang ${clang_enzyme_path}/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
-O2  -o omp_ob_gmm  -std=c++20 -g -Wall -I ${llvm_path}/llvm-project-12.0.1.src/build/projects/openmp/runtime/src \
-fopenmp 



${llvm_path}/llvm-project-12.0.1.src/build/bin/clang++   -Wall  gmm.cpp \
-Xclang -load -Xclang ${clang_enzyme_path}/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
-O2  -o serial_gmm -std=c++20 -g -Wall -I ${llvm_path}/llvm-project-12.0.1.src/build/projects/openmp/runtime/src  

${llvm_path}/llvm-project-12.0.1.src/build/bin/clang++    -Wall -DOBJECTIVE gmm.cpp \
-Xclang -load -Xclang ${clang_enzyme_path}/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
-O2  -o serial_ob_gmm  -std=c++20 -g -Wall -I ${llvm_path}/llvm-project-12.0.1.src/build/projects/openmp/runtime/src \
-fopenmp 


OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
srun --exclusive -N 1 --pty ./omp_gmm




OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
srun --exclusive -N 1 --pty ./omp_ob_gmm


 LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
srun --exclusive -N 1 --pty ./serial_gmm


 LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
srun --exclusive -N 1 --pty ./serial_ob_gmm
