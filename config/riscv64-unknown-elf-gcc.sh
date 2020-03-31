#!/usr/bin/env false
# Setup for riscv64-unknown-elf-gcc. Source this file.

# Must specify riscv64 as arch.
export profile="elf-multilib"

100_build_binutils() {
	:
}

110_build_gcc_bootstrap() {
	:
}

120_build_newlib() {
	:
}

130_build_newlib_nano() {
	:
}

140_copy_newlib_nano() {
	:
}

150_build_gcc_final() {
	:
}

