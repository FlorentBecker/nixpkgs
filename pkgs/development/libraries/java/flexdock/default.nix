{stdenv, fetchurl, ant, jdk8}:

stdenv.mkDerivation {
  name = "flexdock-1.2.4";
  src = fetchurl {
     url = http://forge.scilab.org/index.php/p/flexdock/downloads/get/flexdock-1.2.4.tar.gz;
     md5 = "79883baeb9d628d45fa4d16897f6d96b";
  };

  buildInputs = [ ant jdk8 ];

  buildPhase = "ant dist";

  installPhase = ''
     mkdir -p "$out"/share/java
     cp build/flexdock-1.2.4.jar $out/share/java
     cp lib/*.jar $out/share/java #*/
  '';

  
  meta = {
    homepage = http://forge.scilab.org/index.php/p/flexdock/;
    description = "Java docking framework for use in cross-platform Swing applications.";
    # see http://www.scilab.org/legal
    license = "SciLab"; 
  };

}
