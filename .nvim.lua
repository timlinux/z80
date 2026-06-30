-- Z80 Assembly Development Environment for Neovim
-- Project-specific configuration for ZX Spectrum development
-- Made with love by Kartoza | https://kartoza.com

local M = {}

-- Project root detection
local project_root = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand('<sfile>:p')), ':h')

-- ============================================================================
-- Z80 Assembly Filetype Detection
-- ============================================================================
vim.filetype.add({
  extension = {
    asm = 'z80',
    z80 = 'z80',
    inc = 'z80',
  },
  pattern = {
    ['.*%.asm'] = 'z80',
  },
})

-- ============================================================================
-- Z80 Syntax Highlighting Enhancement
-- ============================================================================
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'z80', 'asm' },
  callback = function()
    -- Set up Z80-specific syntax if not already loaded
    vim.opt_local.commentstring = '; %s'
    vim.opt_local.tabstop = 8
    vim.opt_local.shiftwidth = 8
    vim.opt_local.expandtab = false
    vim.opt_local.iskeyword:append('_')

    -- Enable folding on labels
    vim.opt_local.foldmethod = 'expr'
    vim.opt_local.foldexpr = 'getline(v:lnum)=~"^[a-zA-Z_].*:$"?">1":"="'
    vim.opt_local.foldlevel = 99
  end,
})

