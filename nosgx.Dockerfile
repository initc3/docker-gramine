#FROM ubuntu:20.04
FROM initc3/linux-sgx:2.14-ubuntu20.04

RUN apt-get update && apt-get install --yes \
            autoconf \
            bison \
            build-essential \
            gawk \
            git \
            libcurl4-openssl-dev \
            libprotobuf-c-dev \
            libunwind-dev \
            ninja-build \
            protobuf-c-compiler \
            python3 \
            python3-pip \
            wget

RUN python3 -m pip install click jinja2 'meson>=0.55' protobuf 'toml>=0.10'

RUN git clone --branch v1.0 https://github.com/gramineproject/gramine.git /usr/src/gramine

WORKDIR /usr/src/gramine

RUN meson setup build/ \
            --buildtype=release \
            -Ddirect=disabled \
            -Dsgx=${SGX} \

RUN ninja -C build/
RUN ninja -C build/ install

# for the helloworld example
WORKDIR /usr/src/gramine/LibOS/shim/test/regression
RUN make

WORKDIR /usr/src/gramine
