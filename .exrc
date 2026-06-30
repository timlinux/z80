" Z80 Assembly Development Environment - Project .exrc
" Neovim/Vim project-local configuration
" Made with love by Kartoza | https://kartoza.com
"
" This file sets up which-key mappings under <leader>p for Z80 development
" Requires: which-key.nvim plugin for best experience
"
" ============================================================================
" Load project-specific Lua configuration
" ============================================================================

if has('nvim')
  " Source the Lua configuration
  lua dofile(vim.fn.getcwd() .. '/.nvim.lua')
endif

" ============================================================================
" Z80 Assembly File Type Settings
" ============================================================================

augroup z80_settings
  autocmd!
  autocmd BufNewFile,BufRead *.asm,*.z80,*.inc setlocal filetype=z80
  autocmd FileType z80,asm setlocal commentstring=;\ %s
  autocmd FileType z80,asm setlocal tabstop=8 shiftwidth=8 noexpandtab
  " Enable omni-completion with Ctrl-X Ctrl-O
  autocmd FileType z80,asm setlocal omnifunc=v:lua.Z80Complete
augroup END

" ============================================================================
" Which-Key Mappings (under <leader>p for Project)
" ============================================================================

" Register which-key mappings
if has('nvim')
lua << EOF
  -- Function to register Z80 keymaps
  local function register_z80_keymaps()
    local ok, wk = pcall(require, 'which-key')
    if ok and Z80Dev then
      -- Use which-key v3 API (add)
      wk.add({
        { "<leader>p", group = "Z80 Project" },
        { "<leader>pb", group = "Build/Run" },
        { "<leader>pbc", function() Z80Dev.compile() end, desc = "Compile ASM" },
        { "<leader>pbr", function() Z80Dev.build_and_run() end, desc = "Build & Run" },
        { "<leader>pbs", "<cmd>write<cr>", desc = "Save file" },
        { "<leader>pr", group = "Run Emulator" },
        { "<leader>prr", function() Z80Dev.run() end, desc = "Run (auto: FUSE for .tap, ZEsarUX for .sna)" },
        { "<leader>prz", function() Z80Dev.run_zesarux() end, desc = "Force ZEsarUX" },
        { "<leader>prf", function() Z80Dev.run_fuse() end, desc = "Force FUSE" },
        { "<leader>prd", function() Z80Dev.run_debug() end, desc = "Debug (ZEsarUX ZRCP)" },
        { "<leader>pd", group = "Docs/Reference" },
        { "<leader>pda", function() Z80Dev.show_references() end, desc = "All References" },
        { "<leader>pdm", function() Z80Dev.open_reference('mnemonics') end, desc = "Z80 Mnemonics" },
        { "<leader>pdc", function() Z80Dev.open_reference('charset') end, desc = "ZX Charset" },
        { "<leader>pds", function() Z80Dev.open_reference('manual') end, desc = "Spectrum Manual" },
        { "<leader>pdr", function() Z80Dev.open_reference('rom') end, desc = "ROM Routines" },
        { "<leader>pdt", function() Z80Dev.open_reference('chibiakumas') end, desc = "Tutorials" },
        { "<leader>pdh", function() Z80Dev.open_reference('cheatsheet') end, desc = "Cheat Sheet" },
        { "<leader>ph", group = "Help" },
        { "<leader>phi", function() Z80Dev.instruction_help() end, desc = "Instruction Help (cursor)" },
        { "<leader>phq", "<cmd>copen<cr>", desc = "Open Quickfix" },
        { "<leader>phc", "<cmd>cclose<cr>", desc = "Close Quickfix" },
        { "<leader>pg", group = "Games/Tapes" },
        { "<leader>pgl", function()
            local tapes = {}
            for _, pattern in ipairs({ 'tapes/**/*.tap', 'tapes/**/*.TAP' }) do
              for _, f in ipairs(vim.fn.glob(pattern, false, true)) do
                if vim.fn.isdirectory(f) == 0 then
                  table.insert(tapes, f)
                end
              end
            end
            table.sort(tapes)
            vim.ui.select(tapes, { prompt = 'Select tape to run:' }, function(choice)
              if choice then
                vim.fn.jobstart({
                  'fuse', '--machine', '48', '--no-sound',
                  '--graphics-filter', '4x', '--auto-load', '--tape', choice
                }, { detach = true, env = { LD_LIBRARY_PATH = '' } })
                vim.notify('Loading: ' .. choice, vim.log.levels.INFO)
              end
            end)
          end, desc = "Load Tape" },
        { "<leader>pn", function() Z80Dev.new_program() end, desc = "New Program" },
        { "<leader>pp", function() Z80Dev.pick_program() end, desc = "Pick Program" },
      })
      return true
    end
    return false
  end

  -- Also set up regular keymaps as backup (these always work)
  vim.keymap.set('n', '<leader>pbc', '<cmd>Z80Compile<cr>', { desc = 'Compile ASM' })
  vim.keymap.set('n', '<leader>pbr', '<cmd>Z80BuildRun<cr>', { desc = 'Build & Run' })
  vim.keymap.set('n', '<leader>prz', '<cmd>Z80Run<cr>', { desc = 'Run ZEsarUX' })
  vim.keymap.set('n', '<leader>prf', '<cmd>Z80Fuse<cr>', { desc = 'Run FUSE' })
  vim.keymap.set('n', '<leader>prd', '<cmd>Z80Debug<cr>', { desc = 'Debug mode' })
  vim.keymap.set('n', '<leader>pda', '<cmd>Z80Refs<cr>', { desc = 'References' })
  vim.keymap.set('n', '<leader>phi', '<cmd>Z80Help<cr>', { desc = 'Instruction help' })
  vim.keymap.set('n', '<leader>pn', '<cmd>Z80New<cr>', { desc = 'New program' })
  vim.keymap.set('n', '<leader>pp', '<cmd>Z80Pick<cr>', { desc = 'Pick program' })

  -- Try to register with which-key now
  if not register_z80_keymaps() then
    -- If it fails, try again after VimEnter
    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        vim.defer_fn(register_z80_keymaps, 50)
      end,
      once = true,
    })
  end
