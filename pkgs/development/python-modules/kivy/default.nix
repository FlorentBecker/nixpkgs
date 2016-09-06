{ fetchurl, buildPythonPackage, pkgconfig, cython, kivy-garden, mesa,
  mesa_glu, SDL2, SDL2_gfx, SDL2_image, SDL2_mixer, SDL2_ttf, ffmpeg,
  gst_all_1}:
  
buildPythonPackage {
    name = "kivy-1.9.1";

    buildInputs = ([ cython kivy-garden ]);
    nativeBuildInputs = ([ mesa  SDL2 SDL2_gfx SDL2_image SDL2_mixer SDL2_ttf gst_all_1.gstreamer pkgconfig ]);

    preBuild = "export KIVY_SDL2_PATH=${SDL2}:${SDL2_ttf}:${SDL2_image}:${SDL2_mixer}";

    patches = [ ./setup.diff ];
    
    src = fetchurl {
       url = "https://pypi.python.org/packages/87/eb/a7aa5e23fdaed4683467ca26ab175739bdd05c00610df185eb83f7cdff38/kivy-1.9.1.tar.gz";
       sha256 = "0zk3g1j1z0lzcm9d0k1lprrs95zr8n8k5pdg3p5qlsn26jz4bg19";
    };

    doCheck = false;   

  meta = with stdenv.lib; {
    homepage = "http://kivy.org";

    description = ''
      Open source Python library for rapid development of
      applications that make use of innovative user interfaces, such as
      multi-touch apps.
    '';

     license = with licenses; [ MIT ];
  }

}
