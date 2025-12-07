-- Z80 Development Environment - Neovim Configuration
-- This config layers on top of your existing timvim setup

-- File type detection for Z80 assembly and ZX Spectrum Basic
vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
  pattern = {"*.asm", "*.s", "*.z80"},
  command = "set filetype=z80"
})

vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
  pattern = "*.bas",
  command = "set filetype=basic"
})

-- Configure asm-lsp for Z80 assembly (only if lspconfig is available)
local has_lspconfig, lspconfig = pcall(require, 'lspconfig')
if has_lspconfig then
  -- Basic LSP keybindings for Z80 files
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
else
  print("Note: lspconfig not found, Z80 LSP features not available")
end

-- Z80 specific settings for assembly files
vim.api.nvim_create_autocmd("FileType", {
  pattern = {"z80", "asm"},
  callback = function()
    vim.opt_local.tabstop = 8
    vim.opt_local.shiftwidth = 8
    vim.opt_local.expandtab = false  -- Use tabs for assembly
    vim.opt_local.commentstring = "; %s"
  end
})

print("Z80 development environment loaded! 🚀")