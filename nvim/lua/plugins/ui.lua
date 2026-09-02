-- Colorscheme, statusline, file tree, keybind hints, editing textobjects.

vim.cmd.colorscheme 'catppuccin'
vim.cmd.hi 'Comment gui=none'

require('which-key').setup()
require('which-key').add {
  { '<leader>c', group = '[C]ode' },
  { '<leader>d', group = '[D]ocument' },
  { '<leader>r', group = '[R]ename' },
  { '<leader>s', group = '[S]earch' },
  { '<leader>u', group = 'S[u]rround' },
  { '<leader>w', group = '[W]orkspace' },
  { '<leader>t', group = '[T]oggle' },
  { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
}

-- Shortened file path relative to cwd, keeping at most `length` trailing dirs
-- (port of LazyVim.lualine.pretty_path, minus the LazyVim.root dependency).
local function pretty_path(length)
  length = length or 3
  return function()
    local path = vim.fn.expand '%:p'
    if path == '' then
      return ''
    end
    local cwd = vim.uv.cwd()
    if cwd and path:find(cwd, 1, true) == 1 then
      path = path:sub(#cwd + 2)
    else
      path = vim.fn.expand '%:~'
    end

    local parts = vim.split(path, '[\\/]')
    if #parts > length + 1 then
      parts = { parts[1], '…', unpack(parts, #parts - length + 1, #parts) }
    end
    local out = table.concat(parts, '/')
    if vim.bo.modified then
      out = out .. ' ●'
    end
    if vim.bo.readonly or not vim.bo.modifiable then
      out = out .. ' 󰌾'
    end
    return out
  end
end

require('lualine').setup {
  options = {
    icons_enabled = true,
    component_separators = '|',
    section_separators = '',
  },
  sections = {
    lualine_a = {
      {
        'mode',
        fmt = function(str)
          return str:sub(1, 1)
        end,
      },
      { 'buffers' },
    },
    lualine_c = {
      { pretty_path(6) },
    },
    -- move metals status to the left
    -- vim.lsp.status() replaces fidget.nvim: it aggregates the $/progress
    -- messages every attached server sends. `:h vim.lsp.status()`
    lualine_x = { 'g:metals_status', 'searchcount' },
    lualine_y = { vim.lsp.status },
    lualine_z = { 'progress' },
  },
}

-- Better Around/Inside textobjects
--  - va)  - [V]isually select [A]round [)]paren
--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
--  - ci'  - [C]hange [I]nside [']quote
require('mini.ai').setup { n_lines = 500 }

-- Add/delete/replace surroundings (brackets, quotes, etc.)
--  - <leader>uaiw) - S[u]rround [A]dd [I]nner [W]ord [)]Paren
--  - <leader>ud'   - S[u]rround [D]elete [']quotes
--  - <leader>ur)'  - S[u]rround [R]eplace [)] [']
require('mini.surround').setup {
  mappings = {
    add = '<leader>ua', -- Add surrounding in Normal and Visual modes
    delete = '<leader>ud', -- Delete surrounding
    find = '<leader>uf', -- Find surrounding (to the right)
    find_left = '<leader>uF', -- Find surrounding (to the left)
    highlight = '<leader>uh', -- Highlight surrounding
    replace = '<leader>ur', -- Replace surrounding

    suffix_last = 'l', -- Suffix to search with "prev" method
    suffix_next = 'n', -- Suffix to search with "next" method
  },
}
