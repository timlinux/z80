{
  description = "Z80 Development Environment with Neovim and LSP support";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/632f04521e847173c54fa72973ec6c39a371211c";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zesarux # ZX Spectrum emulator
            fuse-emulator
            sjasmplus # Z80 assembly compiler
            lsof # for checking if zesarux port is allocated
            vscode # Visual Studio Code for DeZog debugging
          ];

          shellHook = ''
            export DIRENV_LOG_FORMAT=

            echo "-----------------------"
            echo "🌈 Your Z80 Dev Environment is prepared."
            echo "it provides compiler, emulator, neovim with LSP support, and vscode for DeZog"
            echo "For Z80 assembly and ZX Spectrum Basic development"
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
            echo "🚀 Tools available:"
            echo "  - vscode - with DeZog extension for Z80 debugging"
            echo "  - sjasmplus - Z80 assembler" 
            echo "  - zesarux - ZX Spectrum emulator"
            echo "  - asm-lsp - Assembly language server"
            echo ""
            echo "📝 Usage:"
            echo "  code --extensions-dir=\".vscode-extensions\" .  # Start VSCode with DeZog"
            echo "  sjasmplus your_file.asm  # Compile assembly"
            echo "  zesarux  # Run ZX Spectrum emulator"
            echo ""
            echo "📒 Note:"
            echo "See https://github.com/maziac/DeZog#dezog for setting up VSCode"
            echo "-----------------------"
          '';
        };
      });
}

