#!/usr/bin/bash

set -x 

core=64
corelist=FFFFFFFFFFFFFFFF
suffix="${core}core"

OMP_NUM_THREADS=${core} taskset ${corelist} /adb/build/src/cpp/runner/CppRunner.exe GMM /adb/build/src/cpp/modules/tapenadeOMP/TapenadeOMP.dll /adb/data/gmm/10k/gmm_d128_K200.txt /adb/tmp1/Release/gmm/10k/${suffix}_ 0.5 1000 1000 60

core=16
corelist=FFFF
suffix="${core}core"

OMP_NUM_THREADS=${core} taskset ${corelist} /adb/build/src/cpp/runner/CppRunner.exe GMM /adb/build/src/cpp/modules/tapenadeOMP/TapenadeOMP.dll /adb/data/gmm/10k/gmm_d128_K200.txt /adb/tmp1/Release/gmm/10k/${suffix}_ 0.5 1000 1000 60

core=4
corelist=F
suffix="${core}core"

OMP_NUM_THREADS=${core} taskset ${corelist} /adb/build/src/cpp/runner/CppRunner.exe GMM /adb/build/src/cpp/modules/tapenadeOMP/TapenadeOMP.dll /adb/data/gmm/10k/gmm_d128_K200.txt /adb/tmp1/Release/gmm/10k/${suffix}_ 0.5 1000 1000 60

core=64
corelist=FFFFFFFFFFFFFFFF
suffix="${core}core"

OMP_NUM_THREADS=${core} taskset ${corelist} /adb/build/src/cpp/runner/CppRunner.exe BA /adb/build/src/cpp/modules/tapenadeOMP/TapenadeOMP.dll /adb/data/ba/ba5_n257_m65132_p225911.txt /adb/tmp1/Release/ba/${suffix}_ 0.5 1000 1000 60

core=16
corelist=FFFF
suffix="${core}core"

OMP_NUM_THREADS=${core} taskset ${corelist} /adb/build/src/cpp/runner/CppRunner.exe BA /adb/build/src/cpp/modules/tapenadeOMP/TapenadeOMP.dll /adb/data/ba/ba5_n257_m65132_p225911.txt /adb/tmp1/Release/ba/${suffix}_ 0.5 1000 1000 60

core=4
corelist=F
suffix="${core}core"

OMP_NUM_THREADS=${core} taskset ${corelist} /adb/build/src/cpp/runner/CppRunner.exe BA /adb/build/src/cpp/modules/tapenadeOMP/TapenadeOMP.dll /adb/data/ba/ba5_n257_m65132_p225911.txt /adb/tmp1/Release/ba/${suffix}_ 0.5 1000 1000 60
