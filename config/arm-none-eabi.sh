#!/usr/bin/env false
# Setup for arm-none-eabi. Source this file.

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
	mkdir -p "${blddir}/newlib-cygwin-nano"
	pushd "${blddir}/newlib-cygwin-nano"
	export CFLAGS_FOR_TARGET="-Os -pipe"
	export CXXFLAGS_FOR_TARGET="-Os -pipe"
	"${distdir}"/newlib-cygwin/configure \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--with-multilib-list="${profile}"
		#--enable-interwork \
		#--enable-multilib \
		#--enable-newlib-nano-malloc \
		#--enable-newlib-io-c99-formats \
		#--enable-newlib-io-long-long \
		#--enable-newlib-nano-malloc \
		#--enable-lite-exit \
		#--enable-newlib-nano-formatted-io \
		#--disable-newlib-atexit-dynamic-alloc \
		#--disable-newlib-supplied-syscalls \		-- may need this.
		#--disable-nls \
		#--with-gnu-as \
		#--with-gnu-ld
	make -j4 all
	make install
	popd
}

140_copy_newlib_nano() {
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

150_build_gcc_final() {
	#mkdir -p "${blddir}/gcc"
	pushd "${blddir}/gcc"
	"${distdir}"/gcc/configure \
		--build="$(gcc -dumpmachine)" --host="$(gcc -dumpmachine)" \
		--target="${TARGET}" --prefix="${PREFIX}" \
		--enable-languages="c,c++" \
		--with-multilib-list='rmprofile'
		#--enable-interwork \
		#--enable-multilib \
		#--disable-shared \
		#--disable-nls \
		#--with-gnu-as \
		#--with-gnu-ld \
		#--with-system-zlib \
		#--with-newlib \
		#--without-headers
	make -j4 all-gcc
	make install-gcc
}
