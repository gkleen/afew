{
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "master";
    };
    flake-utils = {
      type = "github";
      owner = "numtide";
      repo = "flake-utils";
      ref = "master";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem
    (system:
      let pkgs = import nixpkgs {
            inherit system;
          };

          afew = pkgs.python3Packages.buildPythonApplication rec {
            pname = "afew";
            version = "3.0.1";

            src = ./.;
            patches = [ ./flake-setup.py.diff ];

            nativeBuildInputs = with pkgs.python3Packages; [ sphinx ];

            propagatedBuildInputs = with pkgs.python3Packages; [
              setuptools notmuch chardet dkimpy
            ];

            doCheck = true;
            checkInputs = with pkgs.python3Packages; [
              freezegun pkgs.notmuch
            ];

            makeWrapperArgs = [
              ''--prefix PATH ':' "${pkgs.notmuch}/bin"''
            ];

            outputs = [ "out" "doc" ];

            preBuild = with pkgs.lib; ''
              cat >afew/version.py <<EOF
              version = '${version}'
              version_tuple = (${concatStringsSep ", " (splitVersion version)})
              EOF
            '';
            postBuild =  ''
              ${pkgs.python3Packages.python.interpreter} setup.py build_sphinx -b html,man
            '';

            postInstall = ''
              install -D -v -t $out/share/man/man1 build/sphinx/man/*
              mkdir -p $out/share/doc/afew
              cp -R build/sphinx/html/* $out/share/doc/afew
            '';
          };
      in {
        packages = { inherit afew; };
        defaultPackage = self.packages.${system}.afew;
        devShell = self.defaultPackage.${system};
      }
    );
}