-- ============================================================================
-- Z80 Instruction Completion (Omnifunc)
-- ============================================================================
local z80_instructions = {
  -- 8-bit Load Group
  { word = 'LD', info = 'Load: LD dst, src' },
  { word = 'LD A,', info = 'Load accumulator' },
  { word = 'LD B,', info = 'Load B register' },
  { word = 'LD C,', info = 'Load C register' },
  { word = 'LD D,', info = 'Load D register' },
  { word = 'LD E,', info = 'Load E register' },
  { word = 'LD H,', info = 'Load H register' },
  { word = 'LD L,', info = 'Load L register' },
  { word = 'LD (HL),', info = 'Load memory at HL' },
  { word = 'LD (IX+d),', info = 'Load indexed IX' },
  { word = 'LD (IY+d),', info = 'Load indexed IY' },

  -- 16-bit Load Group
  { word = 'LD BC,', info = 'Load BC pair' },
  { word = 'LD DE,', info = 'Load DE pair' },
  { word = 'LD HL,', info = 'Load HL pair' },
  { word = 'LD SP,', info = 'Load stack pointer' },
  { word = 'LD IX,', info = 'Load IX register' },
  { word = 'LD IY,', info = 'Load IY register' },
  { word = 'PUSH', info = 'Push to stack: PUSH rp' },
  { word = 'POP', info = 'Pop from stack: POP rp' },

  -- Exchange Group
  { word = 'EX', info = 'Exchange: EX DE,HL / EX AF,AF\' / EX (SP),HL' },
  { word = 'EX DE,HL', info = 'Exchange DE and HL' },
  { word = "EX AF,AF'", info = 'Exchange AF with shadow' },
  { word = 'EXX', info = 'Exchange BC,DE,HL with shadows' },
  { word = 'LDI', info = 'Load and Increment' },
  { word = 'LDIR', info = 'Load, Inc, Repeat (block copy)' },
  { word = 'LDD', info = 'Load and Decrement' },
  { word = 'LDDR', info = 'Load, Dec, Repeat' },
  { word = 'CPI', info = 'Compare and Increment' },
  { word = 'CPIR', info = 'Compare, Inc, Repeat' },
  { word = 'CPD', info = 'Compare and Decrement' },
  { word = 'CPDR', info = 'Compare, Dec, Repeat' },

  -- Arithmetic Group
  { word = 'ADD', info = 'Add: ADD A,r / ADD HL,rp' },
  { word = 'ADD A,', info = 'Add to accumulator' },
  { word = 'ADD HL,', info = 'Add to HL' },
  { word = 'ADC', info = 'Add with carry: ADC A,r / ADC HL,rp' },
  { word = 'SUB', info = 'Subtract: SUB r' },
  { word = 'SBC', info = 'Subtract with carry: SBC A,r / SBC HL,rp' },
  { word = 'AND', info = 'Logical AND: AND r' },
  { word = 'OR', info = 'Logical OR: OR r' },
  { word = 'XOR', info = 'Logical XOR: XOR r' },
  { word = 'CP', info = 'Compare: CP r (sets flags)' },
  { word = 'INC', info = 'Increment: INC r / INC rp' },
  { word = 'DEC', info = 'Decrement: DEC r / DEC rp' },
  { word = 'DAA', info = 'Decimal Adjust Accumulator' },
  { word = 'CPL', info = 'Complement Accumulator' },
  { word = 'NEG', info = 'Negate Accumulator' },
  { word = 'CCF', info = 'Complement Carry Flag' },
  { word = 'SCF', info = 'Set Carry Flag' },

  -- Rotate and Shift Group
  { word = 'RLCA', info = 'Rotate Left Circular A' },
  { word = 'RLA', info = 'Rotate Left A through carry' },
  { word = 'RRCA', info = 'Rotate Right Circular A' },
  { word = 'RRA', info = 'Rotate Right A through carry' },
  { word = 'RLC', info = 'Rotate Left Circular: RLC r' },
  { word = 'RL', info = 'Rotate Left through carry: RL r' },
  { word = 'RRC', info = 'Rotate Right Circular: RRC r' },
  { word = 'RR', info = 'Rotate Right through carry: RR r' },
  { word = 'SLA', info = 'Shift Left Arithmetic: SLA r' },
  { word = 'SRA', info = 'Shift Right Arithmetic: SRA r' },
  { word = 'SRL', info = 'Shift Right Logical: SRL r' },
  { word = 'RLD', info = 'Rotate Left Digit' },
  { word = 'RRD', info = 'Rotate Right Digit' },

  -- Bit Manipulation Group
  { word = 'BIT', info = 'Test Bit: BIT b,r' },
  { word = 'SET', info = 'Set Bit: SET b,r' },
  { word = 'RES', info = 'Reset Bit: RES b,r' },

  -- Jump Group
  { word = 'JP', info = 'Jump: JP nn / JP cc,nn' },
  { word = 'JP NZ,', info = 'Jump if Not Zero' },
  { word = 'JP Z,', info = 'Jump if Zero' },
  { word = 'JP NC,', info = 'Jump if No Carry' },
  { word = 'JP C,', info = 'Jump if Carry' },
  { word = 'JP PO,', info = 'Jump if Parity Odd' },
  { word = 'JP PE,', info = 'Jump if Parity Even' },
  { word = 'JP P,', info = 'Jump if Positive' },
  { word = 'JP M,', info = 'Jump if Minus' },
  { word = 'JP (HL)', info = 'Jump to address in HL' },
  { word = 'JR', info = 'Jump Relative: JR e / JR cc,e' },
  { word = 'JR NZ,', info = 'Jump Relative if Not Zero' },
  { word = 'JR Z,', info = 'Jump Relative if Zero' },
  { word = 'JR NC,', info = 'Jump Relative if No Carry' },
  { word = 'JR C,', info = 'Jump Relative if Carry' },
  { word = 'DJNZ', info = 'Decrement B, Jump if Not Zero' },

  -- Call and Return Group
  { word = 'CALL', info = 'Call subroutine: CALL nn / CALL cc,nn' },
  { word = 'CALL NZ,', info = 'Call if Not Zero' },
  { word = 'CALL Z,', info = 'Call if Zero' },
  { word = 'CALL NC,', info = 'Call if No Carry' },
  { word = 'CALL C,', info = 'Call if Carry' },
  { word = 'RET', info = 'Return from subroutine' },
  { word = 'RET NZ', info = 'Return if Not Zero' },
  { word = 'RET Z', info = 'Return if Zero' },
  { word = 'RET NC', info = 'Return if No Carry' },
  { word = 'RET C', info = 'Return if Carry' },
  { word = 'RETI', info = 'Return from Interrupt' },
  { word = 'RETN', info = 'Return from NMI' },
  { word = 'RST', info = 'Restart: RST p (00,08,10,18,20,28,30,38)' },

  -- Input/Output Group
  { word = 'IN', info = 'Input: IN A,(n) / IN r,(C)' },
  { word = 'IN A,(', info = 'Input to A from port' },
  { word = 'INI', info = 'Input and Increment' },
  { word = 'INIR', info = 'Input, Inc, Repeat' },
  { word = 'IND', info = 'Input and Decrement' },
  { word = 'INDR', info = 'Input, Dec, Repeat' },
  { word = 'OUT', info = 'Output: OUT (n),A / OUT (C),r' },
  { word = 'OUT (', info = 'Output to port' },
  { word = 'OUTI', info = 'Output and Increment' },
  { word = 'OTIR', info = 'Output, Inc, Repeat' },
  { word = 'OUTD', info = 'Output and Decrement' },
  { word = 'OTDR', info = 'Output, Dec, Repeat' },

  -- CPU Control Group
  { word = 'NOP', info = 'No Operation' },
  { word = 'HALT', info = 'Halt CPU' },
  { word = 'DI', info = 'Disable Interrupts' },
  { word = 'EI', info = 'Enable Interrupts' },
  { word = 'IM 0', info = 'Interrupt Mode 0' },
  { word = 'IM 1', info = 'Interrupt Mode 1' },
  { word = 'IM 2', info = 'Interrupt Mode 2' },

  -- sjasmplus Directives
  { word = 'ORG', info = 'Set origin address: ORG address' },
  { word = 'DEVICE', info = 'Set device: DEVICE ZXSPECTRUM48' },
  { word = 'DEVICE ZXSPECTRUM48', info = 'ZX Spectrum 48K device' },
  { word = 'DEVICE ZXSPECTRUM128', info = 'ZX Spectrum 128K device' },
  { word = 'DEVICE ZXSPECTRUMNEXT', info = 'ZX Spectrum Next device' },
  { word = 'EQU', info = 'Equate: label EQU value' },
  { word = 'DB', info = 'Define Byte(s): DB value,value,...' },
  { word = 'DW', info = 'Define Word(s): DW value,value,...' },
  { word = 'DS', info = 'Define Space: DS count[,fill]' },
  { word = 'DEFS', info = 'Define Space (alias)' },
  { word = 'DEFB', info = 'Define Byte (alias)' },
  { word = 'DEFW', info = 'Define Word (alias)' },
  { word = 'DEFM', info = 'Define Message (string)' },
  { word = 'INCLUDE', info = 'Include file: INCLUDE "file.asm"' },
  { word = 'INCBIN', info = 'Include binary: INCBIN "file.bin"' },
  { word = 'SAVESNA', info = 'Save SNA snapshot: SAVESNA "file.sna", start' },
  { word = 'SAVETAP', info = 'Save TAP file: SAVETAP "file.tap", start' },
  { word = 'SAVEBIN', info = 'Save binary: SAVEBIN "file.bin", start, length' },
  { word = 'SAVENEX', info = 'Save NEX file for ZX Next' },
  { word = 'MACRO', info = 'Define macro: MACRO name [args]' },
  { word = 'ENDM', info = 'End macro definition' },
  { word = 'IF', info = 'Conditional: IF expression' },
  { word = 'ELSE', info = 'Conditional else' },
  { word = 'ENDIF', info = 'End conditional' },
  { word = 'IFDEF', info = 'If defined: IFDEF symbol' },
  { word = 'IFNDEF', info = 'If not defined: IFNDEF symbol' },
  { word = 'MODULE', info = 'Begin module: MODULE name' },
  { word = 'ENDMODULE', info = 'End module' },
  { word = 'STRUCT', info = 'Define structure: STRUCT name' },
  { word = 'ENDS', info = 'End structure' },
  { word = 'ALIGN', info = 'Align to boundary: ALIGN n' },
  { word = 'PAGE', info = 'Set memory page' },
  { word = 'SLOT', info = 'Set memory slot' },
  { word = 'END', info = 'End assembly / set entry point' },
}

