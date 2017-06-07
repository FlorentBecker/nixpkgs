{ stdenv, fetchurl, rustPlatform, perl, darwin }:

with rustPlatform;

buildRustPackage rec {
  name = "pijul-${version}";
  version = "0.6.0";

  raw_src = fetchurl {
    url = "https://pijul.org/releases/${name}.tar.gz";
    sha256 = "a6b066b49b25d1083320c5ab23941deee795e1fcbe1faa951e95189fd594cdb3";
  };

  src = "${name}.tar.gz";

  sourceRoot = "${name}/pijul";

  preUnpack = ''
     tar -cf empty.tar -T /dev/null
     cp ${raw_src} ${name}.tar.gz
     chmod u+w ${name}.tar.gz
     tar -xf ${name}.tar.gz --transform=s,^,${name}/,
     tar -cf ${name}.tar.gz ${name}
     rm -rf ${name}
  '';

  buildInputs = [ perl ]++ stdenv.lib.optionals stdenv.isDarwin
    (with darwin.apple_sdk.frameworks; [ Security ]);

  doCheck = false;

  depsSha256 = "0raim0ahqg6fkidb6picfzircdzwdbsdmmv8in70r5hw770bv67r";

  meta = with stdenv.lib; {
    description = "A distributed version control system";
    homepage = https://pijul.org;
    license = with licenses; [ gpl2Plus ];
    maintainers = [ maintainers.gal_bolle ];
    platforms = platforms.all;
  };
}
