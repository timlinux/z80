{
  description = "Z80 Development Environment with Neovim and LSP support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/632f04521e847173c54fa72973ec6c39a371211c";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Custom Neovim configuration with Z80 and ZX Spectrum Basic LSP support
        neovimConfig = pkgs.neovim.override {
          configure = {
            customRC = ''
              " Basic Neovim configuration for Z80 development
              set number
              set relativenumber
              set tabstop=4
              set shiftwidth=4
              set expandtab
              set smartindent
              set hlsearch
              set incsearch
              set ignorecase
              set smartcase
              set wrap
              set linebreak
              set mouse=a
              set clipboard=unnamedplus
              
              " File type detection for Z80 assembly
              autocmd BufNewFile,BufRead *.asm,*.s,*.z80 set filetype=z80
              autocmd BufNewFile,BufRead *.bas set filetype=basic
              
              " LSP configuration
              lua << EOF
              -- Configure LSP servers
              local lspconfig = require('lspconfig')
              
              -- Basic LSP keybindings
              local on_attach = function(client, bufnr)
                local bufopts = { noremap=true, silent=true, buffer=bufnr }
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
                vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
                vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
                vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
                vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
              end
              
              -- Configure asm-lsp for Z80 assembly
              lspconfig.asm_lsp.setup{
                on_attach = on_attach,
                filetypes = {"asm", "s", "z80"},
                root_dir = function() return vim.loop.cwd() end,
                settings = {
                  asm_lsp = {
                    assemblers = {
                      {
                        name = "sjasmplus",
                        command = "sjasmplus",
                        args = {"--syntax=z80"}
                      }
                    }
                  }
                }
              }
              EOF
            '';
            packages.myVimPackage = with pkgs.vimPlugins; {
              start = [
                nvim-lspconfig
                nvim-treesitter.withAllGrammars
                plenary-nvim
                telescope-nvim
                which-key-nvim
                nvim-cmp
                cmp-nvim-lsp
                cmp-buffer
                cmp-path
                luasnip
                cmp_luasnip
                lualine-nvim
                nvim-web-devicons
                tokyonight-nvim
              ];
            };
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zesarux           # ZX Spectrum emulator
            sjasmplus         # Z80 assembly compiler
            lsof              # for checking if zesarux port is allocated
            lima              # for running containers
            neovimConfig      # Custom Neovim with LSP
            asm-lsp           # Assembly language server
            lua-language-server # For Neovim Lua configuration
          ];
          
          shellHook = ''
            export DIRENV_LOG_FORMAT=
            echo "-----------------------"
            echo "🌈 Your Z80 Dev Environment is prepared."
            echo "it provides compiler, emulator and neovim with LSP support"
            echo "For Z80 assembly and ZX Spectrum Basic development"
            echo ""
            echo "🚀 Tools available:"
            echo "  - neovim (nvim) - with Z80 assembly and Basic LSP"
            echo "  - sjasmplus - Z80 assembler" 
            echo "  - zesarux - ZX Spectrum emulator"
            echo "  - asm-lsp - Assembly language server"
            echo ""
            echo "📝 Usage:"
            echo "  nvim your_file.asm  # Edit Z80 assembly with LSP"
            echo "  nvim your_file.bas  # Edit ZX Spectrum Basic"
            echo "  sjasmplus your_file.asm  # Compile assembly"
            echo "  zesarux  # Run ZX Spectrum emulator"
            echo "-----------------------"
          '';
        };
      });
}