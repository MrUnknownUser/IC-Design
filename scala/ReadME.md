# How to run Scala
1. cd IC-Design/scala
2. sbt "runMain AesSim"

## For troubleshooting with Scala
verilator -cc rtl/AesIterative.v \
  --exe verilator/VAesIterative__spinalWrapper.cpp \
  --top-module AesIterative \
  --Mdir verilator \
  --build \
  -CFLAGS "-I$HOME/.cache/coursier/arc/https/github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.29%252B7/OpenJDK11U-jdk_x64_linux_hotspot_11.0.29_7.tar.gz/jdk-11.0.29+7/include" \
  -CFLAGS "-I$HOME/.cache/coursier/arc/https/github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.29%252B7/OpenJDK11U-jdk_x64_linux_hotspot_11.0.29_7.tar.gz/jdk-11.0.29+7/include/linux"

=> Origin file found in scala/simWorkspace/AesIterative/verilatorScript.sh