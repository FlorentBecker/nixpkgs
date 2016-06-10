{stdenv, fetchurl, ant, jdk8}:

stdenv.mkDerivation {
  name = "jgraphx-3.5.1.4";
  src = fetchurl {
     url = https://github.com/jgraph/jgraphx/archive/v3.5.1.4.tar.gz;
     sha256 = "13zfhdkqjwj0bll7syg7k73cv0qj3msm0m4j6ix28flvp3d38ryb";
  };

  buildInputs = [ ant jdk8 ];

  buildPhase = "ant";

  installPhase = ''
     mkdir -p "$out"/share/java
     cp -v lib/*.jar $out/share/java #*/
     ls $out
  '';
}
