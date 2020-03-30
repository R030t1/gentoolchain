#!/usr/bin/env bash
# Configuration:

export target=${target:-arm-none-eabi}
export prefix=${prefix:-"./${target}"}

export BASE_COMMON_FLAGS="-O2 -pipe"
export BASE_CFLAGS="${BASE_COMMON_FLAGS}"
export BASE_CXXFLAGS="${BASE_COMMON_FLAGS}"
export BASE_LDFLAGS=""

############################################################################

set -e
export TARGET=${target}
export PREFIX=$(readlink -f "${prefix}")
export PATH="${PREFIX}/bin:${PATH}"

export distdir=$(readlink -f "./distfiles")
export blddir="${PREFIX}/build"
export bindir="${PREFIX}/bin"

if [[ ! -d ./distfiles ]];		then mkdir -p "./distfiles"; fi
if [[ ! -d ${PREFIX}/build ]];		then mkdir -p "${PREFIX}/build"; fi
if [[ ! -d ${PREFIX}/bin ]]; 		then mkdir -p "${PREFIX}/bin"; fi

fetch_binutils() {
	if [[ ! -d "${distdir}/binutils-gdb" ]]; then
		pushd "${distdir}" # TODO: Verify.
		git clone git://sourceware.org/git/binutils-gdb.git
		popd
	fi
	pushd "${distdir}/binutils-gdb"
	git checkout gdb-9.1-release
	popd
}

fetch_gcc() {
	if [[ ! -d "${distdir}/gcc" ]]; then
		pushd "${distdir}" # TODO: Verify.
		git clone git://gcc.gnu.org/git/gcc.git
		popd
	fi
	pushd "${distdir}/gcc"
	git checkout releases/gcc-9.2.0
	popd
}

fetch_newlib() {
	if [[ ! -d "${distdir}/newlib-cygwin" ]]; then
		pushd "${distdir}" # TODO: Verify.
		git clone git://sourceware.org/git/newlib-cygwin.git
		popd
	fi
	pushd "${distdir}/newlib-cygwin"
	git checkout newlib-3.3.0
	popd
}

fetch_picolibc() {
	if [[ ! -d "${distdir}/picolibc" ]]; then
		pushd "${distdir}" # TODO: Verify.
		git clone https://github.com/keith-packard/picolibc.git
		popd
	fi
	pushd "${distdir}/picolibc"
	# git checkout ___ YOLO
	popd
}

build_binutils() {
	mkdir -p "${blddir}/binutils-gdb"
	pushd "${blddir}/binutils-gdb"
	${distdir}/binutils-gdb/configure \
		--build="$(gcc -dumpmachine)" --host="$(gcc -dumpmachine)" \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-multilib-list='rmprofile' \
		--enable-interwork \
		--enable-multilib \
		--with-gnu-as \
		--with-gnu-ld \
		--disable-nls
	make -j4 all
	make install
	popd
}

build_gcc_bootstrap() {
	mkdir -p "${blddir}/gcc"
	pushd "${blddir}/gcc"
	export CFLAGS_FOR_TARGET="-O2 -pipe"
	export CXXFLAGS_FOR_TARGET="-O2 -pipe"
	${distdir}/gcc/configure \
		--build="$(gcc -dumpmachine)" --host="$(gcc -dumpmachine)" \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-multilib-list='rmprofile' \
		--enable-interwork \
		--enable-multilib \
		--with-system-zlib \
		--with-newlib \
		--without-headers \
		--disable-shared \
		--disable-nls \
		--with-gnu-as \
		--with-gnu-ld \
		--enable-languages="c"
	make -j4 all-gcc
	make install-gcc
	popd
}

build_newlib() {
	mkdir -p "${blddir}/newlib-cygwin"
	pushd "${blddir}/newlib-cygwin"
	export CFLAGS_FOR_TARGET="-O2 -g -pipe"
	export CXXFLAGS_FOR_TARGET="-O2 -g -pipe"
	${distdir}/newlib-cygwin/configure \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-multilib-list='rmprofile' \
		--enable-interwork \
		--enable-multilib \
		--disable-newlib-supplied-syscalls \
		--with-gnu-as \
		--with-gnu-ld \
		--disable-nls \
		--enable-newlib-nano-malloc \
		--enable-newlib-io-c99-formats \
		--enable-newlib-io-long-long \
		--disable-newlib-atexit-dynamic-alloc
	make -j4 all
	make install
	popd
}

build_newlib_nano() {
	mkdir -p "${blddir}/newlib-cygwin-nano"
	pushd "${blddir}/newlib-cygwin-nano"
	export CFLAGS_FOR_TARGET="-Os -pipe"
	export CXXFLAGS_FOR_TARGET="-Os -pipe"
	${distdir}/newlib-cygwin/configure \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-multilib-list='rmprofile' \
		--enable-interwork \
		--enable-multilib \
		--disable-newlib-supplied-syscalls \
		--with-gnu-as \
		--with-gnu-ld \
		--disable-nls \
		--enable-newlib-nano-malloc \
		--enable-newlib-io-c99-formats \
		--enable-newlib-io-long-long \
		--disable-newlib-atexit-dynamic-alloc \
		--enable-newlib-nano-malloc \
		--enable-lite-exit \
		--enable-newlib-nano-formatted-io
	make -j4 all
	make install
	popd
}

copy_newlib_nano() {
	multilibs=$(${PREFIX}/bin/${TARGET}-gcc -print-multi-lib)
	buildouts=(libc.a libg.a librdimon.a libstdc++.a libsupc++.a)
	lsrcdir="${blddir}/newlib-cygwin-nano"
	ldstdir="${PREFIX}/lib"
	for out in "${buildouts[@]}"; do
		for d in $(find "${lsrcdir}" -name "${out}"); do
			outtarg="${ldstdir}/${d#"${blddir}/newlib-cygwin-nano/${target}/"}"
			outpath="${outtarg%/*}"

			outname="${outtarg##*/}"
			outtarg="${outtarg%%*/}"
			outtarg="${outtarg%.*}_nano.a"
			mkdir -p "${outpath}"
			cp "${d}" "${outtarg}"
		done
	done
	echo $ldstdir
}

build_picolibc() {
	mkdir -p "${blddir}/picolibc"
	pushd "${blddir}/picolibc"
	# Premade arm-none-eabi target.
	${srcdir}/picolibc/do-arm-configure
}

build_gcc_final() {
	#mkdir -p "${blddir}/gcc"
	pushd "${blddir}/gcc"
	${distdir}/gcc/configure \
		--build="$(gcc -dumpmachine)" --host="$(gcc -dumpmachine)" \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-multilib-list='rmprofile' \
		--enable-interwork \
		--enable-multilib \
		--with-system-zlib \
		--with-newlib \
		--without-headers \
		--disable-shared \
		--disable-nls \
		--with-gnu-as \
		--with-gnu-ld \
		--enable-languages="c,c++"
	make -j4 all-gcc
	make install-gcc
}

$@
