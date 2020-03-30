#!/usr/bin/env bash
# Configuration:

export target=${target:-arm-none-eabi}
export prefix=${prefix:-"./install/${target}"}

# CPU multilib profile associated with target. Check gcc/config/**/t-* files.
export profile=${profile:-rmprofile}

export BASE_COMMON_FLAGS="-O2 -pipe"
export BASE_CFLAGS="${BASE_COMMON_FLAGS}"
export BASE_CXXFLAGS="${BASE_COMMON_FLAGS}"
export BASE_LDFLAGS=""

############################################################################

set -e

# Has to run before readlink, readlink only adds at most one level.
# Redo directory creation?
mkdir -p "${prefix}"

export TARGET=${target}
export PREFIX=$(readlink -f "${prefix}")
export PATH="${PREFIX}/bin:${PATH}"

export distdir=$(readlink -f "./distfiles")
export blddir=$(readlink -f "./build/${target}")
export bindir=$(readlink -f "${prefix}/bin")

if [[ ! -d ${distdir} ]];	then mkdir -p "${distdir}"; fi
if [[ ! -d ${blddir} ]];	then mkdir -p "${blddir}"; fi
if [[ ! -d ${bindir} ]]; 	then mkdir -p "${bindir}"; fi
# Bindir redundant? Creates prefix dir, but had to create it above.


fetch_binutils() {
	if [[ ! -d "${distdir}/binutils-gdb" ]]; then
		pushd "${distdir}" # TODO: Verify.
		git clone git://sourceware.org/git/binutils-gdb.git
		popd
	else
		pushd "${distdir}/binutils-gdb" # TODO: Verify.
		git checkout master
		git pull
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
	else
		pushd "${distdir}/gcc" # TODO: Verify.
		git checkout master
		git pull
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
	else
		pushd "${distdir}/newlib-cygwin" # TODO: Verify.
		git checkout master
		git pull
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
	else
		pushd "${distdir}/picolibc" # TODO: Verify.
		git checkout master
		git pull
		popd
	fi
	pushd "${distdir}/picolibc"
	# git checkout ___ YOLO
	popd
}

build_binutils() {
	mkdir -p "${blddir}/binutils-gdb"
	pushd "${blddir}/binutils-gdb"
	"${distdir}"/binutils-gdb/configure \
		--build="$(gcc -dumpmachine)" --host="$(gcc -dumpmachine)" \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-multilib-list="${profile}" \
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
	"${distdir}"/gcc/configure \
		--build="$(gcc -dumpmachine)" --host="$(gcc -dumpmachine)" \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--enable-languages="c" \
		--with-multilib-list="${profile}" \
		--enable-interwork \
		--enable-multilib \
		--with-system-zlib \
		--with-newlib \
		--without-headers \
		--disable-shared \
		--disable-nls \
		--with-gnu-as \
		--with-gnu-ld
	make -j4 all-gcc
	make install-gcc
	popd
}

build_newlib() {
	mkdir -p "${blddir}/newlib-cygwin"
	pushd "${blddir}/newlib-cygwin"
	export CFLAGS_FOR_TARGET="-O2 -g -pipe"
	export CXXFLAGS_FOR_TARGET="-O2 -g -pipe"
	"${distdir}"/newlib-cygwin/configure \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-multilib-list="${profile}" \
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
	"${distdir}"/newlib-cygwin/configure \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-multilib-list="${profile}" \
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
	ldstdir="${PREFIX}/${target}/lib"
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
}

build_picolibc() {
	mkdir -p "${blddir}/picolibc"
	pushd "${blddir}/picolibc"
	# Premade arm-none-eabi target.
	"${srcdir}"/picolibc/do-arm-configure
}

# Source the configuration.
source "./config/${target}.sh"

# Steps to run, in sequence, listed as arguments terminated with --.
steps=()
for arg in "${@}"; do
	if [[ "${arg}" =~ '--' ]]; then break; fi
	steps+=("$arg")
done

(if [[ ${#steps[@]} -eq 0 ]]; then
	# No steps selected, run them in alphanumeric order.
	declare -F | awk '{ print $3; }'
else
	# Steps selected.
	(IFS=$'\n'; echo "${steps[*]}")
fi) | while read -r step; do
	"$step"
done
