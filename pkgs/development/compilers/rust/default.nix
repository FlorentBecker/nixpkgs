{ stdenv, callPackage, recurseIntoAttrs, makeRustPlatform, llvm
, targets ? []
, targetToolchains ? []
, targetPatches ? []
}:

let
  rustPlatform = recurseIntoAttrs (makeRustPlatform (callPackage ./bootstrap.nix {}));
in
rec {
  rustc = callPackage ./rustc.nix {
    shortVersion = "1.17.0";
    isRelease = true;
#    forceBundledLLVM = false;
    configureFlags = [ "--release-channel=stable" ];
    srcRev = "56124baa9e73f28c0709e59e74783cf234a978cf";
    srcSha = "0fk9bx4fmaslmj6rx7mcdd528clnwql2f9k7sa2nwi4s68aqdclk";

    patches = [ ./patches/bootstrap-cargo.patch ]; #[
#      ./patches/darwin-disable-fragile-tcp-tests.patch
#    ] ++ stdenv.lib.optional stdenv.needsPax ./patches/grsec.patch;

    inherit llvm;
    inherit targets;
    inherit targetPatches;
    inherit targetToolchains;
    inherit rustPlatform;
  };

  cargo = callPackage ./cargo.nix rec {
    version = "0.18.0";
    srcRev = "fe7b0cdcf5ca7aab81630706ce40b70f6aa2e666";
    srcSha = "117ivvs9wz848mwf8bw797n10qpn77agd353z8b0hygbxhpribya";
    depsSha256 = "12s2xpgfhl4mb4wa2nk4mzsypr7m9daxxc7l0vraiz5cr77gk7qq";

    inherit rustc; # the rustc that will be wrapped by cargo
    inherit rustPlatform; # used to build cargo
  };
}
