# PyTorch version (torch==2.0.0) shoud be consistent with **/requirements-cuda.txt
FROM freetensor:cuda-mkl-pytorch-dev-3237f8886f0e1478113dc9d434de5388de8fd68b

# Install linux packages
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wget \
        git \
        python3 \
        python3-dev \
        python3-pip \
        cmake \
        # Required by Clang
        libtinfo5 \
        # Required by Enzyme
        libtinfo-dev \
        # Required by DiffSharp
        libopenblas-dev \
        libssl-dev \
        # Required by matplotlib
        libpng-dev \
        && rm -rf /var/lib/apt/lists/*

# Install Clang 16
WORKDIR /utils/clang
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.0/clang+llvm-16.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz \
    && tar -xf clang+llvm-16.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz
ENV PATH=/utils/clang/clang+llvm-16.0.0-x86_64-linux-gnu-ubuntu-18.04/bin/:$PATH
ENV LD_LIBRARY_PATH=/utils/clang/clang+llvm-16.0.0-x86_64-linux-gnu-ubuntu-18.04/lib:$LD_LIBRARY_PATH

# Install Enzyme
WORKDIR /utils/enzyme
RUN wget https://github.com/EnzymeAD/Enzyme/archive/refs/tags/v0.0.69.tar.gz \
    && tar -xf v0.0.69.tar.gz
WORKDIR /utils/enzyme/Enzyme-0.0.69/enzyme/build
RUN cmake .. -DLLVM_DIR=/utils/clang/clang+llvm-16.0.0-x86_64-linux-gnu-ubuntu-18.04/lib/cmake/llvm -DCMAKE_MODULE_PATH=/utils/clang/clang+llvm-16.0.0-x86_64-linux-gnu-ubuntu-18.04/lib/cmake/llvm \
    && make -j

# Legacy libssl 1.0 requried by .NET runner
RUN wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb
RUN DEBIAN_FRONTEND=noninteractive dpkg -i libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb

# Install julia
WORKDIR /utils/julia
RUN wget https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.5-linux-x86_64.tar.gz \
    && tar -xzf julia-1.8.5-linux-x86_64.tar.gz \
    # Create a symlink to julia
    && ln -s /utils/julia/julia-1.8.5/bin/julia /usr/local/bin \
    && rm julia-1.8.5-linux-x86_64.tar.gz

# Install powershell
WORKDIR /utils/powershell
RUN wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-x64.tar.gz \
    && tar -xzf powershell-6.2.3-linux-x64.tar.gz \
    # Create a symlink to pwsh
    && ln -s /utils/powershell/pwsh /usr/local/bin \
    && rm powershell-6.2.3-linux-x64.tar.gz

# Install dotnet 3.1
RUN wget https://dot.net/v1/dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh -c 3.1 \
    # Create a symlink to dotnet
    && ln -s ~/.dotnet/dotnet /usr/local/bin

# upgrade pip to be sure that tf>=2.0 could be installed
RUN python3 -m pip install --upgrade pip

# Module for python packages installing
RUN python3 -m pip install pip setuptools>=41.0.0

WORKDIR /adb
# Copy code to /adb (.dockerignore exclude some files)
COPY . .

# Setting workdir for building the project
WORKDIR /adb/build

# Turn off .NET telemetry
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
# For matplotlib font issue
ENV MPLLOCALFREETYPE=1
# Configure and build
RUN cmake -DCMAKE_BUILD_TYPE=release -DCUDA=ON .. \
    && make

WORKDIR /adb/ADBench
RUN sed -i 's/\r//' run-wrapper.sh \
    # make wrapper script executable
    && chmod +x run-wrapper.sh

ENV OMP_PROC_BIND=true

ENTRYPOINT ["./run-wrapper.sh"]
