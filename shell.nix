let
  nixpkgs = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/9665f56e3b9c0bfaa07ca88b03b62bb277678a23.tar.gz";
  pkgs = import nixpkgs { config = { }; overlays = [ ]; };
in
with pkgs;
mkShell {
  buildInputs = [
    zesarux # zx spectrum emulator
    sjasmplus # assembly compiler
    vscode
  ];

  shellHook = ''
    # Remove playwright from node_modules, so it will be taken from playwright-test
    echo "See https://github.com/maziac/DeZog#dezog for setting up VSCode"
    echo "To start the vscode set up in this dev shell, type:"
    echo "code ."
  '';
}