-- ZX Spectrum specific constants
local zx_constants = {
  -- Screen memory
  { word = '0x4000', info = 'SCREEN_START - Display file start' },
  { word = '0x5800', info = 'ATTR_START - Attribute file start' },
  { word = '0x5B00', info = 'SCREEN_END - End of screen memory' },
  { word = '16384', info = 'SCREEN_START decimal' },
  { word = '22528', info = 'ATTR_START decimal' },
  { word = '6144', info = 'Screen bitmap size (bytes)' },
  { word = '768', info = 'Attribute file size (bytes)' },

  -- System variables
  { word = '0x5C00', info = 'SYSVARS - System variables start' },
  { word = '0x5CB6', info = 'STKBOT - Calculator stack bottom' },
  { word = '0x5C8D', info = 'ATTR_P - Permanent attribute' },
  { word = '0x5C8F', info = 'ATTR_T - Temporary attribute' },
  { word = '0x5C78', info = 'BORDCR - Border colour' },

  -- ROM routines
  { word = '0x0010', info = 'RST 10 - Print character in A' },
  { word = '0x0038', info = 'RST 38 - Interrupt handler' },
  { word = '0x0D6B', info = 'CLS - Clear screen' },
  { word = '0x1601', info = 'CHAN_OPEN - Open channel' },
  { word = '0x15F2', info = 'PRINT_A - Print character in A' },

  -- I/O Ports
  { word = '0xFE', info = 'ULA port - border/speaker/keyboard' },
  { word = '0x7FFD', info = '128K memory paging port' },

  -- Keyboard rows (active low)
  { word = '0xFEFE', info = 'Keyboard row: CAPS-V' },
  { word = '0xFDFE', info = 'Keyboard row: A-G' },
  { word = '0xFBFE', info = 'Keyboard row: Q-T' },
  { word = '0xF7FE', info = 'Keyboard row: 1-5' },
  { word = '0xEFFE', info = 'Keyboard row: 0-6' },
  { word = '0xDFFE', info = 'Keyboard row: P-Y' },
  { word = '0xBFFE', info = 'Keyboard row: ENTER-H' },
  { word = '0x7FFE', info = 'Keyboard row: SPACE-B' },
}

