# vasm (6502, oldstyle syntax)

`vasm6502_oldstyle` is the assembler the test suite uses to build the `.asm` files in
`test/asm_tests/` and `test/irq_tests/`. A prebuilt copy lives here so that a fresh checkout
and the GitHub Actions runner need no extra install.

- **Version:** vasm 2.0f, 6502 backend 1.0c, oldstyle syntax module 0.22a
- **Built for:** Linux x86-64, dynamically linked against glibc only (built on Debian 12, glibc 2.36;
  runs on Ubuntu 24.04, which is what the workflows use)
- **SHA-256:** `dab03f7fff3475292a574964604ff58b7ca73ef0ce7c4eca73edcbe72a363222`
- **Used as:** `vasm6502_oldstyle -Fbin -dotdir -o out.bin in.asm`

`test/asm_harness.py` picks the assembler in this order: the `VASM` environment variable, this
directory, then `vasm6502_oldstyle` on `PATH`.

## Licence

vasm is copyright Volker Barthelmann (2002-2026). From its documentation: the archive may be
redistributed without modifications and used for non-commercial purposes; any other use needs
the author's written consent. The binary here is built from the unmodified upstream source.
Upstream: http://sun.hasenbraten.de/vasm/

## Rebuilding

Get the unmodified source from the upstream site, then:

```sh
make CPU=6502 SYNTAX=oldstyle
```

and copy `vasm6502_oldstyle` here (update the version and SHA-256 above).
