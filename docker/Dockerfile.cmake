ARG UBUNTU_VERSION=16.04
FROM ubuntu:${UBUNTU_VERSION} as cmake

ARG CMAKE_VERSION=3.17.2
RUN dependencies="ca-certificates curl gcc g++ libc-dev libssl-dev make" \
 && apt-get update \
 && apt-get install --assume-yes --no-install-recommends ${dependencies} \
 && mkdir /tmp/cmake \
 && cd /tmp/cmake \
 && curl -sSfL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz" -o cmake.tar.gz \
 && tar -f cmake.tar.gz --strip-components 1 -xz \
 && rm cmake.tar.gz \
 && ./bootstrap \
      --parallel=$(nproc) \
      --datadir=share/cmake \
      --docdir=doc/cmake \
      -- \
      -DCMAKE_BUILD_TYPE:STRING=Release \
 && make -j$(nproc) \
 && make install \
 && cd - \
 && rm -r /tmp/cmake \
 && apt-get purge --assume-yes --auto-remove ${dependencies} \
 && rm -rf /var/lib/apt/lists/*