-- Combine all completions
local all_completions = {}
for _, item in ipairs(z80_instructions) do
  table.insert(all_completions, item)
end
for _, item in ipairs(zx_constants) do
  table.insert(all_completions, item)
end

-- Omnifunc for Z80 completion
function _G.Z80Complete(findstart, base)
  if findstart == 1 then
    -- Find start of word
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local start = col
    while start > 0 and line:sub(start, start):match('[%w_]') do
      start = start - 1
    end
    return start
  else
    -- Find matches
    local matches = {}
    local pattern = '^' .. base:upper()
    for _, item in ipairs(all_completions) do
      if item.word:upper():match(pattern) then
        table.insert(matches, {
          word = item.word,
          info = item.info,
          menu = '[Z80]',
        })
      end
    end
    return matches
  end
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'z80', 'asm' },
  callback = function()
    vim.opt_local.omnifunc = 'v:lua.Z80Complete'
  end,
})

-- ============================================================================
-- Build and Run Functions
-- ============================================================================

-- Get current asm file or default
local function get_asm_file()
  local current = vim.fn.expand('%:p')
  if current:match('%.asm$') then
    return current
  end
  -- Try to find an asm file in current directory
  local files = vim.fn.glob(project_root .. '/**/*.asm', false, true)
  if #files > 0 then
    return files[1]
  end
  return nil
end

