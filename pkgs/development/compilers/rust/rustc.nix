{ stdenv, fetchurl, fetchgit, fetchzip, file, python2, tzdata, procps
, llvm, jemalloc, ncurses, darwin, binutils, rustPlatform, git, cmake, curl
, cacert, tree
, isRelease ? false
, shortVersion
, forceBundledLLVM ? false
, srcSha, srcRev
, configureFlags ? []
, patches
, targets
, targetPatches
, targetToolchains
} @ args:

let
  inherit (stdenv.lib) optional optionalString;

  version = if isRelease then
      "${shortVersion}"
    else
      "${shortVersion}-g${builtins.substring 0 7 srcRev}";

  procps = if stdenv.isDarwin then darwin.ps else args.procps;

  llvmShared = llvm.override { enableSharedLibraries = true; };

  target = builtins.replaceStrings [" "] [","] (builtins.toString targets);
  
  src = fetchgit {
    url = https://github.com/rust-lang/rust;
    rev = srcRev;
    sha256 = srcSha;
  };

  name = "rustc-${version}";

  sourceRoot = "rust-56124ba";

  cargo_exe = "${rustPlatform.rust.cargo}/bin/cargo";

  inherit (rustPlatform) rustRegistry;
  
  in

stdenv.mkDerivation {

  inherit version name src sourceRoot;

  __impureHostDeps = [ "/usr/lib/libedit.3.dylib" ];

  NIX_LDFLAGS = optionalString stdenv.isDarwin "-rpath ${llvmShared}/lib";

  # Enable nightly features in stable compiles (used for
  # bootstrapping, see https://github.com/rust-lang/rust/pull/37265).
  # This loosens the hard restrictions on bootstrapping-compiler
  # versions.
  RUSTC_BOOTSTRAP = "1";

  # Increase codegen units to introduce parallelism within the compiler.
  RUSTFLAGS = "-Ccodegen-units=10";

  # We need rust to build rust. If we don't provide it, configure will try to download it.
  configureFlags = configureFlags
                ++ [ "--enable-local-rust" "--local-rust-root=${rustPlatform.rust.rustc}" "--enable-rpath" ]
                ++ [ "--enable-local-cargo" "--local-cargo-root=${rustPlatform.rust.cargo}" ]
                # ++ [ "--jemalloc-root=${jemalloc}/lib"
                ++ [ "--default-linker=${stdenv.cc}/bin/cc" "--default-ar=${binutils.out}/bin/ar" ]
                ++ optional (stdenv.cc.cc ? isClang) "--enable-clang"
                ++ optional (targets != []) "--target=${target}"
                ++ optional (!forceBundledLLVM) "--llvm-root=${llvmShared}";

  patches = patches ++ targetPatches;

  passthru.target = target;

  cargoDeps = rustPlatform.fetchCargo {
    inherit name src;

    sourceRoot = "${sourceRoot}/src";
    srcs = null;
    sha256 = "0nywf7rcgdi7857qj10c04g9r8shzrgswdq99x1al3wc0y3jzjri";
  };

  postUnpack = ''
    echo "Using cargo deps from $cargoDeps"

    cp -a "$cargoDeps" deps
    chmod +w deps -R

    # It's OK to use /dev/null as the URL because by the time we do this, cargo
    # won't attempt to update the registry anymore, so the URL is more or less
    # irrelevant

    cat <<EOF > deps/config
[registry]
index = "file:///dev/null"
EOF

    export CARGO_HOME="$(realpath deps)"
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt

    # Let's find out which $indexHash cargo uses for file:///dev/null
    (cd $sourceRoot/src && cargo fetch &>/dev/null) || true
    cd deps
    indexHash="$(basename $(echo registry/index/*))"

    echo "Using indexHash '$indexHash'"

    rm -rf -- "registry/cache/$indexHash" \
              "registry/index/$indexHash"

    mv registry/cache/HASH "registry/cache/$indexHash"

    echo "Using rust registry from ${rustRegistry}"
    ln -s "${rustRegistry}" "registry/index/$indexHash"

    # Retrieved the Cargo.lock file which we saved during the fetch
    cd ..
    mv deps/Cargo.lock $sourceRoot/src

    (
        cd $sourceRoot/src

        cargo fetch
        cargo clean
    )
  '';
  
  postPatch = ''
    substituteInPlace src/rust-installer/gen-install-script.sh \
      --replace /bin/echo "$(type -P echo)"
    substituteInPlace src/rust-installer/gen-installer.sh \
      --replace /bin/echo "$(type -P echo)"

    # Workaround for NixOS/nixpkgs#8676
    #substituteInPlace mk/rustllvm.mk \
    #  --replace "\$\$(subst  /,//," "\$\$(subst /,/,"

    # Fix dynamic linking against llvm
    # ${optionalString (!forceBundledLLVM) ''sed -i 's/, kind = \\"static\\"//g' src/etc/mklldeps.py''}

    # Fix the configure script to not require curl as we won't use it
    sed -i configure \
      -e '/probe_need CFG_CURL curl/d'

    # Fix the use of jemalloc prefixes which our jemalloc doesn't have
    # TODO: reenable if we can figure out how to get our jemalloc to work
    #[ -f src/liballoc_jemalloc/lib.rs ] && sed -i 's,je_,,g' src/liballoc_jemalloc/lib.rs
    #[ -f src/liballoc/heap.rs ] && sed -i 's,je_,,g' src/liballoc/heap.rs # Remove for 1.4.0+

    # Disable fragile linker-output-non-utf8 test
    rm -vr src/test/run-make/linker-output-non-utf8 || true

    # Remove test targeted at LLVM 3.9 - https://github.com/rust-lang/rust/issues/36835
    rm -vr src/test/run-pass/issue-36023.rs || true

    # Disable test getting stuck on hydra - possible fix:
    # https://reviews.llvm.org/rL281650
    rm -vr src/test/run-pass/issue-36474.rs || true

    # Useful debugging parameter
    # export VERBOSE=1
  '' +
  # In src/compiler-rt/cmake/config-ix.cmake, the cmake build falls
  # back to darwin 10.4. This causes the OS name to be recorded as
  # "10.4" rather than the expected "osx". But mk/rt.mk expects the
  # built library name to have an "_osx" suffix on darwin.
  optionalString stdenv.isDarwin ''
    substituteInPlace mk/rt.mk --replace "_osx" "_10.4"
  '';

  preConfigure = ''
    # Needed flags as the upstream configure script has a broken prefix substitution
    configureFlagsArray+=("--datadir=$out/share")
    configureFlagsArray+=("--infodir=$out/share/info")
  '';

  # rustc unfortunately need cmake for compiling llvm-rt but doesn't
  # use it for the normal build. This disables cmake in Nix.
  # dontUseCmakeConfigure = true;

  # ps is needed for one of the test cases
  nativeBuildInputs = [ file python2 procps rustPlatform.rust.rustc rustPlatform.rust.cargo git tree ];

  buildInputs = [ ncurses ] ++ targetToolchains
    ++ optional (!forceBundledLLVM) llvmShared;

  outputs = [ "out" "doc" ];
  setOutputFlags = false;
  
  # Disable codegen units for the tests.
  preCheck = ''
    export RUSTFLAGS=
    export TZDIR=${tzdata}/share/zoneinfo
  '' +
  # Ensure TMPDIR is set, and disable a test that removing the HOME
  # variable from the environment falls back to another home
  # directory.
  optionalString stdenv.isDarwin ''
    export TMPDIR=/tmp
    sed -i '28s/home_dir().is_some()/true/' ./src/test/run-pass/env-home-dir.rs
  '';

  doCheck = true;
  dontSetConfigureCross = true;

  # https://github.com/NixOS/nixpkgs/pull/21742#issuecomment-272305764
  # https://github.com/rust-lang/rust/issues/30181
  # enableParallelBuilding = false;

  meta = with stdenv.lib; {
    homepage = http://www.rust-lang.org/;
    description = "A safe, concurrent, practical language";
    maintainers = with maintainers; [ madjar cstrahan wizeman globin havvy wkennington retrry ];
    license = [ licenses.mit licenses.asl20 ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
