set -e
sudo apt update -y
sudo apt upgrade -y

# -------------------------------
# Install essential build tools
# -------------------------------
sudo apt install -y build-essential git cmake pkg-config autoconf automake libtool curl unzip wget

# -------------------------------
# Install C++ compiler and g++
# -------------------------------
sudo apt install -y g++ gcc

# -------------------------------
# Install libcurl and OpenSSL dev packages
# -------------------------------
sudo apt install -y libcurl4-openssl-dev libssl-dev

# -------------------------------
# Install Protobuf
# -------------------------------
sudo apt install -y protobuf-compiler libprotobuf-dev

# -------------------------------
# Install gRPC
# -------------------------------
sudo apt install -y libgrpc++-dev libgrpc-dev

# -------------------------------
# Install Threads support
# -------------------------------
sudo apt install -y libpthread-stubs0-dev

# -------------------------------
# Install R and dependencies
# -------------------------------
# sudo apt install -y r-base r-base-dev

# -------------------------------
# Optional: Install R packages for Yahoo Finance
# -------------------------------
# sudo Rscript -e 'install.packages(c("quantmod","tidyquant","xts","zoo"), repos="https://cloud.r-project.org")'

# -------------------------------
# Verify installations
# -------------------------------
echo "Verifying installations..."
echo -n "CMake: "; cmake --version
echo -n "g++: "; g++ --version
echo -n "Protoc: "; protoc --version
echo -n "gRPC++: "; pkg-config --modversion grpc++
# echo -n "R: "; R --version

# -------------------------------
# Done
# -------------------------------
cd ..\
mkdir .\build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j\$(nproc)


