# gramine-examples

Build:

```console
docker build -t gramine --build-arg SGX=disabled .
```

Hello world:

```console
docker run --rm -it --security-opt seccomp=unconfined  gramine-build bash
```

```console
cd LibOS/shim/test/regression
make
gramine-direct helloworld
```

## Notes
The argument `--security-opt ...` is important. See
https://github.com/gramineproject/gramine/issues/164#issuecomment-949349475.

(docs: https://gramine.readthedocs.io/projects/gsc/en/latest/#execute-with-linux-pal-instead-of-linux-sgx-pal)