-- Find output file (.sna or .tap) in a directory.
-- Prefers .sna over .tap because the snapshot boots instantly — the .tap
-- has to go through the BASIC autostart loader sequence and a full LOAD ""
-- before our code runs. See the long comment block in any template main.asm.
--
-- Resolution order:
--   1. <dir>/<dirname>.sna  -- the template convention (SAVESNA "<name>.sna")
--   2. <dir>/<asm-basename>.sna   -- when the asm is named after the program
--   3. any .sna or .tap in <dir>
local function find_output_file(dir, basename)
  local dname = vim.fn.fnamemodify(dir, ':t')
  -- 1. dirname.sna / dirname.tap (matches the template's SAVESNA convention)
  for _, ext in ipairs({ '.sna', '.tap' }) do
    local f = dir .. '/' .. dname .. ext
    if vim.fn.filereadable(f) == 1 then return f end
  end
  -- 2. asm-basename.sna / asm-basename.tap (when asm is named after program)
  for _, ext in ipairs({ '.sna', '.tap' }) do
    local f = dir .. '/' .. basename .. ext
    if vim.fn.filereadable(f) == 1 then return f end
  end
  -- 3. any output in directory
  local outputs = vim.fn.glob(dir .. '/*.sna', false, true)
  if #outputs == 0 then
    outputs = vim.fn.glob(dir .. '/*.tap', false, true)
  end
  if #outputs > 0 then return outputs[1] end
  return nil
end

-- Launch a child process in an environment safe for the bundled fuse build.
-- LD_LIBRARY_PATH is removed so fuse loads the nix-store glibc it was linked
-- against (host alsa/pipewire libs can pull in a newer glibc and cause
-- "GLIBC_ABI_DT_X86_64_PLT not found" at startup).
local function spawn_emulator(cmd)
  vim.fn.jobstart(cmd, {
    detach = true,
    env = { LD_LIBRARY_PATH = '' },
  })
end

-- Compile current assembly file
function M.compile()
  local file = get_asm_file()
  if not file then
    vim.notify('No assembly file found', vim.log.levels.ERROR)
    return
  end

  local dir = vim.fn.fnamemodify(file, ':h')
  local basename = vim.fn.fnamemodify(file, ':t:r')

  -- Save current file if it's the one being compiled
  if vim.fn.expand('%:p') == file then
    vim.cmd('write')
  end

  local cmd = string.format(
    'cd %s && sjasmplus --fullpath --sld=%s.sld %s 2>&1',
    vim.fn.shellescape(dir),
    basename,
    vim.fn.fnamemodify(file, ':t')
  )

  vim.notify('Compiling ' .. vim.fn.fnamemodify(file, ':t') .. '...', vim.log.levels.INFO)

  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code == 0 then
    vim.notify('Compilation successful!', vim.log.levels.INFO)
  else
    vim.notify('Compilation failed:\n' .. output, vim.log.levels.ERROR)
  end

  -- Parse errors into quickfix
  local qf_list = {}
  for line in output:gmatch('[^\r\n]+') do
    local file_match, line_num, severity, msg = line:match('^(.-)%((%d+)%):%s+(%w+):%s+(.+)$')
    if file_match then
      table.insert(qf_list, {
        filename = file_match,
        lnum = tonumber(line_num),
        type = severity == 'error' and 'E' or 'W',
        text = msg,
      })
    end
  end

  vim.fn.setqflist(qf_list)
  if #qf_list > 0 then
    vim.cmd('copen')
  end
end

-- Launch FUSE for the compiled output.
--   .sna  →  --snapshot (instant boot, the dev fast path)
--   .tap  →  --auto-load --tape (BASIC autostart sequence, authentic)
-- --no-sound silences the noisy "couldn't open sound device" warnings
-- when running in a dev shell that has no working audio backend.
local function launch_emulator(run_file)
  local name = vim.fn.fnamemodify(run_file, ':t')
  local base = { 'fuse', '--machine', '48', '--no-sound', '--graphics-filter', '4x' }
  if run_file:match('%.sna$') then
    vim.list_extend(base, { '--snapshot', run_file })
    spawn_emulator(base)
    vim.notify('Running ' .. name .. ' in FUSE (instant SNA snapshot)', vim.log.levels.INFO)
  else
    vim.list_extend(base, { '--auto-load', '--tape', run_file })
    spawn_emulator(base)
    vim.notify('Running ' .. name .. ' in FUSE (BASIC autostart)', vim.log.levels.INFO)
  end
end

-- Run compiled program (smart: FUSE for .tap, ZEsarUX for .sna)
function M.run()
  local file = get_asm_file()
  if not file then
    vim.notify('No assembly file found', vim.log.levels.ERROR)
    return
  end

  local dir = vim.fn.fnamemodify(file, ':h')
  local basename = vim.fn.fnamemodify(file, ':t:r')
  local run_file = find_output_file(dir, basename)

  if not run_file then
    vim.notify('No .sna or .tap file found. Compile first!', vim.log.levels.WARN)
    return
  end

  launch_emulator(run_file)
end

-- Force run in ZEsarUX (even for .tap files)
function M.run_zesarux()
  local file = get_asm_file()
  if not file then
    vim.notify('No assembly file found', vim.log.levels.ERROR)
    return
  end

  local dir = vim.fn.fnamemodify(file, ':h')
  local basename = vim.fn.fnamemodify(file, ':t:r')
  local run_file = find_output_file(dir, basename)

  if not run_file then
    vim.notify('No .sna or .tap file found. Compile first!', vim.log.levels.WARN)
    return
  end

  -- Use --tape flag for .tap files so ZEsarUX SmartLoads them
  if run_file:match('%.tap$') then
    spawn_emulator({ 'zesarux', '--tape', run_file })
  else
    spawn_emulator({ 'zesarux', '--snap', run_file })
  end
  vim.notify('Launched ZEsarUX with ' .. vim.fn.fnamemodify(run_file, ':t'), vim.log.levels.INFO)
end

-- Run in ZEsarUX with debug mode (ZRCP enabled)
function M.run_debug()
  local file = get_asm_file()
  if not file then
    vim.notify('No assembly file found', vim.log.levels.ERROR)
    return
  end

  local dir = vim.fn.fnamemodify(file, ':h')
  local basename = vim.fn.fnamemodify(file, ':t:r')
  local run_file = find_output_file(dir, basename)

  if not run_file then
    vim.notify('No .sna or .tap file found. Compile first!', vim.log.levels.WARN)
    return
  end

  local cmd = {
    'zesarux',
    '--noconfigfile',
    '--machine', '48k',
    '--enable-remoteprotocol',
    '--disable-autoframeskip',
  }
  if run_file:match('%.tap$') then
    table.insert(cmd, '--tape')
  else
    table.insert(cmd, '--snap')
  end
  table.insert(cmd, run_file)

  spawn_emulator(cmd)
  vim.notify('Launched ZEsarUX in debug mode (ZRCP port 10000)', vim.log.levels.INFO)
end

-- Force run in FUSE emulator
function M.run_fuse()
  local file = get_asm_file()
  if not file then
    vim.notify('No assembly file found', vim.log.levels.ERROR)
    return
  end

  local dir = vim.fn.fnamemodify(file, ':h')
  local basename = vim.fn.fnamemodify(file, ':t:r')
  local run_file = find_output_file(dir, basename)

  if not run_file then
    vim.notify('No .sna or .tap file found. Compile first!', vim.log.levels.WARN)
    return
  end

  local fuse_base = { 'fuse', '--machine', '48', '--no-sound', '--graphics-filter', '4x' }
  if run_file:match('%.tap$') then
    vim.list_extend(fuse_base, { '--auto-load', '--tape', run_file })
  else
    vim.list_extend(fuse_base, { '--snapshot', run_file })
  end
  spawn_emulator(fuse_base)
  vim.notify('Launched FUSE with ' .. vim.fn.fnamemodify(run_file, ':t'), vim.log.levels.INFO)
end

-- Build and run in one step
function M.build_and_run()
  M.compile()
  if vim.v.shell_error == 0 then
    vim.defer_fn(function()
      M.run()
    end, 500)
  end
end

-- ============================================================================
-- New Program Creator
-- ============================================================================

-- Create a new Z80 program in its own subfolder
function M.new_program()
  vim.ui.input({ prompt = 'New program name: ' }, function(name)
    if not name or name == '' then return end

    -- Sanitize: lowercase, spaces to hyphens, strip invalid chars
    name = name:lower():gsub('%s+', '-'):gsub('[^%w-]', '')
    if name == '' then
      vim.notify('Invalid program name', vim.log.levels.ERROR)
      return
    end

    local dir = project_root .. '/' .. name

    if vim.fn.isdirectory(dir) == 1 then
      vim.notify('Directory already exists: ' .. name, vim.log.levels.ERROR)
      return
    end

    -- Run the new-program script
    local script = project_root .. '/scripts/z80-new-program'
    local output = vim.fn.system({ script, name })
    if vim.v.shell_error ~= 0 then
      vim.notify('Failed to create program:\n' .. output, vim.log.levels.ERROR)
      return
    end

    -- Open the new file
    vim.cmd('edit ' .. dir .. '/main.asm')
    vim.notify('Created new program: ' .. name, vim.log.levels.INFO)
  end)
end

-- Pick and open an existing program
function M.pick_program()
  -- Find all .asm files in immediate subdirectories
  local files = vim.fn.glob(project_root .. '/*/*.asm', false, true)

  -- Filter out non-program directories
  local exclude = { 'z80-sample-program', 'tapes', 'img', '.vscode-extensions', '.claude', 'scripts' }
  local exclude_set = {}
  for _, d in ipairs(exclude) do exclude_set[d] = true end

  local items = {}
  for _, f in ipairs(files) do
    local rel = f:sub(#project_root + 2)
    local dir_name = rel:match('^([^/]+)/')
    if dir_name and not exclude_set[dir_name] then
      table.insert(items, rel)
    end
  end
  table.sort(items)

  if #items == 0 then
    vim.notify('No programs found', vim.log.levels.WARN)
    return
  end

  vim.ui.select(items, { prompt = 'Select program to open:' }, function(choice)
    if choice then
      vim.cmd('edit ' .. project_root .. '/' .. choice)
    end
  end)
end

-- ============================================================================
-- Reference Documentation
-- ============================================================================

local reference_urls = {
  mnemonics = 'http://www.z80.info/z80syntx.htm',
  charset = 'https://worldofspectrum.net/ZXBasicManual/zxmanappa.html',
  manual = 'http://www.retro8bitcomputers.co.uk/Content/downloads/manuals/ZX-Spectrum-48K-Manual.pdf',
  rom = 'https://skoolkid.github.io/rom/maps/routines.html',
  chibiakumas = 'https://www.chibiakumas.com/z80/ZXSpectrum.php',
  cheatsheet = 'https://www.chibiakumas.com/book/CheatSheetCollection.pdf',
}

function M.open_reference(name)
  local url = reference_urls[name]
  if url then
    vim.fn.jobstart({ 'xdg-open', url }, { detach = true })
    vim.notify('Opening ' .. name .. ' reference...', vim.log.levels.INFO)
  else
    vim.notify('Unknown reference: ' .. name, vim.log.levels.ERROR)
  end
end

function M.show_references()
  local items = {}
  for name, url in pairs(reference_urls) do
    table.insert(items, name .. ': ' .. url)
  end
  table.sort(items)

  vim.ui.select(items, {
    prompt = 'Select reference to open:',
  }, function(choice)
    if choice then
      local name = choice:match('^(%w+):')
      M.open_reference(name)
    end
  end)
end

-- ============================================================================
-- Z80 Instruction Quick Help (hover-like)
-- ============================================================================

local instruction_help = {
  ['LD'] = 'Load register/memory. Flags: None affected\nForms: LD r,r\' | LD r,n | LD r,(HL) | LD (HL),r | LD rp,nn',
  ['ADD'] = 'Add. Flags: S Z H P/V N C affected\nForms: ADD A,r | ADD A,n | ADD A,(HL) | ADD HL,rp',
  ['SUB'] = 'Subtract. Flags: S Z H P/V N C affected\nForms: SUB r | SUB n | SUB (HL)',
  ['AND'] = 'Logical AND. Flags: S Z H=1 P/V N=0 C=0\nForms: AND r | AND n | AND (HL)',
  ['OR'] = 'Logical OR. Flags: S Z H=0 P/V N=0 C=0\nForms: OR r | OR n | OR (HL)',
  ['XOR'] = 'Logical XOR. Flags: S Z H=0 P/V N=0 C=0\nForms: XOR r | XOR n | XOR (HL)',
  ['CP'] = 'Compare (subtract without storing). Flags: S Z H P/V N C affected\nForms: CP r | CP n | CP (HL)',
  ['INC'] = 'Increment. Flags: S Z H P/V N affected (not C)\nForms: INC r | INC rp | INC (HL)',
  ['DEC'] = 'Decrement. Flags: S Z H P/V N affected (not C)\nForms: DEC r | DEC rp | DEC (HL)',
  ['JP'] = 'Jump. Flags: None affected\nForms: JP nn | JP cc,nn | JP (HL) | JP (IX) | JP (IY)',
  ['JR'] = 'Jump Relative (-128 to +127). Flags: None affected\nForms: JR e | JR cc,e (cc: Z/NZ/C/NC only)',
  ['CALL'] = 'Call subroutine. Flags: None affected\nPushes return address to stack\nForms: CALL nn | CALL cc,nn',
  ['RET'] = 'Return from subroutine. Flags: None affected\nPops return address from stack\nForms: RET | RET cc',
  ['PUSH'] = 'Push to stack. Flags: None affected\nForms: PUSH rp (AF/BC/DE/HL/IX/IY)',
  ['POP'] = 'Pop from stack. Flags: None affected (except POP AF)\nForms: POP rp (AF/BC/DE/HL/IX/IY)',
  ['LDIR'] = 'Block copy HL->DE, BC times. Flags: H=0 P/V=0 N=0\nUsage: LD HL,src | LD DE,dst | LD BC,len | LDIR',
  ['DJNZ'] = 'Decrement B, Jump if Not Zero. Flags: None affected\nUseful for loops: LD B,count | loop: ... | DJNZ loop',
  ['BIT'] = 'Test bit. Flags: Z affected (Z=1 if bit is 0)\nForms: BIT b,r | BIT b,(HL)',
  ['SET'] = 'Set bit to 1. Flags: None affected\nForms: SET b,r | SET b,(HL)',
  ['RES'] = 'Reset bit to 0. Flags: None affected\nForms: RES b,r | RES b,(HL)',
  ['IN'] = 'Input from port. Flags: S Z H P/V N affected (IN r,(C))\nForms: IN A,(n) | IN r,(C)',
  ['OUT'] = 'Output to port. Flags: None affected\nForms: OUT (n),A | OUT (C),r',
  ['EI'] = 'Enable Interrupts. Takes effect after next instruction.',
  ['DI'] = 'Disable Interrupts.',
  ['HALT'] = 'Halt CPU until interrupt. Power-saving wait state.',
  ['NOP'] = 'No Operation. 4 T-states. Useful for timing.',
}

function M.instruction_help()
  local word = vim.fn.expand('<cword>'):upper()
  local help = instruction_help[word]
  if help then
    vim.notify(word .. ':\n' .. help, vim.log.levels.INFO)
  else
    vim.notify('No help for: ' .. word, vim.log.levels.WARN)
  end
end

-- ============================================================================
-- Keymappings (to be sourced by .exrc)
-- ============================================================================

-- These are set up in .exrc using which-key
-- Here we just expose the functions globally
_G.Z80Dev = M

-- Quick access commands
vim.api.nvim_create_user_command('Z80Compile', function() M.compile() end, {})
vim.api.nvim_create_user_command('Z80Run', function() M.run() end, {})
vim.api.nvim_create_user_command('Z80Debug', function() M.run_debug() end, {})
vim.api.nvim_create_user_command('Z80Fuse', function() M.run_fuse() end, {})
vim.api.nvim_create_user_command('Z80BuildRun', function() M.build_and_run() end, {})
vim.api.nvim_create_user_command('Z80Refs', function() M.show_references() end, {})
vim.api.nvim_create_user_command('Z80Help', function() M.instruction_help() end, {})
vim.api.nvim_create_user_command('Z80New', function() M.new_program() end, {})
vim.api.nvim_create_user_command('Z80Pick', function() M.pick_program() end, {})

-- ============================================================================
-- Status Line Info
-- ============================================================================

-- Returns Z80 context for status line if in asm file
function M.statusline()
  if vim.bo.filetype ~= 'z80' and vim.bo.filetype ~= 'asm' then
    return ''
  end
  local file = vim.fn.expand('%:p')
  local dir = vim.fn.fnamemodify(file, ':h')
  local program = vim.fn.fnamemodify(dir, ':t')
  return ' Z80 | ' .. program .. ' | sjasmplus '
end

-- ============================================================================
-- Auto-compile on save (optional, disabled by default)
-- ============================================================================

-- Uncomment to enable auto-compile on save:
-- vim.api.nvim_create_autocmd('BufWritePost', {
--   pattern = '*.asm',
--   callback = function()
--     M.compile()
--   end,
-- })

-- ============================================================================
-- Which-Key Registration - flat <leader>p + key
-- ============================================================================

-- Register keymaps: <leader>p + single key
vim.keymap.set('n', '<leader>pc', '<cmd>Z80Compile<cr>', { desc = 'Compile' })
vim.keymap.set('n', '<leader>pr', '<cmd>Z80BuildRun<cr>', { desc = 'Run (build+run)' })
vim.keymap.set('n', '<leader>pz', '<cmd>Z80Run<cr>', { desc = 'ZEsarUX' })
vim.keymap.set('n', '<leader>pf', '<cmd>Z80Fuse<cr>', { desc = 'FUSE' })
vim.keymap.set('n', '<leader>pd', '<cmd>Z80Debug<cr>', { desc = 'Debug' })
vim.keymap.set('n', '<leader>ph', '<cmd>Z80Help<cr>', { desc = 'Help (instruction)' })
vim.keymap.set('n', '<leader>po', '<cmd>Z80Refs<cr>', { desc = 'Open docs' })
vim.keymap.set('n', '<leader>pq', '<cmd>copen<cr>', { desc = 'Quickfix' })
vim.keymap.set('n', '<leader>pn', '<cmd>Z80New<cr>', { desc = 'New program' })
vim.keymap.set('n', '<leader>pp', '<cmd>Z80Pick<cr>', { desc = 'Pick program' })
vim.keymap.set('n', '<leader>pt', function()
  -- Find actual tape files (not directories), including .TAP uppercase
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
      spawn_emulator({ 'fuse', '--machine', '48', '--no-sound',
        '--graphics-filter', '4x', '--auto-load', '--tape', choice })
      vim.notify('Loading: ' .. choice, vim.log.levels.INFO)
    end
  end)
end, { desc = 'Tapes' })

-- Register with which-key for nice menu display
local function register_which_key()
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add({
      { "<leader>p", group = "Z80" },
    })
  end
end

register_which_key()
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    vim.defer_fn(register_which_key, 10)
  end,
  once = true,
})

return M
