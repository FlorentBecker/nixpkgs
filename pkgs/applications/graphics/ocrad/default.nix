{ fetchurl, stdenv, lzip, texinfo }:

stdenv.mkDerivation rec {
  name = "ocrad-0.23";

  src = fetchurl {
    url = "mirror://gnu/ocrad/${name}.tar.lz";
    sha256 = "0vx0v4sz8ivgcp04zggdq9cv9sb5zxnn7j1nm15cds0zq1wr9g7m";
  };

  buildInputs = [ lzip texinfo ];

  doCheck = true;

  meta = with stdenv.lib; {
    description = "Optical character recognition (OCR) program & library";

    longDescription =
      '' GNU Ocrad is an OCR (Optical Character Recognition) program based on
         a feature extraction method.  It reads images in pbm (bitmap), pgm
         (greyscale) or ppm (color) formats and produces text in byte (8-bit)
         or UTF-8 formats.

         Also includes a layout analyser able to separate the columns or
         blocks of text normally found on printed pages.

         Ocrad can be used as a stand-alone console application, or as a
         backend to other programs.
      '';

    license = licenses.gpl3Plus;

    maintainers = with maintainers; [ pSub ];
    platforms = platforms.gnu;  # arbitrary choice
  };
}
