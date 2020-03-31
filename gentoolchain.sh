#!/usr/bin/env bash
# Configuration:

export target=${target:-arm-none-eabi}
export prefix=${prefix:-"./install/${target}"}		# Version prefix?

export version=${version:-$(date -I | sed s/-//g)}
export bugurl=${bugurl:-""}

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
mkdir -p "./build"

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
		--with-sysroot="${prefix}" \
		--disable-nls \
		--enable-interwork \
		--enable-multilib \
		--with-gnu-as \
		--with-gnu-ld
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
		--with-pkgversion="${version}" \
		--with-bugurl="${bugurl}" \
		--build="$(gcc -dumpmachine)" \
		--host="$(gcc -dumpmachine)" \
		--target="${target}" \
		--prefix="${PREFIX}" \
		--with-gnu-as \
		--with-gnu-ld \
		--with-multilib-profile=rmprofile \
		--disable-threads \
		--disable-tls \
		--disable-tm-clone-registry \
		--enable-languages=c \
		--enable-interwork \
		--disable-libsanitizer \
		--disable-libssp \
		--disable-libquadmath \
		--disable-libgomp \
		--disable-libvtv \
		--disable-nls \
		--with-sysroot="${prefix}" \
		--without-headers \
		--with-newlib
	make -j4 all-gcc
	make install-gcc

	#export CPPFLAGS="-I${prefix}/include ${BASE_CXXFLAGS} ${CPPFLAGS-}"
	#export LDFLAGS="-L${prefix}/lib ${BASE_LDFLAGS} ${LDFLAGS-}"
	#"${distdir}"/gcc/configure \
	#	--build="$(gcc -dumpmachine)" --host="$(gcc -dumpmachine)" \
	#	--target="${TARGET}" --prefix="${PREFIX}" \
	#	--with-multilib-list="${profile}" \
	#	--with-sysroot="${PREFIX}" \
	#	--with-system-zlib \
	#	--with-newlib \
	#	--with-gnu-as \
	#	--with-gnu-ld \
	#	--enable-languages="c" \
	#	--enable-multilib \
	#	--enable-interwork \
	#	--without-headers \
	#	--disable-nls \
	#	--disable-decimal-float \
	#	--disable-libffi \
	#	--disable-libgomp \
	#	--disable-libmudflap \
	#	--disable-libssp \
	#	--disable-libstdcxx-pch \
	#	--disable-threads \
	#	--disable-tls \
	#	--disable-shared
	#make -j4 all-gcc
	#make install-gcc
	popd
}

build_newlib() {
	mkdir -p "${blddir}/newlib-cygwin"
	pushd "${blddir}/newlib-cygwin"
	export CFLAGS_FOR_TARGET="-O2 -g -pipe"
	export CXXFLAGS_FOR_TARGET="-O2 -g -pipe"
	export CPPFLAGS="-I${prefix}/include ${BASE_CXXFLAGS} ${CPPFLAGS-}"
	export LDFLAGS="-L${prefix}/lib ${BASE_LDFLAGS} ${LDFLAGS-}"
	"${distdir}"/newlib-cygwin/configure \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-multilib-list="${profile}" \
		--disable-newlib-supplied-syscalls \
		--enable-interwork \
		--enable-newlib-nano-malloc \
		--enable-newlib-io-c99-formats \
		--enable-newlib-io-long-long \
		--enable-multilib \
		--disable-newlib-atexit-dynamic-alloc \
		--disable-nls \
		--with-gnu-as \
		--with-gnu-ld
	make -j4 all
	make install
	popd
}


build_picolibc() {
	mkdir -p "${blddir}/picolibc"
	pushd "${blddir}/picolibc"
	# Premade arm-none-eabi target.
	"${distdir}"/picolibc/do-arm-configure
	ninja -j4
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
	# TODO: Look for partial step names among declaration list and run them.
	"$step"
done
