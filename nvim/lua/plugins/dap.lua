-- Debugging. `delve` comes from home-manager (no mason).

local dap = require 'dap'
local dapui = require 'dapui'

dapui.setup {
  -- Characters that are more likely to work in every terminal.
  icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
  controls = {
    icons = {
      pause = '⏸',
      play = '▶',
      step_into = '⏎',
      step_over = '⏭',
      step_out = '⏮',
      step_back = 'b',
      run_last = '▶▶',
      terminate = '⏹',
      disconnect = '⏏',
    },
  },
}

dap.listeners.after.event_initialized['dapui_config'] = dapui.open
dap.listeners.before.event_terminated['dapui_config'] = dapui.close
dap.listeners.before.event_exited['dapui_config'] = dapui.close

require('dap-go').setup {
  delve = {
    -- On Windows delve must be run attached or it crashes.
    detached = vim.fn.has 'win32' == 0,
  },
}

-- dap-go's built-in "Debug" config passes `program = "${file}"` -- a single .go
-- file. Delve then compiles just that file as `command-line-arguments`, so a
-- package split across main.go + solution.go fails to build ("undefined: Part1")
-- and nvim-dap reports only "Failed to launch".
--
-- Every puzzle in aoc-go is one package per directory, so point Delve at the
-- current file's directory (the package) instead. These go first so <F5> + Enter
-- picks them over the single-file defaults.
table.insert(dap.configurations.go, 1, {
  type = 'go',
  name = 'Debug puzzle (package)',
  request = 'launch',
  mode = 'debug',
  program = '${fileDirname}',
  outputMode = 'remote',
})

table.insert(dap.configurations.go, 2, {
  type = 'go',
  name = 'Debug test (package)',
  request = 'launch',
  mode = 'test',
  program = '${fileDirname}',
  outputMode = 'remote',
})

vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })
vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>dB', function()
  dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
end, { desc = 'Debug: Set Breakpoint' })
