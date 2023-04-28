FROM buildpack-deps:bullseye-curl as sgx_debian

ARG sgx_url="https://download.01.org/intel-sgx"
ARG sgx_version="2.19"
ARG distro="Debian10"
ARG distro_codename="buster"
ARG sgx_dir="/opt/intel"
ARG deb_pkg="sgx_debian_local_repo"

WORKDIR ${sgx_dir}

RUN set -eux; \
    url="${sgx_url}/sgx-linux/${sgx_version}/distro/${distro}/${deb_pkg}.tgz"; \
    wget "${url}" --progress=dot:giga; \
    sha256="bc0a52dd7ad2023d176ddae3a1db1e895e16389dfe6f8a454508ad786c0c9a20"; \
    echo "${sha256} ${deb_pkg}.tgz" | sha256sum --strict --check -; \
    tar -xvf ${deb_pkg}.tgz; \
    echo "deb [trusted=yes arch=amd64] file:${sgx_dir}/${deb_pkg} ${distro_codename} main" \
                | tee /etc/apt/sources.list.d/${deb_pkg}.list; \
	apt-get update; \
	apt-get install -y --no-install-recommends libsgx-dcap-quote-verify-dev; \
    rm -rf /var/lib/apt/lists/*; \
	rm ${deb_pkg}.tgz;


FROM python:3.10.11-bullseye as base
LABEL org.opencontainers.image.source=https://github.com/initc3/docker-gramine/tree/dev
LABEL org.opencontainers.image.description="Gramine built with in-kernel sgx driver"
LABEL org.opencontainers.image.licenses=GPL-3.0

# to build gramine for the dcap driver
COPY --from=ghcr.io/initc3/linux-sgx:2.19-buster-eb45404 \
		/usr/lib/x86_64-linux-gnu/libsgx_dcap_quoteverify.so \
		/usr/lib/x86_64-linux-gnu/libsgx_dcap_quoteverify.so

RUN set -eux; \
    echo "deb http://deb.debian.org/debian bullseye-backports main" \
                | tee /etc/apt/sources.list.d/bullseye-backports.list;

RUN apt-get update && apt-get install -y --no-install-recommends \
                linux-headers-amd64/bullseye-backports \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install --yes \
                autoconf \
                bison \
                build-essential \
                gawk \
                git \
                libcurl4-openssl-dev \
                libprotobuf-c-dev \
                libunwind-dev \
                nasm \
                pkg-config \
                protobuf-compiler \
                protobuf-c-compiler \
                vim \
                wget \
                libunwind8 \
                musl-tools \
				# to build the patched libgomp library \
                libgmp-dev \
                libmpfr-dev \
                libmpc-dev \
                libisl-dev \
        && rm -rf /var/lib/apt/lists/*

RUN python -m pip install \
            click \
            cryptography \
            jinja2 \
            meson \
            ninja \
            protobuf \
            pyelftools \
            pytest \
            toml \
            tomli \
            tomli-w

FROM base as build
ARG branch=master
ARG remote=sbellem
RUN git clone \
            --branch ${branch} \
            https://github.com/${remote}/gramine.git \
            /usr/src/gramine

WORKDIR /usr/src/gramine

ARG buildtype=release
ARG direct=enabled
ARG sgx=enabled
ARG sgx_driver=upstream
ARG sgx_driver_include_path=/usr/src/linux-headers-6.1.0-0.deb11.6-common/arch/x86/include/uapi/
ARG dcap=enabled

ENV buildtype ${buildtype}
ENV direct ${direct}
ENV sgx ${sgx}
ENV sgx_driver ${sgx_driver}
ENV dcap ${dcap}
ENV sgx_driver_include_path ${sgx_driver_include_path}

RUN meson setup build/ \
            --buildtype=${buildtype} \
            -Ddirect=${direct} \
            -Dsgx=${sgx} \
            -Dsgx_driver=${sgx_driver} \
            -Dsgx_driver_include_path=${sgx_driver_include_path} \
            -Ddcap=${dcap}
RUN ninja -C build/
RUN ninja -C build/ install

RUN mkdir -p ${HOME}/.config/gramine \
        && openssl genrsa -3 -out ${HOME}/.config/gramine/enclave-key.pem 3072

WORKDIR /usr/src/gramine

# workaround
ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
