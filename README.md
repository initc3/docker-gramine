# docker-gramine
A docker image with gramine, to run examples, with SGX support,

## Prerequisites
**Make sure SGX is available** on your system. Flexible Launch Control (FLC)
support is not required. You can use the `cpuid` command:

```console
cpuid | grep -i sgx
```

You'll see something like:

```console
  SGX: Software Guard Extensions supported = true
  SGX_LC: SGX launch config supported      = false
```

Alternatively, you can use https://github.com/ayeks/SGX-hardware#test-sgx.

If your hardware supports SGX but it is not enabled, reboot your computer,
go into the BIOS settings, enable it, save and exit.

### SGX Driver
**IMPORTANT**: SGX MUST be enabled to install the driver.

Install the out-of-tree (oot) SGX driver. For Ubuntu 20.04:

```console
wget https://download.01.org/intel-sgx/sgx-linux/2.14/distro/ubuntu20.04-server/sgx_linux_x64_driver_2.11.0_2d2b795.bin
```

Make the installer executable:

```console
chmod +x sgx_linux_x64_driver_*.bin
```

Install:

```console
sudo ./sgx_linux_x64_driver_*.bin
```

Check:

```console
ls -la /dev/isgx
```

### Set `m.mmap_min_addr=0`
**NOTE**: Only needed for out-of-tree driver.

```console
sudo sysctl vm.mmap_min_addr=0
```

Why?
See https://github.com/alibaba/inclavare-containers/blob/master/rune/libenclave/internal/runtime/pal/skeleton/README.md#enclave-null-dereference-protection.

## Build
Build:

```console
docker-compose build
```

## Hello World Example

```console
docker-compose run --rm gramine bash
```

```console
cd LibOS/shim/test/regression
make SGX=1
make SGX=1 sgx-tokens
gramine-sgx helloworld
```

```console
root@353ee34bd80a:/usr/src/gramine/LibOS/shim/test/regression# gramine-sgx helloworld
-----------------------------------------------------------------------------------------------------------------------
Gramine detected the following insecure configurations:

  - sgx.debug = true                           (this is a debug enclave)
  - loader.insecure__use_cmdline_argv = true   (forwarding command-line args from untrusted host to the app)
  - sys.insecure__allow_eventfd = true         (host-based eventfd is enabled)
  - sgx.allowed_files = [ ... ]                (some files are passed through from untrusted host without verification)

Gramine will continue application execution, but this configuration must not be used in production!
-----------------------------------------------------------------------------------------------------------------------

Hello world!
```

---

## Without SGX Support

Build:

```console
docker build -t gramine:nosgx --file nosgx.Dockerfile .
```

Hello world:

```console
docker run --rm -it --security-opt seccomp=unconfined  gramine:nosgx bash
```

```console
cd LibOS/shim/test/regression
make
gramine-direct helloworld
```

### Notes
The argument `--security-opt seccomp=unconfined` is important. See
https://github.com/gramineproject/gramine/issues/164#issuecomment-949349475.

(docs: https://gramine.readthedocs.io/projects/gsc/en/latest/#execute-with-linux-pal-instead-of-linux-sgx-pal)
