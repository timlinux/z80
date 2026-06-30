{
  description = "Z80 Development Environment with Neovim and LSP support";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/632f04521e847173c54fa72973ec6c39a371211c";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # ────────────────────────────────────────────────────────────────────
        # Helper: compile an assembly file with sjasmplus
        # ────────────────────────────────────────────────────────────────────
        # Usage:   nix run .#compile -- learning/main.asm
        # Output:  learning/learning.tap (BASIC autostart + CODE block)
        #          learning/learning.sna (full 48K snapshot - boots instantly)
        compileScript = pkgs.writeShellScriptBin "z80-compile" ''
          #!/usr/bin/env bash
          set -e
          FILE="''${1:-screen-draw/screen_draw.asm}"
          DIR=$(dirname "$FILE")
          BASE=$(basename "$FILE" .asm)
          echo "Compiling $FILE..."
          cd "$DIR"
          ${pkgs.sjasmplus}/bin/sjasmplus --fullpath --sld="$BASE.sld" "$(basename "$FILE")"
          echo "Done! Output: $DIR/$BASE.sna (or .tap)"
        '';

        # ────────────────────────────────────────────────────────────────────
        # Helper: launch fuse safely (kept on a single logical line so callers
        # can append `--snapshot $FILE` or `--auto-load --tape $FILE` cleanly)
        # ────────────────────────────────────────────────────────────────────
        # `LD_LIBRARY_PATH` is unset so fuse picks up the nix-store glibc.
        # The host shell often exports paths to alsa/pipewire libs that were
        # built against a NEWER glibc than fuse expects, causing:
        #   fuse: /...glibc-2.40/.../libc.so.6: version `GLIBC_ABI_DT_X86_64_PLT'
        #         not found (required by /...glibc-2.42/.../librt.so.1)
        # `--no-sound` skips ALSA entirely (the dev shell has no audio anyway),
        # silencing the noisy "couldn't open sound device" warnings.
        fuseLaunch = "env -u LD_LIBRARY_PATH ${pkgs.fuse-emulator}/bin/fuse --machine 48 --no-sound --graphics-filter 4x";

        # ────────────────────────────────────────────────────────────────────
        # Helper: run a compiled program (smart .sna/.tap pick + auto-build)
        # ────────────────────────────────────────────────────────────────────
        # Accepts either a .asm path (assembles if needed, then runs the
        # matching output) or a .sna / .tap directly. Always prefers .sna —
        # see the long comment block at the top of any template main.asm for
        # why the snapshot is the development fast path.
        #
        # Output-file resolution for a .asm input, in order:
        #   1. <dir>/<dir-name>.sna or .tap   (the template convention)
        #   2. <dir>/<asm-basename>.sna or .tap
        #   3. any .sna or .tap in <dir>
        runScript = pkgs.writeShellScriptBin "z80-run" ''
          #!/usr/bin/env bash
          set -e
          TARGET="''${1:-learning/main.asm}"

          pick_output() {
            local dir="$1"
            # 1. dirname.sna / dirname.tap (matches the template's SAVESNA/SAVETAP)
            local dname="$(basename "$dir")"
            for ext in sna tap; do
              [[ -f "$dir/$dname.$ext" ]] && { echo "$dir/$dname.$ext"; return 0; }
            done
            # 2. matches the .asm basename
            local asmbase="$2"
            for ext in sna tap; do
              [[ -f "$dir/$asmbase.$ext" ]] && { echo "$dir/$asmbase.$ext"; return 0; }
            done
            # 3. any output in dir (prefer .sna)
            local cand
            cand=$(ls -t "$dir"/*.sna "$dir"/*.tap 2>/dev/null | head -1)
            [[ -n "$cand" ]] && { echo "$cand"; return 0; }
            return 1
          }

          if [[ "$TARGET" == *.asm ]]; then
            DIR=$(cd "$(dirname "$TARGET")" && pwd)
            ASMBASE=$(basename "$TARGET" .asm)

            # Assemble if there's no matching output, or if the source is newer.
            OUT=$(pick_output "$DIR" "$ASMBASE" || true)
            if [[ -z "$OUT" || "$DIR/$(basename "$TARGET")" -nt "$OUT" ]]; then
              echo "Assembling $TARGET..."
              (cd "$DIR" && \
                ${pkgs.sjasmplus}/bin/sjasmplus --fullpath \
                  --sld="$ASMBASE.sld" "$(basename "$TARGET")")
              OUT=$(pick_output "$DIR" "$ASMBASE" || true)
            fi

            if [[ -z "$OUT" ]]; then
              echo "No .sna or .tap output found in $DIR — does your asm include SAVESNA / SAVETAP?"
              exit 1
            fi
            TARGET="$OUT"
          fi

          if [[ ! -f "$TARGET" ]]; then
            echo "File not found: $TARGET"
            exit 1
          fi

          case "$TARGET" in
            *.sna)
              echo "Running $TARGET in FUSE (instant SNA snapshot)..."
              exec ${fuseLaunch} --snapshot "$TARGET"
              ;;
            *.tap)
              echo "Running $TARGET in FUSE (--auto-load + BASIC autostart)..."
              exec ${fuseLaunch} --auto-load --tape "$TARGET"
              ;;
            *)
              echo "Unknown file type (need .sna or .tap): $TARGET"
              exit 1
              ;;
          esac
        '';

        # Helper script to run with debug enabled
        debugScript = pkgs.writeShellScriptBin "z80-debug" ''
          #!/usr/bin/env bash
          FILE="''${1:-screen-draw/screen_draw.tap}"
          if [[ ! -f "$FILE" ]]; then
            echo "File not found: $FILE"
            exit 1
          fi
          echo "Starting ZEsarUX in debug mode (ZRCP on port 10000)..."
          if [[ "$FILE" == *.tap ]]; then
            FLAG="--tape"
          else
            FLAG="--snap"
          fi
          ${pkgs.zesarux}/bin/zesarux \
            --noconfigfile \
            --machine 48k \
            --enable-remoteprotocol \
            --disable-autoframeskip \
            $FLAG "$FILE"
        '';

        # ────────────────────────────────────────────────────────────────────
        # Helper: build + run in one step (the "F5" of Z80 dev)
        # ────────────────────────────────────────────────────────────────────
        # This is the everyday loop: edit main.asm, run this, see the result.
        # Prefers the .sna output for instant boot — see the BIG COMMENT in
        # the generated template for the reasoning.
        buildRunScript = pkgs.writeShellScriptBin "z80-build-run" ''
          #!/usr/bin/env bash
          set -e
          FILE="''${1:-learning/main.asm}"
          DIR=$(cd "$(dirname "$FILE")" && pwd)
          BASE=$(basename "$FILE" .asm)
          DNAME=$(basename "$DIR")

          echo "Building $FILE..."
          cd "$DIR"
          ${pkgs.sjasmplus}/bin/sjasmplus --fullpath --sld="$BASE.sld" "$(basename "$FILE")"

          # Resolve output: prefer <dir>/<dirname>.sna (the template convention),
          # then fall back to <dir>/<asm-basename>.sna, then any .sna/.tap.
          OUTPUT=""
          for cand in "$DNAME.sna" "$DNAME.tap" "$BASE.sna" "$BASE.tap"; do
            if [[ -f "$cand" ]]; then OUTPUT="$cand"; break; fi
          done
          if [[ -z "$OUTPUT" ]]; then
            OUTPUT=$(ls -t *.sna *.tap 2>/dev/null | head -1)
          fi
          if [[ -z "$OUTPUT" ]]; then
            echo "No .sna or .tap output found — does your asm include SAVESNA / SAVETAP?"
            exit 1
          fi

          case "$OUTPUT" in
            *.sna)
              echo "Running $OUTPUT in FUSE (instant SNA snapshot)..."
              exec ${fuseLaunch} --snapshot "$OUTPUT"
              ;;
            *.tap)
              echo "Running $OUTPUT in FUSE (--auto-load + BASIC autostart)..."
              exec ${fuseLaunch} --auto-load --tape "$OUTPUT"
              ;;
          esac
        '';

        # Create a new program from template
        newProgramScript = pkgs.writeShellScriptBin "z80-new-program" ''
          #!/usr/bin/env bash
          exec "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/scripts/z80-new-program" "$@"
        '';

        # ────────────────────────────────────────────────────────────────────
        # Helper: force-run in FUSE (regardless of file extension)
        # ────────────────────────────────────────────────────────────────────
        fuseScript = pkgs.writeShellScriptBin "z80-fuse" ''
          #!/usr/bin/env bash
          FILE="''${1:-learning/learning.sna}"
          if [[ ! -f "$FILE" ]]; then
            echo "File not found: $FILE"
            exit 1
          fi
          case "$FILE" in
            *.tap)
              echo "Running $FILE in FUSE (--auto-load + BASIC autostart)..."
              exec ${fuseLaunch} --auto-load --tape "$FILE"
              ;;
            *)
              echo "Running $FILE in FUSE (--snapshot, instant boot)..."
              exec ${fuseLaunch} --snapshot "$FILE"
              ;;
          esac
        '';

        # ────────────────────────────────────────────────────────────────────
        # Helper: browse and run vintage tape collection in tapes/
        # ────────────────────────────────────────────────────────────────────
        tapesScript = pkgs.writeShellScriptBin "z80-tapes" ''
          #!/usr/bin/env bash
          if [[ ! -d "tapes" ]]; then
            echo "No tapes directory found!"
            exit 1
          fi

          if [[ -n "$1" ]]; then
            exec ${fuseLaunch} --auto-load --tape "$1"
          else
            echo "Available tapes:"
            find tapes -type f \( -name "*.tap" -o -name "*.TAP" \) | sort
            echo ""
            echo "Usage: nix run .#tapes -- path/to/tape.tap"
          fi
        '';

        # Open documentation
        docsScript = pkgs.writeShellScriptBin "z80-docs" ''
          #!/usr/bin/env bash
          echo "Z80/ZX Spectrum Reference Documentation"
          echo "======================================="
          echo ""
          echo "1) Z80 Mnemonics:       http://www.z80.info/z80syntx.htm"
          echo "2) ZX Character Set:    https://worldofspectrum.net/ZXBasicManual/zxmanappa.html"
          echo "3) Spectrum Manual:     http://www.retro8bitcomputers.co.uk/Content/downloads/manuals/ZX-Spectrum-48K-Manual.pdf"
          echo "4) ROM Routines:        https://skoolkid.github.io/rom/maps/routines.html"
          echo "5) ChibiAkumas Tuts:    https://www.chibiakumas.com/z80/ZXSpectrum.php"
          echo "6) Cheat Sheet:         https://www.chibiakumas.com/book/CheatSheetCollection.pdf"
          echo ""

          if [[ -n "$1" ]]; then
            case "$1" in
              1|mnemonics)  xdg-open "http://www.z80.info/z80syntx.htm" ;;
              2|charset)    xdg-open "https://worldofspectrum.net/ZXBasicManual/zxmanappa.html" ;;
              3|manual)     xdg-open "http://www.retro8bitcomputers.co.uk/Content/downloads/manuals/ZX-Spectrum-48K-Manual.pdf" ;;
              4|rom)        xdg-open "https://skoolkid.github.io/rom/maps/routines.html" ;;
              5|tutorials)  xdg-open "https://www.chibiakumas.com/z80/ZXSpectrum.php" ;;
              6|cheatsheet) xdg-open "https://www.chibiakumas.com/book/CheatSheetCollection.pdf" ;;
              *)            echo "Unknown option: $1" ;;
            esac
          else
            echo "Usage: nix run .#docs -- [1-7|name]"
          fi
        '';

      in {
        # Convenience apps
        apps = {
          compile = {
            type = "app";
            program = "${compileScript}/bin/z80-compile";
          };
          run = {
            type = "app";
            program = "${runScript}/bin/z80-run";
          };
          debug = {
            type = "app";
            program = "${debugScript}/bin/z80-debug";
          };
          build-run = {
            type = "app";
            program = "${buildRunScript}/bin/z80-build-run";
          };
          fuse = {
            type = "app";
            program = "${fuseScript}/bin/z80-fuse";
          };
          tapes = {
            type = "app";
            program = "${tapesScript}/bin/z80-tapes";
          };
          docs = {
            type = "app";
            program = "${docsScript}/bin/z80-docs";
          };
          new = {
            type = "app";
            program = "${newProgramScript}/bin/z80-new-program";
          };
        };

        # Default app is build-run
        apps.default = self.apps.${system}.build-run;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zesarux # ZX Spectrum emulator
            fuse-emulator # Alternative emulator
            sjasmplus # Z80 assembly compiler
            lsof # for checking if zesarux port is allocated
            xdg-utils # for opening URLs

            # Scripts available in shell
            compileScript
            runScript
            debugScript
            buildRunScript
            fuseScript
            tapesScript
            docsScript
            newProgramScript
          ];

          shellHook = ''
            export DIRENV_LOG_FORMAT=

            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  🎮 Z80 / ZX Spectrum Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "  📦 Tools Available:"
            echo "     • sjasmplus    - Z80 assembler with ZX Spectrum support"
            echo "     • zesarux      - ZX Spectrum emulator (48K/128K/Next)"
            echo "     • fuse         - Alternative Spectrum emulator"
            echo ""
            echo "  🚀 Quick Commands (nix run):"
            echo "     • nix run .#compile -- path/main.asm   - Assemble → .tap + .sna"
            echo "     • nix run .#run     -- path/main.asm   - Build (if needed) & run in FUSE"
            echo "     • nix run .#build-run -- path/main.asm - Force rebuild + run in FUSE"
            echo "     • nix run .#fuse    -- path/file.sna   - Run already-built file in FUSE"
            echo "     • nix run .#debug   -- path/file.sna   - Run in ZEsarUX with ZRCP (port 10000)"
            echo "     • nix run .#new     -- name            - Scaffold a new program from template"
            echo "     • nix run .#tapes                      - List vintage tapes/"
            echo "     • nix run .#docs                       - Open reference documentation"
            echo ""
            echo "     The run scripts prefer .sna (instant boot) over .tap (full BASIC"
            echo "     autostart sequence). See README + template comments for details."
            echo ""
            echo "  📝 Neovim Shortcuts (<leader>p):"
            echo "     • <leader>pbc  - Compile current file"
            echo "     • <leader>pbr  - Build and run"
            echo "     • <leader>pn   - Create new program"
            echo "     • <leader>pp   - Pick/switch program"
            echo "     • <leader>prz  - Run in ZEsarUX"
            echo "     • <leader>prd  - Debug mode"
            echo "     • <leader>pda  - Open reference docs"
            echo "     • <leader>phi  - Help for instruction under cursor"
            echo ""
            echo "  📚 Quick Reference:"
            echo "     • z80-docs     - Show documentation links"
            echo "     • Ctrl-X Ctrl-O in Neovim for Z80 completion"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  Made with 💗 by Kartoza | https://kartoza.com"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
          '';
        };
      });
}

