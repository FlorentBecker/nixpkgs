# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, dataDefault, haskellSrcExts, monadLoops, mtl, text }:

cabal.mkDerivation (self: {
  pname = "hindent";
  version = "3.4";
  sha256 = "060l4dkqz4fma005yai6mdv2bdr2lp59z289j7rv1ygr6p8pqhci";
  isLibrary = true;
  isExecutable = true;
  buildDepends = [ dataDefault haskellSrcExts monadLoops mtl text ];
  meta = {
    description = "Extensible Haskell pretty printer";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
