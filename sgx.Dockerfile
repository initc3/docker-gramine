FROM ubuntu:20.04 as sgx-driver

RUN apt-get update && apt-get install --yes git

RUN git clone \
            --branch sgx_diver_2.14 \
            https://github.com/intel/linux-sgx-driver.git \
            /opt/intel/linux-sgx-driver

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

RUN git clone \
            --branch v1.0 \
            https://github.com/gramineproject/gramine.git \
            /usr/src/gramine

WORKDIR /usr/src/gramine

COPY --from=sgx-driver /opt/intel/linux-sgx-driver /opt/intel/linux-sgx-driver

RUN openssl genrsa -3 -out Pal/src/host/Linux-SGX/signer/enclave-key.pem 3072

RUN meson setup build/ \
            --buildtype=release \
            -Ddirect=enabled \
            -Dsgx=enabled \
            -Dsgx_driver=oot \
            -Dsgx_driver_include_path=/opt/intel/linux-sgx-driver

RUN ninja -C build/
RUN ninja -C build/ install

# for the helloworld example
WORKDIR /usr/src/gramine/LibOS/shim/test/regression
RUN make SGX=1
#RUN make SGX=1 sgx-tokens

WORKDIR /usr/src/gramine
