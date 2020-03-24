#!/usr/bin/env bash
# Configuration:

export target=${target:-arm-none-eabi}
export prefix=${prefix:-"./${target}"}

############################################################################

set -e
export TARGET=${target}
export PREFIX=$(readlink -f "${prefix}")
export PATH="${PREFIX}/bin:${PATH}"

export distdir="./distfiles"
export srcdir="./source"
export blddir="${PREFIX}/build"
export bindir="${PREFIX}/bin"

# TODO: Reuse repo between targets.
if [[ ! -d ./distfiles ]];		then mkdir -p "./distfiles"; fi
if [[ ! -d ./source ]];			then mkdir -p "./source"; fi
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
	# TODO: Find logic to stop lengthy copies if up to date.
	#  With current method srcdir is unused.
	cp -r "${distdir}/binutils-gdb" "${srcdir}"
	mkdir -p "${blddir}/binutils-gdb"
	pushd "${blddir}/binutils-gdb"
	${distdir}/binutils-gdb/configure \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-cpu=cortex-m4 \
		--with-fpu=fpv4-sp-d16 \
		--with-float=hard \
		--with-mode=thumb \
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
	# TODO: Avoid lengthy copies.
	cp -r "${distdir}/gcc" "${srcdir}"
	mkdir -p "${blddir}/gcc"
	pushd "${blddir}/gcc"
	${distdir}/gcc/configure \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-cpu=cortex-m4 \
		--with-fpu=fpv4-sp-d16 \
		--with-float=hard \
		--with-mode=thumb \
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
	# TODO: Avoid lengthy copies.
	cp -r "${distdir}/newlib-cygwin" "${srcdir}"
	mkdir -p "${blddir}/newlib-cygwin"
	pushd "${blddir}/newlib-cygwin"
	${distdir}/newlib-cygwin/configure \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-cpu=cortex-m4 \
		--with-fpu=fpv4-sp-d16 \
		--with-float=hard \
		--with-mode=thumb \
		--enable-interwork \
		--enable-multilib \
		--disable-newlib-supplied-syscalls \
		--with-gnu-as \
		--with-gnu-ld \
		--disable-nls \
		--enable-newlib-nano-malloc
	make -j4 all
	make install
	popd
}

build_picolibc() {
	# TODO: Avoid lengthy copies.
	cp -r "${distdir}/picolibc" "${srcdir}"
	mkdir -p "${blddir}/picolibc"
	pushd "${blddir}/picolibc"
	# Premade arm-none-eabi target.
	${srcdir}/picolibc/do-arm-configure
}

$@
