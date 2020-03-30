# gentoolchain.sh - Generate GCC for predefined host tuples

At time of creation existing tools do not adequately address the complexity of managing
toolchain configuration description. This project solves that by associating host tuples
(usually a 3- or 4-item string like x86\_64-pc-linux-gnu) with CPU profiles and target
libc options.

# Supported architectures

1. `arm-none-eabi`
	Builds for config "rmprofile", targeting armv5-armv8 soft fp, hard fp, and
dsp.

2. `riscv64-unknown-elf-gcc`
	Builds for config "elf-multilib", targeting rv32i to lp64d.
