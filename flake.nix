{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
  };

  outputs = { self, nixpkgs }: 
    let 
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
    packages.${system}.default = pkgs.stdenv.mkDerivation {
      pname = "k4aviewer";
      version = "1.4.1";

      src = ./.; 

      #Stops cmake killing itself
      dontUseCmakeConfigure = true;
      dontUseCmakeBuildDir = true; 
      nativeBuildInputs = with pkgs; [

   
      ];

      buildInputs = with pkgs; [
        #Try and fix build libs
        git
        patchelf
        gnused

        #needed bibs
        cmake
        pkg-config
        ninja
        doxygen
        python312
        nasm
        dpkg

        #Maybe need libs
        glfw
        xorg.libX11
        xorg.libXrandr
        xorg.libXinerama
        xorg.libXcursor
        openssl_legacy
        libsoundio
        libusb1
        libjpeg
        opencv
        libuuid
      ];

      configurePhase =
      let 
        depthengine = builtins.fetchurl {
          url = https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/libk/libk4a1.4/libk4a1.4_1.4.1_amd64.deb;
          sha256 = "sha256:0ackdiakllmmvlnhpcmj2miix7i2znjyai3a2ck17v8ycj0kzin1";
        };
      in ''
        mkdir -p build/bin 
        dpkg -x ${depthengine} build/libdepthengine
        cp build/libdepthengine/usr/lib/x86_64-linux-gnu/libk4a1.4/libdepthengine.so.2.0 build/bin/
        rm -r build/libdepthengine
        cd build
        cmake .. -GNinja
      '';

      buildPhase = ''
        ninja
        export BUILD=`pwd`
      '';

      installPhase = ''
        mkdir -p $out/bin
        cp -r bin $out
        mkdir -p $out/include
        cp -r ../include/k4a $out/include/
      '';
    
      #Removes any RPATH refrences to the temp build folder used during the configure and install phase
      fixupPhase = 
      let
        removeRPATH = file: path: "patchelf --set-rpath `patchelf --print-rpath ${file} | sed 's@'${path}'@@'` ${file}";
      in ''
        cd $out/bin
        for f in *; do if [[ "$f" =~ .*\..*  ]]; then : ignore;else ${removeRPATH "$f" "$BUILD/bin:"};fi; done
        ${removeRPATH "libk4arecord.so.1.4.0" "$BUILD/bin:"}
      '';
      };
    };
}
