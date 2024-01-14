let
  nixpkgs = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/9665f56e3b9c0bfaa07ca88b03b62bb277678a23.tar.gz";
  pkgs = import nixpkgs { config = { }; overlays = [ ]; };
in
with pkgs;
mkShell {
  buildInputs = [
    zesarux # zx spectrum emulator
    fuse-emulator # another (nicer?) zx spectrum emulator - does not work with dezog
    sjasmplus # assembly compiler
    vscode
    lsof # for checking if zesarux port is allocated
  ];
  # DIRENV_LOG_FORMAT to reduce direnv verbosity
  # See https://github.com/direnv/direnv/issues/68#issuecomment-162639262
  shellHook = ''
     export DIRENV_LOG_FORMAT=
     echo "-----------------------"
     echo "🌈 Your Z80 Dev Environment is prepared."
     echo "it provides compiler, emulator and vscode for use with DeZog"
     echo "See https://github.com/maziac/DeZog#dezog for setting up VSCode"
     echo ""
     echo "🪛 Installing VSCode Extensions:"
     echo "--------------------------------"
     code --extensions-dir=".vscode-extensions" --install-extension maziac.asm-code-lens
     code --extensions-dir=".vscode-extensions" --install-extension maziac.dezog
     code --extensions-dir=".vscode-extensions" --install-extension maziac.hex-hover-converter
     code --extensions-dir=".vscode-extensions" --install-extension maziac.z80-instruction-set
     code --extensions-dir=".vscode-extensions" --install-extension maziac.sna-fileviewer
     code --extensions-dir=".vscode-extensions" --install-extension Imanolea.z80-asm
     echo ""
     echo "📒 Note:"
     echo "-----------------------"
     echo "start vscode like this:"
     echo ""
     echo "code --extensions-dir=\".vscode-extensions\" ."
     echo "-----------------------"
  '';
  postShellHook = ''
  '';
}