EOF
endif

" ============================================================================
" Fallback Vim Mappings (for non-nvim or before plugins load)
" ============================================================================

" Quick compile with F5
nnoremap <F5> <cmd>Z80Compile<CR>

" Quick run with F6 (smart: FUSE for .tap, ZEsarUX for .sna)
nnoremap <F6> <cmd>Z80Run<CR>

" Build and run with F7
nnoremap <F7> <cmd>Z80BuildRun<CR>

" Toggle comment with gc (if commentary.vim is available)
" Already handled by vim-commentary or Comment.nvim

" ============================================================================
" Abbreviations for common Z80 patterns
" ============================================================================

" Common screen addresses
iabbrev SCREEN_START 0x4000
iabbrev ATTR_START 0x5800
iabbrev SYSVARS 0x5C00

" Common device declarations
iabbrev DEV48 DEVICE ZXSPECTRUM48
iabbrev DEV128 DEVICE ZXSPECTRUM128

" Common loop pattern
iabbrev LOOP_B LD B,<++><CR>loop_<++>:<CR><++><CR>DJNZ loop_<++>

" ============================================================================
" Quick Snippets (Tab-triggered if UltiSnips/LuaSnip available)
" ============================================================================

" These work as basic snippets without a snippet engine
" Type the abbreviation and press space

" LDIR block copy pattern
iabbrev BLKCOPY ; Block copy: src -> dst, len bytes<CR>LD HL,<++>  ; source<CR>LD DE,<++>  ; destination<CR>LD BC,<++>  ; length<CR>LDIR

" Delay loop pattern
iabbrev DELAY ; Delay loop<CR>LD BC,<++><CR>delay_<++>:<CR>DEC BC<CR>LD A,B<CR>OR C<CR>JR NZ,delay_<++>

" Keyboard check pattern
iabbrev KEYCHECK ; Check keyboard (result in A, active low)<CR>LD A,<++>  ; row (0xFE=CAPS-V, 0xFD=A-G, etc)<CR>IN A,(0xFE)

" ============================================================================
" Project-specific paths (relative to project root)
" ============================================================================

" Set path for gf (go to file) command - includes all program subdirs
set path+=**

" Suffixes to try when using gf
set suffixesadd+=.asm,.inc,.z80

" ============================================================================
" Quickfix Error Format for sjasmplus
" ============================================================================

" sjasmplus error format: file(line): severity: message
set errorformat=%f(%l):\ %t%*[^:]:\ %m

" ============================================================================
" Local Project Variables
" ============================================================================

let g:z80_project_root = getcwd()
let g:z80_emulator = 'zesarux'  " or 'fuse'

" ============================================================================
" Diagnostic display settings
" ============================================================================

if has('nvim')
  lua vim.diagnostic.config({ virtual_text = true, signs = true })
endif

" vim: set ft=vim ts=2 sw=2 et:
