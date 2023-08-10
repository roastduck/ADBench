#!/usr/bin/sh
#  run this file under omp_benchmark/ba,please modify this file
#  result will be saved to results.json
export llvm_path=/home/rd/src/Enzyme_experiments
export clang_enzyme_path=/home/chenyidong/parallel-ad-minibench/enzyme
set -ex
${llvm_path}/llvm-project-12.0.1.src/build/bin/clang++  -DOMP=1  ba.cpp \
-Xclang -load -Xclang ${clang_enzyme_path}/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
-O2  -o omp_ba  -std=c++20 -g -Wall -I  ${llvm_path}/llvm-project-12.0.1.src/build/projects/openmp/runtime/src \
-fopenmp 

OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
srun -N 1 --pty ./omp_ba


${llvm_path}/llvm-project-12.0.1.src/build/bin/clang++    ba.cpp \
-Xclang -load -Xclang ${clang_enzyme_path}/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
-O2  -o serial_ba  -std=c++20 -g -Wall -I  ${llvm_path}/llvm-project-12.0.1.src/build/projects/openmp/runtime/src \

LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
srun -N 1 --pty ./serial_ba



${llvm_path}/llvm-project-12.0.1.src/build/bin/clang++  -DOMP=1 -DOBJECTIVE=1  ba.cpp \
-Xclang -load -Xclang ${clang_enzyme_path}/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
-O2  -o ob_ba  -std=c++20 -g -Wall -I  ${llvm_path}/llvm-project-12.0.1.src/build/projects/openmp/runtime/src \
-fopenmp 

OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
srun -N 1 --pty ./ob_ba

# #!/usr/bin/sh

# #  run this file under omp_benchmark/ba,please modify this file
# #  result will be saved to results.json


# export llvm_path=/home/rd/src/Enzyme_experiments
# export clang_enzyme_path=/home/chenyidong/parallel-ad-minibench/enzyme
# export OMP_NUM_THREADS=256

# set -ex





 



# ${llvm_path}/llvm-project-12.0.1.src/build/bin/clang++  -DOMP=1  ba.cpp \
# -Xclang -load -Xclang ${clang_enzyme_path}/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
# -O2  -o ba_omp  -std=c++20 -g -Wall -I  ${llvm_path}/llvm-project-12.0.1.src/build/projects/openmp/runtime/src \
# -fopenmp 

# ${llvm_path}/llvm-project-12.0.1.src/build/bin/clang++  -DOMP=1 -DOBJECTIVE=1 ba.cpp \
# -Xclang -load -Xclang ${clang_enzyme_path}/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
# -O2  -o ba_objective  -std=c++20 -g -Wall -I  ${llvm_path}/llvm-project-12.0.1.src/build/projects/openmp/runtime/src \
# -fopenmp 




# ${llvm_path}/llvm-project-12.0.1.src/build/bin/clang++   ba.cpp \
# -Xclang -load -Xclang ${clang_enzyme_path}/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so \
# -O2  -o ba_serial  -std=c++20 -g -Wall -I  ${llvm_path}/llvm-project-12.0.1.src/build/projects/openmp/runtime/src \





# for path in "ba4_n372_m47423_p204472.txt" "ba2_n21_m11315_p36455.txt"   "ba2_n21_m11315_p36455.txt"     "ba3_n161_m48126_p182072.txt"   "ba1_n49_m7776_p31843.txt"        "ba5_n257_m65132_p225911.txt"   
            

 
# do

#     OMP_PROC_BIND=1 OMP_WAIT_POLICY=active LD_LIBRARY_PATH=${llvm_path}/llvm-project-12.0.1.src/build/lib:$LD_LIBRARY_PATH \
#     srun -N 1 --pty ./ba_omp $path

#     srun -N 1 --pty ./ba_serial $path


#     srun -N 1 --pty ./ba_objective $path
# done
